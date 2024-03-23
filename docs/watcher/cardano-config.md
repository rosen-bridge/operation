# Cardano Watcher Configuration

Before proceeding, be sure to have followed the initial deployment instructions found [here](./deploy-docker.md).

> Note: For all Watchers, even if you're targeting a different network than Ergo to watch, you still need to configure Ergo Configuration section.

To participate as a watcher in the bridge, you need to deploy a watcher app, observing one of the supported networks. Each supported network has its own set of watchers, that are responsible for reporting users' actions on that specific network.

1. Select the network for your Watcher, this will be a `cardano` Watcher.
```yaml
network: cardano
```


## Ergo Configuration (Essential for all Watchers)

2. For all Watchers, even if you're targeting a different network than Ergo to watch, you still need to configure the Ergo section (Under the `ergo` keyword) in your `config.yaml` file:

Select your primary data source for the Ergo network; block and box information are retrieved from this source. You can use either `explorer` or `node` as the primary source:

```yaml
type: node
```

Note: As you choose one of these and start, your Watcher scans several blocks using that source. Changing the source might cause some issues since the Watcher tries to scan all blocks from the beginning and it takes time to be synced again. So just in case of a serious problem change this config. In some cases, you may want to delete your volume and start over (Consider updating the initial height in such cases).

3. Specify the node and explorer urls. Currently you are required to use an Ergo node for transaction submissions, even when you're using the explorer as your primary source. In contrast, when you rely on a node as your primary information source, you do not need to use the explorer. 

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

4. Set the initial height of your Watcher. For the first time, you should check the current network height and set where to start watching and reporting. You may choose an older height but we highly recommend using the current network height. In case you stop your watcher and start it again later, it will continue its procedure from its last stored block, so you don't need to change the initial height in the future.

```yaml
initialHeight: <latest height>
```

> Note: Fill with a recent block height (e.g. 10 blocks before). You can find Ergo latest blocks [here](https://explorer.ergoplatform.com/en/latest-blocks).

> Note: Once your Watcher has started scanning from the initial block, changing this config wont affect the Watcher behavior. In case you need to restart the watcher from an earlier block consider removing volumes.



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

## Continue to Step 5
Be sure to save the changes you have made to `local.yaml` and navigate to [Step 5](./deploy-docker.md#5-pull-and-deploy-watcher-application) to continue with the Watcher deployment.
