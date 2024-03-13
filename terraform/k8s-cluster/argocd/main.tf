resource "helm_release" "argocd" {
  name  = "argocd-release"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  version          = "4.9.7"
  create_namespace = true

  values = [
    file("${path.module}/argocd-values/values.yaml"),
  ]
}