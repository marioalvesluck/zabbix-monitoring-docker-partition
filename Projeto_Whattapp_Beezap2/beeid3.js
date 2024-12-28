// Desenvolvido por: Bee Solutions //
// Autor: Fernando Almondes //
// Data: 23/12/2024 //
// Creditos adicionais: Comunidade Bee Solutions //
// Aqui voce pega a lista de grupos e ids //

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