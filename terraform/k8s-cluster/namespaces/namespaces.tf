resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace-1
  }
}


resource "kubernetes_namespace" "apps" {
  metadata {
    name = var.namespace-2
  }
}
