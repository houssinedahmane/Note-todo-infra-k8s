resource "helm_release" "keycloak" {
  name       = "keycloak"
  namespace  = var.namespace
  version    = var.keycloak-version
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"

  values = [
    file("${path.module}/keycloak-values/values.yaml"),
  ]
}
