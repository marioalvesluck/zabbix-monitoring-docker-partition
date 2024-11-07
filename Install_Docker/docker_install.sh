#!/bin/bash

# Atualize o sistema
echo "Atualizando o sistema..."
sudo dnf update -y

# Instale dependências necessárias
echo "Instalando dependências..."
sudo dnf install -y dnf-plugins-core

# Instale git necessárias
echo "Instalando dependências..."
sudo dnf install -y git

# Adicione o repositório oficial do Docker
echo "Adicionando repositório do Docker..."
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Instale o Docker
echo "Instalando Docker..."
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Inicie e habilite o serviço Docker
echo "Iniciando e habilitando o Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# Verifique a instalação do Docker
docker --version
if [ $? -ne 0 ]; then
    echo "Erro na instalação do Docker. Verifique o log para detalhes."
    exit 1
fi
echo "Docker instalado com sucesso!"

# Instale o Docker Compose
echo "Baixando e instalando Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Dê permissão para o Docker Compose
echo "Dando permissão para o Docker Compose..."
sudo chmod +x /usr/local/bin/docker-compose

# Verifique a instalação do Docker Compose
docker-compose --version
if [ $? -ne 0 ]; then
    echo "Erro na instalação do Docker Compose. Verifique o log para detalhes."
    exit 1
fi
echo "Docker Compose instalado com sucesso!"

# Adicione o usuário atual ao grupo Docker para evitar o uso de sudo
echo "Adicionando o usuário ao grupo Docker..."
sudo usermod -aG docker $USER
echo "Reinicie a sessão para aplicar as permissões."

echo "Instalação concluída com sucesso!"
