resource "helm_release" "postgres-exporter" {
  name       = "postgres-exporter"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-postgres-exporter"
  version    = "5.3.0"



  values = [
    file("${path.module}/postgres-values/postgres-exporter.yaml"),
  ]


}



