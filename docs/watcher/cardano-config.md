# Cardano Watcher Configuration

For all Watchers, even if you're targeting a different network than Ergo to watch, you still need to configure the Ergo Wallet and Ergo Configuration sections

Before proceeding, be sure to have followed the initial deployment instructions found [here](./deploy-docker.md).

## Ergo Wallet (Essential for all Watchers)

1. Create a new, empty wallet for your Watcher, and set the wallet mnemonic in the `MNEMONIC=` enviroment variable (`.env`) file. (you can use any wallet to generate a valid mnemonic on Ergo, and please use a new fresh wallet for this purpose only):

```shell
MNEMONIC=<your wallet mnemonic> # E.g. MNEMONIC=word1 word2 word3 ... wordn
```

> Note: Utilizing this mnemonic in a standard, previously used, multi-address wallet will lead to watcher misbehavior.

> **⚠️ NOTE**: We recommend utilizing environment variables over direct configuration file settings for **security** purpose to not accidently share your seed phrase while troubleshooting etc. See your `.env` file. Once updated, in /config/local.yaml delete your mnemonic phrase and put in a comment like so "mnemonic: #see local config env file"

## Ergo Configuration (Essential for all Watchers)

For all Watchers, even if you're targeting a different network than Ergo to watch, you still need to configure the Ergo section (Under the `ergo` keyword) in your `config.yaml` file:

1. Select your primary data source for the Ergo network; block and box information are retrieved from this source. You can use either `explorer` or `node` as the primary source:

```yaml
type: node
```

Note: As you choose one of these and start, your Watcher scans several blocks using that source. Changing the source might cause some issues since the Watcher tries to scan all blocks from the beginning and it takes time to be synced again. So just in case of a serious problem change this config. In some cases, you may want to delete your volume and start over (Consider updating the initial height in such cases).

2. Specify the node and explorer urls. Currently you are required to use an Ergo node for transaction submissions, even when you're using the explorer as your primary source. In contrast, when you rely on a node as your primary information source, you do not need to use the explorer. 

```yaml
node:
  url: https://ergo-node.zoomout.io
explorer:
  url: https://api.ergoplatform.com
```

> Note: If you don't specify the explorer url, it will use the 'https://api.ergoplatform.com' by default, but you need to specify your node url (You may want to use a public node).

> Note: Make sure the Ergo node has extra indexing turned on. Otherwise, health check parameters won't update correctly (the Watcher works correctly, but WID and asset health check parameters may have problems). Read more about extra indexing [here](https://docs.ergoplatform.com/node/conf/conf-node/#extra-index).

> Note: A list of public nodes with extra indexing enabled can be found [here](https://api.tokenjay.app/peers/list?unreachable=false&closedApi=false&limit=100)

> Note: Do not use nodes with version 5.0.15 and 5.0.16 due to a bug in extra indexing.

3. Set the initial height of your Watcher. For the first time, you should check the current network height and set where to start watching and reporting. You may choose an older height but we highly recommend using the current network height. In case you stop your watcher and start it again later, it will continue its procedure from its last stored block, so you don't need to change the initial height in the future.

```yaml
initialHeight: <latest height>
```

> Note: Fill with a recent block height (e.g. 10 blocks before). You can find Ergo latest blocks [here](https://explorer.ergoplatform.com/en/latest-blocks).

> Note: Once your Watcher has started scanning from the initial block, changing this config wont affect the Watcher behavior. In case you need to restart the watcher from an earlier block consider removing volumes.

To participate as a Watcher in Rosen Bridge, you need to deploy a Watcher app to observe over one of the supported networks. Each supported network has its own set of watchers that are responsible for reporting users' actions on that specific network.

Before proceeding, be sure to have followed the initial deployment instructions found [here](./deploy-docker.md)

## Cardano Configuration (Just for Cardano watchers)

To configure a Cardano watcher, you should set these configs under the `cardano` keyword in your `config.yaml`:

1. Choose your information source for the Cardano network and specify its connection information. You can use either `koios`, `blockfrost` or `ogmios` as the data source.

```yaml
type: koios
koios:
  url: https://api.koios.rest/api/beta
  authToken: <your auth token> # Recommended to use KOIOS_AUTH_TOKEN environment variable, remove line if so.
```

or

```yaml
type: blockfrost
blockfrost:
  url: https://cardano-mainnet.blockfrost.io/api/v0
  projectID: <your projectID token> # Recommended to use BLOCKFROST_PROJECT_ID environment variable, remove line if so.
```

or

```yaml
type: ogmios
ogmios:
  host: 127.0.0.1
  port: 1337
  useTls: false
```

> **NOTE**: When using Docker, there is an environment variable available for `Koios` and `Blockfrost` tokens that you can set instead of in the local configuration. This is the preferred method.

> Note: If you don't specify the koios url, it will use the https://api.koios.rest/api/beta by default, but in case you're using ogmios as your source you should specify the host address and port of an ogmios instance.

> Note: If you're using a TLS enabled ogmios, set the useTls to true.

> Note: Watcher utilize Koios v1 APIs, and you can use your authentication token on the Koios platform by configuring the authToken. Alternatively, the watcher uses the public tier of the Koios platform, which comes with limitations on requests. You can get your koios access token [here](https://koios.rest/pricing/Pricing.html).

> Note: Currently, the watcher is only compatible with Ogmios v6. Utilizing other versions of Ogmios may result in improper functionality.

> Note: As you choose one of these and start, your watcher scans several blocks using that source. Changing the source might cause some issues since the watcher tries to scan all blocks from the beginning and it takes time to be synced again. So just in case of a serious problem change this config. In some cases, you may want to delete your volume and start over (Consider updating the initial height in such cases).


2. Set your watcher's initial height, where you start observing and reporting events. Like the Ergo network, you may choose to start from an older height but we highly recommend using the latest block as your initial point. You should specify the initial block height, hash, and slot.

```yaml
initial:
  height: <latest height>
  hash: <latest hash>
  slot: <latest slot>
```

> Note: Koios and Blockfrost utilize block height, while Ogmios relies on the hash and slot of the initial block.

> Note: Use block absolute slot

> Note: Fill with a recent block height (e.g. 10 blocks before). You can find Cardano latest blocks [here](https://cardanoscan.io/blocks).

> Note: Once the Watcher has started scanning from the initial block, changing this config wont affect the Watcher behavior. In case you need to restart the Watcher from an earlier block, consider removing volumes and updating both Ergo and Cardano initial heights.

Finally, an example Cardano watcher `local.yaml` file would look like:

```yaml
network: cardano
ergo:
  type: explorer
  initialHeight: <latest height>
  node:
    url: https://ergo-node.zoomout.io
  explorer:
    url: https://api.ergoplatform.com
cardano:
  type: koios
  koios:
    authToken: "eyJhbGciOiJIUzI1NiIsInR5..." # Remove line if Token is entered as an enviroment variable.
  initial:
    height: <latest height>
    hash: <latest hash>
    slot: <latest slot>
```

## Get Watcher Permit

After setting up and running your Watcher instance, access the watcher UI by visiting http://localhost:3030. From your dashboard, you can view network information, assets, and health status alongside action buttons. To activate your watcher, proceed to the 'LOCK' action, where you can utilize assets from the watcher wallet for registration and obtain reporting permits. Top up your wallet with the specified amounts of ERG and RSN and receive these permits.

As a watcher, your primary responsibility is to monitor your network and report actions related to the bridge. To report a bridge event, you must have report permits, and acquiring these permits involves two types of payments:

1. _Collateral:_ To obtain your initial report permits, you must provide one-time collateral in the form of ERG and RSN tokens. This collateral serves as a security measure to mitigate Sybil attacks, ensuring that one entity cannot create an excessive number of watchers on the bridge. When you register your watcher by locking collateral, you have the flexibility to increase or decrease your report permit counts as needed. When you return all your report permits, the collateral is automatically refunded, and your watcher is unregistered.

2. _RSN for Permits:_ To obtain report permits, you must lock RSN tokens. In return for locking each RSN token, you receive a permit token. To initiate a report, you'll need to use a batch of permit tokens, which we refer to as a "report permit." The number of report permits you possess determines how many concurrent reports you can create. The specific number of permit tokens required for each report permit is a configuration that is specific to each blockchain. Note that, this configuration may vary across different chains and may change over time. In contrast to collateral, please be aware that these permit tokens are subject to potential seizure in the event of fraudulent activity.

In the event of a valid report submission, the report permit used for that report will be refunded, in addition to your report reward. However, if your report is found to be invalid, your permit will be seized as a form of penalty. In such a case, you won't be able to retrieve your locked RSN tokens corresponding to the seized permit. If you do not possess a report permit, you won't be able to create new reports, until your permits have been refunded. Therefore, you should purchase enough report permits to manage concurrent event reports effectively.
