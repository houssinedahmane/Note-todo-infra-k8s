resource "helm_release" "blackbox-exporter" {
  name       = "blackbox-exporter"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-blackbox-exporter"
  version    = "8.12.0"
  

  values = [
    file("${path.module}/blackbox-values/blackbox-values.yaml"),
  ]

}



