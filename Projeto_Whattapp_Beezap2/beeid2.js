const { Client, LocalAuth } = require('whatsapp-web.js');

const client = new Client({
    authStrategy: new LocalAuth(),
    puppeteer: {
        args: ['--no-sandbox'],
        headless: true, // Certifique-se de que o navegador está rodando em modo headless
        timeout: 60000 // Aumentar o timeout para 60 segundos
    }
});

client.on('ready', async () => {
    console.log('Cliente está pronto!');

    try {
        console.time('Obter chats'); // Início do timer para obter chats
        const chats = await client.getChats();
        console.timeEnd('Obter chats'); // Fim do timer para obter chats

        console.time('Filtrar grupos'); // Início do timer para filtrar grupos
        const groupChats = chats.filter(chat => chat.isGroup);
        console.timeEnd('Filtrar grupos'); // Fim do timer para filtrar grupos

        console.time('Obter informações dos grupos'); // Início do timer para obter informações dos grupos
        const groupInfo = groupChats.map(chat => ({ id: chat.id._serialized, name: chat.name }));
        console.timeEnd('Obter informações dos grupos'); // Fim do timer para obter informações dos grupos

        console.log('Lista de IDs e nomes de grupos:', groupInfo);
    } catch (error) {
        console.error('Erro ao obter a lista de IDs e nomes de grupos:', error);
    }

    // Encerrar a sessão após obter os IDs e nomes dos grupos
    client.destroy();
});

client.initialize();
