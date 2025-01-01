# Usando imagem base Ubuntu
FROM ubuntu:22.04

# Informações do mantenedor
LABEL maintainer="Mario Alves <marioalvesrzti@gmail.com>"

# Configuração do ambiente
ENV DEBIAN_FRONTEND=noninteractive \
    NVM_DIR=/root/.nvm

# Atualizando o sistema e instalando dependências necessárias
RUN apt update && apt upgrade -y && \
    apt install -y curl wget nano vim tar unzip git xdg-utils fontconfig software-properties-common gnupg && \
    apt install -y libasound2 libgbm1 libnspr4 libnss3 fonts-liberation libvulkan1 && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Baixando e instalando o Google Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome.deb && \
    apt install -y /tmp/google-chrome.deb && \
    rm /tmp/google-chrome.deb

# Instalando Node.js via NVM
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install node && \
    nvm use node && \
    npm install -g pm2

# Criando diretório de trabalho
WORKDIR /opt/beezap2

# Criando estrutura de diretórios necessária
RUN mkdir -p /opt/beezap2/uploads/bee

# Copiando apenas os arquivos necessários
COPY index.js /opt/beezap2/index.js
COPY beeid2.js /opt/beezap2/beeid2.js
COPY beezap2.js /opt/beezap2/beezap2.js

COPY ./setup_beezap2.sh /opt/beezap2/setup_beezap2.sh

# Tornando o script executável
RUN chmod +x /opt/beezap2/setup_beezap2.sh


# Instalando dependências do projeto
RUN . $NVM_DIR/nvm.sh && \
    npm install whatsapp-web.js express qrcode-terminal multer moment-timezone

# Registrando os scripts no PM2
RUN . $NVM_DIR/nvm.sh && \
    pm2 start beezap2.js --name beezap2-api && \
    pm2 save

# Expondo a porta da API
EXPOSE 4000

CMD ["tail", "-f", "/dev/null"]
