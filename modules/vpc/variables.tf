variable "vpc_cidr" {
  type        = string
  description = "CIDR block of VPC"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "public_subnets" {
  type = map(object({
    subnet_cidr = string, subnet_az = string
  }))
  description = "A map of subnets"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources created by the VPC module"
}