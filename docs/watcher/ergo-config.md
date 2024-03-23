# Ergo Watcher Configuration

Before proceeding, be sure to have followed the initial deployment instructions found [here](./deploy-docker.md).

To participate as a watcher in the bridge, you need to deploy a watcher app, observing one of the supported networks. Each supported network has its own set of watchers, that are responsible for reporting users' actions on that specific network.

> Note: For all Watchers, even if you're targeting a different network than Ergo to watch, you still need to configure Ergo Configuration section.

1. Select the network for your Watcher, this will be an `ergo` Watcher.
```yaml
network: ergo
```

## Ergo Configuration (Essential for all Watchers)

2. For all Watchers, even if you're targeting a different network than Ergo to watch, you still need to configure the Ergo section (Under the `ergo` keyword) in your `config.yaml` file:

Select your primary data source for the Ergo network; block and box information are retrieved from this source. You can use either `explorer` or `node` as the primary source:

```yaml
type: node
```

> Note: As you choose one of these and start, your Watcher scans several blocks using that source. Changing the source might cause some issues since the Watcher tries to scan all blocks from the beginning and it takes time to be synced again. So just in case of a serious problem change this config. In some cases, you may want to delete your volume and start over (Consider updating the initial height in such cases).

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

## Ergo Watcher Configuration (JUST ERGO WATCHER)


1. To ensure the Watcher's proper functionality, event observations should be confirmed enough to take action. You should customize observation confirmation and validity threshold to align with your watching network specification. By default, these settings are configured much higher. For Ergo, we recommend using the following configurations:

```yaml
observation:
  confirmation: 10
  validThreshold: 2160
```


Finally, example Ergo Watchers `local.yaml` and `.env` files would look like:

```yaml
network: ergo

ergo:
  type: explorer
  initialHeight: <latest height>
  node:
    url: https://ergo-node.zoomout.io
  explorer:
    url: https://api.ergoplatform.com

observation:
  confirmation: 10
  validThreshold: 2160
```

```shell
# Required Environments

POSTGRES_PASSWORD= # a random alphanumeric password without special characters (like $%!-#)

POSTGRES_USER= # a random name

POSTGRES_DB= # a random name

POSTGRES_PORT=5432 # 5432 is set as default, you can change it

API_KEY_HASH= # blake2b hash of api_key, e.g. API_KEY_HASH=myHashHere

MNEMONIC= # Ergo wallet mnemonic phrases, e.g. MNEMONIC=word1 word2 word3 ... wordn

## Continue to Step 5
Be sure to save the changes you have made to `local.yaml` and navigate to [Step 5](./deploy-docker.md#5-pull-and-deploy-watcher-application) to continue with the Watcher deployment.
