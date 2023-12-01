## Guard Operation: Setup

The following document will help you through setup your guard for production on Docker after a successful `key generation ceremony`.

# Edit Config File

You need to specify some required configs in `local.yaml`.

## API

Default value of `isManualTxRequestActive` is `false`. This field prevents
service from getting manual transactions. Whenever you want to request to
sign a manual transaction, set this value to `true`, restart your guard, submit your transaction using guard app, reset this value to `false` and restart your guard.

> **NOTE**: It is crucial to keep this config as `false` to prevent
insertion of unwanted transactions in case of unauthorized access of malicious actor.

```yaml
api:
  isManualTxRequestActive: false
```

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
  explorer:
    url: 'YOUR_NODE_URL'
```

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
    host: 'YOUR_GRAFANA_URL'
    level: 'info' # [debug, info, warn, error]
  ```

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

## Overall

Combine all of your configs in `local.yaml`. The structure will be:

```yaml
api:
  isManualTxRequestActive: false
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
