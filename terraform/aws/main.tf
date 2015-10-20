provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_instance" "cockroach" {
    tags {
      Name = "${format("cockroach-%d", "${count.index}")}"
    }
    ami = "${var.aws_ami_id}"
    instance_type = "t1.micro"
    security_groups = ["${aws_security_group.default.name}"]
    key_name = "${var.key_name}"
    count = "${var.num_instances}"

    connection {
      user = "ubuntu"
      key_file = "~/.ssh/${var.key_name}.pem"
    }

    provisioner "file" {
        source = "${var.cockroach_binary}"
        destination = "/home/ubuntu/cockroach"
    }

    provisioner "file" {
        source = "launch.sh"
        destination = "/home/ubuntu/launch.sh"
    }

   provisioner "remote-exec" {
        inline = [
          "chmod 755 launch.sh",
          "./launch.sh ${var.action} ${var.gossip}",
          "sleep 1",
        ]
   }
}
