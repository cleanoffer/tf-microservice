variable "name" {  }
variable "vpc_id" {  }
variable "port" {  }
variable "host_port" {  }
variable "subnet_ids" {  }
variable "healthy_threshold" {  }
variable "unhealthy_threshold" {  }
variable "healthcheck" {  }
variable "host_name" {  }
variable "dns_zone_id" {  }
variable "internal" {  }

resource "aws_security_group" "elb" {
  name_prefix = "${var.name}-elb"
  description = "security group used by thumbnailer service elb"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port = "${var.port}"
    to_port = "${var.port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "${var.host_port}"
    to_port = "${var.host_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-elb"
    Terraform = true
  }
}

resource "aws_elb" "elb" {
  name = "${var.name}"
  subnets = ["${split(",", var.subnet_ids)}"]
  security_groups = ["${aws_security_group.elb.id}"]

  internal = "${var.internal}"
  connection_draining = true
  connection_draining_timeout = 500

  listener {
    instance_port = "${var.host_port}"
    instance_protocol = "http"
    lb_port = "${var.port}"
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = "${var.healthy_threshold}"
    unhealthy_threshold = "${var.unhealthy_threshold}"
    timeout = 5
    target = "HTTP:${var.host_port}${var.healthcheck}"
    interval = 30
  }

  tags {
    Name = "${var.name}-balancer"
    Terraform = true
  }
}

resource "aws_route53_record" "elb" {
  name = "${var.host_name}"
  zone_id = "${var.dns_zone_id}"
  type = "A"

  alias {
    name = "${aws_elb.elb.dns_name}"
    zone_id = "${aws_elb.elb.zone_id}"
    evaluate_target_health = true
  }
}

output "elb_id" {
  value = "${aws_elb.elb.id}"
}

output "fqdn" {
  value = "${aws_route53_record.elb.fqdn}"
}
