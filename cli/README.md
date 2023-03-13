# Getting Started

Load CLI
```sh
# get Ark CLI repo
git clone https://github.com/arkprotocol/ics721-tools
# go to cli directory
$ cd ics721-tools/cli
# load ark scripts
$ source ./ark-cli.sh 
init ARK_HISTORY
ark 0.1.0
- please select operating chain: ark select chain [chain: stagagaze|irisnet|juno|uptick|omniflix|osmosis]
- max calls (like tx queries) until succcesful response set to: MAX_CALL_LIMIT=200
```

Ark CLI syntax: `ark [command] [module] [sub command] [flags]`

The Ark CLI loads for each chain an `.env` file and supports these chains:

- Stargaze: [stargaze.env](stargaze.env)
- Juno: [juno.env](juno.env)
- IRISnet: [irisnet.env](irisnet.env)
- Uptick: [uptick.env](uptick.env)
- OmniFlix: [omniflix.env](omniflix.env)

Additional chains can be easily added by adding another `.env` file.

First thing you need to do is to select the chain on which `Ark` CLI is suppose to work with:
```sh
# tell ARK on which chain it should operate with
ark select chain irisnet
```

IMPORTANT NOTE:
Instead of using `ark select chain` it is also possible for all commands using the `--chain` flag!

# Chain Config / `$CHAIN.env` files

As a a minimum please enter your wallets for these entries in the corresponding env files:

```sh
export WALLET_CREATOR="stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf"
export WALLET_MINTER="stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf"
export WALLET_RELAYER="stars1g0krhq56pmxmaz8lnj8h6jf55kcsq7x0lw5ywc"
```

The relayer wallet is only needed - in case you want to manually relay your own IBC packets (e.g. ICS721/NFT transfers).
Please also NOTE that the creator and minter wallets provided in env files are being used by Ark team internally - so please be kind and use your own wallet ;)!

# Create a collection

Now let's create a collection on IRISnet:

```sh
# tell ARK on which chain it should operate with
ark select chain irisnet # stargaze, juno, irisnet, uptick, and omniflix
# create collection on selected chain
ark create collection \
--collection arkalpha004 \
--uri "https://arkprotocol.io/" \
--symbol arkalpha \
--name "Ark Alpha Collection - coming soon..." \
--description "holders earn on each ICS721 transfer!" \
--from $WALLET_MINTER \
| jq # optional: using jq for better formatting JSON output!
```

The following output is then shown:

1. CLI command: actual command being executed. Like: `iris tx nft issue ...`
2. Query command: queries for mint transaction
3. Command output containing: `{cmd: ..., data: ...}`

The 1st command is the ones used for creating a collection. The return transaction hash is used for the 2nd command. The query command is called x times based on MAX_CALL_LIMIT as defined in [cli.env](cli.env):

```sh
export MAX_CALL_LIMIT=200
```

Once it succeeds output looks like this:

```sh
reading irisnet.env
====> irisnet: creating collection arkalpha004, from: iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f  <====
iris tx nft issue arkalpha004                --symbol "arkalpha"                                --name "Ark Alpha Collection - coming soon..."                --uri "https://arkprotocol.io/"                --description="holders earn on each ICS721 transfer!"                --mint-restricted=true --update-restricted=true                --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f                --fees 2000uiris                -b sync --yes --output json

====> executing until success.....<====
iris query tx EA421D256B287E52626CD8AD34D8D9181F1869F5302B1E466833293B136669C3 --output json
command and output added to history (1 entries)
{
  "cmd": "iris tx nft issue arkalpha004 --symbol \"arkalpha\" --name \"Ark Alpha Collection - coming soon...\" --uri \"https://arkprotocol.io/\" --description=\"holders earn on each ICS721 transfer!\" --mint-restricted=true --update-restricted=true --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --fees 2000uiris -b sync --yes --output json",
  "data": {
    "height": "446320",
    "txhash": "EA421D256B287E52626CD8AD34D8D9181F1869F5302B1E466833293B136669C3",
    "codespace": "",
    "code": 0,
    ...
  },
  "id": "arkalpha004"
}
```

Please note that output provides the collection in `id` (e.g. 'arkalpha004'). Id varies depending on chain. Like for Stargaze it returns a CW721 contract for `id`.

For ease of use, collection id may be added to env file, like in [irisnet.env](irisnet.env):

```sh
export ARK_GON_COLLECTION="arkalpha003"
```

# Mint/Issue an NFT for a collection


```sh
ark mint collection \
--from $WALLET_MINTER \
--recipient $WALLET_MINTER \
--collection $ARK_GON_COLLECTION \
--token arkalpha001 \
| jq # optional: using jq for better formatting JSON output!
```

Output shows: mint command, tx query and output including mint command and tx result.

```sh
~/data/development/ics721-tools/cli (main)$ ark mint collection \
--from $WALLET_MINTER \
--recipient $WALLET_MINTER \
--collection $ARK_GON_COLLECTION \
--token arkalpha001 \
| jq # optional: using jq for better formatting JSON output!
reading irisnet.env
====> minting arkalpha001 on chain irisnet <====
iris tx nft mint 'arkalpha004' 'arkalpha001'                --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f                --recipient iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f                                                                --fees 2000uiris                -b sync --yes --output json

====> executing until success........<====
iris query tx 774BBFB3B4EAE294200D11E7DE09BCC91B6EB62CC65F5953DD79CA423188F59D --output json
command and output added to history (1 entries)
{
  "cmd": "iris tx nft mint 'arkalpha004' 'arkalpha001' --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --recipient iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --fees 2000uiris -b sync --yes --output json",
  "data": {
    "height": "446342",
    "txhash": "774BBFB3B4EAE294200D11E7DE09BCC91B6EB62CC65F5953DD79CA423188F59D",
    ...
  },
  "id": "arkalpha001"
}
```

# Query collections and tokens

Query all collections

```sh
# query all collections on IRISnet
ark select chain irisnet
ark query collection collections # please note there is a limit of 100! Also there is a bug on IRISnet, where offset is not working: https://github.com/game-of-nfts/gon-evidence/issues/194
# query on another chain using `--chain` flag instead of using `ark select chain`
ark query collection collections --chain stargaze
# query for all collections starting at page/offset 7
ark query collection collections --chain omniflix --offset 7

```

Query for all tokens for a specific collection:
```sh
ark query collection tokens --collection $ARK_GON_COLLECTION | jq
```

Query for specific token and collection:
```sh
ark query collection token --collection $ARK_GON_COLLECTION --token arkalpha011 | jq
```

```sh

```


# ICS721 transfer


```sh
# transfer from selected chain (e.g. IRISnet) to target chain Juno
ark transfer ics721 \
--from $WALLET_MINTER \
--recipient stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf \
--target-chain stargaze \
--source-channel $CHANNEL_1_TO_STARGAZE \
--collection $ARK_GON_COLLECTION \
--token arkalpha001
```

Transfer output contains:
1. transfer cmd: transfers NFT from source to target chain
2. query cmd waiting for above transfer transaction to be finished
3. query for counter-part channel (needed for retrieving class-id on target chain)
4. query class-id on target chain
5. output with info on source and target chain like class id and collection id

Regarding:
4. class id query: please note there is an optional `--source-class-id` flag. In case it is not provided `--collection` is used (also outlined in output below!).

```sh
====> transferring arkalpha001 (collection: arkalpha004), from irisnet to stargaze  <====
iris tx nft-transfer transfer 'nft-transfer' 'channel-22' 'stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf' 'arkalpha004' 'arkalpha001'            --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f            --fees 2000uiris            -b sync --yes --output json

====> executing until success........<====
iris query tx 4050049F3855891F0415C016DC4F2755A5245E04F00AFACCC2FAA93AF4BB273A --output json
command and output added to history (1 entries)
====> query counter-part channel for channel-22 <====
...
--source-class-id not defined, using collection arkalpha004
====> find class-id at stargaze, target port: wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh, target channel: channel-207, source class id: arkalpha004 <====
ark query ics721 class-id        --chain stargaze        --dest-port wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh        --dest-channel channel-207        --source-class-id arkalpha004        --sleep 1        --max-call-limit 200
reading stargaze.env

====> retrieving class-id.......<====
command and output added to history (2 entries)
====> query token arkalpha001 at stargaze and collection stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw <====

====> executing until success<====
ark query collection token        --chain stargaze        --collection stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw        --token arkalpha001
reading stargaze.env
starsd query wasm contract-state smart            stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw            '{"all_nft_info":{"token_id": "arkalpha001"}}' --output json
command and output added to history (2 entries)
====> NFT recipient on target chain: stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf <====
NFT arkalpha001 owned on target chain by stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf
...
{
  "cmd": "iris tx nft-transfer transfer 'nft-transfer' 'channel-22' 'stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf' 'arkalpha004' 'arkalpha001' --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --fees 2000uiris -b sync --yes",
  "tx": "4050049F3855891F0415C016DC4F2755A5245E04F00AFACCC2FAA93AF4BB273A",
  "source": {
    "chain": "irisnet",
    "collection": "arkalpha004",
    "class_id": "arkalpha004",
    "channel": "channel-22",
    "port": "nft-transfer"
  },
  "target": {
    "chain": "stargaze",
    "collection": "stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw",
    "class_id": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkalpha004",
    "channel": "channel-207",
    "port": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh"
  }
}
command and output added to history (1 entries)
```

Now let's use above NFT for transferring to another chain. In this case `--source-class-id` is needed. In this case it is the class id on previous chain, with target chain Stargaze. For this have a look at above output for target chain Stargaze:

- `collection` contract: `stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw`
- `class_id`: `wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkalpha004`

The `collection` is required for transferring an NFT from Stargaze and the `class_id` is required for retrieving collection on next chain, Omniflix.

```json
{
  "cmd": "iris tx nft-transfer transfer 'nft-transfer' 'channel-22' 'stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf' 'arkalpha004' 'arkalpha001' --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --fees 2000uiris -b sync --yes",
  "tx": "4050049F3855891F0415C016DC4F2755A5245E04F00AFACCC2FAA93AF4BB273A",
  "source": {
    "chain": "irisnet",
    "collection": "arkalpha004",
    "class_id": "arkalpha004",
    "channel": "channel-22",
    "port": "nft-transfer"
  },
  "target": {
    "chain": "stargaze",
    "collection": "stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw",
    "class_id": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkalpha004",
    "channel": "channel-207",
    "port": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh"
  }
}
```

Now let's transfer and also manually relay using optional `--relay` flag:

```sh
# switch to Stargaze
ark select chain stargaze
# transfer from Stargaze to Omniflix
ark transfer ics721 \
--from $WALLET_MINTER \
--recipient omniflix183e7ccwsnngj2q8lfxnmekunspnfxs6qw3yyyx \
--target-chain omniflix \
--source-channel $CHANNEL_1_TO_OMNIFLIX \
--collection stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw \
--token arkalpha001 \
--source-class-id wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkalpha004 \
--relay

```

The JSON output looks like this:
```json
{
  "cmd": "starsd tx wasm execute 'stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw' '{ \"send_nft\": { \"contract\": \"stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh\", \"token_id\": \"arkalpha001\", \"msg\": \"ewogICAgICAgICAgICAicmVjZWl2ZXIiOiAib21uaWZsaXgxODNlN2Njd3NubmdqMnE4bGZ4bm1la3Vuc3BuZnhzNnF3M3l5eXgiLAogICAgICAgICAgICAiY2hhbm5lbF9pZCI6ICJjaGFubmVsLTIwOSIsCiAgICAgICAgICAgICJ0aW1lb3V0IjogeyAidGltZXN0YW1wIjogIjE2Nzg4MDc1OTY4NDIzNjQ4MjkiIH0gfQo=\"}}' --from stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf --gas-prices 0.01ustars --gas auto --gas-adjustment 1.3 -b sync --yes",
  "tx": "7B2BD324F0535DBF2164CE3440C9DA0BC7BEC3793D121557B4DD65AB50186429",
  "source": {
    "chain": "stargaze",
    "collection": "stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw",
    "class_id": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkalpha004",
    "channel": "channel-209",
    "port": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh"
  },
  "target": {
    "chain": "omniflix",
    "collection": "ibc/CDA10747CF2BC440B1BBD25FBC093241E26508BC2F65F7DA9A1DF80B9FF48DE8",
    "class_id": "nft-transfer/channel-44/wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkalpha004",
    "channel": "channel-44",
    "port": "nft-transfer"
  }
}
```

```sh

```

