# Monitoring Stack Deployment

To deploy a monitoring stack, you need to set up the unified monitoring services (Prometheus, Grafana, Loki and Alertmanager) with Docker. This stack is designed to monitor and collect logs for both Guard and Watcher services, so if you use either (or both) of them, this monitoring stack can be useful.

> [!NOTE]
> **Alternative: Using Grafana Cloud (No Self-Hosting Required)**  
> If you prefer not to host monitoring services locally (saving ~2 GB of server RAM and CPU resources), you can use the managed [Grafana Cloud](https://grafana.com/products/cloud/).  
>  
> **Recommendation:** Our pre-configured self-hosted stack is **strongly recommended** because it is a one-click deployment and significantly easier to set up and maintain. In comparison, setting up Grafana Cloud requires more manual configuration (generating credentials, importing dashboards, recreating alert rules, and setting up notification policies).  
>  
> *(Note: The **Forever Free Plan** includes **10,000 active series** for Prometheus metrics, **50 GB logs** with 14-day retention, **50 GB traces**, 3 active users, and **40M tokens/month for Grafana AI Assistant**. If your project exceeds these resource limits, you will need to upgrade to a paid plan or deploy the self-hosted stack described below).*
> 
> <details>
> <summary><b>Click here to view the Step-by-Step Grafana Cloud Setup Guide</b></summary>
> 
> ### Step 1: Create an Account & Cloud Stack
> 1. Sign up for a free account at [grafana.com](https://grafana.com).
> 2. Once logged in, navigate to the [Grafana Cloud Portal](https://grafana.com/auth/sign-in/) (or your organization portal `https://grafana.com/orgs/<your-org>`).
> 3. Your default Grafana Cloud stack will be ready for use.
> 
> ---
> 
> ### Step 2: Retrieve Credentials & Configure Client Services (Watcher / Guard)
> 
> On your Cloud Portal overview page after clicking on your stack **Details button**, you will see cards for **Prometheus** and **Loki**:
> 
> #### 1. Prometheus (Metrics)
> 1. Click **Details** (or **Send Metrics**) on the **Prometheus** card.
> 2. Copy the **Remote Write URL** (e.g. `https://prometheus-prod-xxx.grafana.net/api/v1/push`).
> 3. Copy the **Username / Instance ID** (a numeric ID like `3614354`).
> 4. Click **Generate Token** (Password) and give a name to it.
> 5. In your Watcher or Guard directory, paste these into `.env.monitoring`:
>    ```env
>    PROMETHEUS_URL=https://prometheus-prod-xxx.grafana.net/api/v1/push
>    PROMETHEUS_USERNAME=<your_prometheus_numeric_id>
>    PROMETHEUS_PASSWORD=<your_generated_token>
>    ```
> 
> #### 2. Loki (Logs)
> 1. Click **Details** (or **Send Logs**) on the **Loki** card.
> 2. Copy the **Push URL** (under the Alloy configuration, e.g. `https://logs-prod-xxx.grafana.net/loki/api/v1/push`).
> 3. Copy the **Username / Instance ID** (a numeric ID like `1802845`).
> 4. Click **Generate Token** (Password) and give a name to it.
> 5. In your Watcher or Guard directory, paste these into `.env.logger`:
>    ```env
>    LOKI_URL=https://logs-prod-xxx.grafana.net/loki/api/v1/push
>    LOKI_USERNAME=<your_loki_numeric_id>
>    LOKI_PASSWORD=<your_generated_token>
>    ```
> 
> #### 3. General Client Settings
> In the main `.env` file of Watcher/Guard, ensure you set:
> ```env
> IS_SAME_HOST=false
> ```
> *(Because the monitoring stack is remote on Grafana Cloud, not on the same local Docker network).*
> 
> ---
> 
> ### Step 3: Launch Grafana & Import Dashboards
> 
> 1. In the Grafana Cloud Portal on your stack page, click the **Launch** button next to **Grafana**.
> 2. In Grafana's left-hand navigation menu, click **Dashboards** > **New** > **Import**.
> 3. Drag and drop the JSON dashboard files located in this repository under `monitoring/grafana/dashboards/*`:
>    - **[containers.json](../../monitoring/grafana/dashboards/monitoring/containers.json)**: In the import settings under **Select a Prometheus data source**, choose your Grafana Cloud Prometheus data source (name starts with `grafanacloud-...-prom`).
>    - **[system_metrics.json](../../monitoring/grafana/dashboards/monitoring/system_metrics.json)**: Choose the same Prometheus data source (`grafanacloud-...-prom`).
>    - **[logs_servicename.json](../../monitoring/grafana/dashboards/logger/logs_servicename.json)**: In the import settings under **Select a Loki data source**, choose your Grafana Cloud Loki data source (name starts with `grafanacloud-...-logs`).
> 4. Click **Import** for each dashboard. All panels, variables, and logs will automatically connect and visualize your data.
> 
> ---
> 
> ### Step 4: Configure Alert Rules & Notifications
> 
> You do not need to deploy a local Alertmanager container. Grafana Cloud has built-in alerting:
> 
> 1. In Grafana, navigate to **Alerts & IRM** > **Alert rules** and click **+ New alert rule** (or **Create alert rules**).
> 2. Select your Prometheus data source (`grafanacloud-...-prom`), set the **Folder** (e.g., `GrafanaCloud`), and create each **Evaluation group** by clicking **+ New evaluation group** (set interval to `1m`).
> 3. Add each of the preconfigured rules from `monitoring/prometheus/rules/`:
> 
>    * **Alert 1: `NodeDiskUsageHigh` (from [`disk-alerts.yaml`](../../monitoring/prometheus/rules/disk-alerts.yaml))**
>      - **Rule name**: `NodeDiskUsageHigh`
>      - **Expression (PromQL)**:
>        ```promql
>        100 * (1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs|aufs|nsfs",mountpoint!~"/run.*|/var/lib/docker/.*|/var/lib/containerd/.*"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs|aufs|nsfs",mountpoint!~"/run.*|/var/lib/docker/.*|/var/lib/containerd/.*"}))
>        ```
>      - **Alert condition**: `IS ABOVE 90`
>      - **Evaluation group**: `disk-alerts` | **Pending period**: `1m`
>      - **Labels**: `severity` = `critical`
>      - **Summary Annotation**: `Disk usage is {{ printf "%.1f" $values.A.Value }}% on {{ $labels.host }}, Mountpoint: {{ $labels.mountpoint }} ({{ $labels.device }}).`
> 
>    * **Alert 2: `HostDown` (from [`host_down.yaml`](../../monitoring/prometheus/rules/host_down.yaml))**
>      - **Rule name**: `HostDown`
>      - **Expression (PromQL)**:
>        ```promql
>        max_over_time(up{job="node-exporter"}[30m])
>        ```
>      - **Alert condition**: `IS BELOW 1`
>      - **Evaluation group**: `host-availability` | **Pending period**: `0s`
>      - **Labels**: `severity` = `critical`
>      - **Summary Annotation**: `The {{ $labels.instance }} instance is Down.`
>      - **Description Annotation**: `No successful node-exporter scrape for 30 minutes.`
> 
>    * **Alert 3: `DockerServiceStopped` (from [`docker-services.yaml`](../../monitoring/prometheus/rules/docker-services.yaml))**
>      - **Rule name**: `DockerServiceStopped`
>      - **Expression (PromQL)**:
>        ```promql
>        max by (host, container_label_com_docker_compose_project, container_label_com_docker_compose_service) (present_over_time(container_last_seen{container_label_com_docker_compose_service!="", name=~".*(guard|watcher|monitoring).*"}[1d])) unless on (host, container_label_com_docker_compose_project, container_label_com_docker_compose_service) max by (host, container_label_com_docker_compose_project, container_label_com_docker_compose_service) (present_over_time(container_last_seen{container_label_com_docker_compose_service!="", name=~".*(guard|watcher|monitoring).*"}[1m]))
>        ```
>      - **Alert condition**: `IS ABOVE 0`
>      - **Evaluation group**: `docker-services` | **Pending period**: `0s`
>      - **Labels**: `severity` = `critical`
>      - **Summary Annotation**: `Service {{ $labels.container_label_com_docker_compose_service }} appears stopped in {{ $labels.container_label_com_docker_compose_project }} project.`
> 
>    * **Alert 4: `DockerServiceRestartLoop` (from [`docker-services.yaml`](../../monitoring/prometheus/rules/docker-services.yaml))**
>      - **Rule name**: `DockerServiceRestartLoop`
>      - **Expression (PromQL)**:
>        ```promql
>        changes(container_start_time_seconds{container_label_com_docker_compose_service!="", name=~".*(guard|watcher|monitoring).*"}[5m]) > 3 or (count by (container_label_com_docker_compose_project, container_label_com_docker_compose_service, name) (present_over_time(container_start_time_seconds{container_label_com_docker_compose_service!="", name=~".*(guard|watcher|monitoring).*"}[5m])) > 3)
>        ```
>      - **Alert condition**: `IS ABOVE 0`
>      - **Evaluation group**: `docker-services` | **Pending period**: `0s`
>      - **Labels**: `severity` = `critical`
>      - **Summary Annotation**: `Restart loop detected for service {{ $labels.container_label_com_docker_compose_service }}.`
> 
> 4. **Delivery to Discord / Telegram / Email (Contact points):**
>    - In Grafana, go to **Alerts & IRM** > **Contact points** and click **+ Add contact point**.
>    - Select your notification integration (e.g., **Discord** and paste your webhook URL, or Telegram/Email).
>    - Set this contact point as the **Default policy** under **Notification policies** so all firing alerts are immediately forwarded to your notification channel.
> </details>

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
- Set `MONITORING_DOMAIN` to the base URL where you access Grafana (e.g., `http://localhost:3000` or `https://domain.example.com`). This will be used to generate clickable **Source** and **Silence** links within your Discord alerts.

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
