module "azure_infrastructure" {
  source = "../../modules/azure_infrastructure"
}

output "kube_config" {
  value     = module.azure_infrastructure.host
  sensitive = true
}

output "acr_login_server" {
  value = module.azure_infrastructure.acr_login_server
}
