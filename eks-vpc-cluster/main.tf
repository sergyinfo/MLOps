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

# Отримуємо дані про створений кластер для авторизації
data "aws_eks_cluster" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Налаштовуємо Helm провайдер
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Налаштовуємо Kubernetes провайдер
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Викликаємо наш новий модуль ArgoCD
module "argocd" {
  source     = "./argocd"
  depends_on = [module.eks] # ArgoCD встановлюється ТІЛЬКИ після створення кластера
}