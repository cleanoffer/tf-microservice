variable "name"        { description = "name of microservice" }
variable "vpc_id"      { }
variable "host_name"   { }
variable "dns_zone_id" { }
variable "subnet_ids"  { }
variable "cluster_id"  { }

variable "task_definition" { description = "ECS service task definition arn" }

variable "iam_role" { description = "the service's IAM role arn" }

variable "container_port" { }
variable "host_port"      { }
variable "port"           {
  description = "the microservice's port"
  default = "80"
}

variable "desired_count" {
  description = "service desired count"
  default = 2
}

variable "deployment_maximum_percent" {
  description = "The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment."
  default = 200
}

variable "deployment_minimum_healthy_percent" {
  descripption = "The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment."
  default = 100
}

variable "internal_elb" {
  description = "use an internal load balancer or an internet-facing one"
  default = true
}

variable "healthy_threshold" {
  default = 2
}

variable "unhealthy_threshold" {
  default = 2
}

variable "healthcheck" {
  description = "Simple health check url for the load balancer"
  default = "/service-status"
}

variable "log_retention" {
  default = 0
}

module "elb" {
  source = "./elb"
  name = "${var.name}"
  vpc_id = "${var.vpc_id}"
  port = "${var.port}"
  host_port = "${var.host_port}"
  subnet_ids = "${var.subnet_ids}"
  healthy_threshold = "${var.healthy_threshold}"
  unhealthy_threshold = "${var.unhealthy_threshold}"
  healthcheck = "${var.healthcheck}"
  host_name = "${var.host_name}"
  dns_zone_id = "${var.dns_zone_id}"
  internal = "${var.internal_elb}"
}

resource "aws_ecs_service" "microservice" {
  name = "${var.name}"
  cluster = "${var.cluster_id}"
  task_definition = "${var.task_definition}"
  desired_count = "${var.desired_count}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent = "${var.deployment_maximum_percent}"
  iam_role = "${var.iam_role}"

  load_balancer {
    elb_name = "${module.elb.elb_id}"
    container_name = "${var.name}"
    container_port = "${var.container_port}"
  }
}

output "elb_fqdn" {
  value = "${module.elb.fqdn}"
}
