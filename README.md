# Ark Protocol

> Ark Protocol’s mission is to build multi-chain NFT utilities that can be used by ANY collection on ANY chain at ANY time,
> using the Inter-Blockchain Communication protocol (IBC) to enable the transfer of NFTs between different blockchains and
> allowing smart contracts to access utilities on other chains.

Official Links:
- [arkprotocol.io](https://arkprotocol.io/)
- [Twitter](https://twitter.com/ArkProtocol)
- [Discord](https://discord.gg/fVv6Mf9Wr8)

In case of support:
- best way is joining our discord (invite above) and go to [ibc-ics-support channel](https://discord.com/channels/974384596684791828/1040388398382321795)
- regarding this document use [discussions on GitHub](https://github.com/arkprotocol/ics721-demo/discussions)
- in case of changes please file an [issue on GitHub](https://github.com/arkprotocol/ics721-demo/issues)

Higly recommended: Do you wonder why it is possible by transferring 2 NFTs to the same target chain, may end up into two different collections? Well, then you should read our ["Building Multi-Chain NFT Utilities" blog](https://arkprotocol.substack.com/p/nfts-and-utilities-going-multi-chain). In the second part of this post, it explains in detail how ICS721 works.

# How-To Send NFTs to Another Chain Using ICS721

This is quick how-to for testing ICS721 on these 4 testnets: Stargaze, Juno, IRISnet and Uptick. Stargaze and Juno support CosmWasm. Both are using the ICS721 contract, while IRISnet and Uptick are using the NFT module for interchain NFT transfers.

Below you will also find a quick setup guide for:

- installing CLIs (command line interfaces) to interact with contracts: `starsd`, `junod`, `iris`, and `uptickd`
- installing Hermes relayer to handle messages (packets) between chains

You will be able to use CLIs for transferring an NFT from a source chain to a target chain. For this ICS721 testing it requires setting up a wallet for:

- test admin: owning ICS721 and CW721 (collection) contract
- test creator: wallet eligible to mint on CW721 collection contract
- test minter: wallet receiving NFTs from mint or ICS721 transfer

Relayers also interact and execute transactions on each chains for sending packets. In this case a relayer also needs a key/wallet for each chain.

All CLIs have the same key commands. There are certain specifics on each CLI - but not needed here.p

# Setup

## Wallets, Mnemonics, Contracts

For quick testing and not setting up all on your own, below wallets with test tokens contracts can be used.

### Mnemonics

These mnemonics are being used for all wallets on each chain:

test_creator:
stay filter slight agree priority urban act manual brown long journey dumb glory roast actual dumb claim fabric solution subject soft trip close rubber

test_minter:
erase kick merry stumble spawn leaf unique aerobic else rare judge bind six accident nominee will glimpse session detail drum runway calm alley cupboard

test_relayer:
scale alter grace come maze rug school math faint lawsuit auction wheat tribe hand cricket garbage boil utility eager dutch strategy grocery convince bone

### Wallets

Stargaze:
- creator: stars192meglgpmt5pdz45wv6qgd5apfuxy9u5jfq7e6
- minter: stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq
- relayer: stars1lc492y067qn2txqzhya7uecj8hn02sdc2dutaf

Juno:
- creator: juno192meglgpmt5pdz45wv6qgd5apfuxy9u5s85c4h
- minter: juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md
- relayer: juno1lc492y067qn2txqzhya7uecj8hn02sdcgrgd3y

IRISnet:
- creator: iaa192meglgpmt5pdz45wv6qgd5apfuxy9u5nhhjs6
- minter: iaa1f0zfmahd9c43nmpljx3hel6h5d9vl7gzswhq7q
- relayer: iaa1lc492y067qn2txqzhya7uecj8hn02sdctnt85f

Uptick:
- creator: uptick15j5hrlxkvv7meew85s9w9rnmamnll2hsdatzdw
- minter: uptick1hz93x4fyetrrteaucsazaxl2q2jfmjp6gx2747
- relayer: uptick1nlrntuydkq7dte8fenlu3e4zenmqhkluhl6hay

Omniflixhub:
- creator: omniflix192meglgpmt5pdz45wv6qgd5apfuxy9u5mtx694
- minter: omniflix1f0zfmahd9c43nmpljx3hel6h5d9vl7gzcjxgt0
- relayer: omniflix1lc492y067qn2txqzhya7uecj8hn02sdcr060px


### Contracts

Stargaze:
- CW721: code id `803`, ark test collection address `stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es`
- ICS721: code id `804`, address `stars16teejyjpa4qpcha54eulxv9l3n5vv9ujw3wc263ctuqahxx5k3as52my82`

Juno:
- CW721: code id `116`, ark test collection address `juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02`
- ICS721: code id `117`, address `juno1tu78n53x26egjjadshq5dnynghuza7kxs5m9k9clau6807jtrrmqzc88ye`

## Install CLIs

Read this for detailed installation:
- https://docs.stargaze.zone/nodes-and-validators/getting-setup#build-stargaze-from-source
- https://docs.junonetwork.io/validators/getting-setup
- https://www.irisnet.org/docs/get-started/install.html
- https://docs.uptick.network/quickstart/installation.html

Make sure checking out the correct cli version for using on testnet:
- Stargaze: 8.0.0-rc.1
- Juno: v10.0.0 or higher
- IRISnet: v1.1.1
- Uptick: v0.2.4

Stargaze:
```sh
git clone https://github.com/public-awesome/stargaze
cd stargaze
git fetch
# make sure correct version is checked out for testnet
git checkout 8.0.0-rc.1
make install
# check uptickd CLI is working:
starsd version # HEAD-3d1e40d0d42b420ac02c624a2d6e8225c0b5991b
# config
starsd config chain-id elgafar-1
starsd config node https://rpc.elgafar-1.stargaze-apis.com:443
starsd config broadcast-mode block
# show and check config
starsd config
```

Juno:
```sh
git clone https://github.com/CosmosContracts/juno
cd juno
git fetch
# make sure correct version is checked out for testnet
git checkout v10.0.0
make install
# check uptickd CLI is working:
junod version # v10.0.0
# config
junod config chain-id uni-6
junod config node https://rpc.uni.junonetwork.io:443
junod config broadcast-mode block
# show and check config
junod config
```

IRISnet:
```sh
git clone https://github.com/irisnet/irishub
cd irishub
# make sure correct version is checked out for testnet
git checkout feature/gon
make install
# check uptickd CLI is working:
iris version # 1.4.1-26-g0ac92bcb


# config
iris config chain-id iris-1
iris config node http://34.145.1.166:26657
iris config broadcast-mode block
# show and check config
iris config

```

Uptick:
```sh
git clone https://github.com/UptickNetwork/uptick.git
cd uptick/
# make sure correct version is checked out for testnet
git checkout v0.2.4
make install
# check uptickd CLI is working:
uptickd version # HEAD-3d1e40d0d42b420ac02c624a2d6e8225c0b5991b
# config
uptickd config chain-id uptick_7000-1
uptickd config node http://52.74.190.214:26657
uptickd config broadcast-mode block
# show and check config
uptickd config
```

Onmiflixhub
```sh
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub
git checkout v0.8.0
go mod tidy
make install
# check omniflixhubd CLI is working:
omniflixhubd version # 0.8.0
# config
omniflixhubd config chain-id gon-flixnet-1
omniflixhubd config node http://65.21.93.56:26657
omniflixhubd config broadcast-mode block
# show and check config
omniflixhubd config

```

## Create Wallet

Create two wallets: one for creator and one for minter:

```sh
starsd keys add test_creator
# test_creator wallet: stars192meglgpmt5pdz45wv6qgd5apfuxy9u5jfq7e6
# backup in output your mnemonic phrase, for testing same mnemonic will used on other chain!
# mnemonic for test_creator: stay filter slight agree priority urban act manual brown long journey dumb glory roast actual dumb claim fabric solution subject soft trip close rubber

starsd keys add test_minter
# test_minter wallet: stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq
# mnemonic for test_minter: erase kick merry stumble spawn leaf unique aerobic else rare judge bind six accident nominee will glimpse session detail drum runway calm alley cupboard

starsd keys add test_relayer
# test_relayer wallet: stars1lc492y067qn2txqzhya7uecj8hn02sdc2dutaf
# mnemonic: scale alter grace come maze rug school math faint lawsuit auction wheat tribe hand cricket garbage boil utility eager dutch strategy grocery convince bone

```
## faucets 
Now get some test STARS tokens:
- join Stargaze discord: https://discord.gg/stargaze
- go to faucet channel: https://discord.com/channels/755548171941445642/940653213022031912

In faucet channel enter:
```sh
$request stars192meglgpmt5pdz45wv6qgd5apfuxy9u5jfq7e6 # replace with test creator wallet address
$request stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq # replace with test minter wallet address
$request stars1lc492y067qn2txqzhya7uecj8hn02sdc2dutaf # replace with test relayer wallet address
```

Now check whether above 3 wallets has funds using CLI:

```sh
starsd query bank balances stars192meglgpmt5pdz45wv6qgd5apfuxy9u5jfq7e6 # output amount is 10000000000 ustars
starsd query bank balances stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq # output amount is 10000000000 ustars
starsd query bank balances stars1lc492y067qn2txqzhya7uecj8hn02sdc2dutaf # output amount is 10000000000 ustars
```

NOTE: 10000000000 ustars is 10'000 STARS!

For Juno use same mnemonic and follow same steps as above. Faucets can be requested either via site or faucet channel on discord:
- site: https://test.juno.tools/request-tokens/
- discord invite: https://discord.gg/juno
- faucet channel: https://discord.com/channels/816256689078403103/842073995059003422

Use same mnemonic for recovering wallets for Juno, IRISnet and Uptick:

```sh
# ---- Juno
# test_creator: juno192meglgpmt5pdz45wv6qgd5apfuxy9u5s85c4h
junod keys add test_creator --recover # you will be prompted for entering your mnemonic
# test_minter: juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md
junod keys add test_minter --recover
# test relayer: juno1lc492y067qn2txqzhya7uecj8hn02sdcgrgd3y
junod keys add test_relayer --recover

# ---- IRISnet
# test_creator: iaa192meglgpmt5pdz45wv6qgd5apfuxy9u5nhhjs6
iris keys add test_creator --recover # you will be prompted for entering your mnemonic
# test_minter: iaa1f0zfmahd9c43nmpljx3hel6h5d9vl7gzswhq7q
iris keys add test_minter --recover
# test relayer: iaa1lc492y067qn2txqzhya7uecj8hn02sdctnt85f
iris keys add test_relayer --recover

# ---- Uptick
# test_creator: uptick15j5hrlxkvv7meew85s9w9rnmamnll2hsdatzdw
uptickd keys add test_creator --recover # you will be prompted for entering your mnemonic
# test_minter: uptick1hz93x4fyetrrteaucsazaxl2q2jfmjp6gx2747
uptickd keys add test_minter --recover
# test relayer: uptick1nlrntuydkq7dte8fenlu3e4zenmqhkluhl6hay
uptickd keys add test_relayer --recover
```

Now get some test JUNOX (Juno tokens are called JUNOX on testnet), NYAN and UPTICK tokens:
- join IRISnet discord: https://discord.gg/ZYNhsmjbmu
- go to faucet channel: https://discord.com/channels/806356514973548614/820953811434471494

In faucet channel enter:
```sh
$faucet iaa192meglgpmt5pdz45wv6qgd5apfuxy9u5nhhjs6 # replace with test creator wallet address
$faucet iaa1f0zfmahd9c43nmpljx3hel6h5d9vl7gzswhq7q # replace with test minter wallet address
# IRISnet allows only 2 request per day, so wait another day, or send funds from creator to relayer wallet
$faucet iaa1lc492y067qn2txqzhya7uecj8hn02sdctnt85f
```


- join Uptick discord: https://discord.gg/MVU8h6tXAF
- go to faucet channel: https://discord.com/channels/781005936260939818/953652276508119060

In faucet channel enter:
```sh
$faucet uptick15j5hrlxkvv7meew85s9w9rnmamnll2hsdatzdw # replace with test creator wallet address
# Uptick allows only 1 request per day, so wait another day, or send funds from creator wallet
$faucet uptick1hz93x4fyetrrteaucsazaxl2q2jfmjp6gx2747 # replace with test minter wallet address

Juno faucet 
https://test.juno.tools/request-tokens/
```

Now check whether above 3 wallets has funds using CLI:

```sh
# --- iris
iris query bank balances iaa192meglgpmt5pdz45wv6qgd5apfuxy9u5nhhjs6 --node http://34.145.1.166:26657
# note: 100000000unyan is 100 NYAN!
iris query bank balances iaa1f0zfmahd9c43nmpljx3hel6h5d9vl7gzswhq7q --node http://34.145.1.166:26657
iris query bank balances iaa1lc492y067qn2txqzhya7uecj8hn02sdctnt85f --node http://34.145.1.166:26657
# optional: transfer funds to relayer wallet
iris tx bank send iaa192meglgpmt5pdz45wv6qgd5apfuxy9u5nhhjs6 iaa1lc492y067qn2txqzhya7uecj8hn02sdctnt85f 50000000unyan -y --node http://34.145.1.166:26657 --chain-id nyancat-9 --fees 400unyan

# --- uptick
uptickd query bank balances uptick15j5hrlxkvv7meew85s9w9rnmamnll2hsdatzdw # output amount is 5000000000000000000 auptick
uptickd query bank balances uptick1hz93x4fyetrrteaucsazaxl2q2jfmjp6gx2747
uptickd query bank balances uptick1nlrntuydkq7dte8fenlu3e4zenmqhkluhl6hay
# optional: transfer funds to minter and relayer wallet
uptickd tx bank send uptick15j5hrlxkvv7meew85s9w9rnmamnll2hsdatzdw uptick1hz93x4fyetrrteaucsazaxl2q2jfmjp6gx2747 2500000000000000000auptick -y
uptickd tx bank send uptick15j5hrlxkvv7meew85s9w9rnmamnll2hsdatzdw uptick1nlrntuydkq7dte8fenlu3e4zenmqhkluhl6hay 1000000000000000000auptick -y
```

NOTE: 5000000000000000000 auptick is 5 UPTICK!


## Build and Upload Contracts

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
starsd tx wasm store ./CW721_base_v0.16.0.wasm --gas auto --gas-adjustment 1.3 -b block --output json --from test_creator --yes
# find stored contract's code_id in output: {"height":"2964307", ... {\"key\":\"code_id\",\"value\":\"803\"}]} ...}
# instantiate collection based on instantiate msg: https://github.com/CosmWasm/cw-nfts/blob/v0.16/contracts/CW721-base/src/msg.rs#L6-L16
starsd tx wasm instantiate 803 '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq"}' --label ark-test-01 --gas auto --gas-adjustment 1.3 -b block --from test_creator --yes --admin stars192meglgpmt5pdz45wv6qgd5apfuxy9u5jfq7e6
# find instantiated contract in output: raw_log: '[{"events"... {"key":"_contract_address","value":"stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es"} ...]
# test collection and query for number of NFTs (result count should be 0)
starsd query wasm contract-state smart stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es '{"num_tokens":{}}' # count: 0

# same for juno
# - upload
junod tx wasm store ./cw721_base_v0.16.0.wasm --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --output json --from test_creator --yes # code id 116
# - instantiate
junod tx wasm instantiate 116 '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md"}' --label ark-test-01 --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --from test_creator --yes --admin juno192meglgpmt5pdz45wv6qgd5apfuxy9u5s85c4h # adress juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02
junod query wasm contract-state smart juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02 '{"num_tokens":{}}' # count: 0

```

Build and upload ICS721 contract:

```sh
git clone https://github.com/public-awesome/ICS721/
cd ICS721
git checkout 3af19e421a95aec5291a0cabbe796c58698ac97f # latest PR44
./ts-relayer-tests/build.sh
cp ./artifacts/cw_ICS721_bridge.wasm cw_ICS721_bridge_pr44.wasm
starsd tx wasm store ./cw_ics721_bridge_pr44.wasm  --gas auto --gas-adjustment 1.3 -b block --output json --from test_creator --yes
# find contract's code_id in output: {"height":"2965732", ... {"key":"code_id","value":"804"} ...}
# instantiate based on instantiate msg: https://github.com/public-awesome/ICS721/blob/3af19e421a95aec5291a0cabbe796c58698ac97f/contracts/cw-ICS721-bridge/src/msg.rs#L17
starsd tx wasm instantiate 804 '{"CW721_base_code_id":803}' --label ark-test-ICS721-pr44 --gas auto --gas-adjustment 1.3 -b block --from test_creator --yes --admin stars192meglgpmt5pdz45wv6qgd5apfuxy9u5jfq7e6
# find instantiated contract in output: raw_log: '[{"events"... {"key":"_contract_address","value":"stars16teejyjpa4qpcha54eulxv9l3n5vv9ujw3wc263ctuqahxx5k3as52my82"} ...]
# test query on ICS721
starsd query wasm contract-state smart stars16teejyjpa4qpcha54eulxv9l3n5vv9ujw3wc263ctuqahxx5k3as52my82 '{"nft_contract":{"class_id":""}}' # data: null

# juno
# - upload
junod tx wasm store ./cw_ICS721_bridge_pr44.wasm --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --output json --from test_creator --yes # code id 117
# - instantiate
junod tx wasm instantiate 117 '{"cw721_base_code_id":117}' --label ark-test-ICS721-pr44 --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --from test_creator --yes --admin juno192meglgpmt5pdz45wv6qgd5apfuxy9u5s85c4h # address juno1tu78n53x26egjjadshq5dnynghuza7kxs5m9k9clau6807jtrrmqzc88ye
junod query wasm contract-state smart juno1tu78n53x26egjjadshq5dnynghuza7kxs5m9k9clau6807jtrrmqzc88ye '{"nft_contract":{"class_id":""}}' # data: null

```

## Relayer Setup

Hermes:
- installation here: https://hermes.informal.systems/quick-start/installation.html
- config.toml provided here with all chains and channels for Stargaze, Juno, IRISnet and Uptick

```sh
# restore relayer wallets for hermes
hermes --config config.toml keys add --chain elgafar-1 --mnemonic-file ./relayer-mnemonic # stars1lc492y067qn2txqzhya7uecj8hn02sdc2dutaf
hermes --config config.toml keys add --chain uni-6 --mnemonic-file ./relayer-mnemonic # juno1lc492y067qn2txqzhya7uecj8hn02sdcgrgd3y
hermes --config config.toml keys add --chain uptick_7000-1 --mnemonic-file ./relayer-mnemonic # uptick150htnyf53qsq3z5kmpzwnrp9zq3gmkgdz8hn5f
hermes --config config.toml keys add --chain iris-1 --mnemonic-file ./relayer-mnemonic # iaa1lc492y067qn2txqzhya7uecj8hn02sdctnt85f
hermes --config config.toml keys add --chain gon-flixnet-1 --mnemonic-file ./relayer-mnemonic # iaa1lc492y067qn2txqzhya7uecj8hn02sdctnt85f
```

Starting hermes

```sh
hermes --config config.toml start # from the directory the config is located

# wait a until hermes is running; this can take a while
# 2023-01-20T12:59:56.811226Z  INFO ThreadId(01) Hermes has started
```

# Commands for Testing

Here's a list of commands that is required:

- Create and recover keys (wallets)
- Upload and instantiate collection (CW721, nft module) and ICS721 contracts
- Create an IBC channel
- Mint an NFT
- IBC (interchain) transfer
- Relay channels

CLIs has a `--help` flag. So you can always use `starsd keys --help` or `uptickd keys add --help` for subcommands.

## Create and Recover Keys (Wallets)

Syntax:
```sh
starsd keys add KEY_NAME [flags] # same commands for other CLIs like junod, uptickd and iris
```

Example:

```sh
# create new wallet with name test_creator
starsd keys add test_creator # MNEMONIC will returned, pls backup!
# recover a wallet
uptickd keys add test_creator --recover # prompts for mnemonic!
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
iris tx nft issue DENOM_ID --symbol DENOM_SYMBOL --description "OPTIONAL_DESCRIPTION" --uri "OPTIONAL_OFFCHAIN_CLASS_METADATA_URI" --from test_creator -b block -y --mint-restricted=false --update-restricted=false --fees 20uiris

```

Example:

```sh
# ========================== wasm module ==========================
# uploading CW721 contract
# - search in output for code_id! this is needed for instantiation!
starsd tx wasm store ./cw721_base_v0.16.0.wasm --gas auto --gas-adjustment 1.3 -b block --output json --from test_creator --yes
# upload ICS721 contract
# - search in output for code_id! this is needed for instantiation!
# - in case of 'out of gas in location' error use '--gas-prices' option:
junod tx wasm store ./cw721_base_v0.16.0.wasm --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --output json --from test_creator --yes

# instantiate CW721, only required for wasm module
# - search in output for CW721's contract_address! Needed for execution and query on CW721 collection contract.
starsd tx wasm instantiate 803 '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq"}' --label ark-test-01 --gas auto --gas-adjustment 1.3 -b block --from test_creator --yes --no-admin

junod tx wasm instantiate 4232 '{"name":"ark test collection", "symbol":"ark-test-01", "minter":"juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md"}' --label ark-test-01 --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --from test_creator --yes --no-admin

# instantiate ICS721 contract
junod tx wasm instantiate 4233 '{"CW721_base_code_id":4232}' --label ark-test-ICS721-pr44 --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --from test_creator --yes --no-admin

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
iris tx nft issue ark/MyAwesomeCollection --symbol ark-awesome --description "you BETTER check this out" --uri "https://arkprotocol.io/" --from test_creator -b block -y --mint-restricted=false --update-restricted=false --fees 20uiris
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
hermes --config config.toml create channel --a-chain uni-6 --b-chain elgafar-1 --a-port wasm.juno1tu78n53x26egjjadshq5dnynghuza7kxs5m9k9clau6807jtrrmqzc88ye --b-port wasm.stars16teejyjpa4qpcha54eulxv9l3n5vv9ujw3wc263ctuqahxx5k3as52my82 --new-client-connection --channel-version ics721-1 --yes

# - query using CLI, search using port id for finding channel and counter part channel
starsd query ibc channel channels --limit 100 # also use --page for pagination
# - query using hermes
hermes --config config.toml query channels --chain uni-6

# ========================== nft module ==========================
# - create channel between nft module and ICS721
hermes --config config.toml create channel --a-chain uni-6 --b-chain iris-1 --a-port wasm.juno1tu78n53x26egjjadshq5dnynghuza7kxs5m9k9clau6807jtrrmqzc88ye --b-port nft-transfer --new-client-connection --channel-version ics721-1 --yes
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
# - starsd
starsd tx wasm execute stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es '{"mint": {"token_id":"20", "owner":"stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq"}}' --from test_minter --gas auto --gas-adjustment 1.3 -b sync --yes --output json

# - junod with --gas-prices option
junod tx wasm execute juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02  '{"mint": {"token_id": "1", "owner": "juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md", "token_uri": "https://arkprotocol.io/"}}' --from test_minter --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --yes --output json

# query
# - number of tokens
starsd query wasm contract-state smart stars1rngd33njs2cjzpneejx4q5z3cagxl57a85838xmc0uy82wrg7dssdvy9es '{"num_tokens":{}}'
# - token info and owner
junod query wasm contract-state smart juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02 '{"all_nft_info":{"token_id": "1"}}'
# ========================== nft module ==========================
iris tx nft mint ark ark1 --uri=foo.bar --recipient=iaa1f0zfmahd9c43nmpljx3hel6h5d9vl7gzswhq7q --from=test_creator -y --fees 20uiris
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
# - send nft from juno to stargaze
junod tx wasm execute juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02 '{"send_nft": { "contract": "juno1tu78n53x26egjjadshq5dnynghuza7kxs5m9k9clau6807jtrrmqzc88ye", "token_id": "1", "msg": "eyAicmVjZWl2ZXIiOiAic3RhcnMxZjB6Zm1haGQ5YzQzbm1wbGp4M2hlbDZoNWQ5dmw3Z3ozc3F2aHEiLCAiY2hhbm5lbF9pZCI6ICJjaGFubmVsLTUwOCIsICJ0aW1lb3V0IjogeyAiYmxvY2siOiB7ICJyZXZpc2lvbiI6IDEsICJoZWlnaHQiOiAzOTk5OTk5IH0gfSB9"}}' --from test_minter --gas-prices 0.1ujunox --gas auto --gas-adjustment 1.3 -b block --yes
# - query and check NFT is locked/owned by ICS721 contract
junod query wasm contract-state smart juno16gfchrhfrds40dtda32a75c7hs5hvylq577cqm7kmnj9g006w20qewek02 '{"all_nft_info":{"token_id": "1"}}'
# - relay
hermes --config config.toml clear packets --chain uni-6 --channel channel-508 --port wasm.juno1tu78n53x26egjjadshq5dnynghuza7kxs5m9k9clau6807jtrrmqzc88ye
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

