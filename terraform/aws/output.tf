output "port" {
  value = "${var.cockroach_port}"
}

output "elb" {
  value = "${aws_elb.elb.dns_name}"
}

output "gossip_variable" {
  value = "${format("lb=%s:%s", aws_elb.elb.dns_name, var.cockroach_port)}"
}

output "instances" {
  value = "${join(",", aws_instance.cockroach.*.public_dns)}"
}
