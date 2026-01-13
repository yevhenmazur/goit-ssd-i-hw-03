variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group is created"
  type        = string
}

variable "sg_name" {
  description = "Security group name"
  type        = string
  default     = "user-api-sg"
}

variable "sg_description" {
  description = "Security group description"
  type        = string
  default     = "Security group for user-api service"
}

variable "ingress_port" {
  description = "Ingress port to allow"
  type        = number
  default     = 443
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the service"
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.allowed_cidr_blocks : cidr != "0.0.0.0/0"])
    error_message = "0.0.0.0/0 is not allowed. Use restricted CIDR ranges."
  }
}

variable "egress_cidr_blocks" {
  description = "Allowed CIDR blocks for outbound traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"] # може бути додатково обмежено policy
}

variable "environment" {
  description = "Deployment environment (dev/stage/prod)"
  type        = string
}

variable "owner" {
  description = "Resource owner for governance and audit"
  type        = string
}
