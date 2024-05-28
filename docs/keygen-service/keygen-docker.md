## Keygen Service

Being a guard, you need a set of secret keys that will be used in multisig operations. One of these keys will be used by the `TSS library` for `EcDSA` and `EdDSA` multisig wallets. 

The following document will help you through generating these keys by connecting the `keygen service` to your `guard service` in a `key generation ceremony`.

# Docker Deployment

If you are participating in a Rosen key generation ceremony for the first time, clone [Operation repository](https://github.com/rosen-bridge/operation.git) and go to `operation/keygen-service` directory

```shell
git clone https://github.com/rosen-bridge/operation.git
cd operation/keygen-service/
```
 
>**Note:** If you have participated in the previous key generation ceremony, we would like to stress the importance of ensuring that you have backed up your important data before taking any further actions. If you do not have a backup, please refer to the information provided [here](#backup).

If you have participated in the previous key generation ceremony, just pull the latest changes from operation repo

```shell
cd operation/
git pull
cd keygen-service/
```

**Note:** if you need to set specific keygen service image version create environment file `.env` based on `env.template` file in the `keygen-service` directory (In general, there is no need to specify a particular version for the key generation service image.)

```shell
cp env.template .env
```

Set your parameters in `.env` file 
>**Note:** do not use space after `=` sign

```shell
# Optional Environments

KEYGEN_IMAGE_VERSION=
```

Set required permissions and create `local.yaml` file in the `config` directory

```shell
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

In order to instruct the service to generate a new key, copy and paste the following lines in `local.yaml` file, fill in the required parameters, and save the file.
  > Ask the keygen ceremony moderator to provide the required info for the `FILL_ACCORDING_TO_YOUR_GUARD_SET` parameters

```shell
# Paste these lines in local.yaml file, fill in the parameters.

keygen: 
  guards: FILL_ACCORDING_TO_YOUR_GUARD_SET(number) # total number of guards
  threshold: FILL_ACCORDING_TO_YOUR_GUARD_SET(number) # signing threshold (at least threshold + 1 guards are required)
  algorithm: FILL_ACCORDING_TO_YOUR_GUARD_SET(string) # ecdsa or eddsa
p2p:
  addresses:
    - peerId: FILL_ACCORDING_TO_YOUR_GUARD_SET
      address: FILL_ACCORDING_TO_YOUR_GUARD_SET
```

In the `keygen-service` directory, run the container
  
```shell
docker compose up # use `docker-compose up` for older versions of Docker
```

> **Note:**
> Each guard has a unique peerId that you should provide to the moderator of the keygen ceremony. Your peerId will be whitelisted relays. Upon starting your guard or keygen-service for the first time, you can find the value of this parameter in your guard's logs or keygen-service's logs. For example, you should see a line like this in your log file located at `./keygen-service/logs/keygen-logs/` or ./guard/logs/guard-logs/ or in your console:
> ```
> info: Dialer node started with peerId: 12D3KooWNGaHx3EAdNeKUFxAKrg3EyKFN8gHHw9H5ZiBmRVjxHpG.
> ```
> In this example, `12D3KooWNGaHx3EAdNeKUFxAKrg3EyKFN8gHHw9H5ZiBmRVjxHpG` represents the peerId.


## Successful Keygen

After discovering all peers, the colaborative key genaration process will be started. In case of a successful key genaration, a message with the following structure could be seen in the console as well as in the log file located at `./keygen-service/logs/keygen-logs/`.

```
info: [keygen] request start keygen with response {"shareID":"17919185987749025101810558434858548363703702891441976713238832618792983045264897561171919","pubKey":"9a685c62d667fd99c22dbd1d8e97b27a268003e146ac8af74b03c5a1f25f4f5f","status":"success"} called
```
Please provide this data to the moderator of the keygen ceremony to acknowledge your successful operation.

After a successful keygen ceremony, In the `keygen-service` directory, stop the container
  
```shell
docker compose down # use `docker-compose down` for older versions of Docker
```

### Backup

After a successful keygen ceremony, back up the `keygen data` as well as the `p2p data` by executing the following commands in the `guard` directory:

```shell
cd ./operation/guard
mkdir -p guard_data_backup/tss
docker compose cp service:/app/peer-dialer/peer-dialer.json ./guard_data_backup/
docker compose cp service:/app/tss-api/home/ ./guard_data_backup/tss
```

> **Note:**
> Keep the directory `guard_data_backup` in a secure location. Your key share can be found in `./guard_data_backup/tss/(ecdsa || eddsa)/keygen_data.json`.
