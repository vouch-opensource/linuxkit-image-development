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

TODO...

#### Mechanics

##### Usage

document terraform module...

> Note: You have to use a [Nitro-based Instance Type](https://aws.amazon.com/ec2/nitro/) to ensure you can use the automatic
> numbering for NVMe attached EBS volumes. See the [list of instance types](https://aws.amazon.com/ec2/instance-types/).
> This configuration has been tested with T3 and T3a instances. 
