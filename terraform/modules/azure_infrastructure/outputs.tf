output "vm_public_ip" {
  value       = azurerm_public_ip.public_ip.ip_address
  description = "Dirección IP pública asignada a la Máquina Virtual"
}

output "vm_private_ip" {
  value       = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
  description = "Dirección IP privada de la VM en la subred de Azure"
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "Servidor de login para Azure Container Registry"
}

output "acr_admin_username" {
  value       = azurerm_container_registry.acr.admin_username
  description = "Nombre de usuario administrador para ACR"
}

output "acr_admin_password" {
  value       = azurerm_container_registry.acr.admin_password
  description = "Contraseña administradora para ACR"
  sensitive   = true
}

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Nombre del Grupo de Recursos creado"
}
