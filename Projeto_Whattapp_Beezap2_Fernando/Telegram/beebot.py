#!/usr/bin/env python3

#### INÍCIO DAS INSTRUÇÕES ####

# Testado no Debian 11 e Ubuntu Server 20.04 ou 22.04
# Crie o diretório padrão: mkdir /var/tmp/zabbix
# Dê permissão ao diretório para o Zabbix: chown -R zabbix:zabbix /var/tmp/zabbix
# Dê permissão de execução ao script: chmod +x /usr/lib/zabbix/alertscripts/beebot.py
# Instale as dependências: apt install python3-pip && pip install requests
# Testando script telegram.py: python3 /usr/lib/zabbix/alertscripts/telegram.py " Item ID: 12345" "Título da mensagem de Teste" "SEU-CHAT-ID-DO-TELEGRAM"
# Lembre-se de importar o tipo de mídia para o Zabbix, criar a Trigger Action e incluir o seu CHAT-ID do Telegram em Media no Profile do usuário do Zabbix

#### FIM DAS INSTRUÇÕES ####

import os
import re
import sys
import requests

#### Início da Declaração de Variáveis ####

# Parâmetros do Telegram
telegram_token = 'TOKEN-TELEGRAM-AQUI'

# URL base do Zabbix
zabbix_url = 'http://127.0.0.1/zabbix'

# Credenciais de login
username = 'USUARIO-ZABBIX-COM-PERMISSAO'
password = 'SENHA-ZABBIX'

# Diretório para salvar os gráficos
graph_directory = '/var/tmp/zabbix/'

#### Fim da Declaração de Variáveis ####

# Função para extrair o item_id da mensagem
def extract_item_id(mensagem):
    # Procura o padrão "Item ID: <item_id>" na mensagem
    match = re.search(r'Item ID:\s*(\d+)', mensagem)
    return match.group(1) if match else None

# Função para fazer login no Zabbix
def zabbix_login(session, url, username, password):
    login_url = f'{url}/index.php'
    login_data = {
        'name': username,
        'password': password,
        'enter': 'Sign in',
        'autologin': 1
    }
    response = session.post(login_url, data=login_data)
    if 'Falha no login' in response.text:
        print('Falha no login')
        sys.exit()
    return session

# Função para obter o gráfico do Zabbix
def get_zabbix_graph(session, url, item_id, save_path):
    graph_url = f'{url}/chart.php?from=now-1h&to=now&itemids[0]={item_id}&type=0&profileIdx=web.charts.filter'
    response = session.get(graph_url)
    if response.status_code == 200:
        with open(save_path, 'wb') as file:
            file.write(response.content)
        print(f'O gráfico foi salvo em {save_path}')
    else:
        print('Falha ao obter o gráfico')
        sys.exit()

# Função para enviar a mensagem com o gráfico via Telegram
def send_telegram_photo(token, chat_id, photo_path, caption):
    url = f'https://api.telegram.org/bot{token}/sendPhoto'
    data = {
        'caption': caption,
        'chat_id': chat_id
    }
    with open(photo_path, 'rb') as photo:
        files = {'photo': photo}
        response = requests.post(url, data=data, files=files)
    if response.status_code == 200:
        print('Mensagem e gráfico enviados com sucesso via Telegram')
    else:
        print('Falha ao enviar mensagem e gráfico via Telegram')

#### Início do Script ####

# Verifica se os argumentos necessários foram passados
if len(sys.argv) != 4:
    print('Uso: python3 beebot.py "<mensagem>" "<título>" "<chat_id>"')
    sys.exit()

mensagem, titulo, chat_id = sys.argv[1], sys.argv[2], sys.argv[3]
item_id = extract_item_id(mensagem)

if not item_id:
    print('Item ID não encontrado na mensagem')
    sys.exit()

graph_filename = os.path.join(graph_directory, f'graph_{item_id}.png')

# Cria uma sessão e faz login no Zabbix
session = requests.Session()
session = zabbix_login(session, zabbix_url, username, password)

# Obtém o gráfico do Zabbix
get_zabbix_graph(session, zabbix_url, item_id, graph_filename)

# Envia a mensagem e o gráfico via Telegram
send_telegram_photo(telegram_token, chat_id, graph_filename, f'{titulo}\n\n{mensagem}')
