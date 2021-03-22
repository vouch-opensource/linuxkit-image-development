# Linuxkit Image Development

This is a set of tools to help development of LinuxKit images on AWS. 

## Rationale

The examples in the LinuxKit project for working with AWS make use of the `linuxkit push aws` command, which
on creates an AMI. The tools in this repo try to solve 2 problems that this approach has:

1. The user has to manually setup the right infrastructure and permissions to make the push command work.
2. The development cycle with this approach is painfully slow. Under the hood, linuxkit pushes the raw image 
   to S3 and triggers a VM Snapshot Import task to create the AMI. This process may take up to 30 mins.

## Tools

### AWS Account Setup

This repository provides a terraform module that sets up the required infrastructure for automating linuxkit push commands:
- an S3 bucket in which to store the raw images
- an IAM policy that allows access to this bucket and allows triggering the VM Import Snapshot task.

### Faster Development Workflow 

Once you applied the terraform and your setup is completed:

1. Whether git clone your project or copy your linuxkit yaml file to `./sync`
2. (Optional) To start to using a private Docker Registry if required for your build. Run the following
```make
make remote-docker-login URL=registry.hub.docker.com USERNAME=john PASSWORD=123`
```
3. Build and deploy your image to linuxkit instance
```make
make remote-deploy BUILD_INSTANCE_NAME="linuxkit-build" LINUXKIT_INSTANCE_NAME="linuxkit-instance" FILE="linuxkit.yml"
````
4. Test the image built sshing your linuxkit instance
1. Once you're ready to build a new AMI. Run the following:
```make
make remote-push BUILD_INSTANCE_NAME="linuxkit-build" FILE="linuxkit.yml"
````
You'll find the AMI ID in the command's output.

#### Mechanics

##### Make commands

| Command | Inputs | Description |
| ----------- | ----------- | ----------- |
| `make remote-docker-login` | `URL`, `USERNAME`, `PASSWORD` | Build machine log in to a private Docker Registry. `URL` can be any registry url available as github, dockerhub, gcr, ecr...|
| `make remote-sync` |  `BUILD_INSTANCE_NAME` |  Copy `./sync` local directory to build machine. |
| `make remote-build` |  `BUILD_INSTANCE_NAME`, `FILE` |  Build the image with the given file name. Notice that `FILE` is a `./sync` relative path. |
| `make remote-deploy` |  `BUILD_INSTANCE_NAME`, `LINUXKIT_INSTANCE_NAME`, `FILE` | Build the image with the given file name and mount it on the given linuxkit instance's root volume. Notice that the instance names are EC2 Tag Names. |
| `make remote-push` |  `BUILD_INSTANCE_NAME`, `LINUXKIT_INSTANCE_NAME`, `FILE` |  Build the image and upload its raw file to AWS for AMI creation. Once it's done, you can find the AMI ID in output.|

##### Input Variables

- `linuxkit_instance_id` - The linuxkit instance under management
- `linuxkit_bucket_name` - S3 bucket name for storing the exported linuxkit image
- `machine_name` - Name of the build machine
- `instance_ondemand` - Whether the build machine is ondemand or spot
- `instance_type` - The instance type of build machine to start
- `key_pair_name` - Key name of the Key Pair to use for the instance
- `vpc_id` - VPC ID of the build machine to launch in
- `subnet_id` - Subnet ID of the build machine to launch in
- `ebs_kms_key_arn` - ARN of the KMS key to use when linuxkit instances has encrypted volumes
- `vmimport_service_role_enabled` - Enable vmimport service role creation
- `install` - Set of strings with versions of packages to be installed from userdata script. The block supports the following:
  - `linuxkit_version` - Desired [linuxkit](https://github.com/linuxkit/linuxkit) version. The value can be any reference that would be accepted by the git checkout command, including branch and tag names.
  - `babashka_version` - Desired [babashka](https://github.com/babashka/babashka) version. The value can be any reference that would be accepted by the git checkout command, including branch and tag names.

##### Usage

###### Basic example

In your terraform code add something like this:

```hcl
resource "aws_kms_key" "linuxkit_instance" {
  description = "KMS linuxkit instance"
  deletion_window_in_days = 10
}

module "lxk-dev" {
  source = "github.com/vouch-opensource/linuxkit-image-development/dev_cycle/terraform"
  instance_type = "t3.medium"
  linuxkit_instance_id = "i-1234567890"
  key_pair_name = "key-name"
  machine_name = "linuxkit-build"
  vpc_id = "vpc-123456"
  subnet_id = "subnet-123456"
  ebs_kms_key_arn = aws_kms_key.linuxkit_instance.arn
  bucket_name = "linuxkit-imports"
}
```

###### vmimport

Sometimes you have multiple environments and you want to create the vmimport service role separately:

```hcl

# creates the vmimport service role with no bucket creation; also, allow the role to read buckets with the given prefix
module "linuxkit_import" {
  source = "github.com/vouch-opensource/linuxkit-image-development/vmimport/terraform"
  bucket_name = "my-linuxkit-images*"
  bucket_enabled = false
}

resource "aws_kms_key" "linuxkit_instance" {
  description = "KMS linuxkit instance"
  deletion_window_in_days = 10
}

# provision the development environment with no vmimport service role
module "lxk-dev" {
  source = "github.com/vouch-opensource/linuxkit-image-development/dev_cycle/terraform"
  instance_type = "t3.medium"
  linuxkit_instance_id = "i-1234567890"
  key_pair_name = "key-name"
  machine_name = "linuxkit-build"
  vpc_id = "vpc-123456"
  subnet_id = "subnet-123456"
  ebs_kms_key_arn = aws_kms_key.linuxkit_instance.arn
  bucket_name = "linuxkit-imports"
  vmimport_service_role_enabled = false
}

```

> Note: You have to use a [Nitro-based Instance Type](https://aws.amazon.com/ec2/nitro/) to ensure you can use the automatic
> numbering for NVMe attached EBS volumes. See the [list of instance types](https://aws.amazon.com/ec2/instance-types/).
> This configuration has been tested with T3 and T3a instances. 
