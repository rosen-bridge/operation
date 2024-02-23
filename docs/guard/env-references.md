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
API_KEY_HASH= # blake2b hash of api_key, e.g. API_KEY_HASH=myHashHere

MNEMONIC= # ergo mnemonic phrases, e.g. MNEMONIC= word1 word2 word3 ... wordn

TSS_SECRET= # the secret used to encrypt messages to start the signing process

KOIOS_AUTH_TOKEN=

BLOCKFROST_PROJECT_ID=

OVERRIDE_LOKI_BASIC_AUTH=

DISCORD_WEBHOOK_URL=

GUARD_PORT= # (default is 8081 if no value is set)

GUARD_IMAGE_VERSION= # Don't change it!

UI_IMAGE_VERSION= # Don't change it!
```
