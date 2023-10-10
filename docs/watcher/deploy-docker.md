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

Set your parameters in `.env` file (make sure not to use spaces after the '=' sign):

```shell
# Required Environments

POSTGRES_PASSWORD= # a random alphanumeric password without special characters (like $%!-#)

POSTGRES_USER= # a random name

POSTGRES_DB= # a random name

POSTGRES_PORT=5432 # 5432 is set as default, you can change it


# Optional Environments

WATCHER_PORT= # (default is 3030 if no value is set)

WATCHER_IMAGE_VERSION= # Don't change it!

UI_IMAGE_VERSION= # Don't change it!
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

### Ergo Config (Essential for all watchers)

For all watchers, even if you're targeting a different network than Ergo to watch, you still need to configure the Ergo section (Under the `ergo` keyword):

1. Create an empty wallet for your watcher, and set the wallet mnemonic in the config file (you can use any wallet to generate a valid mnemonic on Ergo, and please use a new fresh wallet for this purpose only):

```yaml
mnemonic: "pretty dad program ...."
```

> Note: Utilizing this mnemonic in a standard multi-address wallet will lead to watcher misbehavior.

2. Select your primary data source for the Ergo network; block and box information are retrieved from this source. You can use either `explorer` or `node` as the primary source:

```yaml
type: node
```

3. Specify the node and explorer urls (Currently you are required to use an Ergo node for transaction submissions, even when you're using the explorer as your primary source. In contrast, when you rely on a node as your primary information source, you do not need to use the explorer.)

```yaml
node:
  url: https://node.ergopool.io
explorer:
  url: https://api.ergoplatform.com
```

> Note: If you don't specify the explorer url, it will use the 'https://api.ergoplatform.com' by default, but you need to specify your node url (You may want to use a public node).

4. Set the initial height of your watcher. For the first time, you should check the current network height and set where to start watching and reporting. You may choose an older height but we highly recommend using the current network height. In case you stop your watcher and start it again later, it will continue its procedure from its last stored block, so you don't need to change the initial height in the future.

```yaml
initialHeight: 1092300
```

Finally, an example Ergo watcher `local.yaml` file would look like:

```yaml
network: ergo
ergo:
  type: explorer
  initialHeight: 1092300
  mnemonic: "pretty dad program ...."
  node:
    url: https://node.ergopool.io
  explorer:
    url: https://api.ergoplatform.com
```

### Cardano Config (Just for Cardano watchers)

If you are configuring a Cardano watcher, you should set these configs under the `cardano` keyword as well:

1. Choose your information source for cardano network and specify its connection information. You can use either `koios` or `ogmios` as the data source.

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
koios:In contrast you don't need to use explorer while using node as the primary information source
  url: https://api.koios.rest/api/v0
```

> Note: If you don't specify the koios url, it will use the 'https://api.koios.rest/api/v0' by default, but in case you're using ogmios as your source you should specify the ip and port of an ogmios instance.

> Note: If you're using a TLS enabled ogmios, set the useTls to true.

2. Set your watcher's initial height, where you start observing and reporting events. Like the Ergo network, you may choose to start from an older height but we highly recommend using the latest block as your initial point. You should specify the initial block height, hash, and slot.

```yaml
initial:
  height: 9297100
  hash: a2f07e6b1ba2830c946d4cf7a92f9d03b3de26d4109259fe14ae9291dd2e3e47
  slot: 103305423
```

> Note: Koios utilizes block height, while Ogmios relies on the hash and slot of the initial block.

> Note: Use block absolute slot

3. To ensure the watcher's proper functionality, event observations should be confirmed enough to take action. You should customize observation confirmation and validity threshold to align with your watching network specification. By default, these settings are configured according to Ergo's requirements, so you should make adjustments if you're watching a different chain. For Cardano, we recommend using the following configurations:

```yaml
observation:
  confirmation: 60
  validThreshold: 2880
```

Finally, an example Cardano watcher `local.yaml` file would look like:

```yaml
network: cardano
ergo:
  type: explorer
  initialHeight: 1092300
  mnemonic: "pretty dad program ...."
  node:
    url: https://node.ergopool.io
cardano:
  type: koios
  initial:
    height: 9297100
    hash: a2f07e6b1ba2830c946d4cf7a92f9d03b3de26d4109259fe14ae9291dd2e3e47
    slot: 103305423
observation:
  confirmation: 60
  validThreshold: 2880
```

## Get Watcher Permit

After setting up and running your watcher instance, access the watcher UI by visiting http://localhost:3030. From your dashboard, you can view network information, assets, and health status alongside action buttons. To activate your watcher, proceed to the 'LOCK' action, where you can utilize assets from the watcher wallet for registration and obtain reporting permits. Top up your wallet with the specified amounts of ERG and RSN and receive these permits.

As a watcher, your primary responsibility is to monitor your network and report actions related to the bridge. To report a bridge event, you must have report permits, and acquiring these permits involves two types of payments:

1. _Collateral:_ To obtain your initial report permits, you must provide one-time collateral in the form of ERG and RSN tokens. This collateral serves as a security measure to mitigate Sybil attacks, ensuring that one entity cannot create an excessive number of watchers on the bridge. When you register your watcher by locking collateral, you have the flexibility to increase or decrease your report permit counts as needed. When you return all your report permits, the collateral is automatically refunded, and your watcher is unregistered.

2. _RSN for Permits:_ To obtain report permits, you must lock RSN tokens. In return for locking each RSN token, you receive a permit token. To initiate a report, you'll need to use a batch of permit tokens, which we refer to as a "report permit." The number of report permits you possess determines how many concurrent reports you can create. The specific number of permit tokens required for each report permit is a configuration that is specific to each blockchain. Note that, this configuration may vary across different chains and may change over time. In contrast to collateral, please be aware that these permit tokens are subject to potential seizure in the event of fraudulent activity.

In the event of a valid report submission, the report permit used for that report will be refunded, in addition to your report reward. However, if your report is found to be invalid, your permit will be seized as a form of penalty. In such a case, you won't be able to retrieve your locked RSN tokens corresponding to the seized permit. If you do not possess a report permit, you won't be able to create new reports, until your permits have been refunded. Therefore, you should purchase enough report permits to manage concurrent event reports effectively.
