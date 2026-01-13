provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "user_api" {
  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from allowed CIDR ranges"
    from_port   = var.ingress_port
    to_port     = var.ingress_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Outbound traffic (restricted)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.egress_cidr_blocks
  }

  tags = {
    Name        = var.sg_name
    App         = "user-api"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
  }
}