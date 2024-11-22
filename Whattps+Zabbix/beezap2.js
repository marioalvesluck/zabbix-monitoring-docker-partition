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
