variable "aws_region" { type = string }
variable "name" { type = string }

variable "vpc_cidr" { type = string }
variable "public_subnet_cidr" { type = string }
variable "az" { type = string }

variable "ssh_allowed_cidr" { type = string }

variable "ami_id" { type = string }
variable "instance_type" { type = string }
variable "key_name" { type = string }
