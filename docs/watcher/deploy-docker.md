# Watcher Deployment

To participate as a watcher in the bridge, you need to deploy a watcher app, observing one of the supported networks. Each supported network has its own set of watchers, that are responsible for reporting users' actions on that specific network.

We are utilizing Docker for ease of deployment and upgrading. Install Docker for your Operating System [here](https://www.docker.com/products/docker-desktop/). Once installed, proceed with the following instructions.

In order to run a Watcher, a number of steps need to be taken:
1. Create local directory and files
2. Create Watcher wallet and API Key hash
3. Edit Watcher enviroment variable file
4. Edit Watcher configuration file
5. Pull and deploy Watcher application


## 1. Create local directory and files

1.1 Clone [Operation repository](https://github.com/rosen-bridge/operation.git) and navigate to `operation/watcher` directory:

```shell
git clone https://github.com/rosen-bridge/operation.git
cd operation/watcher/
```

1.2 Create `local.yaml` file in the `config` directory and set required permission for the `logs` directory

```shell
sudo chown -R 3000:3000 logs
touch config/local.yaml
```

Only on `MacOS`: set `707` permission for the `logs` directory

```shell
# only on MacOS
sudo chmod -R 707 logs
```


1.3 Create your environment file `.env` based on `env.template` file in the `watcher` directory:

```shell
cp env.template .env
```

To view hidden .env later, use `ls -a`.



## 2. Create Watcher wallet and API Key hash

2.1 Create Ergo Wallet (Essential for all Watchers)
Create a new, empty wallet for your Watcher, you can use any Ergo wallet to generate a valid mnemonic phrase. Please use a new, fresh wallet for this purpose only.

Later we will set the wallet mnemonic phrase in the `MNEMONIC=` enviroment variable (`.env`) file.


2.2 Create API Key Hash

To secure the Watcher action-based APIs (ex: lock, unlock, ...), you should set a unique and robust api key. We are using a blake2b hash to secure APIs.


#### Compute api_key's Hash

Use [rosen command line](https://github.com/rosen-bridge/utils/tree/dev/packages/cli) to compute api key hash:

```shell
  # use nodejs solution
  npx @rosen-bridge/cli blake2b-hash YOUR_API_KEY
  # or docker solution
  docker run -it --rm node:18.16 npx --yes @rosen-bridge/cli blake2b-hash YOUR_API_KEY```
```

Alternatively, you could utilize Swagger on a locally run node. Do not generate hash from a public node.




After obtaining the hash, input it into `API_KEY_HASH=` in your `.env` file. Example output Blake2b hash of `hello` is `324dcf027dd4a30a932c441f365a25e86b173defa4b8e58948253471b81b72cf`.

> **⚠️ NOTE**: We recommend utilizing environment variables over direct configuration file settings for **security** purpose to not accidently share your api key while troubleshooting etc. After updating, you can delete `apiKeyHash` from /config/local.yaml.


## 3. Edit Watcher enviroment variable file

You can configure some Environment Variables when deploying with docker, you can find all of them [here](./env-references.md).

Set your parameters in `.env` file (make sure not to use spaces after the '=' sign):

```shell
# Required Environments

POSTGRES_PASSWORD= # a random alphanumeric password without special characters (like $%!-#)

POSTGRES_USER= # a random name

POSTGRES_DB= # a random name

POSTGRES_PORT=5432 # 5432 is set as default, you can change it

API_KEY_HASH= # blake2b hash of api_key, e.g. API_KEY_HASH=myHashHere

MNEMONIC= # Ergo wallet mnemonic phrases, e.g. MNEMONIC=word1 word2 word3 ... wordn
```

### Ergo Wallet (Essential for all Watchers)

Create a new, empty wallet for your Watcher, and set the wallet mnemonic in the `MNEMONIC=` enviroment variable (`.env`) file. (you can use any wallet to generate a valid mnemonic on Ergo, and please use a new fresh wallet for this purpose only):

```shell
MNEMONIC=<your wallet mnemonic> # E.g. MNEMONIC=word1 word2 word3 ... wordn
```

> Note: Utilizing this mnemonic in a standard, previously used, multi-address wallet will lead to watcher misbehavior. Use it wolely as the Watcher wallet.

> **⚠️ NOTE**: We recommend utilizing environment variables over direct configuration file settings for **security** purpose to not accidently share your seed phrase while troubleshooting etc.


### API Key Hash

To secure the Watcher action-based APIs (ex: lock, unlock, ...), you should set a unique and robust api key. We are using a blake2b hash to secure APIs.


#### Compute api_key's Hash

Use [rosen command line](https://github.com/rosen-bridge/utils/tree/dev/packages/cli) to compute api key hash:

```shell
  # use nodejs solution
  npx @rosen-bridge/cli blake2b-hash YOUR_API_KEY
  # or docker solution
  docker run -it --rm node:18.16 npx --yes @rosen-bridge/cli blake2b-hash YOUR_API_KEY```
```

Alternatively, you could utilize Swagger on a locally run node. Do not generate hash from a public node.




After obtaining the hash, input it into `API_KEY_HASH=` in your `.env` file. Example output Blake2b hash of `hello` is `324dcf027dd4a30a932c441f365a25e86b173defa4b8e58948253471b81b72cf`.

> **⚠️ NOTE**: We recommend utilizing environment variables over direct configuration file settings for **security** purpose to not accidently share your api key while troubleshooting etc. After updating, you can delete `apiKeyHash` from /config/local.yaml.


## Local Configuration File

The Watcher will use a file called `local.yaml` for network specific configurations. 







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


## Get Watcher Permit

After setting up and running your watcher instance, access the watcher UI by visiting http://localhost:3030. From your dashboard, you can view network information, assets, and health status alongside action buttons. To activate your watcher, proceed to the 'LOCK' action, where you can utilize assets from the watcher wallet for registration and obtain reporting permits. Top up your wallet with the specified amounts of ERG and RSN and receive these permits.

As a watcher, your primary responsibility is to monitor your network and report actions related to the bridge. To report a bridge event, you must have report permits, and acquiring these permits involves two types of payments:

1. _Collateral:_ To obtain your initial report permits, you must provide one-time collateral in the form of ERG and RSN tokens. This collateral serves as a security measure to mitigate Sybil attacks, ensuring that one entity cannot create an excessive number of watchers on the bridge. When you register your watcher by locking collateral, you have the flexibility to increase or decrease your report permit counts as needed. When you return all your report permits, the collateral is automatically refunded, and your watcher is unregistered.

2. _RSN for Permits:_ To obtain report permits, you must lock RSN tokens. In return for locking each RSN token, you receive a permit token. To initiate a report, you'll need to use a batch of permit tokens, which we refer to as a "report permit." The number of report permits you possess determines how many concurrent reports you can create. The specific number of permit tokens required for each report permit is a configuration that is specific to each blockchain. Note that, this configuration may vary across different chains and may change over time. In contrast to collateral, please be aware that these permit tokens are subject to potential seizure in the event of fraudulent activity.

In the event of a valid report submission, the report permit used for that report will be refunded, in addition to your report reward. However, if your report is found to be invalid, your permit will be seized as a form of penalty. In such a case, you won't be able to retrieve your locked RSN tokens corresponding to the seized permit. If you do not possess a report permit, you won't be able to create new reports, until your permits have been refunded. Therefore, you should purchase enough report permits to manage concurrent event reports effectively.
