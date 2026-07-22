#!/bin/sh

mkdir -p /etc/alertmanager/secrets

if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    echo "$DISCORD_WEBHOOK_URL" > /etc/alertmanager/secrets/discord_webhook_url
else
    touch /etc/alertmanager/secrets/discord_webhook_url
fi

exec /bin/alertmanager "$@"
