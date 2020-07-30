#!/usr/bin/env bb

(defn shell-throw
  [& args]
  (let [{:keys [out err exit] :as result} (apply shell/sh args)]
    (if-not (= exit 0)
      (throw (ex-info err result))
      out)))

(defn attach-volume
  [instance-id volume-id volume-device]
  (shell-throw
   "aws" "ec2" "attach-volume" "--instance-id" instance-id "--volume-id" volume-id "--device" volume-device))

(defn attachment-status
  [instance-id volume-id]
  (-> (shell-throw "aws" "ec2" "describe-volumes" "--filters" (str "Name=volume-id,Values=" volume-id) (str "Name=attachment.instance-id,Values=" instance-id) "--output" "json")
      (json/parse-string true)
      :Volumes
      first
      :Attachments
      first
      :State))

(defn get-volume-id
  [instance-id device]
  (-> (shell-throw "aws" "ec2" "describe-volumes" "--filters" (str "Name=attachment.instance-id,Values=" instance-id) (str "Name=attachment.device,Values=" device) "--output" "json")
      (json/parse-string true)
      :Volumes
      first
      :VolumeId))

(defn attach-and-wait
  [instance-id volume-id volume-device timeout]
  (loop [status (attachment-status instance-id volume-id)
         seconds timeout]
    (cond

      (= status "attached")
      (str "Volume " volume-id " attached to instance id " instance-id)

      (> 0 seconds)
      (throw (ex-info (str "Unable to attach volume " volume-id " to instance " instance-id ". Status: " status ". Waited " timeout " seconds.") {:type :timeout}))

      (= status "attaching")
      (do (Thread/sleep 1000)
          (recur (attachment-status instance-id volume-id) (dec seconds)))
      
      (= status nil) 
      (do
        (attach-volume instance-id volume-id volume-device)
        (recur (attachment-status instance-id volume-id) seconds))

      :else
      (throw (ex-info (str "Unable to attach volume " volume-id " to instance " instance-id ". Status: " status ".") {:type :fault})))))

(defn detach-volume
  [instance-id volume-id]
  (shell-throw "aws" "ec2" "detach-volume" "--volume-id" volume-id "--instance-id" instance-id))

(defn detach-and-wait
  [instance-id volume-id timeout]
  (loop [status (attachment-status instance-id volume-id)
         seconds timeout]
    (cond
      (= status "attached")
      (do (detach-volume instance-id volume-id)
          (recur (attachment-status instance-id volume-id) seconds))
      
      (= status "detaching")
      (recur (attachment-status instance-id volume-id) (dec seconds))
      
      (= status "attaching")
      (recur (attachment-status instance-id volume-id) (dec seconds))
      
      (= status nil)
      :ok
      
      :else
      (throw (ex-info (str "Unable to detach volume. Unknown status: " status) {:type :fault})))))

(defn instance-status
  [instance-id]
  (-> (shell-throw "aws" "ec2" "describe-instances" "--instance-ids" instance-id "--output" "json")
      (json/parse-string true)
      :Reservations
      first
      :Instances
      first
      :State
      :Name))

(defn stop-instance
  [instance-id]
  (shell-throw "aws" "ec2" "stop-instances" "--instance-ids" instance-id))

(defn stop-instance-and-wait
  [instance-id timeout]
  (loop [status (instance-status instance-id)
         seconds timeout]
    (cond
      (= status "stopped")
      :ok

      (> 0 seconds)
      (throw (ex-info (str "Unable to stop instance " instance-id " within the given timeout of " timeout " seconds.")))
      
      (#{"pending" "stopping"} status)
      (do (Thread/sleep 1000)
          (recur (instance-status instance-id) (dec seconds)))

      (= status "running")
      (do (stop-instance instance-id)
          (recur (instance-status instance-id) seconds))

      :else
      (throw (ex-info (str "Unable to stop instance " instance-id ". Status: " status))))))

(defn start-instance
  [instance-id]
  (shell-throw "aws" "ec2" "start-instances" "--instance-ids" instance-id))

(defn start-instance-and-wait
  [instance-id timeout]
  (loop [status (instance-status instance-id)
         seconds timeout]
    (cond
      (= status "running")
      :ok
      
      (> 0 seconds)
      (throw (ex-info (str "Unable to start instance " instance-id " within the given timeout of " timeout " seconds.") {:type :fault}))
      
      (#{"pending" "stopping"} status)
      (do (Thread/sleep 1000)
          (recur (instance-status instance-id) (dec seconds)))
      
      (= status "stopped")
      (do (start-instance instance-id)
          (recur (instance-status instance-id) seconds))
      
      :else
      (throw (ex-info (str "Unable to start instance " instance-id ". Status: " status) {:type :fault})))))

(defn stop
  [lxk-instance-id volume-id instance-id]
  (println "Stopping LXK instance")
  (stop-instance-and-wait lxk-instance-id 120)
  (println "Detaching Root volume from LXK instance")
  (detach-and-wait lxk-instance-id volume-id 20)
  (println "Attaching Root volume to this instance")
  (attach-and-wait instance-id volume-id "/dev/sdf" 20))

(defn start
  [lxk-instance-id volume-id instance-id]
  (println "Detaching volume from this instance")
  (detach-and-wait instance-id volume-id 20)
  (println "Attaching volume to LXK instance")
  (attach-and-wait lxk-instance-id volume-id "/dev/sda1" 20)
  (println "Starting LXK instance")
  (start-instance-and-wait lxk-instance-id 120))

(let [command (first *command-line-args*)
      lxk-instance-id (second *command-line-args*)
      instance-id (:body (babashka.curl/get "http://169.254.169.254/latest/meta-data/instance-id"))]
  (case command
    "get-volume" (println (get-volume-id lxk-instance-id (nth *command-line-args* 2)))
    "start" (start lxk-instance-id (nth *command-line-args* 2) instance-id)
    "stop" (stop lxk-instance-id (nth *command-line-args* 2) instance-id)))
