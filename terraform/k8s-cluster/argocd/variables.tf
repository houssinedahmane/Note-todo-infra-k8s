variable "kube_config" {
  type    = string
  default = "~/.kube/config"
}
variable "namespace" {
  type    = string
  default = "argocd"
}
variable "argocd-version" {
  type    = string
  default = "4.9.7"
}
