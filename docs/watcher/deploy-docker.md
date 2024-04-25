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

### Note for Raspberry Pi ARM users

To run the watcher on a ARM based raspberry pi, you'll need to use an arm-based db. You can use the special db image according to you architecture:
- [arm64v8](https://hub.docker.com/r/arm64v8/postgres/)
- [arm32v7](https://hub.docker.com/r/arm32v7/postgres/)

Change the db image in docker compose according to your OS architecture for example if you are using `arm64v8`, change this line in your docker-compose file:
```diff
services:
  db:
-   image: rapidfort/postgresql:16.0.0
+   image: arm64v8/postgres:16.0
```
and change volume of db to this:
```diff
    volumes:
-     - postgres-data:/bitnami/postgresql
+     - postgres-data:/var/lib/postgresql/data/
```

Final changes for a `arm64v8` image is something like this:
```
  db:
    image: arm64v8/postgres:16.0
    env_file:
      - .env
    volumes:
      - postgres-data:/var/lib/postgresql/data/
    networks:
      - rosen_network
    restart: always
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB']
      interval: 10s
      timeout: 5s
      retries: 3
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

To start your watcher, you should configure the local.yaml file. First, specify the target network you're watching. Currently, we support `ergo` and `cardano`:

```yaml
network: ergo
```

## API

```yaml
api:
  apiKeyHash: 'YOUR_API_KEY_HASH'
```

### apiKeyHash
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
initialHeight: <latest height>
```

> Note: Fill with a recent block height (e.g. 10 blocks before). You can find Ergo latest blocks [here](https://explorer.ergoplatform.com/en/latest-blocks).

> Note: Once watcher started scanning from the initial block, changing this config wont affect the watcher behavior. In case you need to restart the watcher from an earlier block consider removing volumes.

5. (JUST ERGO WATCHER) You need to update the commitment validity threshold to match with Ergo network:

```yaml
transaction:
  commitmentTimeoutConfirmation: 720
```

6. (JUST ERGO WATCHER) To ensure the watcher's proper functionality, event observations should be confirmed enough to take action. You should customize observation confirmation and validity threshold to align with your watching network specification. By default, these settings are configured much higher. For Ergo, we recommend using the following configurations:

```yaml
observation:
  confirmation: 10
  validThreshold: 720
```

Finally, an example Ergo watcher `local.yaml` file would look like:

```yaml
network: ergo
api:
  apiKeyHash: 'YOUR_API_KEY_HASH'
ergo:
  type: explorer
  initialHeight: <latest height>
  mnemonic: "pretty dad program ...."
  node:
    url: https://example.node.com
  explorer:
    url: https://api.ergoplatform.com
  transaction:
    commitmentTimeoutConfirmation: 720

observation:
  confirmation: 10
  validThreshold: 720
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
  url: https://api.koios.rest/api/beta
  authToken: <your auth token>
```
> **NOTE**: When using docker there is an `KOIOS_AUTH_TOKEN` environment variable available for `authToken` that you can set instead of in the local configuration.

> Note: If you don't specify the koios url, it will use the https://api.koios.rest/api/beta by default, but in case you're using ogmios as your source you should specify the host address and port of an ogmios instance.

> Note: If you're using a TLS enabled ogmios, set the useTls to true.

> Note: Watcher utilize Koios v1 APIs, and you can use your authentication token on the Koios platform by configuring the authToken. Alternatively, the watcher uses the public tier of the Koios platform, which comes with limitations on requests. You can get your koios access token [here](https://koios.rest/pricing/Pricing.html).

> Note: Currently, the watcher is only compatible with Ogmios v6. Utilizing other versions of Ogmios may result in improper functionality.

> Note: As you choose one of these and start, your watcher scans several blocks using that source. Changing the source might cause some issues since the watcher tries to scan all blocks from the beginning and it takes time to be synced again. So just in case of a serious problem change this config. In some cases, you may want to delete your volume and start over (Consider updating the initial height in such cases).


1. Set your watcher's initial height, where you start observing and reporting events. Like the Ergo network, you may choose to start from an older height but we highly recommend using the latest block as your initial point. You should specify the initial block height, hash, and slot.

```yaml
initial:
  height: <latest height>
  hash: <latest hash>
  slot: <latest slot>
```

> Note: Koios utilizes block height, while Ogmios relies on the hash and slot of the initial block.

> Note: Use block absolute slot

> Note: Fill with a recent block height (e.g. 10 blocks before). You can find Cardano latest blocks [here](https://cardanoscan.io/blocks).

> Note: Once watcher started scanning from the initial block, changing this config wont affect the watcher behavior. In case you need to restart the watcher from an earlier block consider removing volumes and updating both Ergo and Cardano initial heights.

Finally, an example Cardano watcher `local.yaml` file would look like:

```yaml
network: cardano
api:
  apiKeyHash: 'YOUR_API_KEY_HASH'
ergo:
  type: explorer
  initialHeight: <latest height>
  mnemonic: "pretty dad program ...."
  node:
    url: https://example.node.com
cardano:
  type: koios
  koios:
    authToken: "eyJhbGciOiJIUzI1NiIsInR5..."
  initial:
    height: <latest height>
    hash: <latest hash>
    slot: <latest slot>
```

## Get Watcher Permit

After setting up and running your watcher instance, access the watcher UI by visiting http://localhost:3030. From your dashboard, you can view network information, assets, and health status alongside action buttons. To activate your watcher, proceed to the 'LOCK' action, where you can utilize assets from the watcher wallet for registration and obtain reporting permits. Top up your wallet with the specified amounts of ERG and RSN and receive these permits.

As a watcher, your primary responsibility is to monitor your network and report actions related to the bridge. To report a bridge event, you must have report permits, and acquiring these permits involves two types of payments:

1. _Collateral:_ To obtain your initial report permits, you must provide one-time collateral in the form of ERG and RSN tokens. This collateral serves as a security measure to mitigate Sybil attacks, ensuring that one entity cannot create an excessive number of watchers on the bridge. When you register your watcher by locking collateral, you have the flexibility to increase or decrease your report permit counts as needed. When you return all your report permits, the collateral is automatically refunded, and your watcher is unregistered.

2. _RSN for Permits:_ To obtain report permits, you must lock RSN tokens. In return for locking each RSN token, you receive a permit token. To initiate a report, you'll need to use a batch of permit tokens, which we refer to as a "report permit." The number of report permits you possess determines how many concurrent reports you can create. The specific number of permit tokens required for each report permit is a configuration that is specific to each blockchain. Note that, this configuration may vary across different chains and may change over time. In contrast to collateral, please be aware that these permit tokens are subject to potential seizure in the event of fraudulent activity.

In the event of a valid report submission, the report permit used for that report will be refunded, in addition to your report reward. However, if your report is found to be invalid, your permit will be seized as a form of penalty. In such a case, you won't be able to retrieve your locked RSN tokens corresponding to the seized permit. If you do not possess a report permit, you won't be able to create new reports, until your permits have been refunded. Therefore, you should purchase enough report permits to manage concurrent event reports effectively.
