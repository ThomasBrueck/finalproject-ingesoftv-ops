output "public_ip" {
  value       = azurerm_public_ip.jenkins_pip.ip_address
  description = "IP pública de la VM de Jenkins"
}

output "jenkins_url" {
  value       = "http://${azurerm_public_ip.jenkins_pip.ip_address}:8080"
  description = "URL de acceso a Jenkins"
}

output "sonarqube_url" {
  value       = "http://${azurerm_public_ip.jenkins_pip.ip_address}:9000"
  description = "URL de acceso a SonarQube"
}

output "ssh_command" {
  value       = "ssh ${azurerm_linux_virtual_machine.jenkins_vm.admin_username}@${azurerm_public_ip.jenkins_pip.ip_address}"
  description = "Comando SSH para conectarse a la VM"
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.jenkins_vm.name
  description = "Nombre de la VM en Azure"
}

output "resource_group" {
  value       = azurerm_resource_group.jenkins_rg.name
  description = "Resource group de la VM Jenkins"
}
