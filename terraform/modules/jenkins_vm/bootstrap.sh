#!/bin/bash
# ==============================================================================
# CircleGuard — Bootstrap Jenkins VM
# Ejecutado por cloud-init al crear la VM. Instala Docker, Jenkins y SonarQube.
# ==============================================================================
set -euo pipefail
exec > /var/log/bootstrap.log 2>&1

echo "[bootstrap] Iniciando instalación — $(date)"

# ── 1. Actualizar sistema ──────────────────────────────────────────────────────
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

# ── 2. Instalar Docker CE ──────────────────────────────────────────────────────
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# ── 3. Instalar kubectl ────────────────────────────────────────────────────────
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# ── 4. Instalar Azure CLI ──────────────────────────────────────────────────────
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# ── 5. Requerimiento de SonarQube (Elasticsearch) ─────────────────────────────
sysctl -w vm.max_map_count=524288
echo 'vm.max_map_count=524288' >> /etc/sysctl.conf
echo 'fs.file-max=131072'      >> /etc/sysctl.conf

# ── 6. Crear stack de CI/CD ───────────────────────────────────────────────────
mkdir -p /opt/cicd

cat > /opt/cicd/docker-compose.yml << 'COMPOSE'
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk21
    container_name: jenkins
    restart: unless-stopped
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/local/bin/kubectl:/usr/local/bin/kubectl
    environment:
      - JAVA_OPTS=-Xmx1024m -Djenkins.install.runSetupWizard=true
    networks:
      - cicd

  sonarqube:
    image: sonarqube:lts-community
    container_name: sonarqube
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
      - SONAR_JAVA_OPTS=-Xmx1024m -Xms512m
    networks:
      - cicd

networks:
  cicd:
    driver: bridge

volumes:
  jenkins_home:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:
COMPOSE

# ── 7. Servicio systemd para auto-arranque ─────────────────────────────────────
cat > /etc/systemd/system/cicd.service << 'UNIT'
[Unit]
Description=CircleGuard CI/CD Stack (Jenkins + SonarQube)
Requires=docker.service
After=docker.service network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/cicd
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable cicd

# ── 8. Iniciar los servicios ───────────────────────────────────────────────────
cd /opt/cicd && docker compose up -d

echo "[bootstrap] Instalación completada — $(date)"
echo "[bootstrap] Jenkins:    http://$(curl -s ifconfig.me):8080"
echo "[bootstrap] SonarQube:  http://$(curl -s ifconfig.me):9000"
