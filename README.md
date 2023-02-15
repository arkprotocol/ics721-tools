# Ark Protocol

> Ark Protocol’s mission is to build multi-chain NFT utilities that can be used by ANY collection on ANY chain at ANY time,
> using the Inter-Blockchain Communication protocol (IBC) to enable the transfer of NFTs between different blockchains and
> allowing smart contracts to access utilities on other chains.

Official Links:
- [arkprotocol.io](https://arkprotocol.io/)
- [Twitter](https://twitter.com/ArkProtocol)
- [Discord](https://discord.gg/fVv6Mf9Wr8)

In case of support:
- best way is joining our discord (invite above) and go to [ibc-ics-support](https://discord.com/channels/974384596684791828/1040388398382321795) channel
- regarding this document use [GitHub discussions](https://github.com/arkprotocol/ics721-demo/discussions)
- in case of changes please file an [issue on GitHub](https://github.com/arkprotocol/ics721-demo/issues)

Higly recommended: Do you wonder why it is possible by transferring 2 NFTs to the same target chain, may end up into two different collections? Well, then you should read our ["Building Multi-Chain NFT Utilities"](https://arkprotocol.substack.com/p/nfts-and-utilities-going-multi-chain) blog. In the second part of this post, it explains in detail how ICS721 works:

![Building Multi-Chain NFT Utilities](https://substackcdn.com/image/fetch/f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2Fa0c571f0-9a1f-4747-9786-d63c0f29685f_1600x913.jpeg)


# How-To Send NFTs to Another Chain Using ICS721

This is quick how-to for testing ICS721 on these 4 testnets: Stargaze, Juno, IRISnet and Uptick. Stargaze and Juno support CosmWasm. Both are using the ICS721 contract, while IRISnet and Uptick are using the NFT module for interchain NFT transfers.

Make sure you have [set this up](setup-clis.md):

- installing CLIs (command line interfaces) to interact with contracts on different chains
- installing Hermes relayer to handle messages (packets) between chains

You will be able to use CLIs for transferring an NFT from a source chain to a target chain. For ICS721 testing it requires setting up a wallet for:

- test admin: owning ICS721 and CW721 (collection) contract
- test creator: wallet eligible to mint on CW721 collection contract
- test minter: wallet receiving NFTs from mint or ICS721 transfer

Relayers interact and execute transactions on each chains for sending packets. In this case a relayer also needs a keyring (wallet) for each chain.

All CLIs have the same key commands. There are certain specifics on each CLI - but not needed here.p

# Setup

For quick testing all environment variables are defined in [ics721-demo.env](ics721-demo.env). Call this command for setting these variables in your shell: `source ./ics721-demo.env`. It contains:

- wallets including test tokens
- cw721 and ics721 (contracts, code ids)
- CLI settings (chain-id, node, keys, mnemonics)

# CLI Commands for Testing

Below is a list of CLI commands you may need for testing:

- Create and recover keys (wallets)
- Upload and instantiate collection (CW721, nft module) and ICS721 contracts
- Create an IBC channel
- Mint an NFT
- IBC (interchain) transfer
- Relay channels

CLIs has a `--help` flag. So you can always use `starsd keys --help` or `uptickd keys add --help` for subcommands.

## Build and Upload Contracts

### CW721 Contract

For chains with wasm module, like Stargaze, collection contract (CW721) can be build and uploaded:

```sh
git clone https://github.com/CosmWasm/cw-nfts
cd cw-nfts
git checkout v0.16.0
# builds an optimized wasm contract
./scripts/build.sh
# optional renaming
mv CW721_base.wasm CW721_base_v0.16.0.wasm
# upload/store on chain
starsd tx wasm store ./cw721_base_v0.16.0.wasm --gas auto --gas-adjustment 1.3 -b block --output json --from $KEY_CREATOR_NAME --yes
# find stored contract's code_id in output: {"height":"2964307", ... {\"key\":\"code_id\",\"value\":\"803\"}]} ...}
# instantiate collection based on instantiate msg: https://github.com/CosmWasm/cw-nfts/blob/v0.16/contracts/CW721-base/src/msg.rs#L6-L16
printf -v INSTANTIATE_MSG '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"%s"}' $STARGAZE_WALLET_MINTER;starsd tx wasm instantiate 803 "$INSTANTIATE_MSG" --label ark-test-01 --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --admin $STARGAZE_WALLET_CREATOR # address defined in $STARGAZE_CONTRACT_CW721
# find instantiated contract in output: raw_log: '[{"events"... {"key":"_contract_address","value":"stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es"} ...]
# test collection and query for number of NFTs (result count should be 0)
starsd query wasm contract-state smart $STARGAZE_CONTRACT_CW721 '{"num_tokens":{}}'

# same for juno
# - upload
junod tx wasm store ./cw721_base_v0.16.0.wasm --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --output json --from $KEY_CREATOR_NAME --yes # code id 116
# - instantiate
printf -v INSTANTIATE_MSG '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"%s"}' $JUNO_WALLET_MINTER;junod tx wasm instantiate 116 "$INSTANTIATE_MSG" --label ark-test-01 --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --admin $JUNO_WALLET_CREATOR # address defined in $JUNO_CONTRACT_CW721
junod query wasm contract-state smart $JUNO_CONTRACT_CW721 '{"num_tokens":{}}'

# same for osmosis
# - upload
osmosisd tx wasm store ./cw721_base_v0.16.0.wasm --gas-prices 0.1uosmo --gas auto --gas-adjustment 1.3 -b block --output json --from $KEY_CREATOR_NAME --yes # code id 5942
# - instantiate
printf -v INSTANTIATE_MSG '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"%s"}' $OSMOSIS_WALLET_MINTER;osmosisd tx wasm instantiate 5942 "$INSTANTIATE_MSG" --label ark-test-01 --gas-prices 0.1uosmo --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --admin $OSMOSIS_WALLET_CREATOR # address defined in $OSMOSIS_CONTRACT_CW721
osmosisd query wasm contract-state smart $OSMOSIS_CONTRACT_CW721 '{"num_tokens":{}}'

```

### ICS721 Contract

A binary (build based on pull request 44) from git repo is stored here in `./cw_ICS721_bridge_pr44.wasm`. Or build and upload ICS721 contract from git repo manually:

```sh
git clone https://github.com/public-awesome/ICS721/
cd ICS721
git checkout 3af19e421a95aec5291a0cabbe796c58698ac97f # latest PR44
./ts-relayer-tests/build.sh
cp ./artifacts/cw_ICS721_bridge.wasm cw_ICS721_bridge_pr44.wasm
```

Upload contract:

```sh
starsd tx wasm store ./cw_ics721_bridge_pr44.wasm  --gas auto --gas-adjustment 1.3 -b block --output json --from $KEY_CREATOR_NAME --yes
# find contract's code_id in output: {"height":"2965732", ... {"key":"code_id","value":"804"} ...}
# instantiate based on instantiate msg: https://github.com/public-awesome/ICS721/blob/3af19e421a95aec5291a0cabbe796c58698ac97f/contracts/cw-ICS721-bridge/src/msg.rs#L17
starsd tx wasm instantiate 804 '{"cw721_base_code_id":803}' --label ark-test-ICS721-pr44 --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --admin $STARGAZE_WALLET_CREATOR
# find instantiated contract in output: raw_log: '[{"events"... {"key":"_contract_address","value":"stars16teejyjpa4qpcha54eulxv9l3n5vv9ujw3wc263ctuqahxx5k3as52my82"} ...]

# test query on ICS721
starsd query wasm contract-state smart $STARGAZE_CONTRACT_ICS721 '{"nft_contract":{"class_id":"DUMMY"}}' # data: null

# juno
# - upload
junod tx wasm store ./cw_ics721_bridge_pr44.wasm --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --output json --from $KEY_CREATOR_NAME --yes # code id 117
# - instantiate
junod tx wasm instantiate 117 '{"cw721_base_code_id":117}' --label ark-test-ICS721-pr44 --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --admin $JUNO_WALLET_CREATOR
# test query on ICS721
junod query wasm contract-state smart $JUNO_CONTRACT_ICS721 '{"nft_contract":{"class_id":"DUMMY"}}' # data: null

# osmosis
# - upload
osmosisd tx wasm store ./cw_ics721_bridge_pr44.wasm --gas-prices 0.1uosmo --gas auto --gas-adjustment 1.3 -b block --output json --from $KEY_CREATOR_NAME --yes # code id 5947
# - instantiate
osmosisd tx wasm instantiate 5947 '{"cw721_base_code_id":5942}' --label ark-test-ICS721-pr44 --gas-prices 0.1uosmo --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --admin $OSMOSIS_WALLET_CREATOR
# test query on ICS721
osmosisd query wasm contract-state smart $OSMOSIS_CONTRACT_ICS721 '{"nft_contract":{"class_id":"DUMMY"}}' # data: null
```

## Create and Recover Keys (Wallets)

Syntax:
```sh
starsd keys add KEY_NAME [flags] # same commands for other CLIs like junod, uptickd and iris
```

Example:

```sh
# create new wallet with name test_creator
starsd keys add $KEY_CREATOR_NAME # MNEMONIC will returned, pls backup!
# recover a wallet
uptickd keys add $KEY_CREATOR_NAME --recover # prompts for mnemonic!
# list all keys
iris query nft collection ibc/05472E356B4178A3131291252F6031DFF465658BE4A526D499139F8691D5A31F
```

## Upload and Instantiate Collection (CW721, NFT Module) and ICS721 Contracts

Syntax:
```sh
# ========================== wasm module ==========================
# upload contract (only cosmwasm)
starsd tx wasm store WASM_FILE --gas auto --gas-adjustment 1.3 -b block --output json --from KEY_WALLET_NAME_OR_ADDRESS --yes # same command for junod
# create/instantiate collection
# - instantiate wasm contract
junod tx wasm instantiate CODE_ID 'JSON_ENCODED_INIT_MESSAGE' --label LABEL_TEXT --gas auto --gas-adjustment 1.3 -b block --from KEY_WALLET_NAME_OR_ADDRESS --yes --no-admin
# ========================== nft module ==========================
# instantiate (issue) collection (denom_id)
# DENOM_ID must match this regex: ([a-z][a-zA-Z0-9/]{2,127})
iris tx nft issue DENOM_ID --symbol DENOM_SYMBOL --description "OPTIONAL_DESCRIPTION" --uri "OPTIONAL_OFFCHAIN_CLASS_METADATA_URI" --from $KEY_CREATOR_NAME -b block -y --mint-restricted=false --update-restricted=false --fees 20uiris

```

Example:

```sh
# ========================== wasm module ==========================
# uploading CW721 contract
# - search in output for code_id! this is needed for instantiation!
starsd tx wasm store ./cw721_base_v0.16.0.wasm --gas auto --gas-adjustment 1.3 -b block --output json --from $KEY_CREATOR_NAME --yes
# upload ICS721 contract
# - search in output for code_id! this is needed for instantiation!
# - in case of 'out of gas in location' error use '--gas-prices' option:
junod tx wasm store ./cw721_base_v0.16.0.wasm --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --output json --from $KEY_CREATOR_NAME --yes

# instantiate CW721, only required for wasm module
# - search in output for CW721's contract_address! Needed for execution and query on CW721 collection contract.
starsd tx wasm instantiate 803 '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq"}' --label ark-test-01 --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --no-admin

junod tx wasm instantiate 4232 '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md"}' --label ark-test-01 --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --no-admin

# instantiate ICS721 contract
junod tx wasm instantiate 4233 '{"CW721_base_code_id":4232}' --label ark-test-ICS721-pr44 --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --from $KEY_CREATOR_NAME --yes --no-admin

# query collection info
# - wasm module
# -- list all collection addresses for given code id
starsd query wasm list-contract-by-code 803
# -- metadata like admin, creator, label for given contract
starsd query wasm contract stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es
# -- contract info like name and symbol
starsd query wasm contract-state smart stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es '{"contract_info": {}}'

# ========================== nft module ==========================
# - instantiate/issue collection
iris tx nft issue ark/MyAwesomeCollection --symbol ark-awesome --description "you BETTER check this out" --uri "https://arkprotocol.io/" --from $KEY_CREATOR_NAME -b block -y --mint-restricted=false --update-restricted=false --fees 20uiris
# - query all collections
iris query nft denoms
# - specific query
iris query nft denom ark/MyAwesomeCollection
```

## Create an IBC Channel

Syntax:
```sh
# ========================== Hermes relayer ==========================
hermes --config config.toml create channel --a-chain A_CHAIN_ID --b-chain B_CHAIN_ID --a-port A_CHAIN_IBC_PORT_ID --b-port B_CHAIN_IBC_PORT_ID --new-client-connection --channel-version VERSION --yes
```

Example:

```sh
# ========================== hermes relayer ==========================
# create channel between 2 ICS721 contracts
# port id is: wasm.ICS_CONTRACT_ADDRESS, VERSION is defined in ICS721 contract
# - create channel with NEW connection
hermes --config config.toml create channel --a-chain uni-6 --b-chain elgafar-1 --a-port wasm.juno1agyzqtp8f5u2347sg48qav7l3zm4m0awpprzly5pvzdhd9a2pkqsu98aeh --b-port wasm.stars16teejyjpa4qpcha54eulxv9l3n5vv9ujw3wc263ctuqahxx5k3as52my82 --new-client-connection --channel-version ics721-1 --yes

# - query using CLI, search using port id for finding channel and counter part channel
starsd query ibc channel channels --limit 100 # also use --page for pagination
# - query using hermes
hermes --config config.toml query channels --chain uni-6

# ========================== nft module ==========================
# - create channel between nft module and ICS721
hermes --config config.toml create channel --a-chain $JUNO_CHAIN_ID --b-chain $IRIS_CHAIN_ID --a-port $JUNO_CONTRACT_ICS721_PORT --b-port $IRIS_CONTRACT_ICS721_PORT --new-client-connection --channel-version $ICS721_VERSION --yes
```

## Mint an NFT

Syntax:
```sh
# ========================== wasm module ==========================
starsd tx wasm execute CW721_CONTRACT '{"mint": {"token_id":"TOKEN_ID", "owner":"MINTTER_WALLET_ADDRESS", "token_uri":"OPTIONAL_TOKEN_URI"}}' --from test_minter --gas auto --gas-adjustment 1.3 -b sync --yes --output json # same commands for other CLIs like junod
# ========================== nft module ==========================
# - mint
iris tx nft mint DENOM_ID NFT_ID --uri=OFFCHAIN_METADATA_URI --recipient=NFT_WALLET_OR_KEY_NAME --from=SIGNER_WALLET_OR_KEY_NAME -y --fees 20uiris
```

Example:

```sh
# ========================== wasm module ==========================
# mint
# - starsd, in case NFT has already been minted an 'token_id already claimed' error is, in this case check below and query for number of tokens
starsd tx wasm execute stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es '{"mint": {"token_id":"20", "owner":"stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq"}}' --from test_minter --gas auto --gas-adjustment 1.3 -b sync --yes --output json

# - junod with --gas-prices option
junod tx wasm execute juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02  '{"mint": {"token_id": "1", "owner": "juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md", "token_uri": "https://arkprotocol.io/"}}' --from test_minter --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --yes --output json

# query
# - number of tokens
starsd query wasm contract-state smart stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es '{"num_tokens":{}}'
# - token info and owner
junod query wasm contract-state smart juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02 '{"all_nft_info":{"token_id": "1"}}'
# ========================== nft module ==========================
iris tx nft mint ark ark1 --uri=foo.bar --recipient $IRISNET_WALLET_MINTER --from $KEY_CREATOR_NAME -y --fees 20uiris
# - query all nfts
iris query nft collection ark
# - query specific nft
iris query nft token ark ark1
```

## IBC (Interchain) Transfer

Syntax:
```sh
# ========================== wasm module ==========================
starsd tx wasm execute CW721_COLLECTION_ADDR '{"send_nft": { "contract": "ICS721_CONTRACT", "token_id": "TOKEN_ID", "msg": "BASE64_ENCODED_JSON_MSG_FOR_ICS721"}}' --from test_minter --gas auto --gas-adjustment 1.3 -b block --yes
# ========================== nft module ==========================
iris tx nft-transfer transfer nft-transfer SOURCE_CHANNEL_ID TARGET_RECIPIENT DENOM_ID NFT_ID --from SIGNER_WALLET_OR_KEY_NAME -b block --fees 50uiris -y
```

NOTE: BASE64_ENCODED_JSON_MSG_FOR_ICS721 must be:
```json
// for timeout use highest block height for example
{ "receiver": "RECEIVER_WALLET_ADDRESS_ON_TARGET_CHAIN", "channel_id": "SOURCE_ICS721_CHANNEL", "timeout": { "block": { "revision": 1, "height": 3999999 } } }
```

Example:

```sh
# ========================== wasm module ==========================
# - send nft with token-id 1 from juno to stargaze via channel-508
junod tx wasm execute juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02 '{"send_nft": { "contract": "juno1agyzqtp8f5u2347sg48qav7l3zm4m0awpprzly5pvzdhd9a2pkqsu98aeh", "token_id": "1", "msg": "eyAicmVjZWl2ZXIiOiAic3RhcnMxZjB6Zm1haGQ5YzQzbm1wbGp4M2hlbDZoNWQ5dmw3Z3ozc3F2aHEiLCAiY2hhbm5lbF9pZCI6ICJjaGFubmVsLTUwOCIsICJ0aW1lb3V0IjogeyAiYmxvY2siOiB7ICJyZXZpc2lvbiI6IDEsICJoZWlnaHQiOiAzOTk5OTk5IH0gfSB9Cg=="}}' --from test_minter --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --yes
# - query and check NFT is locked/owned by ICS721 contract
junod query wasm contract-state smart juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02 '{"all_nft_info":{"token_id": "1"}}'
# - relay
hermes --config config.toml clear packets --chain uni-6 --channel channel-508 --port wasm.juno1agyzqtp8f5u2347sg48qav7l3zm4m0awpprzly5pvzdhd9a2pkqsu98aeh
# - query for CW721 contract on target ICS721
starsd query wasm contract-state smart stars16teejyjpa4qpcha54eulxv9l3n5vv9ujw3wc263ctuqahxx5k3as52my82 '{"nft_contract": {"class_id" : "wasm.stars16teejyjpa4qpcha54eulxv9l3n5vv9ujw3wc263ctuqahxx5k3as52my82/channel-130/juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02"}}'
# - query on cw271 whether it has been transferred on target chain
starsd query wasm contract-state smart stars1fxdn4dmkfk0v87d5s3n3hr2g5huhkmde6n4ye9ywwsc0he8ywgys673k7d '{"all_nft_info":{"token_id": "1"}}'

# ========================== nft module ==========================
# - transfer to nft module
iris tx nft-transfer transfer nft-transfer channel-13 juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md ark ark1 --from test_minter -b block --fees 50uiris -y
# - relay
hermes --config config.toml clear packets --chain iris-1 --channel channel-13 --port wasm.juno1mq7p6l5z3xl96c2fgn3ln2mxl0tq6tffp8ge4s3nsegz6chxuswqkkacv0

hermes --config config.toml clear packets --chain uni-6 --channel channel-509 --port nft-transfer
```

# FAQ

