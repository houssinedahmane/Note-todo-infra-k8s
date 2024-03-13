variable "kube_config" {
  type    = string
  default = "~/.kube/config"
}
variable "namespace" {
  type    = string
  default = "monitoring"
}
variable "kube-version" {
  type    = string
  default = "56.15.0"
}


