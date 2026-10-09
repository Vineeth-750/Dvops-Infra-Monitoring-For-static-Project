variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "project_name" {
  type        = string
  default     = "static-site-devops"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "admin_cidr" {
  type        = string
  description = "Your public IPv4 CIDR for SSH and admin dashboards, e.g. 198.51.100.25/32"
  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR."
  }
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "rhel_ami_id" {
  type        = string
  description = "Optional explicit RHEL AMI ID for your selected region. Leave blank to use the latest published RHEL 9 AMI from the AWS public SSM parameter."
  default     = ""
}

variable "web_root_volume_gb" {
  type    = number
  default = 12
}

variable "monitoring_root_volume_gb" {
  type    = number
  default = 20
}
