variable "aws_access_key" {}
variable "aws_secret_key" {}

# Value of the --gossip flag to pass to the backends.
# This should be populated with the load balancer address.
# Make sure to populate this before changing num_instances to greater than 0.
# eg: lb=elb-893485366.us-east-1.elb.amazonaws.com:26257
variable "gossip" {}

# Number of instances to start.
variable "num_instances" {}

# Port used for the load balancer and backends.
variable "cockroach_port" {
  default = "26257"
}

# AWS region to use. WARNING: changing this will break the AMI ID.
variable "aws_region" {
  default = "us-east-1"
}

# AWS availability zones. You should include all zones for that region.
variable "aws_azs" {
  default = {
    us-east-1 = "us-east-1a,us-east-1c,us-east-1d"
    us-west-2 = "us-west-2a,us-west-2b,us-west-2c"
  }
}

# AWS image ID. The default is valid for region "us-east-1".
variable "aws_ami_id" {
  default = "ami-408c7f28"
}

# Path to the cockroach binary.
variable "cockroach_binary" {
  default = "~/cockroach/src/github.com/cockroachdb/cockroach/cockroach"
}

# Name of the ssh key pair for this AWS region. Your .pem file must be:
# ~/.ssh/<key_name>.pem
variable "key_name" {
  default = "cockroach"
}

# Action is one of "init" or "start". init should only be specified when
# running `terraform apply` on the first node.
variable "action" {
  default = "start"
}
