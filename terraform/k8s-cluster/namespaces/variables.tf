variable "kube_config" {
  type    = string
  default = "~/.kube/config"
}
variable "namespace-1" {
  type    = string
  default = "monitoring"
}

variable "namespace-2" {
  type    = string
  default = "apps"
}

# variable "namespace-3" {
#   type    = string
#   default = "argocd"
# }
