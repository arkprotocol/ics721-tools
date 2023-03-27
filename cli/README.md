# Getting Started

Load CLI
```sh
# get Ark CLI repo
$ git clone https://github.com/arkprotocol/ics721-tools
# go to cli directory
$ cd ics721-tools/cli
# initialize ark CLI
$ source ./ark-cli.sh
init ARK_HISTORY
ark 0.1.0
- please select operating chain: ark select chain [chain: stagagaze|irisnet|juno|uptick|omniflix|osmosis]
- max calls (like tx queries) until succcesful response set to: MAX_CALL_LIMIT=200
# init CLI and pass chain
$ source ./ark-cli.sh stargaze
init ARK_HISTORY
ark 0.1.0
reading stargaze.env
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
$ ark select chain irisnet
reading irisnet.env
```

IMPORTANT NOTE:
Instead of using `ark select chain` it is also possible for all commands using the `--chain` flag!

```sh
ark query chain tx --tx E856A27A9496DDD7EE11FC5722BB7611017DB265F293C7962666EA31588BD1E9 --chain juno
```

# Chain Config / `$CHAIN.env` files

As a a minimum please enter your wallets for these entries in the corresponding env files:

```sh
export WALLET_CREATOR="stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf"
export WALLET_MINTER="stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf"
export WALLET_RELAYER="stars1g0krhq56pmxmaz8lnj8h6jf55kcsq7x0lw5ywc"
```

The relayer wallet is only needed - in case you want to manually relay your own IBC packets (like for ICS721/NFT transfers).

Please also NOTE that the creator and minter wallets provided in env files are being used by Ark team internally - so please be kind and use your own wallet ;)!

# Commands

## ICS721 Commands

### NFT Interchain Transfer

Transferring to another chain
```sh
ark transfer ics721 token \
[--chain CHAIN] \
[--from FROM] \
[--recipient RECIPIENT] \
[--target-chain TARGET_CHAIN] \
[--source-channel SOURCE_CHANNEL] \
[--collection COLLECTION] \
[--token TOKEN] \
[--relay]

```

### NFT Multi-Chain Transfer

Transferring through multiple chains
```sh
ark transfer ics721 chains \
[--chain CHAIN] \
[--from FROM] \
[--recipients RECIPIENTS] \
[--target-chains TARGET_CHAINS] \
[--source-channels SOURCE_CHANNELS] \
[--collection COLLECTION] \
[--token TOKEN] \
[--max-height MAX_HEIGHT]

```

### Collection Query By Class ID

A collection being transferred to chains using `nft` module have this id format: `ibc/SOME_HASH`.
The hash is generated using a class id.

TODO: remove `--dest-port`

```sh
ark query ics721 class-id \
[--chain CHAIN] \
[--class-id CLASS_ID] \
[--dest-port DEST_PORT] \
[--max-call-limit MAX_CALL_LIMIT] \
[--sleep SLEEP] \
```

## Query transaction

```sh
ark query chain tx --tx [TXHASH]
```

## Chain: Select, Query, Reload

```sh
$ ark select chain juno
reading juno.env

$ ark query chain
selected chain: juno

$ ark reload chain
reading juno.env
```

## Ark Command history

TODO: not working yet

```sh
ark query history list
[]
```

## Create Collection

```sh
ark create collection \
[--chain CHAIN] \
[--name NAME] \
[--data DATA] \
[--symbol SYMBOL] \
[--uri URI] \
[--label LABEL] \
[--collection COLLECTION] \
[--code-id CODE_ID] \
[--description DESCRIPTION] \
[--from FROM] \
[--admin ADMIN]
```

## Mint/Issue an NFT for a collection

```sh
ark mint collection \
[--chain CHAIN] \
[--collection COLLECTION] \
[--token TOKEN] \
[--data DATA] \
[--uri URI] \
[--name NAME] \
[--from FROM] \
[--recipient RECIPIENT]
```

## Query All Collections

```sh
ark query collection collections \
[--chain CHAIN] \
[--owner OWNER] \
[--limit LIMIT] \
[--code-id CODE_ID] \
[--offset OFFSET]
```

## Query For All Tokens For A Specific Collection

```sh
ark query collection tokens \
[--chain CHAIN] \
[--collection COLLECTION]
```

## Query For Specific Token And Collection

```sh
ark query collection token \
[--chain CHAIN] \
[--collection COLLECTION] \
[--token TOKEN]
```

## Snapshot / Query For Owners

```sh
ark query nft snapshot \
[--chain CHAIN] \
[--collection COLLECTION]
```

## Block Height Query

Outputs latest block height.

```sh
ark query chain height --chain [CHAIN]
```

## Transaction Query

Queries for transaction until max call limit is reached. Helpful for sync operations, since this query waits until tx is finished!
```sh
ark query chain tx --chain [CHAIN] --tx [TXHASH] --max-call-limit [MAX_CALL_LIMIT]
```

## NFT Commands

### NFT Transfer

Transfer NFT to another owner (within same chain).

NOTE: In case NFT is not owned by `FROM`, this command waits until max call limit. This allows doing a transfer, while another command (like interchain transfers) is transferring NFT to this new
```sh
ark transfer nft --collection [COLLECTION] --token [TOKEN] --recipient [RECIPIENT] --from [FROM]
```

### NFT Assert Token Owner

Helper function, awaiting for NFT owned by given address until max call limit.

```sh
 ark assert nft token-owner --chain irisnet --collection arkprotocol002 --token ark100 --owner iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --max-call-limit 200
```

Output returns with exit code 0, in case of success.

##

```sh

```

##

```sh

```

##

```sh

```

##

```sh

```

# Commands explained

## Create A Collection

Now let's create a collection on IRISnet:

```sh
# tell ARK on which chain it should operate with
$ ark select chain irisnet # stargaze, juno, irisnet, uptick, and omniflix
# create collection on selected chain
$ ark create collection \
--collection alphacollection001 \
--uri "https://arkprotocol.io/" \
--symbol ArkAlphaCollection \
--name "Ark Alpha Collection - coming soon..." \
--description "Alpha holders earn rewards on each transfer and multichain utility and any collection!" \
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

Once it succeeds, output looks like this:

```json
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
# change vars in env file
export ARK_GON_COLLECTION="arkalpha003"
# IMPORTANT: don't forget reloading your envs!
$ ark select chain irisnet
```

## Mint/Issue An NFT For A Collection

```sh
$ ark mint collection \
--from $WALLET_MINTER \
--recipient $WALLET_MINTER \
--collection $ARK_GON_COLLECTION \
--token arkalpha001 \
| jq # optional: using jq for better formatting JSON output!
```

Output shows: mint command, tx query and output including mint command and tx result.

```json
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

## Query Collections And Tokens

Query all collections

```sh
# query all collections on IRISnet
$ ark select chain irisnet
$ ark query collection collections # please note there is a limit of 100! Also there is a bug on IRISnet, where offset is not working: https://github.com/game-of-nfts/gon-evidence/issues/194
# query on another chain using `--chain` flag instead of using `ark select chain`
$ ark query collection collections --chain stargaze
# query for all collections starting at page/offset 7
$ ark query collection collections --chain omniflix --offset 7

```

Query for all tokens for a specific collection:
```sh
$ ark query collection tokens --collection $ARK_GON_COLLECTION | jq
```

Query for specific token and collection:
```sh
$ ark query collection token --collection $ARK_GON_COLLECTION --token arkalpha011 | jq
```

## ICS721 Commands

### NFT Interchain Transfer

```sh
# transfer from selected chain (e.g. IRISnet) to target chain Juno
$ ark transfer ics721 token \
--from $WALLET_MINTER \
--recipient stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf \
--target-chain stargaze \
--source-channel $CHANNEL_1_TO_STARGAZE \
--collection $ARK_GON_COLLECTION \
--token arkalpha002 \
| jq
```

Transfer output contains:
1. transfer cmd: transfers NFT from source to target chain
2. query cmd waiting for above transfer transaction to be finished
3. query for counter-part channel (needed for retrieving class-id on target chain)
4. query class-id on target chain
5. output with info on source and target chain like class id and collection id

```json
{
  "cmd": "iris tx nft-transfer transfer 'nft-transfer' 'channel-22' 'stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf' 'arkprotocol002' 'ark192' --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --fees 2000uiris --packet-timeout-timestamp 300000000000 -b sync --yes",
  "source": {
    "chain": "irisnet",
    "chain_id": "gon-irishub-1",
    "port": "nft-transfer",
    "channel": "channel-22",
    "collection": "arkprotocol002",
    "class_id": "arkprotocol002",
    "owner": "iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f"
  },
  "target": {
    "chain": "stargaze",
    "chain_id": "elgafar-1",
    "port": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh",
    "channel": "channel-207",
    "collection": "stars1ff06t96hwd96fa3pq7uxgrxqqt3gv4zda444k0kappcr6tcwyzass8e4jz",
    "class_id": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkprotocol002",
    "owner": "stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf"
  },
  "tx": "900F2A87ECC5A00AEC4DB62C4600D8C7A35EF4490B688CBA585B7FB6365F64A8",
  "height": "578254",
  "id": "ark192"
}
```

Now let's use above NFT for transferring to another chain. For this have a look at above output for target chain Stargaze:

- `collection` contract: `stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw`

The `collection` is required for transferring an NFT from recipient's target chain Stargaze.

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
$ ark select chain stargaze
# transfer from Stargaze to Omniflix
$ ark transfer ics721 \
--from $WALLET_MINTER \
--recipient omniflix183e7ccwsnngj2q8lfxnmekunspnfxs6qw3yyyx \
--target-chain omniflix \
--source-channel $CHANNEL_1_TO_OMNIFLIX \
--collection stars1ztf5rfs06cgduxn3j68l8nqcsdgne06c0fd6e80xn6xjllde3hns52x7xw \
--token arkalpha001 \
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

### NFT Multi-Chain Transfer

Transferring through 5 chains and channels through this flow:
`i --(1)--> s --(1)--> j --(1)--> u --(1)--> o --(1)--> i`

Flow starts from IRISnet and ends at IRISnet, resulting each collection being escrowed/locked on all 5 chains. In addtion last transfer creates a new collection on IRISnet, while initial collection is locked at IRISnet.

```sh
# transfer from selected chain (e.g. IRISnet) to target chain Juno
ark transfer ics721 chains --collection $ARK_GON_COLLECTION --from $WALLET_MINTER --recipients stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf/juno183e7ccwsnngj2q8lfxnmekunspnfxs6q9akx5y/uptick1h7c0ltrj6z707eh3z4cyv4jkqwfv6lj76se7lr/omniflix183e7ccwsnngj2q8lfxnmekunspnfxs6qw3yyyx/iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --target-chains stargaze/juno/uptick/omniflix/irisnet --source-channels channel-22/channel-230/channel-86/channel-5/channel-24 --token ark193 --max-height 50 | jq
```

Transfer output contains:
1. transfers: details for each interchain transfer, including chain, chain id, collection, port, channel, target channel, class id and owner (before transfer)
2. final chain details: chain, chain id, collection, port, channel, class id and owner

Please also note, that in log output, it provides an undo command, allowing to transfer back to initial chain. Like: `Skip revert: ark transfer ics721 chains --chain irisnet --collection ibc/415A6D8164A11757001E29DEEE482FC373D2CB37BC33E9D8BECFC458358478AA --token ark193 --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --recipients omniflix183e7ccwsnngj2q8lfxnmekunspnfxs6qw3yyyx/uptick1h7c0ltrj6z707eh3z4cyv4jkqwfv6lj76se7lr/juno183e7ccwsnngj2q8lfxnmekunspnfxs6q9akx5y/stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf/iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --target-chains omniflix/uptick/juno/stargaze/irisnet --source-channels channel-0/channel-41/channel-7/channel-120/channel-207`

```json
{
{
  "transfers": [
    {
      "cmd": "ark transfer ics721 token --from iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --collection arkprotocol002 --token ark193 --recipient stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf --target-chain stargaze --source-channel channel-22",
      "tx": "F3850F73175A0FFD9FB0C37960D6E13DAC6558DA019B6DAC60D926C2AA4C548D",
      "height": "578375",
      "chain": "irisnet",
      "chain_id": "gon-irishub-1",
      "port": "nft-transfer",
      "channel": "channel-22",
      "target_channel": "channel-207",
      "collection": "arkprotocol002",
      "class_id": "arkprotocol002",
      "owner": "iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f"
    },
    {
      "cmd": "ark transfer ics721 token --from stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf --collection stars1ff06t96hwd96fa3pq7uxgrxqqt3gv4zda444k0kappcr6tcwyzass8e4jz --token ark193 --recipient juno183e7ccwsnngj2q8lfxnmekunspnfxs6q9akx5y --target-chain juno --source-channel channel-230",
      "tx": "E33F4C1F789338F06916C2571E0C91D970A0881CC164375E2E78389475C5F5AA",
      "height": "3970056",
      "chain": "stargaze",
      "chain_id": "elgafar-1",
      "port": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh",
      "channel": "channel-230",
      "target_channel": "channel-120",
      "collection": "stars1ff06t96hwd96fa3pq7uxgrxqqt3gv4zda444k0kappcr6tcwyzass8e4jz",
      "class_id": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkprotocol002",
      "owner": "stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf"
    },
    {
      "cmd": "ark transfer ics721 token --from juno183e7ccwsnngj2q8lfxnmekunspnfxs6q9akx5y --collection juno1pzphrwp3vp3m6vsd2axjak4lgzr9hg7lxelx0lnntm76gh69ypnsafdew2 --token ark193 --recipient uptick1h7c0ltrj6z707eh3z4cyv4jkqwfv6lj76se7lr --target-chain uptick --source-channel channel-86",
      "tx": "9FD429D9514B8C7E610CCF9665D245C4264AC4CC0D18A3FD8756C6C41FD3FD87",
      "height": "640281",
      "chain": "juno",
      "chain_id": "uni-6",
      "port": "wasm.juno1stv6sk0mvku34fj2mqrlyru6683866n306mfv52tlugtl322zmks26kg7a",
      "channel": "channel-86",
      "target_channel": "channel-7",
      "collection": "juno1pzphrwp3vp3m6vsd2axjak4lgzr9hg7lxelx0lnntm76gh69ypnsafdew2",
      "class_id": "wasm.juno1stv6sk0mvku34fj2mqrlyru6683866n306mfv52tlugtl322zmks26kg7a/channel-120/wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkprotocol002",
      "owner": "juno183e7ccwsnngj2q8lfxnmekunspnfxs6q9akx5y"
    },
    {
      "cmd": "ark transfer ics721 token --from uptick1h7c0ltrj6z707eh3z4cyv4jkqwfv6lj76se7lr --collection ibc/1945C3288496E68862A524E6C5A59627ABFB5BA9D624E13B826F050AA055CDFF --token ark193 --recipient omniflix183e7ccwsnngj2q8lfxnmekunspnfxs6qw3yyyx --target-chain omniflix --source-channel channel-5",
      "tx": "CD159BD292FF6326CB12FE658D6C59021102E9B3BDBAE843C27D7B9047EDB284",
      "height": "2590229",
      "chain": "uptick",
      "chain_id": "uptick_7000-2",
      "port": "nft-transfer",
      "channel": "channel-5",
      "target_channel": "channel-41",
      "collection": "ibc/1945C3288496E68862A524E6C5A59627ABFB5BA9D624E13B826F050AA055CDFF",
      "class_id": "nft-transfer/channel-7/wasm.juno1stv6sk0mvku34fj2mqrlyru6683866n306mfv52tlugtl322zmks26kg7a/channel-120/wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkprotocol002",
      "owner": "uptick1h7c0ltrj6z707eh3z4cyv4jkqwfv6lj76se7lr"
    },
    {
      "cmd": "ark transfer ics721 token --from omniflix183e7ccwsnngj2q8lfxnmekunspnfxs6qw3yyyx --collection ibc/39B2848724674E175F6803CDC3FA260E9CFE209D619E9C83EFC3A4E9AE538322 --token ark193 --recipient iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --target-chain irisnet --source-channel channel-24",
      "tx": "2BC5BBF6FB734A9CF24E3EBFCD962AEA62948F545F0FA596288662818E91B989",
      "height": "665924",
      "chain": "omniflix",
      "chain_id": "gon-flixnet-1",
      "port": "nft-transfer",
      "channel": "channel-24",
      "target_channel": "channel-0",
      "collection": "ibc/39B2848724674E175F6803CDC3FA260E9CFE209D619E9C83EFC3A4E9AE538322",
      "class_id": "nft-transfer/channel-41/nft-transfer/channel-7/wasm.juno1stv6sk0mvku34fj2mqrlyru6683866n306mfv52tlugtl322zmks26kg7a/channel-120/wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkprotocol002",
      "owner": "omniflix183e7ccwsnngj2q8lfxnmekunspnfxs6qw3yyyx"
    }
  ],
  "chain": "irisnet",
  "chain_id": "gon-irishub-1",
  "port": "nft-transfer",
  "channel": "channel-0",
  "collection": "ibc/415A6D8164A11757001E29DEEE482FC373D2CB37BC33E9D8BECFC458358478AA",
  "class_id": "nft-transfer/channel-0/nft-transfer/channel-41/nft-transfer/channel-7/wasm.juno1stv6sk0mvku34fj2mqrlyru6683866n306mfv52tlugtl322zmks26kg7a/channel-120/wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/arkprotocol002",
  "owner": "iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f",
  "total_duration_height": "19"
}
```

### Collection Query By Class ID

A collection being transferred to chains using `nft` module have this id format: `ibc/SOME_HASH`.
The hash is generated using a class id.

TODO: remove `--dest-port`

```sh
ark query ics721 class-id --class-id wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/gonTeamRace2 --dest-port wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh
```

output:

```json
{
  "cmd": "starsd query wasm contract-state smart stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh '{\"nft_contract\":{\"class_id\":\"wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/gonTeamRace2\"}}' --output json",
  "data": {
    "class_id": "wasm.stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh/channel-207/gonTeamRace2",
    "collection": "stars1unjgjcyhhx5r8tn96hqs92xdv6d0hy64xw55qu4um8awvy5qdulq0ggj28"
  }
}
```

## NFT Commands

### NFT Transfer

```sh
ark transfer nft --collection arkprotocol002 --token ark194 --recipient $WALLET_MINTER --from $WALLET_CREATOR
```

### NFT Assert Token Owner

```sh
 ark assert nft token-owner --chain irisnet --collection arkprotocol002 --token ark100 --owner $WALLET_MINTER --max-call-limit 200
```

Output returns with exit code 0, in case of success.