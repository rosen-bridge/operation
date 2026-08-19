# Monitoring Stack Deployment

To deploy a monitoring stack, you need to set up the unified monitoring services (Prometheus, Grafana, Loki and Alertmanager) with Docker. This stack is designed to monitor and collect logs for both Guard and Watcher services, so if you use either (or both) of them, this monitoring stack can be useful.

## Setting Up the Stack

### Minimum Requirements
The monitoring stack requires a minimum of **2 GB RAM** and **1 CPU core** to operate smoothly.

> **Warning**: If you are monitoring multiple services or containers and you notice a container (such as Prometheus) exiting with code `137` (which indicates an **OOM Kill**), it means the service consumed more memory than available. To resolve this, you must increase the machine memory (even with swap) or limit its memory usage in your `docker-compose.yaml` (or `docker-compose.override.yaml`) under the `deploy` section. For example:
> ```yaml
>     deploy:
>       resources:
>         limits:
>           memory: 2G
> ```

Clone [Operation repository](https://github.com/rosen-bridge/operation.git) and navigate to the `operation/monitoring` directory:

```shell
git clone https://github.com/rosen-bridge/operation.git
cd operation/monitoring/
```

Create your environment file `.env` based on `env.template` file in the `operation` directory:

```shell
cp env.template .env
```

### Environment Variable Configs

You can configure some Environment Variables when deploying with docker as below:

#### Port Exposing

By default, the services bind to local addresses (e.g., `127.0.0.1:9090`). If you want to expose them publicly or on a specific interface, change the published port variables:

- `PROMETHEUS_PUBLISHED_PORT=0.0.0.0:PORT`
- `LOKI_PUBLISHED_PORT=0.0.0.0:PORT`
- `GRAFANA_PUBLISHED_PORT=0.0.0.0:PORT`

#### Security and Authentication

Access to Prometheus (port 9090) and Loki (port 3100) is secured via Basic Authentication.

- Configure `MONITORING_ADMIN_USER` and `MONITORING_ADMIN_PASSWORD` to set your credentials.
- **To disable Auth:** If you leave these two variables completely empty, the Nginx proxy will automatically disable Basic Authentication, allowing open access to the endpoints.

Grafana also uses basic admin credentials:

- Set `GRAFANA_ADMIN_USER` and `GRAFANA_ADMIN_PASSWORD`.

#### Alertmanager

To receive alerts on Discord:

- Set `DISCORD_WEBHOOK_URL` to your Discord channel webhook URL. If left empty, alerts will still be evaluated but not sent to Discord.

> **Note**: If you want to receive alerts on other platforms, you can modify the [`alertmanager.yaml`](../../monitoring/alertmanager/alertmanager.yaml) configuration file according to the [official Alertmanager documentation](https://prometheus.io/docs/alerting/latest/configuration/).

### Customizing Prometheus Rules

Prometheus evaluates alerting rules from the `prometheus/rules/` directory. We have provided several default rules (like `host_down.yaml` for missing Node Exporter data, `docker-services.yaml` for container outages or missing cAdvisor data, and `disk-alerts.yaml` for full disks).

- **To add/modify rules:** You can simply create a new `.yaml` file or edit the existing ones in `prometheus/rules/`. Prometheus is configured to automatically load any `*.yaml` file placed in that directory.
- After adding or changing a rule, apply the changes by restarting the Prometheus container.

## Run monitoring Services

You can start the services by activating the required profiles using the `COMPOSE_PROFILES` environment variable in `.env` file. You can run only the logging stack (`logger`), only the monitoring stack (`monitoring`), or both separated by a comma (e.g., `COMPOSE_PROFILES=logger,monitoring`).

Then run the commands below to correct the files permissions:

```shell
chmod -R ao+rX ./prometheus ./loki ./alertmanager ./nginx ./grafana
chmod o+x ./alertmanager/entrypoint.sh ./nginx/entrypoint.sh
```

Finally run docker compose services:

```shell
docker compose up -d
```
