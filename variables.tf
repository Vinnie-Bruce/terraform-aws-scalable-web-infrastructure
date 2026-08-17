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
    cidr_block = string
  }))
  description = "Public subnets"
}