# Setup CLIs

Here's a quick guide for setting up CLIs for these chains (chain - `cli name`):
- Stargaze - `starsd`
- Juno - `junod`
- Omosis - `osmosisd`
- IRISnet - `iris`
- Uptick - `uptickd`
- OmniFlix - `omniflixhubd`
- Teritori - `teritorid`

For quick testing all environment variables are defined in [ics721-demo.env](ics721-demo.env). Call this command for setting these variables in your shell: `source ./ics721-demo.env`. It contains:

- wallets including test tokens
- cw721 and ics721 (contracts, code ids)
- CLI settings (chain-id, node, keys, mnemonics)

# Install CLIs

Read this for detailed installation:
- https://docs.stargaze.zone/nodes-and-validators/getting-setup#build-stargaze-from-source
- https://docs.junonetwork.io/validators/getting-setup
- https://docs.osmosis.zone/osmosis-core/osmosisd
- https://www.irisnet.org/docs/get-started/install.html
- https://docs.uptick.network/quickstart/installation.html
- https://github.com/omniflix/omniflixhub#installation
- https://teritori.gitbook.io/teritori-whitepaper/join-teritori-testnet#step-3.-get-cosmos-sdk-and-build-teritorid
- https://docs.kujira.app/validators/run-a-node
- https://docs.terra.money/develop/terrad/install-terrad

Make sure checking out the correct cli version for using on testnet:
- Stargaze: 8.0.0-rc.1
- Juno: v10.0.0 or higher
- Osmosis: v13.0.0-rc5-testnet or higher
- IRISnet: v1.1.1
- Uptick: v0.2.4
- OmniFlix: v0.9.0-gon-rc5

Stargaze:
```sh
git clone https://github.com/public-awesome/stargaze
cd stargaze
git fetch
# make sure correct version is checked out for testnet
git checkout 8.0.0-rc.1
make install
# check CLI is working:
starsd version # HEAD-3d1e40d0d42b420ac02c624a2d6e8225c0b5991b
# config
starsd config chain-id $GON_STARGAZE_CHAIN_ID
starsd config node $GON_STARGAZE_CHAIN_NODE
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
# check CLI is working:
junod version # v10.0.0
# config
junod config chain-id $GON_JUNO_CHAIN_ID
junod config node $GON_JUNO_CHAIN_NODE
junod config broadcast-mode block
# show and check config
junod config
```

Omosis:
```sh
git clone https://github.com/osmosis-labs/osmosis
cd osmosis
git fetch
# make sure correct version is checked out for testnet
git checkout v13.0.0-rc5-testnet
make install
# check CLI is working:
osmosisd version # v13.0.0-rc5-testnet
# config
osmosisd config chain-id $GON_OSMOSIS_CHAIN_ID
osmosisd config node $GON_OSMOSIS_CHAIN_NODE
osmosisd config broadcast-mode block
# show and check config
osmosisd config
```

IRISnet:
```sh
git clone https://github.com/irisnet/irishub
cd irishub
# make sure correct version is checked out for testnet
git checkout feature/gon
make install
# check CLI is working:
iris version # 1.4.1-26-g0ac92bcb


# config
iris config chain-id $GON_IRISNET_CHAIN_ID
iris config node $GON_IRISNET_CHAIN_NODE
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
# check CLI is working:
uptickd version # HEAD-3d1e40d0d42b420ac02c624a2d6e8225c0b5991b
# config
uptickd config chain-id $GON_UPTICK_CHAIN_ID
uptickd config node $GON_UPTICK_CHAIN_NODE
uptickd config broadcast-mode block
# show and check config
uptickd config
```

Omniflixhub
```sh
git clone https://github.com/Omniflix/omniflixhub.git
cd omniflixhub
git checkout v0.9.0-gon-rc5
go mod tidy
make install
# check omniflixhubd CLI is working:
omniflixhubd version # 0.9.0-gon-rc5
# config
omniflixhubd config chain-id $GON_OMNIFLIX_CHAIN_ID
omniflixhubd config node $GON_OMNIFLIX_CHAIN_NODE
omniflixhubd config broadcast-mode block
# show and check config
omniflixhubd config

```

Teritori
```sh
git clone https://github.com/TERITORI/teritori-chain.git
cd  teritori-chain/
git checkout teritori-testnet-v3
make install
# check CLI is working:
teritorid version
# config
teritorid config chain-id $GON_TERITORI_CHAIN_ID
teritorid config node $GON_TERITORI_CHAIN_NODE
teritorid config broadcast-mode block
# show and check config
teritorid config
```

Kujira
```sh
git clone https://github.com/Team-Kujira/core kujira-core
cd kujira-core
git checkout v0.6.4
make install
# check CLI is working:
kujirad version
# config
kujirad config chain-id $GON_KUJIRA_CHAIN_ID
kujirad config node $GON_KUJIRA_CHAIN_NODE
kujirad config broadcast-mode block
# show and check config
kujirad config

```

Terra
Endpoints: https://docs.terra.money/develop/endpoints/
```sh
git clone https://github.com/terra-money/core terra-core
cd terra-core
git checkout v2.2.0
make install
# check CLI is working:
terrad version
# config, since terrad has no config command, client.toml needs to be edited directly!
sed -i 's/chain-id = ".*"/chain-id = "pisco-1"/' ~/.terra/config/client.toml
sed -i 's/node = ".*"/node = "https:\/\/terra-rpc.polkachu.com:443"/' ~/.terra/config/client.toml
sed -i 's/broadcast-mode = ".*"/broadcast-mode = "block"/' ~/.terra/config/client.toml
# show and check config
tail ~/.terra/config/client.toml

```

# Create Keyrings (Wallets) and Fund With Tokens Using Faucet

## Stargaze

Create 3 wallets: creator, minter and relayer wallet

```sh
# create new wallets
starsd keys add $GON_KEY_CREATOR_NAME # backup in output your mnemonic phrase, for ease of testing same mnemonic may be used for other chains as well!
starsd keys add $GON_KEY_MINTER_NAME
starsd keys add $GON_KEY_RELAYER_NAME

# recover wallet using mnemonic
cat ./creator.mnemonic|starsd keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|starsd keys add $GON_KEY_MINTER_NAME --recover
cat ./relayer.mnemonic|starsd keys add $GON_KEY_RELAYER_NAME --recover

```

Now fund these wallets and get some test STARS tokens:
- join Stargaze discord: https://discord.gg/stargaze
- go to faucet channel: https://discord.com/channels/755548171941445642/940653213022031912

In faucet channel enter:
```sh
$request GON_STARGAZE_WALLET_CREATOR # replace with test creator wallet address
$request GON_STARGAZE_WALLET_MINTER # replace with test minter wallet address
$request GON_STARGAZE_WALLET_RELAYER # replace with test relayer wallet address
```

Verify whether above 3 wallets has funds using CLI:

```sh
starsd query bank balances $GON_STARGAZE_WALLET_CREATOR # output amount is 10000000000 ustars
starsd query bank balances $GON_STARGAZE_WALLET_MINTER # output amount is 10000000000 ustars
starsd query bank balances $GON_STARGAZE_WALLET_RELAYER # output amount is 10000000000 ustars
```

NOTE: 10000000000 ustars is 10'000 STARS!

## Juno

For Juno use same mnemonic and follow same steps as above. Faucets can be requested either via site or faucet channel on discord:

- use site: https://test.juno.tools/request-tokens/
- alternative use discord
  - invite: https://discord.gg/juno
  - faucet channel: https://discord.com/channels/816256689078403103/842073995059003422

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
# recover wallet using mnemonic
cat ./creator.mnemonic|junod keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|junod keys add $GON_KEY_MINTER_NAME --recover
cat ./relayer.mnemonic|junod keys add $GON_KEY_RELAYER_NAME --recover
```

Now get some test JUNOX (Juno tokens are called JUNOX on testnet): https://test.juno.tools/request-tokens/

Check whether above 3 wallets has funds using CLI:

```sh
junod query bank balances $GON_JUNO_WALLET_CREATOR
junod query bank balances $GON_JUNO_WALLET_MINTER
junod query bank balances $GON_JUNO_WALLET_RELAYER
```

## Osmosis

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
# recover wallet using mnemonic
cat ./creator.mnemonic|osmosisd keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|osmosisd keys add $GON_KEY_MINTER_NAME --recover
cat ./relayer.mnemonic|osmosisd keys add $GON_KEY_RELAYER_NAME --recover
```

Now get some test OSMO:
- use site: https://faucet.osmosis.zone
- alternative use discord
  - invite: https://discord.gg/osmosis
  - faucet channel: https://discord.com/channels/798583171548840026/911309363464007741


Check whether above 3 wallets has funds using CLI:

```sh
osmosisd query bank balances $GON_OSMOSIS_WALLET_CREATOR
osmosisd query bank balances $GON_OSMOSIS_WALLET_MINTER
osmosisd query bank balances $GON_OSMOSIS_WALLET_RELAYER
```

## IRISnet

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
cat ./creator.mnemonic|iris keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|iris keys add $GON_KEY_MINTER_NAME --recover
cat ./relayer.mnemonic|iris keys add $GON_KEY_RELAYER_NAME --recover
```

Get some test NYAN tokens:
- join IRISnet discord: https://discord.gg/ZYNhsmjbmu
- go to faucet channel: https://discord.com/channels/806356514973548614/820953811434471494

In faucet channel enter:
```sh
$faucet iaa192meglgpmt5pdz45wv6qgd5apfuxy9u5nhhjs6 # replace with test creator wallet address
$faucet iaa1f0zfmahd9c43nmpljx3hel6h5d9vl7gzswhq7q # replace with test minter wallet address
# IRISnet allows only 2 request per day, so wait another day, or send funds from creator to relayer wallet
$faucet iaa1lc492y067qn2txqzhya7uecj8hn02sdctnt85f
```

Check whether above 3 wallets has funds using CLI:

```sh
iris query bank balances $GON_IRISNET_WALLET_CREATOR
iris query bank balances $GON_IRISNET_WALLET_MINTER
iris query bank balances $GON_IRISNET_WALLET_RELAYER
# optional: transfer funds to relayer wallet
iris tx bank send $GON_IRISNET_WALLET_CREATOR $GON_IRISNET_WALLET_RELAYER 5000000uiris -y --fees 20uiris # send 5 IRIS tokens
```

NOTE: 1,000,000uiris is 1 IRIS!

## Uptick

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
cat ./creator.mnemonic|uptickd keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|uptickd keys add $GON_KEY_MINTER_NAME --recover
# Hermes uses default HD Path 118 as defined by Cosmos Hub
cat ./relayer.mnemonic|uptickd keys add $GON_KEY_RELAYER_NAME --hd-path "m/44'/118'/0'/0/0" --recover
```

- join Uptick discord: https://discord.gg/MVU8h6tXAF
- go to faucet channel: https://discord.com/channels/781005936260939818/953652276508119060

In faucet channel enter:
```sh
$faucet uptick15j5hrlxkvv7meew85s9w9rnmamnll2hsdatzdw # replace with test creator wallet address
# Uptick allows only 1 request per day, so wait another day, or send funds from creator wallet
$faucet uptick1hz93x4fyetrrteaucsazaxl2q2jfmjp6gx2747 # replace with test minter wallet address

```

Check whether above 3 wallets has funds using CLI:

```sh
uptickd query bank balances $GON_UPTICK_WALLET_CREATOR
uptickd query bank balances $GON_UPTICK_WALLET_MINTER
uptickd query bank balances $GON_UPTICK_WALLET_RELAYER
# optional: transfer funds to minter and relayer wallet
uptickd tx bank send $GON_UPTICK_WALLET_CREATOR $GON_UPTICK_WALLET_MINTER 2500000000000000000auptick -y
uptickd tx bank send $GON_UPTICK_WALLET_CREATOR $GON_UPTICK_WALLET_RELAYER 1000000000000000000auptick -y
```

NOTE: 1,000,000,000,000,000,000 auptick is 1 UPTICK!

## OmniFlix

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
cat ./creator.mnemonic|omniflixhubd keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|omniflixhubd keys add $GON_KEY_MINTER_NAME --recover
cat ./relayer.mnemonic|omniflixhubd keys add $GON_KEY_RELAYER_NAME --recover
```

OmniFlix faucet
   - Claim flix tokens on $GON_OMNIFLIX_CHAIN_ID
   ```
    # url
    https://faucet.gon-flixnet.omniflix.io/?address=<omniflix-account-address>

    # using curl
    curl -s https://faucet.gon-flixnet.omniflix.io/?address=$GON_OMNIFLIX_WALLET_RELAYER # replace with env key defined in ./ics721-demo.env
   ```
   - Check balance
    ```sh
    omniflixhubd q bank balances $GON_OMNIFLIX_WALLET_CREATOR # replace with your omniflix account
    omniflixhubd q bank balances $GON_OMNIFLIX_WALLET_MINTER # replace with your omniflix account
    omniflixhubd q bank balances $GON_OMNIFLIX_WALLET_RELAYER # replace with your omniflix account
    ```

NOTE: 1,000,000uflix is 1 FLIX

## Teritori

```sh
# recover wallet using mnemonic
cat ./creator.mnemonic|teritorid keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|teritorid keys add $GON_KEY_MINTER_NAME --recover
cat ./relayer.mnemonic|teritorid keys add $GON_KEY_RELAYER_NAME --recover
```

Now get some test TORI:
- discord
  - invite: https://discord.gg/teritori
  - faucet channel: https://discord.com/channels/972545424357474334/991387449295122492


Check whether above 3 wallets has funds using CLI:

```sh
teritorid query bank balances $GON_TERITORI_WALLET_CREATOR
teritorid query bank balances $GON_TERITORI_WALLET_MINTER
teritorid query bank balances $GON_TERITORI_WALLET_RELAYER
```

## Kujira

```sh
# recover wallet using mnemonic
cat ./creator.mnemonic|kujirad keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|kujirad keys add $GON_KEY_MINTER_NAME --recover
cat ./relayer.mnemonic|kujirad keys add $GON_KEY_RELAYER_NAME --recover
```

Now get some test KUJI:
- discord
  - invite: https://discord.gg/teamkujira
  - faucet channel: https://discord.com/channels/970650215801569330/1009931570263629854


Check whether above 3 wallets has funds using CLI:

```sh
kujirad query bank balances $GON_KUJIRA_WALLET_CREATOR
kujirad query bank balances $GON_KUJIRA_WALLET_MINTER
kujirad query bank balances $GON_KUJIRA_WALLET_RELAYER
```

## Terra

```sh
# recover wallet using mnemonic
cat ./creator.mnemonic|terrad keys add $GON_KEY_CREATOR_NAME --recover
cat ./minter.mnemonic|terrad keys add $GON_KEY_MINTER_NAME --recover
# Hermes uses default HD Path 118 as defined by Cosmos Hub
cat ./relayer.mnemonic|terrad keys add $GON_KEY_RELAYER_NAME --hd-path "m/44'/118'/0'/0/0" --recover
```

Now get some test LUNA:
- https://faucet.terra.money/


Check whether above 3 wallets has funds using CLI:

```sh
terrad query bank balances $GON_TERRA_WALLET_CREATOR
terrad query bank balances $GON_TERRA_WALLET_MINTER
terrad query bank balances $GON_TERRA_WALLET_RELAYER
```

# Relayer Setup

Hermes:
- installation here: https://hermes.informal.systems/quick-start/installation.html
- config.toml provided here with all chains and channels for Stargaze, Juno, IRISnet and Uptick

```sh
# restore relayer wallets for hermes
hermes --config config.toml keys add --key-name stargaze_relayer_wallet --chain elgafar-1 --mnemonic-file ./relayer.mnemonic # $GON_STARGAZE_WALLET_RELAYER
hermes --config config.toml keys add --key-name juno_relayer_wallet --chain uni-6 --mnemonic-file ./relayer.mnemonic # $GON_JUNO_WALLET_RELAYER
hermes --config config.toml keys add --key-name osmosis_relayer_wallet --chain osmo-test-4 --mnemonic-file ./relayer.mnemonic # $GON_JUNO_WALLET_RELAYER
hermes --config config.toml keys add --key-name irisnet_relayer_wallet --chain gon-irishub-1 --mnemonic-file ./relayer.mnemonic # $GON_IRISNET_WALLET_RELAYER
hermes --config config.toml keys add --key-name uptick_relayer_wallet --chain uptick_7000-2 --mnemonic-file ./relayer.mnemonic # $GON_UPTICK_WALLET_RELAYER
hermes --config config.toml keys add --key-name omniflix_relayer_wallet --chain gon-flixnet-1 --mnemonic-file ./relayer.mnemonic # $GON_OMNIFLIX_WALLET_RELAYER
```

Starting hermes

```sh
hermes --config config.toml start # from the directory the config is located

# wait a until hermes is running; this may take a while - depending how channels is configured and Hermes need to lookup
# 2023-01-20T12:59:56.811226Z  INFO ThreadId(01) Hermes has started
```
