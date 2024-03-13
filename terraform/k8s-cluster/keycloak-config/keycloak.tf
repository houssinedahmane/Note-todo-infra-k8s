terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
}

# configure keycloak provider
provider "keycloak" {
  client_id                = "admin-cli"
  username                 = "admin"
  password                 = "admin"
  url                      = "http://192.168.49.2:30080/"
  tls_insecure_skip_verify = true
}

locals {
  realm_id = "master"
  groups   = ["grafana-dev", "grafana-admin"]
  user_groups = {
    user-dev   = ["grafana-dev"]
    user-admin = ["grafana-admin"]
  }
}

# create groups
resource "keycloak_group" "groups" {
  for_each = toset(local.groups)
  realm_id = local.realm_id
  name     = each.key
}

# create users
resource "keycloak_user" "users" {
  for_each       = local.user_groups
  realm_id       = local.realm_id
  username       = each.key
  enabled        = true
  email          = "${each.key}@domain.com"
  email_verified = true
  first_name     = each.key
  last_name      = each.key
  initial_password {
    value = each.key
  }
}

# configure use groups membership
resource "keycloak_user_groups" "user_groups" {
  for_each  = local.user_groups
  realm_id  = local.realm_id
  user_id   = keycloak_user.users[each.key].id
  group_ids = [for g in each.value : keycloak_group.groups[g].id]

}

# create groups openid client scope
resource "keycloak_openid_client_scope" "groups" {
  realm_id               = local.realm_id
  name                   = "groups"
  include_in_token_scope = true
  gui_order              = 1
  consent_screen_text    = false
  
}

resource "keycloak_openid_group_membership_protocol_mapper" "groups" {
  realm_id            = local.realm_id
  client_scope_id     = keycloak_openid_client_scope.groups.id
  name                = "groups"
  claim_name          = "groups"
  full_path           = false
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true

}

# create argocd openid client
resource "keycloak_openid_client" "grafana" {
  realm_id              = local.realm_id
  client_id             = "grafana"
  name                  = "grafana"
  enabled               = true
  access_type           = "CONFIDENTIAL"
  client_secret         = "grafana-client-secret"
  standard_flow_enabled = true

  service_accounts_enabled = true
  direct_access_grants_enabled = true
  root_url    = "http://localhost:3000/"
  base_url    = "http://localhost:3000/"
  admin_url   = "http://localhost:3000/"
  web_origins = ["*"]

  valid_redirect_uris = [
    "http://localhost:3000/*"  
  ]
}

# configure argocd openid client default scopes
resource "keycloak_openid_client_default_scopes" "grafana" {
  realm_id  = local.realm_id
  client_id = keycloak_openid_client.grafana.id
  default_scopes = [
    "profile",
    "email",
    "roles",
    "web-origins",
    keycloak_openid_client_scope.groups.name,
  ]
}
