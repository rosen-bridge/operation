## Guard Operation: Setup

The following document will help you through setup your guard for production on Docker.

## Environment Variable Configs
You can configure some Environment Variables when deploying with docker, you can find all of them [here](./env-references.md).

Note: Set your parameters in `.env` file (make sure not to use spaces after the '=' sign)

# Docker Deployment

Clone [Operation repository](https://github.com/rosen-bridge/operation.git) and go to `operation/guard` directory

```shell
git clone https://github.com/rosen-bridge/operation.git
cd operation/guard/
```

Create your environment file `.env` based on `env.template` file in the `guard` directory

```shell
cp env.template .env
```

Set your parameters in `.env` file 
>**Note:** do not use space after `=` sign

```shell
# Required Environments

POSTGRES_PASSWORD= # a random alphanumeric password without special characters (like $%!-#)

POSTGRES_USER= # a random name

POSTGRES_DB= # a random name

POSTGRES_PORT=5432 # 5432 is set as default, you can change it.


# Optional Environments

GUARD_PORT= # (default is 8081 if no value is set)

GUARD_IMAGE_VERSION= # Don't change it!

UI_IMAGE_VERSION= # Don't change it!
```

Set required permissions and create `thresholds.json` and `local.yaml` files in the `config` directory

```shell
touch config/thresholds.json
touch config/local.yaml
sudo chown -R 8080:8080 logs config
```

Only on `MacOS`: set `707` permission for the `logs` directory

```shell
# only on MacOS
sudo chmod -R 707 logs
```

Pull the Docker image

  ```shell
  docker compose pull # use `docker-compose pull` for older versions of Docker
  ```

In order to instruct the service to create require docker volumes, in the `guard` directory

```shell
docker compose create # use `docker-compose create` for older versions of Docker
```

Before commencing your guard service duties, you must take part in the key generation ceremony. For detailed instructions, please refer to [this guide](../keygen-service/keygen-docker.md).


# Edit Config File

You need to specify some required configs in `local.yaml`.

## API

```yaml
api:
  isManualTxRequestActive: false
  apiKeyHash: 'YOUR_API_KEY_HASH'
```
### isManualTxRequestActive

Default value of `isManualTxRequestActive` is `false`. This field prevents
service from getting manual transactions. Whenever you want to request to
sign a manual transaction, set this value to `true`, restart your guard, submit your transaction using guard app, reset this value to `false` and restart your guard.

> **NOTE**: It is crucial to keep this config as `false` to prevent
insertion of unwanted transactions in case of unauthorized access of malicious actor.

### apiKeyHash
To secure the action-based APIs, you should set a unique and robust api key.
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

## DATABASE
Specify your database connection and credentials.

```yaml
  type: 'postgres'
  host: ''         # database host (for postgres)
  port: 5432       # database port (for postgres)
  user: ''         # database user (for postgres)
  password: ''     # database password (for postgres)
  name: ''         # database name (for postgres)
```
> **NOTE**: When using docker there are some environment variables (POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB) for database configuration that you can set instead of in the local configuration.


## Cardano

### Network

Specify your network. If you are using Koios, set `chainNetwork` field as
`koios` and set your koios url.

```yaml
cardano:
  chainNetwork: 'koios'
  koios:
    url: 'https://api.koios.rest/api/v1'
```

If you have auth token for koios, you can specify that too.

```yaml
cardano:
  chainNetwork: 'koios'
  koios:
    url: 'https://api.koios.rest/api/v1'
    authToken: 'YOUR_AUTH_TOKEN'
```

> **NOTE**: When using docker there is an `KOIOS_AUTH_TOKEN` environment variable available for `authToken` that you can set instead of in the local configuration.

If you plan to use Blockfrost for your network, set `chainNetwork` field
as `blockfrost` and set your project Id.

```yaml
cardano:
  chainNetwork: 'blockfrost'
  blockfrost:
    projectId: 'YOUR_PROJECT_ID'
```

You can also use custom blockfrost instance. In this case, also set url:

```yaml
cardano:
  chainNetwork: 'blockfrost'
  blockfrost:
    projectId: 'YOUR_PROJECT_ID'
    url: 'YOUR_BLOCKFROST_URL'
```

> **NOTE**: When using docker there is an `BLOCKFROST_PROJECT_ID` environment variable available for `projectId` that you can set instead of in the local configuration.

### Address Info

Other than network, you need to specify generated public key in `key generation ceremony` and cold storage address on cardano.

```yaml
cardano:
  bankPublicKey: 'GENERATED_PUBLIC_KEY'
  coldStorageAddress: 'COLD_ADDRESS'
```

> **NOTE**: Leave `coldStorageAddress` empty for now. This field will be set
in further notice.

### Overall

Your Cardano config will be something like this:

```yaml
cardano:
  chainNetwork: 'koios'
  koios:
    url: 'https://api.koios.rest/api/v1'
  bankPublicKey: 'GENERATED_PUBLIC_KEY'
  coldStorageAddress: ''
```

## Ergo

### Network

Similar to Cardano, you need to specify your network on Ergo. In case of using Explorer, set `chainNetwork` field as `explorer` and specify url:

```yaml
ergo:
  chainNetwork: 'explorer'
  explorer:
    url: 'https://api.ergoplatform.com/'
```

In case of using node, set `chainNetwork` field as `node` and specify url:

```yaml
ergo:
  chainNetwork: 'node'
  node:
    url: 'YOUR_NODE_URL'
```

> Note: Make sure the Ergo node has extra indexing turned on. Read more about extra indexing [here](https://docs.ergoplatform.com/node/conf/conf-node/#extra-index).

### Initial Height

Specify **current height** of Ergo blockchain as initial height. The scanner will start on this height to capture any reported events.

```yaml
ergo:
  initialHeight: 1000000
```

### Address Info

You should also specify Ergo cold storage address.

> **NOTE**: Leave `coldStorageAddress` empty for now. This field will be set
in further notice.

```yaml
ergo:
  coldStorageAddress: ''
```

### Overall

Your Ergo config will be something like this:

```yaml
ergo:
  chainNetwork: 'explorer'
  explorer:
    url: 'https://api.ergoplatform.com/'
  initialHeight: 1000000
  coldStorageAddress: ''
```

## Reward

Specify reward distribution configs. Ensure values with moderator. Config will be like this:

```yaml
reward:
  bridgeFeeRepoAddress: 'MULTISIG_FUND_ADDRESS'
  RSNEmissionAddress: 'MULTISIG_REWARD_ADDRESS'
  networkFeeRepoAddress: 'NETWORK_FEE_ADDRESS'
  watchersSharePercent: 0
  watchersRSNSharePercent: 70
```

## TSS

You should specify your TSS secret along side public key and share ids
of all other guards. The public keys and share ids list should be the same 
between all guards, so get these values from moderator. The structure will be:

```yaml
tss:
  secret: 'TSS_SECRET'
  publicKeys:
    - 'PK_1'
    - 'PK_2'
    - 'PK_3'
    ...
  ks:
    - 'SHARE_1'
    - 'SHARE_2'
    - 'SHARE_3'
    ...
```

> **NOTE**: When using docker there is an `TSS_SECRET` environment variable available for `secret` that you can set instead of in the local configuration.

## P2P

Keep the config provided by keygen moderator for `key generation ceremony`.

## Keygen

Keygen mode should be deactivated. Delete whole `keygen` section from your config file.

## Mnemonic

Specify your Ergo address mnemonic under `guard` path:

```yaml
guard:
  mnemonic: 'YOUR_MNEMONIC'
```

> **⚠️ NOTE**: Instead of setting `mnemonic` in the local configuration file, consider using the `MNEMONIC` environment variable for ease of management. We recommend utilizing environment variables over direct configuration file settings for **security** purpose to not accidently share your seed phrase while troubleshooting etc. See your `.env` file. Once updated, in /config/local.yaml delete your mnemonic phrase and put in a comment like so "mnemonic: #see local config env file"

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

You also can set multiple logs config. Therefore your config will be something like this:

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

## Cold Storage Active hour

Specify the period which your guard will generate cold storage transaction.
Note that this config is personal and is independent from other guards. The
hour will be in UTC timezone.

```yaml
coldStorage:
  startHour: 17 # start of cold storage transaction generation period
  endHour: 19 # end of cold storage transaction generation period
```

## Discord Notification

Setup a webhook on discord. Some notification (such as cases where hot
address does not have enough assets to pay an event) will be sent to discord
using this hook. Set it in config like this:

```yaml
discordWebHookUrl: 'YOUR_WEBHOOK_URL' # Discord webhook url for sending notifications
```

> **NOTE**: When using docker there is an `DISCORD_WEBHOOK_URL` environment variable available for `discordWebHookUrl` that you can set instead of in the local configuration.


## Overall

Combine all of your configs in `local.yaml`. The structure will be:

```yaml
api:
  isManualTxRequestActive: false
  apiKeyHash: ''
cardano:
  ...
ergo:
  ...
reward:
  ...
tss:
  ...
p2p:
  ...
guard:
  mnemonic: 'YOUR_MNEMONIC'
logs:
  ...
coldStorage:
  ...
discordWebHookUrl: 'YOUR_WEBHOOK_URL'
```

# Run Guard Service

In the `guard` directory, run the container
  
```shell
docker compose up # use `docker-compose up` for older versions of Docker
```
