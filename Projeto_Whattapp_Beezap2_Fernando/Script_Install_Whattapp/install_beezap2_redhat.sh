#!/bin/bash
#####################################################################################################
# Script Title:   BEEZAP2 INSTALLER                                                                 #
# Script Descr:   Install and configure Beezap2                                                     #
# Script Name:    beezap2.sh                                                                        #
# Author:         Mário Alves                                                                       #
# E-Mail:         marioalvesrzti@gmail.com                                                          #
# Telegram:       @malviluckofficial                                                                #
# Description BR: Instala e configura o Beezap2.                                                    #
# Description EN: Installs and configures Beezap2.                                                  #
# Help:           Execute /bin/bash beezap2.sh para informações de uso.                             #
#                 Run /bin/bash beezap2.sh for usage information.                                   #
# Create v1.0.0:  Sun Jul 21 10:00:00 BRT 2024                                                      #
#####################################################################################################

LOG_FILE="/var/log/beezap2_install.log"

# Função para exibir as instruções de uso
function show_help() {
    echo "################################################################################"
    echo "# Script Title:   BEEZAP2 INSTALLER                                            #"
    echo "# Script Descr:   Install and configure Beezap2                                #"
    echo "# Script Name:    beezap2.sh                                                   #"
    echo "# Author:         Mário Alves                                                  #"
    echo "# E-Mail:         marioalvesrzti@gmail.com                                     #"
    echo "# Telegram:       @malviluckofficial                                           #"
    echo "# Description BR: Instala e configura o Beezap2.                               #"
    echo "# Description EN: Installs and configures Beezap2.                             #"
    echo "# Help:           Execute /bin/bash beezap2.sh para informações de uso.        #"
    echo "#                 Run /bin/bash beezap2.sh for usage information.              #"
    echo "# Create v1.0.0:  Sun Jul 21 10:00:00 BRT 2024                                 #"
    echo "################################################################################"
    echo ""
    echo "Instruções de uso:"
    echo "  Para instalar: script.sh install"
    echo "  Ler Qrcode: node index.js"
    echo "  Mostra grupos e IDS WhatsApp: node beeid2.js"
    echo "  Para definir o pm2 para iniciar na inicialização do sistema, use os comandos:"
    echo "  pm2 start beezap2.js --name beezap2-api"
    echo "  pm2 startup"
    echo "  pm2 save"
    echo "  Acessar Servidor Zabbix server: copie arquivo para servidor zabbix server pasta /usr/lib/zabbix/alertscripts"
    echo "  beebootzap.py"
    echo "  Criar pasta em /tmp: mkdir /var/tmp/zabbix"
    echo "  Dar permissão ao usuario zabbix: chown -R zabbix:zabbix /var/tmp/zabbix"
}

# Desenvolvido por: Bee Solutions
# Autor: Fernando Almondes

# Verificar os argumentos passados
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
elif [[ "$1" != "install" ]]; then
    echo "Comando inválido. Use 'script.sh install' para instalar ou 'script.sh --help' para ver as instruções de uso."
    exit 1
fi

# Função para desabilitar o SELinux
function disable_selinux() {
    echo "Desabilitando o SELinux..." | tee -a $LOG_FILE

    # Editar o arquivo de configuração do SELinux para desativá-lo permanentemente
    sudo sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config

    # Aplicar a alteração imediatamente
    sudo setenforce 0

    echo "SELinux desabilitado. Por favor, reinicie o sistema para aplicar as alterações permanentemente." | tee -a $LOG_FILE
}

# Chamar a função para desabilitar o SELinux
disable_selinux

# Interrompe o script se qualquer comando falhar
set -e

# Variáveis para reutilização
PROJECT_DIR="/opt/beezap2"
UPLOAD_DIR="${PROJECT_DIR}/uploads/bee"
CHROME_PKG="google-chrome-stable_current_x86_64.rpm"
NVM_INSTALL_SCRIPT="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh"

# Função para obter a hora atual
get_time() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Instalação do Beezap2
echo "Iniciando a instalação do Beezap2..." | tee -a $LOG_FILE

# Tempo de início da instalação
start_time=$(date +%s)
echo "Início da instalação: $(get_time)" | tee -a $LOG_FILE

# Atualizar e instalar pacotes necessários para o projeto
echo "Atualizando sistema e instalando pacotes necessários..." | tee -a $LOG_FILE
yum update -y && yum upgrade -y && yum install -y \
    nano vim curl epel-release wget unzip fontconfig xdg-utils git tar
echo "Pacotes necessários instalados."

#Liberando Portas do Firewall
echo "Iniciando Liberação da Porta..." | tee -a $LOG_FILE
firewall-cmd --zone=public --add-port=4000/tcp --permanent
firewall-cmd --reload
firewall-cmd --list-ports
echo "Porta Liberada com Sucesso"

# Criar estrutura do projeto
echo "Criando estrutura do projeto..." | tee -a $LOG_FILE
mkdir -p ${UPLOAD_DIR}
cd ${PROJECT_DIR}
echo "Estrutura do projeto criada." | tee -a $LOG_FILE

# Instalar pacote google-chrome
echo "Instalando Google Chrome..." | tee -a $LOG_FILE
wget https://dl.google.com/linux/direct/${CHROME_PKG}
yum localinstall -y ${CHROME_PKG}
rm ${CHROME_PKG}
echo "Google Chrome instalado." | tee -a $LOG_FILE

# Instalar NVM
echo "Instalando NVM..." | tee -a $LOG_FILE
curl -o- ${NVM_INSTALL_SCRIPT} | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
source "$NVM_DIR/nvm.sh"
echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm' >> ~/.bashrc
source ~/.bashrc
echo "NVM instalado." | tee -a $LOG_FILE

# Verificar versão do NVM
echo "Verificando versão do NVM..." | tee -a $LOG_FILE
nvm --version | tee -a $LOG_FILE

# Instalar Node
echo "Instalando Node.js..." | tee -a $LOG_FILE
nvm install node
nvm use node
echo "Node.js instalado." | tee -a $LOG_FILE

# Iniciar projeto dentro da pasta /opt/beezap2/
echo "Iniciando projeto e instalando dependências npm..." | tee -a $LOG_FILE
npm init -y
npm install -g pm2 n

# Verificar se npm está disponível
echo "Verificando instalação do npm e pm2..." | tee -a $LOG_FILE
if ! command -v npm &> /dev/null; then
    echo "npm não encontrado. Verifique a instalação do npm e tente novamente." | tee -a $LOG_FILE
    exit 1
fi

if ! command -v pm2 &> /dev/null; then
    echo "pm2 não encontrado, tentando carregar npm..." | tee -a $LOG_FILE
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # Carregar NVM e tentar novamente
        source "$NVM_DIR/nvm.sh"
        npm install -g pm2 | tee -a $LOG_FILE
        if ! command -v pm2 &> /dev/null; then
            echo "pm2 ainda não encontrado após tentar carregar npm. Verifique a instalação e tente novamente." | tee -a $LOG_FILE
            exit 1
        fi
    else
        echo "NVM não encontrado. Verifique a instalação do NVM e tente novamente." | tee -a $LOG_FILE
        exit 1
    fi
fi

echo "Configuração concluída com sucesso." | tee -a $LOG_FILE


npm install whatsapp-web.js express qrcode-terminal multer moment-timezone
n latest
echo "Dependências npm instaladas." | tee -a $LOG_FILE

# Realizar sed no arquivo package.json
# echo "Atualizando whatsapp-web.js no package.json..."
# sed -i 's/"whatsapp-web.js": "^1.26.0"/"whatsapp-web.js": "github:pedroslopez\/whatsapp-web.js#webpack-exodus"/' package.json
# echo "whatsapp-web.js atualizado." | tee -a $LOG_FILE

# # Realizar update e instalação do whatsapp-web.js#webpack-exodus
# echo "Atualizando e instalando whatsapp-web.js#webpack-exodus..." | tee -a $LOG_FILE
npm update whatsapp-web.js
# npm install github:pedroslopez/whatsapp-web.js#webpack-exodus
# echo "whatsapp-web.js atualizado." | tee -a $LOG_FILE

# Criar e escrever no arquivo index.js
echo "Criando index.js..." | tee -a $LOG_FILE
cat << 'EOF' > ${PROJECT_DIR}/index.js
const qrcode = require('qrcode-terminal');
const { Client, LocalAuth } = require('whatsapp-web.js');

//const client = new Client();
const client = new Client({
        authStrategy: new LocalAuth(),
        puppeteer: { args: ['--no-sandbox'] }
});

client.on('qr', qr => {
    qrcode.generate(qr, {small: true});
});


client.initialize();

client.on('loading_screen', (percent, message) => {
    console.log('Carregando', percent, message);
});

client.on('authenticated', () => {
    console.log('Autenticado');
});

client.on('auth_failure', msg => {
    // Fired if session restore was unsuccessful
    console.error('Falha na autenticacao', msg);
});

client.on('ready', () => {
    console.log('Cliente iniciado e pronto para uso!');
});
EOF
echo "index.js criado." | tee -a $LOG_FILE

# Criar beeid2.js
echo "Criando beeid2.js..." | tee -a $LOG_FILE
cat << 'EOF' > ${PROJECT_DIR}/beeid2.js
const { Client, LocalAuth } = require('whatsapp-web.js');

const client = new Client({
    authStrategy: new LocalAuth(),
    puppeteer: {
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    }
});

client.on('ready', async () => {
    console.log('Cliente está pronto!');

    try {
        // Adicionar tempo para carregamento completo dos chats
        await new Promise(resolve => setTimeout(resolve, 5000));

        // Obter lista de chats
        const chats = await client.getChats();

        console.log('Total de chats:', chats.length);

        // Verificar propriedades de cada chat
        chats.forEach(chat => {
            console.log(`Chat: ${chat.name || 'Sem nome'} | ID: ${chat.id?._serialized || 'Sem ID'} | É grupo: ${chat.isGroup || false}`);
        });

        // Filtrar apenas grupos
        const groupChats = chats.filter(chat => chat.isGroup);

        // Obter IDs e nomes de grupos
        const groupInfo = groupChats.map(chat => ({
            id: chat.id._serialized,
            name: chat.name
        }));

        console.log('Lista de IDs e nomes de grupos:', groupInfo);
    } catch (error) {
        console.error('Erro ao obter grupos:', error.message);
        console.error(error.stack);
    }

    client.destroy(); // Finalizar cliente após execução
});

client.on('auth_failure', msg => {
    console.error('Falha de autenticação:', msg);
});

client.on('disconnected', reason => {
    console.log('Cliente desconectado:', reason);
});

client.initialize();
EOF
echo "beeid2.js criado." | tee -a $LOG_FILE

# Criar beezap2.js
echo "Criando beezap2.js..." | tee -a $LOG_FILE
cat << 'EOF' > ${PROJECT_DIR}/beezap2.js
const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const express = require('express');
const multer = require('multer');
const moment = require('moment-timezone');

const app = express();
const port = 4000;

const client = new Client({
    authStrategy: new LocalAuth(),
    puppeteer: { args: ['--no-sandbox'] }
});

client.initialize();

client.on('loading_screen', (percent, message) => {
    console.log('Carregando', percent, message);
});

client.on('authenticated', () => {
    console.log('Autenticado');
});

client.on('auth_failure', msg => {
    console.error('Falha na autenticacao', msg);
});

client.on('ready', () => {
    console.log('Cliente iniciado e pronto para uso!');
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Adicione o middleware para logar as requisições recebidas
app.use((req, res, next) => {
    console.log(`Recebido pedido: ${req.method} ${req.url}`);
    next();
});

// Adicione esta rota para responder ao endpoint /api
app.get('/api', (req, res) => {
    res.send('WhatsApp API is running');
});

// Enviando mensagens inicio | POST
app.post('/api/message', (req, res) => {
    const { number, message } = req.body;

    const isGroup = (number) => {
        return number.toString().startsWith('55') && number.toString().length === 12;
    };

    const getCurrentTime = () => {
        return moment().tz('America/Sao_Paulo').format('YYYY-MM-DD HH:mm:ss');
    };

    if (isGroup(number)) {
        client.sendMessage(`${number}@c.us`, message)
            .then(() => {
                console.log(getCurrentTime(), '- Mensagem enviada com sucesso para:', number);
                res.json({ message: 'Mensagem enviada com sucesso' });
            })
            .catch((error) => {
                console.error(getCurrentTime(), '- Erro ao enviar mensagem para:', number);
                console.error('Erro:', error);
                res.status(500).json({ error: 'Erro ao enviar mensagem' });
            });
    } else {
        client.sendMessage(`${number}@g.us`, message)
            .then(() => {
                console.log(getCurrentTime(), '- Mensagem enviada com sucesso para:', number);
                res.json({ message: 'Mensagem enviada com sucesso' });
            })
            .catch((error) => {
                console.error(getCurrentTime(), '- Erro ao enviar mensagem para:', number);
                console.error('Erro:', error);
                res.status(500).json({ error: 'Erro ao enviar mensagem' });
            });
    }
});

// Enviando mensagens inicio | GET
app.get('/api/message', (req, res) => {
    const { number, message } = req.query;

    const isGroup = (number) => {
        return number.toString().startsWith('55') && number.toString().length === 12;
    };

    const getCurrentTime = () => {
        return moment().tz('America/Sao_Paulo').format('YYYY-MM-DD HH:mm:ss');
    };

    if (isGroup(number)) {
        client.sendMessage(`${number}@c.us`, message)
            .then(() => {
                console.log(getCurrentTime(), '- Mensagem enviada com sucesso para:', number);
                res.json({ message: 'Mensagem enviada com sucesso' });
            })
            .catch((error) => {
                console.error('Erro ao enviar mensagem:', error);
                res.status(500).json({ error: 'Erro ao enviar mensagem' });
            });
    } else {
        client.sendMessage(`${number}@g.us`, message)
            .then(() => {
                console.log(getCurrentTime(), '- Mensagem enviada com sucesso para:', number);
                res.json({ message: 'Mensagem enviada com sucesso' });
            })
            .catch((error) => {
                console.error(getCurrentTime(), '- Erro ao enviar mensagem para:', number);
                console.error('Erro:', error);
                res.status(500).json({ error: 'Erro ao enviar mensagem' });
            });
    }
});

// Enviando arquivos inicio
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const uploadDirectory = req.body.destination || 'uploads/';
        cb(null, uploadDirectory);
    },
    filename: function (req, file, cb) {
        cb(null, file.originalname);
    }
});

const upload = multer({ storage: storage });

app.post('/api/download', upload.single('file'), async (req, res) => {
    const getCurrentTime = () => {
        return moment().tz('America/Sao_Paulo').format('YYYY-MM-DD HH:mm:ss');
    };

    try {
        const { number, filepath, caption, destination } = req.body;
        const uploadDirectory = destination || 'uploads/';
        const media = MessageMedia.fromFilePath(`${uploadDirectory}${filepath}`);
        const isGroup = (number) => {
            return number.toString().startsWith('55') && number.toString().length === 12;
        };

        if (isGroup(number)) {
            await client.sendMessage(`${number}@c.us`, media, { caption: `${caption}` });
            console.log(getCurrentTime(), '- Arquivo enviado com sucesso para:', number);
            res.json({ message: 'Arquivo enviado com sucesso para: ' + `${number}@c.us` });
        } else {
            await client.sendMessage(`${number}@g.us`, media, { caption: `${caption}` });
            console.log(getCurrentTime(), '- Arquivo enviado com sucesso para:', number);
            res.json({ message: 'Arquivo enviado com sucesso para: ' + `${number}@g.us` });
        }
    } catch (error) {
        console.error(getCurrentTime(), '- Erro ao enviar o arquivo:', error);
        res.status(500).send('Erro ao enviar o arquivo');
    }
});

// Inicia o servidor ouvindo em todos os IPs
app.listen(port, '0.0.0.0', () => {
    console.log(`Servidor está rodando em http://0.0.0.0:${port}`);
});
EOF
echo "beezap2.js criado." | tee -a $LOG_FILE

# Iniciando Projeto e Parando PM2
echo " Iniciando Projeto Beezap2 Rodando Comandos Abaixo..."
echo " Acesse Pasta /opt/beezap2"
echo " npm install -g pm2 n"
echo " pm2 start beezap2.js --name beezap2-api"
echo " pm2 stop beezap2.js --name beezap2-api"
echo " pm2 save"

# Acessando pasta do Projeto
#cd ${PROJECT_DIR}
#echo "${PROJECT_DIR}"
#echo "Reinstalando PM2"
#npm install -g pm2 n
#echo "Instalado com Sucesso"

# Finalizar tempo de instalação
end_time=$(date +%s)
duration=$((end_time - start_time))
echo "Instalação concluída em $(($duration / 60)) minutos e $(($duration % 60)) segundos." | tee -a $LOG_FILE

# Exibir o conteúdo do arquivo de log
echo "Conteúdo do arquivo de log:" | tee -a $LOG_FILE

# Finalizar script
echo "Script finalizado com sucesso!" | tee -a $LOG_FILE