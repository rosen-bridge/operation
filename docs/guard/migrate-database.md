# Migrate Database Image

Due to a change in RapidFort's business strategy, the PostgreSQL image we were using (`rapidfort/postgresql:16.0.0`) is no longer available on Docker Hub. As a result, guard operators may encounter the following error:

```
pull access denied for rapidfort/postgresql, repository does not exist or may require 'docker login'
```

Follow the instructions below by navigating to the `operation/guard` directory:

```shell
cd operation/guard/
```

## Take a Backup

### Stop the Guard Service
```shell
docker compose down service
```

### Backup the Database
```shell
docker compose exec -T db pg_dump -U PUT_POSTGRES_USER_HERE PUT_POSTGRES_DB_HERE > dump_guard_db.bak
```

> **Notes:**  
> - Replace `PUT_POSTGRES_USER_HERE` and `PUT_POSTGRES_DB_HERE` with the values from your `.env` file.  
> - You will need to enter your `POSTGRES_PASSWORD` after running the above command.  
> - Ensure that `dump_guard_db.bak` is successfully created in the same directory as the `docker-compose.yaml` file.  
> - The backup file should have a reasonable size (not in KB or bytes).  

---

## Stop Services

Stop all services and remove db volume:

```shell
docker compose down
docker volume rm guard_postgres-data
```

---

## Pull Changes

### Update the `operation` Repository
Pull the latest changes in the `operation` repository. If you have made manual changes to the `docker-compose` file, remove or stash them first:

```shell
git pull
```

### Pull Docker Images
```shell
docker compose pull
```

---

## Restore Backup

### Start the Database Service
```shell
docker compose up -d db
```

### Restore the Backup
```shell
docker compose exec -T db psql -U PUT_POSTGRES_USER_HERE < dump_guard_db.bak
```

> **Notes:**  
> - Replace `PUT_POSTGRES_USER_HERE` with the correct value from your `.env` file.  
> - To verify the successful restoration of your database, run the following command and look for `block_entity` in the result:  

```shell
docker compose exec -it db psql -U PUT_POSTGRES_USER_HERE -c "\dt"
```

The expected output should look like this:

```
                List of relations
 Schema |          Name           | Type  | Owner
--------+-------------------------+-------+-------
 public | address_txs_entity      | table | YOUR_USERNAME
 public | block_entity            | table | YOUR_USERNAME
 public | collateral_entity       | table | YOUR_USERNAME
 public | commitment_entity       | table | YOUR_USERNAME
 public | confirmed_event_entity  | table | YOUR_USERNAME
 public | event_trigger_entity    | table | YOUR_USERNAME
 public | extractor_status_entity | table | YOUR_USERNAME
 public | migrations              | table | YOUR_USERNAME
 public | permit_entity           | table | YOUR_USERNAME
 public | revenue_entity          | table | YOUR_USERNAME
 public | transaction_entity      | table | YOUR_USERNAME
 public | typeorm_metadata        | table | YOUR_USERNAME
```

---

## Start Services

Finally, start the guard service:

```shell
docker compose up -d
```

> Note: If everything is okay, you can remove `dump_guard_db.bak`.
