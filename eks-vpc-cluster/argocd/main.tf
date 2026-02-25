# Створюємо окремий namespace для ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "infra-tools"
  }
}

# Встановлюємо Helm-чарт ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.11"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  timeout = 600

  # Підключаємо наш файл із налаштуваннями
  values = [
    file("${path.module}/values/argocd-values.yaml")
  ]
}