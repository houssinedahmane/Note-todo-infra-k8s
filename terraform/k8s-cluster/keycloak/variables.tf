variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "keycloak-version" {
  type    = string
  default = "19.2.0"
}

variable "kube_config" {
  type    = string
  default = "~/.kube/config"
}