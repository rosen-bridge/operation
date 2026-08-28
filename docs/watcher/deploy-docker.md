# Watcher Deployment

To participate as a watcher in the bridge, you need to deploy a watcher app, observing one of the supported networks. Each supported network has its own set of watchers, that are responsible for reporting users' actions on that specific network.

## Docker

Clone [Operation repository](https://github.com/rosen-bridge/operation.git) and navigate to `operation/watcher` directory:

```shell
git clone https://github.com/rosen-bridge/operation.git
cd operation/watcher/
```

Create your environment file `.env` based on `env.template` file in the `watcher` directory:

```shell
cp env.template .env
```

To view hidden .env later, use `ls -a`.

## Environment Variable Configs

You can configure some Environment Variables when deploying with docker, you can find all of them [here](./env-references.md).

Set your parameters in `.env` file (make sure not to use spaces after the '=' sign):

```shell
# Required Environments

POSTGRES_PASSWORD= # a random alphanumeric password without special characters (like $%!-#)

POSTGRES_USER= # a random name

POSTGRES_DB= # a random name

POSTGRES_PORT=5432 # 5432 is set as default, you can change it
```

Set required permissions and create `local.yaml` file in the `config` directory

```shell
sudo chown -R 3000:3000 logs
touch config/local.yaml
```

Only on `MacOS`: set `707` permission for the `logs` directory

```shell
# only on MacOS
sudo chmod -R 707 logs
```

### Pull docker images and run service

Pull the Docker image

```shell
docker compose pull # use `docker-compose pull` for older versions of Docker
```

Set up your `local.yaml` using the instructions in the next section (Local Config).

Finally, after saving the 'local.yaml' changes, run the container:

```shell
docker compose up -d # use `docker-compose up -d` for older versions of Docker
```

## Local Config

To start your watcher, you should configure the local.yaml file.
First, specify the target network you're watching. Currently, we support `ergo`, `cardano`, `bitcoin`, `ethereum`, `binance`, `doge` and `bitcoin-runes`:

```yaml
network: ergo
```

### API

```yaml
api:
  apiKeyHash: <your api key hash>
```

#### apiKeyHash

To secure the action-based APIs (ex: lock, unlock, ...), you should set a unique and robust api key.
We are using a blake2b hash to secure APIs.

#### Compute api_key's Hash

Use [rosen command line](https://github.com/rosen-bridge/utils/tree/dev/packages/cli) to compute api key hash:

```shell
  # use nodejs solution
  npx @rosen-bridge/cli blake2b-hash YOUR_API_KEY
  # or docker solution
  docker run -it --rm node:18.16 npx --yes @rosen-bridge/cli blake2b-hash YOUR_API_KEY
```

#### Update Configuration File

After obtaining the hash, input it into your config file. For example, the salted Blake2b hash of `hello` is `$USHxmI8E$7Bby9L7leeExrYFt2n3270K4+PMCCszZ+UwCV8klqBs=`.

> **⚠️ NOTE**: When using docker there is an `API_KEY_HASH` environment variable available for `apiKeyHash` that you can set instead of in the local configuration. See your `.env` file. We recommend utilizing environment variables over direct configuration file settings for **security** purpose to not accidently share your api key while troubleshooting etc. After updating, you can delete `apiKeyHash` from /config/local.yaml. Note that you should set your hash between single quotes, for example: API_KEY_HASH='$USHxmI8E$7Bby9L7leeExrYFt2n3270K4+PMCCszZ+UwCV8klqBs='.

## Notification

To be informed about your watcher health status you can configure the notification setting. Currently, we support discord notifications and you can set up a discord webhook url in your local config file:

```yaml
notification:
  discordWebhookUrl: <your webhook url>
```

## Logs

You have 3 options for your logs.

- console

  service logs will be only printed on console, you just need to specify
  log level.

  ```yaml
  - type: 'console'
    level: 'info' # [debug, info, warn, error]
  ```

- file

  service logs will be printed in files in give path.

  ```yaml
  - type: 'file'
    path: './logs/'
    maxSize: '20m' # maximum size of each log file (20 MB)
    maxFiles: '14d' # maximum number of log files (14 days)
    level: 'info' # [debug, info, warn, error]
  ```

  > **NOTE**: Don't change `path`, since it's hard coded in Dockerfile.

- loki

  service logs will be sent to Grafana server.

  ```yaml
  - type: 'loki'
    host: 'YOUR_LOKI_URL'
    level: 'info' # [debug, info, warn, error]
    basicAuth: '' # Required if you have a remote loki server
  ```

  > **NOTE**: When using docker there is an `OVERRIDE_LOKI_BASIC_AUTH` environment variable available for `basicAuth` that you can set instead of in the local configuration.

  > **⚠️ NOTE**: Using the `loki` type logger with the `winston-logger` package may sometimes result in missed logs. recommended to use the `file` logger type instead and let **Alloy** handle shipping the logs.
  > 
  > For the exact `file` logger configuration required and the complete setup for the Alloy service, please refer to the [Monitoring Agents Configuration](#monitoring-agents-configuration) section.

You also can set multiple logs config. Therefore your config will be something like this:git

```yaml
logs:
  - type: 'console'
    level: 'info'
  - type: 'file' # [file, console]
    path: './logs/' # path to log files (only for rotateFile type)
    maxSize: '20m' # maximum size of each log file (20 MB)
    maxFiles: '14d' # maximum number of log files (14 days)
    level: 'info' # [debug, info, warn, error]
```

## Reward Collection

Watchers earn rewards in eRSN, but these need to be converted to RSN. The watcher service runs a regular task to collect and exchange eRSN for RSN once a certain amount is reached. It can also send the RSN rewards to a different address. You can set both the collection amount and the reward address by adding these configuration to the local config file (Otherwise it will use default threshold and send the exchanged RSN to the default watcher address):

```yaml
rewardCollection:
  threshold: <rsn collection threshold>
  address: <your reward collection address>
```

> Note: Set the threshold considering the RSN token decimal places (3 decimal points). For example, if you want to collect RSNs after reaching to 200 you should set `rewardCollection.threshold` to 200000.

## Observation Raw Data

When a transfer request is initiated on any chain, the transaction containing the request must include some data that can be processed by watchers. The raw data observed by watchers has a structure specific to each source chain. Watchers extract the Rosen-compatible data from this raw data but store both forms in the database.

You can disable raw-data storage without affecting watcher behavior. Raw data is stored only to provide additional insights for advanced users in the watcher UI. Note that storing raw data does not add any computational overhead to the watcher.

Observation raw-data storage is enabled by default, but you can turn it off by adding the following configuration:

```yaml
observation:
  storeRawData: false
```

### Ergo Config (Essential for all watchers)

For all watchers, even if you're targeting a different network than Ergo to watch, you still need to configure the Ergo section (Under the `ergo` keyword):

1. Create an empty wallet for your watcher, and set the wallet mnemonic in the config file (you can use any wallet to generate a valid mnemonic on Ergo, and please use a new fresh wallet for this purpose only):

```yaml
mnemonic: <your wallet mnemonic>
```

> Note: Utilizing this mnemonic in a standard multi-address wallet will lead to watcher misbehavior.

> **⚠️ NOTE**: Instead of setting `mnemonic` in the local configuration file, consider using the `MNEMONIC` environment variable for ease of management. We recommend utilizing environment variables over direct configuration file settings for **security** purpose to not accidently share your seed phrase while troubleshooting etc. See your `.env` file. Once updated, in /config/local.yaml delete your mnemonic phrase and put in a comment like so "mnemonic: #see local config env file"

1. Select your primary data source for the Ergo network; block and box information are retrieved from this source. You can use either `explorer` or `node` as the primary source:

```yaml
type: node
```

Note: As you choose one of these and start, your watcher scans several blocks using that source. Changing the source might cause some issues since the watcher tries to scan all blocks from the beginning and it takes time to be synced again. So just in case of a serious problem change this config. In some cases, you may want to delete your volume and start over (Consider updating the initial height in such cases).

3. Specify the node and explorer urls (Currently you are required to use an Ergo node for transaction submissions, even when you're using the explorer as your primary source. In contrast, when you rely on a node as your primary information source, you do not need to use the explorer.)

```yaml
node:
  url: https://example.node.com
explorer:
  url: https://api.ergoplatform.com
```

> Note: If you don't specify the explorer url, it will use the 'https://api.ergoplatform.com' by default, but you need to specify your node url (You may want to use a public node).

> Note: Make sure the Ergo node has extra indexing turned on. Otherwise, health check parameters won't update correctly (the watcher works correctly, but wid and asset health check params might have problems). Read more about extra indexing [here](https://docs.ergoplatform.com/node/conf/conf-node/#extra-index).

> Note: Do not use nodes with version 5.0.15 and 5.0.16 due to a bug in extra indexing (in case you're using these versions you can downgrade to 5.0.14 for now).

4. Set the initial height of your watcher. For the first time, you should check the current network height and set where to start watching and reporting. You may choose an older height but we highly recommend using the current network height. In case you stop your watcher and start it again later, it will continue its procedure from its last stored block, so you don't need to change the initial height in the future.

```yaml
initialHeight: <latest ergo height>
```

> Note: Fill with a recent block height (e.g. 10 blocks before). You can find Ergo latest blocks [here](https://explorer.ergoplatform.com/en/latest-blocks).

> Note: Once watcher started scanning from the initial block, changing this config wont affect the watcher behavior. In case you need to restart the watcher from an earlier block consider removing volumes.

5. (JUST ERGO WATCHER) To ensure the watcher's proper functionality, event observations should be sufficiently confirmed before taking action. You should customize observation confirmation to align with your watching network's specification. By default, this setting is configured much higher. For Ergo, we recommend using the following configuration:

```yaml
observation:
  confirmation: 9
```

Finally, an example Ergo watcher `local.yaml` file would look like:

```yaml
network: ergo
api:
  apiKeyHash: <your api key hash>
ergo:
  type: explorer
  initialHeight: <latest ergo height>
  mnemonic: <your wallet mnemonic>
  node:
    url: https://example.node.com
  explorer:
    url: https://api.ergoplatform.com

observation:
  confirmation: 9
```

### Cardano Config (Just for Cardano watchers)

If you are configuring a Cardano watcher, you should set these configs under the `cardano` keyword as well:

1. Choose your information source for Cardano network and specify its connection information. You can use either `koios` or `ogmios` as the data source.

```yaml
type: ogmios
ogmios:
  host: 127.0.0.1
  port: 1337
  useTls: false
```

or

```yaml
type: koios
koios:
  url: https://api.koios.rest/api/v1/
  authToken: <your koios auth token>
```

> **NOTE**: When using docker there is an `KOIOS_AUTH_TOKEN` environment variable available for `authToken` that you can set instead of in the local configuration.

> Note: If you don't specify the koios url, it will use the https://api.koios.rest/api/v1/ by default, but in case you're using ogmios as your source you should specify the host address and port of an ogmios instance.

> Note: If you're using a TLS enabled ogmios, set the useTls to true.

> Note: Watcher utilize Koios v1 APIs, and you can use your authentication token on the Koios platform by configuring the authToken. Alternatively, the watcher uses the public tier of the Koios platform, which comes with limitations on requests. You can get your koios access token [here](https://koios.rest/pricing/Pricing.html).

> Note: Currently, the watcher is only compatible with Ogmios v6. Utilizing other versions of Ogmios may result in improper functionality.

> Note: As you choose one of these and start, your watcher scans several blocks using that source. Changing the source might cause some issues since the watcher tries to scan all blocks from the beginning and it takes time to be synced again. So just in case of a serious problem change this config. In some cases, you may want to delete your volume and start over (Consider updating the initial height in such cases).

> Note: To extract observation raw data using the Ogmios client, it must return the encoded transaction in `cbor` format. You can enable `cbor` output by running the Ogmios client with the `--include-cbor` or `--include-transaction-cbor` flag.
> If the transaction data does not include `cbor`, the Ogmios scanner will get stuck. If you do not have access to the client configuration, or you simply do not need raw-data storage, you can disable obsreavtion raw-data storage. Please refer to [this section](#observation-raw-data) for the raw-data storage configuration.

2. Set your watcher's initial height; this height is the point from which you start observing and reporting events. Like the Ergo network, you may choose to start from an older height but we highly recommend using the latest block as your initial point. You should specify the initial block height, hash, and slot.

```yaml
initial:
  height: <latest cardano height>
  hash: <latest cardano hash>
  slot: <latest cardano slot>
```

> Note: Koios utilizes block height, while Ogmios relies on the hash and slot of the initial block.

> Note: Use block absolute slot

> Note: Fill with a recent block height (e.g. 10 blocks before). You can find Cardano latest blocks [here](https://cardanoscan.io/blocks).

> Note: Once watcher started scanning from the initial block, changing this config wont affect the watcher behavior. In case you need to restart the watcher from an earlier block consider removing volumes and updating both Ergo and Cardano initial heights.

3. To ensure the watcher's proper functionality, event observations should be sufficiently confirmed before taking action. You should customize observation confirmation to align with your watching network's specification. For Cardano, we recommend using the following configuration:

```yaml
observation:
  confirmation: 25
```

Finally, an example Cardano watcher `local.yaml` file would look like:

```yaml
network: cardano
api:
  apiKeyHash: <your api key hash>
ergo:
  type: explorer
  initialHeight: <latest ergo height>
  mnemonic: <your wallet mnemonic>
  node:
    url: https://example.node.com
cardano:
  type: koios
  koios:
    authToken: <your koios auth token>
  initial:
    height: <latest cardano height>
    hash: <latest cardano hash>
    slot: <latest cardano slot>
observation:
  confirmation: 25
```

### Bitcoin Config (Just for Bitcoin watchers)

As a Bitcoin watcher, you should specify these configurations under `bitcoin` keyword:

1. Choose your information source for Bitcoin network and specify its connection information. You can use either `rpc` or `esplora` as the data source.

```yaml
type: rpc
rpc:
  url: <your rpc url>
  username: <your rpc username>
  password: <your rpc password>
```

or

```yaml
type: esplora
esplora:
  url: https://blockstream.info
```

> NOTE: When using docker there are `BITCOIN_RPC_USERNAME` and `BITCOIN_RPC_PASSWORD` environment variable available for rpc authentication that you can set instead of in the local configuration.

> Note: If you don't specify an esplora url, it will use the https://blockstream.info by default, but in case you're using RPC as your source you should specify your bitcoin node instance RPC url.

> Note: RPC authentication configuration is optional, if you're using a public node you don't need to add username and password.

> Note: You can use both configuration, but using RPC is recommended. An RPC connection to a bitcoin node is much faster and does not have limits on fetching data.

2. Set your watcher's initial height, where you start observing and reporting events. Like the Ergo network, we highly recommend using the latest block as your initial point. You should specify the initial block height.

```yaml
initial:
  height: <latest bitcoin height>
```

> Note: You can find latest bitcoin blocks [here](https://blockstream.info/).

> Note: Once watcher started scanning from the initial block, changing this config wont affect the watcher behavior. In case you need to restart the watcher from an earlier block consider removing volumes and updating both Ergo and Bitcoin initial heights.

3. To ensure the watcher's proper functionality, event observations should be sufficiently confirmed before taking action. You should customize observation confirmation to align with your watching network's specification. For Bitcoin, we recommend using the following configuration:

```yaml
observation:
  confirmation: 1
```

Finally, an example Bitcoin watcher `local.yaml` file would look like:

```yaml
network: bitcoin
api:
  apiKeyHash: <your api key hash>
ergo:
  type: explorer
  initialHeight: <latest ergo height>
  mnemonic: <your wallet mnemonic>
  node:
    url: https://example.node.com
bitcoin:
  type: rpc
  rpc:
    url: <your rpc url>
    username: <your rpc username>
    password: <your rpc password>
  initial:
    height: <latest bitcoin height>
observation:
  confirmation: 1
```

### Ethereum Config (Just for Ethereum watchers)

As a Ethereum watcher, you should specify these configurations under `ethereum` keyword:

1. Currently Ethereum watchers only support rpc endpoints. You should specify the rpc endpoint connection information in the following format:

```yaml
type: rpc
rpc:
  url: <your rpc url>
  authToken: <your rpc auth token>
```

> Note: RPC authentication token is optional, if you're using a public node you don't need to add authToken.

> **NOTE**: When using docker there is an `ETHEREUM_RPC_AUTH_TOKEN` environment variable available for `authToken` that you can set instead of in the local configuration.

2. Set your watcher's initial height, where you start observing and reporting events. Like the Ergo network, we highly recommend using the latest block as your initial point. You should specify the initial block height.

```yaml
initial:
  height: <latest ethereum height>
```

> Note: You can find latest ethereum blocks [here](https://etherscan.io/).

> Note: Once watcher started scanning from the initial block, changing this config wont affect the watcher behavior. In case you need to restart the watcher from an earlier block consider removing volumes and updating both Ergo and Ethereum initial heights.

3. To ensure the watcher's proper functionality, event observations should be sufficiently confirmed before taking action. You should customize observation confirmation to align with your watching network's specification. For Ethereum, we recommend using the following configuration:

```yaml
observation:
  confirmation: 20
```

Finally, an example Ethereum watcher `local.yaml` file would look like:

```yaml
network: ethereum
api:
  apiKeyHash: <your api key hash>
ergo:
  type: explorer
  initialHeight: <latest ergo height>
  mnemonic: <your wallet mnemonic>
  node:
    url: https://example.node.com
ethereum:
  type: rpc
  rpc:
    url: <your rpc url>
  initial:
    height: <latest ethereum height>
observation:
  confirmation: 20
```

### Binance Config (Just for Binance watchers)

If you're running a Binance watcher, configure it under the `binance` section as follows:

1. **Connection configuration:** Binance watchers currently support only RPC endpoints. Specify your connection details in this format:

```yaml
type: rpc
rpc:
  url: <your rpc url>
  authToken: <your rpc auth token>
```

> Note: RPC authentication token is optional, if you're using a public node you don't need to add authToken.

> NOTE: If you're running the watcher in docker, you can set `BINANCE_RPC_AUTH_TOKEN` as an environment variable instead of storing it in the local configuration.

2. **Initial Block Height:** Define the starting block height for observing and reporting events. We recommend using the latest Binance block:

```yaml
initial:
  height: <latest binance height>
```

> Note: Find the latest Binance blocks [here](https://bscscan.com/).

> Note: Once the watcher begins scanning from the initial block, updating this setting won't change its behavior. To restart from an earlier block, remove volumes and update both the Ergo and Binance initial heights.

3. **Observation Confirmation:** To ensure accurate event tracking, set confirmation based on Binance's network specifications. Recommended value:

```yaml
observation:
  confirmation: 300
```

Finally, an example Binance watcher `local.yaml` file would look like:

```yaml
network: binance
api:
  apiKeyHash: <your api key hash>
ergo:
  type: node
  initialHeight: <latest ergo height>
  mnemonic: <your wallet mnemonic>
  node:
    url: https://example.node.com
binance:
  type: rpc
  rpc:
    url: <your rpc url>
  initial:
    height: <latest binance height>
observation:
  confirmation: 300
```

### Doge Config (Just for Doge watchers)

If you're running a Doge watcher, configure it under the `doge` section as follows:

1. **Connection configuration:** Doge watchers currently support only RPC endpoints. Specify your connection details in this format:

```yaml
type: rpc
rpc:
  - url: <your rpc url>
    timeout: <your rpc timeout in seconds>
    username: <your rpc username>
    password: <your rpc password>
```

> Note: RPC username and password is optional, if you're using a public node you don't need to add authorization configs.

> NOTE: You can add multiple RPC instances to the Doge configuration. The watcher will automatically balance the load across all instances. (For example, if you're using a GetBlock.io RPC node, you should add at least one additional RPC connection to avoid hitting rate limits.)

2. **Initial Block Height:** Define the starting block height for observing and reporting events. We recommend using the latest Doge block:

```yaml
initial:
  height: <latest doge height>
```

> Note: Find the latest Doge blocks [here](https://sochain.com/DOGE).

> Note: Once the watcher begins scanning from the initial block, updating this setting won't change its behavior. To restart from an earlier block, remove volumes and update both the Ergo and Doge initial heights.

3. **Observation Confirmation:** To ensure accurate event tracking, set confirmation based on Doge's network specifications. Recommended value:

```yaml
observation:
  confirmation: 10
```

Finally, an example Doge watcher `local.yaml` file would look like:

```yaml
network: doge
api:
  apiKeyHash: <your api key hash>
ergo:
  type: node
  initialHeight: <latest ergo height>
  mnemonic: <your wallet mnemonic>
  node:
    url: https://example.node.com
doge:
  type: rpc
  rpc:
    - url: <your first rpc instance url without username-password>
      timeout: 10
    - url: <your second rpc instance url>
      timeout: 10
      username: <your second rpc instance username>
      password: <your second rpc instance password>
  initial:
    height: <latest doge height>
observation:
  confirmation: 10
```

### Bitcoin-Runes Config (Just for Bitcoin-Runes watchers)

Since Bitcoin-Runes is not a separate chain from Bitcoin and is simply a standard on the Bitcoin network, running a Bitcoin-Runes bridge requires configuring both Bitcoin and Bitcoin-Runes.

As with other Bitcoin watchers, configure the Bitcoin network connection according to the instructions in [this section](#bitcoin-config-just-for-bitcoin-watchers).

In addition to the Bitcoin configuration, you must provide data sources for Runes. Add these configurations under the `bitcoinRunes` section. You can use either `ordiscan` or `unisat` as the data source:

```yml
type: ordiscan
ordiscan:
  apiKey: <your ordiscan api key>
```

or

```yml
type: unisat
unisat:
  apiKey: <your unisat api key>
```

> Note: You can get a Unisat API key from [here](https://developer.unisat.io/account/login) or Ordiscan API Key from [here](https://ordiscan.com/docs/api/login).

> NOTE: You can set Unisat or Ordiscan api key as docker environment variables with keys `UNISAT_API_KEY` or `ORDISCAN_API_KEY` instead of storing it in the local configuration.

Finally, an example Bitcoin-Runes watcher `local.yaml` file would look like:

```yaml
network: bitcoin-runes
api:
  apiKeyHash: <your api key hash>
ergo:
  type: explorer
  initialHeight: <latest ergo height>
  mnemonic: <your wallet mnemonic>
  node:
    url: https://example.node.com
bitcoin:
  type: rpc
  rpc:
    url: <your rpc url>
    username: <your rpc username>
    password: <your rpc password>
  initial:
    height: <latest bitcoin height>
bitcoinRunes:
  type: unisat
  unisat:
    apiKey: <your unisat api key>
observation:
  confirmation: 1
```

### Firo Config (Just for Firo watchers)

If you're running a Firo watcher, configure it under the `firo` section as follows:

1. **Connection configuration:** Firo watchers currently supports direct JSON-RPC and ElectrumX endpoints. The ElectrumX is recommended as the JSON-RPC might be removed in near future. Specify your connection details in this format:

```yaml
type: electrumx
electrumx:
  host: <your electrumX host>
  port: 50002
```

or

```yaml
type: rpc
rpc:
  url: <your json-rpc url>
  username: <your rpc username>
  password: <your rpc password>
```

> Note: ElectrumX network uses socket connection, so reconnection delay (with `reconnectDelay` key) can be configured too. Alternatively, you can change the port, which is `50002` by default.

> Note: RPC username and password is optional, if you're using a public node you don't need to add authorization configs.

> NOTE: When using docker there are `FIRO_RPC_USERNAME` and `FIRO_RPC_PASSWORD` environment variable available for rpc authentication that you can set instead of in the local configuration.

2. **Initial Block Height:** Define the starting block height for observing and reporting events. We recommend using the latest Firo block:

```yaml
initial:
  height: <latest firo height>
```

> Note: Find the latest Firo blocks [here](https://explorer.firo.org).

> Note: Once the watcher begins scanning from the initial block, updating this setting won't change its behavior. To restart from an earlier block, remove volumes and update both the Ergo and Firo initial heights.

3. **Observation Confirmation:** To ensure accurate event tracking, set confirmation based on Firo's network specifications. Recommended value:

```yaml
observation:
  confirmation: 8
```

Finally, an example Firo watcher `local.yaml` file would look like:

```yaml
network: firo
api:
  apiKeyHash: <your api key hash>
ergo:
  type: node
  initialHeight: <latest ergo height>
  mnemonic: <your wallet mnemonic>
  node:
    url: https://example.node.com
firo:
  type: electrumx
  electrumx:
    host: <your electrumX host>
    port: 50002
  initial:
    height: <latest firo height>
observation:
  confirmation: 8
```

## Monitoring Agents Configuration

You have two deployment options depending on where your Observability Stack (Grafana, Prometheus and Loki) is located:

### Mode 1: Single-Server Deployment (Same Machine)
If you intend to host both this Watcher service and the Observability Stack on the **same machine**, the agents here will connect directly to the Observability Stack.
* Ensure you set `IS_SAME_HOST=true` in your `.env` file (this is the default).
* **Requirement:** You MUST deploy the Observability Stack first. If you try to run this service with monitoring profiles enabled before the Observability Stack is up, you will get a "network not found" error. Please follow the [Monitoring Setup Guide](../monitoring/setup.md) to bring up the Observability Stack before proceeding.

### Mode 2: Multi-Server Deployment (Different Machines)
If your Observability Stack is already deployed on a **different machine**, you just need to replace the URL and Basic Auth values with the correct ones in the `.env.monitoring` and `.env.logger` files (these files are explained below).
If you have not deployed it yet and intend to deploy the Observability Stack on a separate machine, you can follow the [Monitoring Setup Guide](../monitoring/setup.md) to do so.
* In this case, ensure you set `IS_SAME_HOST=false` in the `.env` file of your Watcher server.

The monitoring agents stack (Alloy, Node Exporter, cAdvisor, and Prometheus Agent) is defined in `docker-compose.override.yaml` and will be automatically applied alongside the main `docker-compose.yaml` file. To activate the monitoring agents, you must set the `COMPOSE_PROFILES` variable in your `.env` file. You can set it to `logger` (to manage Watcher logs), `monitoring` (to monitor the machine and container metrics), or both separated by a comma (e.g., `COMPOSE_PROFILES=logger,monitoring`). If left empty, no monitoring agents will start.

If you activate the `logger` profile, you must also configure your `local.yaml` to write logs to a file so Alloy can ship them to Loki. Ensure your `logs` section in `local.yaml` contains the following `file` logger configuration:

```yaml
logs:
  - type: 'file'
    path: './logs/'
    maxSize: '20m' # maximum size of each log file (20 MB)
    maxFiles: '14d' # maximum number of log files (14 days)
    level: 'info' # [debug, info, warn, error]
    serviceName: 'watcher' # set custom string for the service name
    format: 'json' # recommended format against of plain format when you want ship logs to loki
    createSymlink: true # creates a symlink tailable file to current log file named current.log
```

Create the environment files `.env.logger` and `.env.monitoring` based on `env.logger.template` and `env.monitoring.template` files in the `watcher` directory:

```shell
cp env.logger.template .env.logger
cp env.monitoring.template .env.monitoring
```

> **Note**: If you are deploying using **Mode 2** (Observability on Different Machine), ensure you replace the URL and Basic Auth values in these files appropriately.

Finally run the commands below before starting the services.

```shell
chmod -R ao+rX ./alloy ./prometheus-agent
chmod o+x ./prometheus-agent/entrypoint.sh
```

## Get Watcher Permit

After setting up and running your watcher instance, access the watcher UI by visiting http://localhost:3030. From your dashboard, you can view network information, assets, and health status alongside action buttons. To activate your watcher, proceed to the 'LOCK' action, where you can utilize assets from the watcher wallet for registration and obtain reporting permits. Top up your wallet with the specified amounts of ERG and RSN and receive these permits.

As a watcher, your primary responsibility is to monitor your network and report actions related to the bridge. To report a bridge event, you must have report permits, and acquiring these permits involves two types of payments:

1. _Collateral:_ To obtain your initial report permits, you must provide one-time collateral in the form of ERG and RSN tokens. This collateral serves as a security measure to mitigate Sybil attacks, ensuring that one entity cannot create an excessive number of watchers on the bridge. When you register your watcher by locking collateral, you have the flexibility to increase or decrease your report permit counts as needed. When you return all your report permits, the collateral is automatically refunded, and your watcher is unregistered.

2. _RSN for Permits:_ To obtain report permits, you must lock RSN tokens. In return for locking each RSN token, you receive a permit token. To initiate a report, you'll need to use a batch of permit tokens, which we refer to as a "report permit." The number of report permits you possess determines how many concurrent reports you can create. The specific number of permit tokens required for each report permit is a configuration that is specific to each blockchain. Note that, this configuration may vary across different chains and may change over time. In contrast to collateral, please be aware that these permit tokens are subject to potential seizure in the event of fraudulent activity.

In the event of a valid report submission, the report permit used for that report will be refunded, in addition to your report reward. However, if your report is found to be invalid, your permit will be seized as a form of penalty. In such a case, you won't be able to retrieve your locked RSN tokens corresponding to the seized permit. If you do not possess a report permit, you won't be able to create new reports, until your permits have been refunded. Therefore, you should purchase enough report permits to manage concurrent event reports effectively.
