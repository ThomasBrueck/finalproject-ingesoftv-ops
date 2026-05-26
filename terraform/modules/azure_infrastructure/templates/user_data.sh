#!/bin/bash
# ==============================================================================
# CircleGuard - VM Bootstrap Script (Docker, K3s, Helm, Jenkins)
# ==============================================================================
set -e

# Exportar variables de entorno no interactivas
export DEBIAN_FRONTEND=noninteractive

echo "=== 1. Actualizando paquetes del sistema ==="
apt-get update -y
apt-get upgrade -y
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    openjdk-17-jdk

echo "=== 2. Instalando Docker Engine ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker

# Agregar el usuario administrador de Azure al grupo de docker
usermod -aG docker ${admin_username}

echo "=== 3. Instalando K3s (Kubernetes ligero) ==="
# Instalamos K3s deshabilitando traefik si quisiéramos instalar Nginx Ingress después, 
# pero mantendremos la instalación por defecto que incluye Traefik para simplicidad
curl -sfL https://get.k3s.io | sh -

# Esperar a que K3s esté listo
sleep 15

# Configurar permisos para que el usuario administrador pueda usar kubectl sin sudo
mkdir -p /home/${admin_username}/.kube
cp /etc/rancher/k3s/k3s.yaml /home/${admin_username}/.kube/config
chown -R ${admin_username}:${admin_username} /home/${admin_username}/.kube
chmod 600 /home/${admin_username}/.kube/config

echo "=== 4. Instalando Helm ==="
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "=== 5. Instalando Jenkins ==="
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

# Asegurar que el usuario jenkins pueda ejecutar comandos de Docker
usermod -aG docker jenkins

# Dar acceso a K3s para Jenkins
mkdir -p /var/lib/jenkins/.kube
cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod 600 /var/lib/jenkins/.kube/config

# Reiniciar docker y jenkins para aplicar cambios de grupos
systemctl restart docker
systemctl restart jenkins

echo "=== Configuración Completada Exitosamente ==="
