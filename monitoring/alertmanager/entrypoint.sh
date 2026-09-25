#!/bin/sh

# Handle Discord webhook secret in container
mkdir -p /etc/alertmanager/secrets

if [ -n "$DISCORD_WEBHOOK_URL" ]; then
    echo "$DISCORD_WEBHOOK_URL" > /etc/alertmanager/secrets/discord_webhook_url
else
    touch /etc/alertmanager/secrets/discord_webhook_url
fi

# Inject MONITORING_DOMAIN into alertmanager.yaml
cp /tmp/alertmanager.yaml /etc/alertmanager/alertmanager.yaml
sed -i "s#MONITORING_DOMAIN#${MONITORING_DOMAIN:-http://localhost:3000}#g" /etc/alertmanager/alertmanager.yaml

exec /bin/alertmanager "$@"
