#!/bin/bash

# Função para imprimir e executar comandos
run_command() {
    local description=$1
    local command=$2

    echo "Starting: $description"
    if $command; then
        echo "Completed: $description"
    else
        echo "Failed: $description"
        exit 1
    fi
}

# Atualizar o sistema
run_command "Updating package index" "sudo dnf -y update"

# Remover versões antigas do Docker
run_command "Removing old Docker versions" "sudo dnf -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine"

# Instalar pacotes necessários para configuração do repositório
run_command "Installing packages for repository setup" "sudo dnf -y install dnf-plugins-core"

# Adicionar chave GPG oficial do Docker e repositório
run_command "Adding Docker's official GPG key and repository" "sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"

# Instalar Docker
run_command "Installing Docker" "sudo dnf -y install docker-ce docker-ce-cli containerd.io"

# Iniciar e habilitar serviço do Docker
run_command "Starting Docker service" "sudo systemctl start docker"
run_command "Enabling Docker service to start on boot" "sudo systemctl enable docker"

# Adicionar usuário atual ao grupo docker
run_command "Adding current user to the docker group" "sudo usermod -aG docker $USER"

# Instalar Docker Compose
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)

run_command "Downloading Docker Compose" "sudo curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose"
run_command "Applying executable permissions to Docker Compose binary" "sudo chmod +x /usr/local/bin/docker-compose"

# Verificar instalação do Docker Compose
DOCKER_COMPOSE_VERSION_INSTALLED=$(docker-compose --version)
if [ $? -eq 0 ]; then
    echo "Docker Compose installed successfully: $DOCKER_COMPOSE_VERSION_INSTALLED"
else
    echo "Failed to verify Docker Compose installation"
    exit 1
fi

echo "=== Docker and Docker Compose installation completed successfully ==="
echo "Please log out and back in for the group changes to take effect."