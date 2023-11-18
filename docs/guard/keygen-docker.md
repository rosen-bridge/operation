## Guard Operation: Key Generation

Being a guard, you need a set of secret keys that will be used in multisig operations. One of these keys will be used by the `TSS library` for `EcDSA` and `EdDSA` multisig wallets. 

The following document will help you through generating this key by activating the `keygen mode` in the guard application in a `key generation ceremony`.

> **Note:** The guard application does not have a UI interface for key generation process.

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
sudo chown -R 8080:8080 logs
touch config/thresholds.json
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

In order to instruct the service to generate a new key, copy and paste the following lines in `local.yaml` file, fill in the required parameters, and save the file.
  > Ask the keygen ceremony moderator to provide the required info for the `FILL_ACCORDING_TO_YOUR_GUARD_SET` parameters

```shell
# Paste these lines in local.yaml file, fill in the parameters.

keygen: 
  active: true # set true to start keygen process on startup
  guards: FILL_ACCORDING_TO_YOUR_GUARD_SET(number) # total number of guards
  threshold: FILL_ACCORDING_TO_YOUR_GUARD_SET(number) # signing threshold (at least threshold + 1 guards are required)
p2p:
  addresses:
    - peerId: FILL_ACCORDING_TO_YOUR_GUARD_SET
      address: FILL_ACCORDING_TO_YOUR_GUARD_SET
```

In the `guard` directory, run the containers
  
```shell
docker compose up # use `docker-compose up` for older versions of Docker
```

> **Note:**
> Each guard has a unique peerId that you should provide to the moderator of the keygen ceremony. Your peerId will be whitelisted in the network's relay. Upon starting your guard, you can find the value of this parameter in your guard's logs. For example, you should see a line like this in your log file located at `./logs/guard-logs/` or in your console:
> ```
> info: Dialer node started with peerId: 12D3KooWNGaHx3EAdNeKUFxAKrg3EyKFN8gHHw9H5ZiBmRVjxHpG.
> ```
> In this example, `12D3KooWNGaHx3EAdNeKUFxAKrg3EyKFN8gHHw9H5ZiBmRVjxHpG` represents the peerId.


## Successful Keygen

After discovering all peers, the colaborative key genaration process will be started. In case of a successful key genaration you can see the following message in the console as well as in the log file located at `./logs/guard-logs/`.

```
info: [keygen] request start keygen with response {"shareID":"17919185987749025101810558434858548363703702891441976713238832618792983045264897561171919","pubKey":"9a685c62d667fd99c22dbd1d8e97b27a268003e146ac8af74b03c5a1f25f4f5f","status":"success"} called
```
Please provide this data to the moderator of the keygen ceremony to acknowledge your successful operation.


### Backup

After a successful keygen ceremony, back up the `keygen data` as well as the `p2p data` by executing the following commands in the guard directory:

```shell
mkdir guard_data_backup
docker compose cp service:/app/peer-dialer/peer-dialer.json ./guard_data_backup/
docker compose cp service:/app/tss-api/home/eddsa/keygen_data.json ./guard_data_backup/
```

> **Note:**
> Keep the directory `guard_data_backup` in a secure location. Your key share can be found in `keygen_data.json`. 
