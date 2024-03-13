resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = var.namespace
  version    = var.kube-version
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"

  values = [
    file("${path.module}/kube-values/test-values.yaml"),
  ]
}
