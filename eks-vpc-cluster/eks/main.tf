module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    cpu_nodes = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      instance_types = ["t3.medium"]
    }
    ml_nodes = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      instance_types = ["t3.medium"]
      labels = { role = "ml-worker" }
    }
  }
}