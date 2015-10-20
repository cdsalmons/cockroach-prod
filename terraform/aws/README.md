# Deploy cockroach cluster on AWS using Terraform

This directory contains the [Terraform](https://terraform.io/) configuration
files needed to launch a cockroach cluster on AWS.

The following steps will create a three node cluster.

## One-time setup steps
1. Have an [AWS](http://aws.amazon.com/) account
2. [Download terraform](https://terraform.io/downloads.html), unzip, and add to your `PATH`.
3. [Find your AWS credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html#cli-signup). We will refer to them as `AWS_ACCESS_KEY` and `AWS_SECRET_KEY`.
4. [Create an AWS keypair](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:sort=keyName) named `cockroach` and save the file as `~/.ssh/cockroach.pem`.
5. Check out the [Cockroach repository](https://github.com/cockroachdb/cockroach) and build the cockroach binary. It must be located at `~/cockroach/src/github.com/cockroachdb/cockroach/cockroach` (adjust `cockroach_binary` in `variables.tf` otherwise).

## Create the cluster

The following three commands will initialize all needed AWS infrastructure in the region `us-east-1`,
initialize the first cockroach node, then add two more nodes to the cluster.
All dynamic configuration is set through terraform command-line flags but can be set in `variables.tf`.

To see the actions expected to be performed by terraform, use `plan` instead of `apply`.

#### Initialize AWS infrastructure

```
$ terraform apply \
    --var=aws_access_key="AWS_ACCESS_KEY" \
    --var=aws_secret_key="AWS_SECRET_KEY" \
    --var=gossip=""                       \
    --var=num_instances=0

aws_security_group.default: Creating...
aws_security_group.default: Creation complete
aws_elb.elb: Creating...
aws_elb.elb: Creation complete
Outputs:
  elb             = elb-1289187553.us-east-1.elb.amazonaws.com
  gossip_variable = lb=elb-1289187553.us-east-1.elb.amazonaws.com:26257
  instances       = 
  port            = 26257

```

This command creates a load balancer and displays the value of the gossip flag to be used in the
following steps.

#### Initialize the first node

```
$ terraform apply \
    --var=aws_access_key="AWS_ACCESS_KEY" \
    --var=aws_secret_key="AWS_SECRET_KEY" \
    --var=gossip="lb=elb-1289187553.us-east-1.elb.amazonaws.com:26257" \
    --var=num_instances=1                 \
    --var=action="init"

aws_security_group.default: Refreshing state... (ID: sg-828435e4)
aws_elb.elb: Refreshing state... (ID: elb)
aws_instance.cockroach: Creating...
aws_instance.cockroach: Provisioning with 'file'...
aws_instance.cockroach: Provisioning with 'file'...
aws_instance.cockroach: Provisioning with 'remote-exec'...
aws_instance.cockroach: Creation complete
aws_elb.elb: Modifying...
aws_elb.elb: Modifications complete
Outputs:
  elb             = elb-1289187553.us-east-1.elb.amazonaws.com
  gossip_variable = lb=elb-1289187553.us-east-1.elb.amazonaws.com:26257
  instances       = ec2-54-85-12-159.compute-1.amazonaws.com
  port            = 26257

```

The `--var=action="init"` parameter causes the first node to be initialized for with a new cluster.
The cluster is now running with a single node and is reachable through the load balancer (see `Using the cluster`).

#### Add more nodes to the cluster

```
$ terraform apply \
    --var=aws_access_key="AWS_ACCESS_KEY" \
    --var=aws_secret_key="AWS_SECRET_KEY" \
    --var=gossip="lb=elb-1289187553.us-east-1.elb.amazonaws.com:26257" \
    --var=num_instances=3

aws_security_group.default: Refreshing state... (ID: sg-828435e4)
aws_instance.cockroach.0: Refreshing state... (ID: i-1d10fbca)
aws_elb.elb: Refreshing state... (ID: elb)
aws_instance.cockroach.1: Creating...
aws_instance.cockroach.2: Creating...
aws_instance.cockroach.2: Provisioning with 'file'...
aws_instance.cockroach.1: Provisioning with 'file'...
aws_instance.cockroach.2: Provisioning with 'remote-exec'...
aws_instance.cockroach.2: Creation complete
aws_instance.cockroach.1: Provisioning with 'remote-exec'...
aws_instance.cockroach.1: Creation complete
aws_elb.elb: Modifying...
aws_elb.elb: Modifications complete
Outputs:
  elb             = elb-1289187553.us-east-1.elb.amazonaws.com
  gossip_variable = lb=elb-1289187553.us-east-1.elb.amazonaws.com:26257
  instances       = ec2-54-85-12-159.compute-1.amazonaws.com,ec2-54-175-192-198.compute-1.amazonaws.com,ec2-54-88-84-13.compute-1.amazonaws.com
  port            = 26257

```

## Use the cluster

#### Connect to the cluster

Use the load balancer address to connect to the cluster.

```
$ ./cockroach sql --insecure --addr=elb-1289187553.us-east-1.elb.amazonaws.com:26257
elb-1289187553.us-east-1.elb.amazonaws.com:26257> show databases;
+----------+
| Database |
+----------+
| system   |
+----------+
```

#### Ssh into individual instances

The DNS names of AWS instances is shown as a comma-separated list in the terraform output.

```
$ ssh -i ~/.ssh/cockroach.pem ubuntu@ec2-54-85-12-159.compute-1.amazonaws.com

ubuntu@ip-172-31-15-87:~$ ps -Af|grep cockroach
ubuntu    1448     1  4 20:03 ?        00:00:39 ./cockroach start --log-dir=logs --logtostderr=false --stores=ssd=data --insecure --gossip=lb=elb-1289187553.us-east-1.elb.amazonaws.com:26257

ubuntu@ip-172-31-15-87:~$ ls logs
cockroach.ERROR
cockroach.INFO
cockroach.ip-172-31-15-87.ubuntu.log.ERROR.2015-11-02T20_03_14Z.1448
cockroach.ip-172-31-15-87.ubuntu.log.INFO.2015-11-02T20_03_09Z.1443
cockroach.ip-172-31-15-87.ubuntu.log.INFO.2015-11-02T20_03_09Z.1448
cockroach.ip-172-31-15-87.ubuntu.log.WARNING.2015-11-02T20_03_09Z.1448
cockroach.STDERR
cockroach.STDOUT
cockroach.WARNING

```

## Destroy the cluster

```
$ terraform destroy \
    --var=aws_access_key="AWS_ACCESS_KEY" \
    --var=aws_secret_key="AWS_SECRET_KEY" \
    --var=gossip="lb=elb-1289187553.us-east-1.elb.amazonaws.com:26257" \
    --var=num_instances=3
```

The destroy command requires confirmation.
