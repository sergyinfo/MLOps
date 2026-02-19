variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "cluster_name" {
  description = "GoIT EKS cluster"
  type        = string
  default     = "ml-production-cluster"
}