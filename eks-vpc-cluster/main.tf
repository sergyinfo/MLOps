module "vpc" {
  source          = "./vpc"
  vpc_name        = "ml-vpc"
  vpc_cidr        = "10.0.0.0/16"

  azs             = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

module "eks" {
  source       = "./eks"
  cluster_name = "ml-eks-cluster"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}