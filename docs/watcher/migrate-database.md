# Migrate Database Image

Due to a change in RapidFort's business strategy, the PostgreSQL image we were using (`rapidfort/postgresql:16.0.0`) is no longer available on Docker Hub. As a result, our watchers may encounter the following error:

```
pull access denied for rapidfort/postgresql, repository does not exist or may require 'docker login'
```

Follow the instructions below by navigating to the `operation/watcher` directory:

```shell
cd operation/watcher/
```

---

## Pull Changes

### Update the `operation` Repository
Pull the latest changes in the `operation` repository. If you have made manual changes to the `docker-compose` file, remove or stash them first:

```shell
git pull
```

Checkout on a stable commit:

```shell
git checkout 4673077008fe58e2b8eb3d986b80281fab1ae482
```

---

If you want to preserve your database and data, follow the step-by-step instructions below. Otherwise, skip this section and pull your `initial height` forward in your config file (local.yaml file) then go to [Stop Services](#stop-services).

---

## Take a Backup

### Stop the Watcher Service
```shell
docker compose down service
```

### Backup the Database
```shell
docker compose exec -T db pg_dump -U PUT_POSTGRES_USER_HERE PUT_POSTGRES_DB_HERE > dump_watcher_db.bak
```

> **Notes:**  
> - Replace `PUT_POSTGRES_USER_HERE` and `PUT_POSTGRES_DB_HERE` with the values from your `.env` file.  
> - You will need to enter your `POSTGRES_PASSWORD` after running the above command.  
> - Ensure that `dump_watcher_db.bak` is successfully created in the same directory as the `docker-compose.yaml` file.  
> - The backup file should have a reasonable size (not in KB or bytes).  

---

## Stop Services

Stop all services and remove volumes:

```shell
docker compose down --volumes
```

---

## Checkout on latest commit

### Update the `operation` Repository
Checkout on the latest changes in the `operation` repository:

```shell
git checkout dev
```

### Pull Docker Images
```shell
docker compose pull
```

---

## Restore Backup

If you have created a backup in the [Take a Backup](#take-a-backup) section, restore it using the steps below.

### Start the Database Service
```shell
docker compose up -d db
```

### Restore the Backup
```shell
docker compose exec -T db psql -U PUT_POSTGRES_USER_HERE -d PUT_POSTGRES_DB_HERE < dump_watcher_db.bak
```

> **Notes:**  
> - Replace `PUT_POSTGRES_USER_HERE` and `PUT_POSTGRES_DB_HERE` with the correct value from your `.env` file.  
> - To verify the successful restoration of your database, run the following command and look for `block_entity` in the result:  

```shell
docker compose exec -it db psql -U PUT_POSTGRES_USER_HERE -d PUT_POSTGRES_DB_HERE -c "\dt"
```

The expected output should look like this:

```
                              List of relations
 Schema |           Name            | Type  |  Owner
--------+---------------------------+-------+------------
 public | block_entity              | table | YOUR_USERNAME
 public | box_entity                | table | YOUR_USERNAME
 public | collateral_entity         | table | YOUR_USERNAME
 public | commitment_entity         | table | YOUR_USERNAME
 public | event_trigger_entity      | table | YOUR_USERNAME
 public | extractor_status_entity   | table | YOUR_USERNAME
 public | migrations                | table | YOUR_USERNAME
 public | observation_entity        | table | YOUR_USERNAME
 public | observation_status_entity | table | YOUR_USERNAME
 public | permit_entity             | table | YOUR_USERNAME
 public | revenue_entity            | table | YOUR_USERNAME
 public | token_entity              | table | YOUR_USERNAME
 public | tx_entity                 | table | YOUR_USERNAME
 public | typeorm_metadata          | table | YOUR_USERNAME
```

---

## Start Services

Finally, start the watcher service:

```shell
docker compose up -d
```

> Note: If everything is okay, you can remove `dump_watcher_db.bak`.
