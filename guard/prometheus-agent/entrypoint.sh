#!/bin/sh

mkdir -p /etc/prometheus

cp /tmp/prometheus-agent/prometheus-agent.yaml.template /etc/prometheus/prometheus-agent.yaml

# Set default URL if not provided
export PROMETHEUS_URL="${PROMETHEUS_URL:-http://monitoring-proxy:9090/api/v1/write}"

# Replace basic variables
sed -i 's|PROMETHEUS_URL|'"$PROMETHEUS_URL"'|g' /etc/prometheus/prometheus-agent.yaml
sed -i 's|PROMETHEUS_LABEL_HOST|'"$PROMETHEUS_LABEL_HOST"'|g' /etc/prometheus/prometheus-agent.yaml

# Handle Basic Auth
if [ -z "$PROMETHEUS_USERNAME" ] || [ -z "$PROMETHEUS_PASSWORD" ]; then
  sed -i '/basic_auth:/,+2d' /etc/prometheus/prometheus-agent.yaml
else
  sed -i 's|PROMETHEUS_USERNAME|'"$PROMETHEUS_USERNAME"'|g' /etc/prometheus/prometheus-agent.yaml
  sed -i 's|PROMETHEUS_PASSWORD|'"$PROMETHEUS_PASSWORD"'|g' /etc/prometheus/prometheus-agent.yaml
fi

exec /bin/prometheus "$@"
