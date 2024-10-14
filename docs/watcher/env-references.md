## Environment Variable References
Note: 
- For the environmental variable file, no quotes are needed around the the strings. 
- Delete all comments after copying and pasting in.
- Delete all whitespaces after the last word of the line item entry.

# Required Environments
```
POSTGRES_PASSWORD= # a random alphanumeric password without special characters (like $%!-#)

POSTGRES_USER= # a random name

POSTGRES_DB= # a random name

POSTGRES_PORT=5432 # 5432 is set as default, you can change it.

```

# Optional Environments
```
API_KEY_HASH= # blake2b saletd hash of api_key, please put your apiKeyHash between single quotes e.g. API_KEY_HASH='myHashHere'

MNEMONIC= # watcher mnemonic phrases, e.g. MNEMONIC=word1 word2 word3 ... wordn

KOIOS_AUTH_TOKEN=

ETHEREUM_RPC_AUTH_TOKEN=

BLOCKFROST_PROJECT_ID=

OVERRIDE_LOKI_BASIC_AUTH=

WATCHER_HOST= # (default is 127.0.0.1 if no value is set)

WATCHER_PORT= # (default is 3030 if no value is set)

WATCHER_IMAGE_VERSION= # Don't change it!

UI_IMAGE_VERSION= # Don't change it!
```
