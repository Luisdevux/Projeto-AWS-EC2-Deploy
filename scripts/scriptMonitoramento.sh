#!/bin/bash

# Variavel que define o caminho de salvamento dos logs
LOG_FILE="/var/log/meu_monitoramento.log"

if [ ! -f  "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

# Variavel para definir ip da requisicao automaticamente
IP_REQUEST=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
# URL do WEBHOOK
URL_WEBHOOK="URL DO SEU WEBHOOK DO DISCORD VAI AQUI"
# Variavel para armazenar data e ser reutilizavel
DATE=$(date '+%Y-%m-%d %H:%M:%S')

enviar_discord() {
  local MESSAGE=$1
  curl -s -H "Content-Type: application/json" \
       -X POST \
       -d "{\"content\": \"\`\`\`$MESSAGE\`\`\`\"}" \
       "$URL_WEBHOOK"
}

# Verificacao do status do serviço nginx
NGINX_STATUS=$(systemctl is-active nginx)

if [ "$NGINX_STATUS" != "active" ]; then
    MSG="$DATE - ERRO: Nginx não está rodando!Verifique! Status atual: $NGINX_STATUS"
    echo "$MSG" >> "$LOG_FILE"
    enviar_discord "$MSG"
    exit 1
else
    MSG="$DATE - SUCESSO: Nginx está rodando corretamente. Status: $NGINX_STATUS"
    echo "$MSG" >> "$LOG_FILE"
    enviar_discord "$MSG"
fi

# Variavel que ira guardar o resultado da requisicao
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$IP_REQUEST")
# Variavel para verificar sucesso de conexão
CURL_EXIT_CODE=$?

# Verificacao de conexao
if [ $CURL_EXIT_CODE -ne 0 ]; then
    MSG="$DATE - ERRO: Falha ao conectar na URL! curl retornou código de erro $CURL_EXIT_CODE"
    echo "$MSG" >> "$LOG_FILE"
    enviar_discord "$MSG"
    exit 1
elif [ "$STATUS_CODE" = "000" ]; then
    MSG="$DATE - ERRO: Nenhuma resposta HTTP recebida (status 000). Possível falha de conexão."
    echo "$MSG" >> "$LOG_FILE"
    enviar_discord "$MSG"
    exit 1
fi

# Verificacao das requisicoes
if [ "$STATUS_CODE" -eq 200 ]; then
    MSG="$DATE - SUCESSO: Requisição bem sucedida! Status retornado: $STATUS_CODE"
    echo "$MSG" >> "$LOG_FILE"
    enviar_discord "$MSG"
elif [ "$STATUS_CODE" -eq 500 ]; then
    MSG="$DATE - ERRO: Erro interno do servidor... Status retornado: $STATUS_CODE"
    echo "$MSG" >> "$LOG_FILE"
    enviar_discord "$MSG"
    exit 1
else
    MSG="$DATE - ERRO: Falha ao executar requisição! Status retornado: $STATUS_CODE"
    echo "$MSG" >> "$LOG_FILE"
    enviar_discord "$MSG"
    exit 1
fi