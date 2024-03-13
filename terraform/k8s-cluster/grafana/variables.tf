variable "grafana_auth" {
  description = "Authentication token for Grafana"
  type        = string
  default     = "glsa_3cRXaTwcXKlWr8Xu2kFGNgwLawky1Yhi_2fa66691"
}

variable "webhook_team" {
  description = "Webhook URL for Microsoft Teams"
  type        = string
  default     = "https://eviden.webhook.office.com/webhookb2/be0cedcb-a0c4-4599-8848-c1886ac7e4e0@7d1c7785-2d8a-437d-b842-1ed5d8fbe00a/IncomingWebhook/c34647d2cf25479c94b27514bcfbf879/827be7cf-ce33-4157-b595-1fd00534773d"

}

variable "env" {
  description = "Environment label for Grafana alert rule"
  type        = string
  default     = "dev"
}
