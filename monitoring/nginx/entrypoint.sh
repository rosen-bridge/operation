#!/bin/sh
apk add --no-cache apache2-utils > /dev/null 2>&1

if [ -n "$MONITORING_ADMIN_USER" ] && [ -n "$MONITORING_ADMIN_PASSWORD" ]; then
  htpasswd -bc /etc/nginx/.htpasswd "$MONITORING_ADMIN_USER" "$MONITORING_ADMIN_PASSWORD" > /dev/null 2>&1
  export AUTH_BASIC="Authentication Required"
else
  touch /etc/nginx/.htpasswd
  export AUTH_BASIC="off"
fi

rm -f /etc/nginx/conf.d/default.conf

if echo "$COMPOSE_PROFILES" | grep -q "monitoring"; then
  cp /etc/nginx/templates/default.conf.template /etc/nginx/conf.d/prometheus.conf
  sed -i "s|\${PROXY_PORT}|9090|g" /etc/nginx/conf.d/prometheus.conf
  sed -i "s|\${UPSTREAM_HOST}|prometheus|g" /etc/nginx/conf.d/prometheus.conf
  sed -i "s|\${UPSTREAM_PORT}|9090|g" /etc/nginx/conf.d/prometheus.conf
  sed -i "s|\${AUTH_BASIC}|$AUTH_BASIC|g" /etc/nginx/conf.d/prometheus.conf
fi

if echo "$COMPOSE_PROFILES" | grep -q "logger"; then
  cp /etc/nginx/templates/default.conf.template /etc/nginx/conf.d/loki.conf
  sed -i "s|\${PROXY_PORT}|3100|g" /etc/nginx/conf.d/loki.conf
  sed -i "s|\${UPSTREAM_HOST}|loki|g" /etc/nginx/conf.d/loki.conf
  sed -i "s|\${UPSTREAM_PORT}|3100|g" /etc/nginx/conf.d/loki.conf
  sed -i "s|\${AUTH_BASIC}|$AUTH_BASIC|g" /etc/nginx/conf.d/loki.conf
fi

exec nginx -g "daemon off;"
