# Setup CLIs

Here's a quick guide for setting up CLIs for these chains (chain - `cli name`):
- Stargaze - `starsd`
- Juno - `junod`
- Omosis - `osmosisd`
- IRISnet - `iris`
- Uptick - `uptickd`
- OmniFlix - `omniflixhubd`

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
starsd config chain-id $STARGAZE_CHAIN_ID
starsd config node $STARGAZE_CHAIN_NODE
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
junod config chain-id $JUNO_CHAIN_ID
junod config node $JUNO_CHAIN_NODE
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
osmosisd config chain-id $OSMOSIS_CHAIN_ID
osmosisd config node $OSMOSIS_CHAIN_NODE
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
iris config chain-id $IRISNET_CHAIN_ID
iris config node $IRISNET_CHAIN_NODE
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
uptickd config chain-id $UPTICK_CHAIN_ID
uptickd config node $UPTICK_CHAIN_NODE
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
omniflixhubd config chain-id $OMNIFLIX_CHAIN_ID
omniflixhubd config node $OMNIFLIX_CHAIN_NODE
omniflixhubd config broadcast-mode block
# show and check config
omniflixhubd config

```

# Create Keyrings (Wallets) and Fund With Tokens Using Faucet

## Stargaze

Create 3 wallets: creator, minter and relayer wallet

```sh
# create new wallets
starsd keys add $KEY_CREATOR_NAME # backup in output your mnemonic phrase, for ease of testing same mnemonic may be used for other chains as well!
starsd keys add test_minter
starsd keys add test_relayer

# recover wallet using mnemonic
echo $KEY_CREATOR_MNEMONIC|starsd keys add $KEY_CREATOR_NAME --recover
echo $KEY_MINTER_MNEMONIC|starsd keys add $KEY_MINTER_NAME --recover
echo $KEY_RELAYER_MNEMONIC|starsd keys add $KEY_RELAYER_NAME --recover

```

Now fund these wallets and get some test STARS tokens:
- join Stargaze discord: https://discord.gg/stargaze
- go to faucet channel: https://discord.com/channels/755548171941445642/940653213022031912

In faucet channel enter:
```sh
$request STARGAZE_WALLET_CREATOR # replace with test creator wallet address
$request STARGAZE_WALLET_MINTER # replace with test minter wallet address
$request STARGAZE_WALLET_RELAYER # replace with test relayer wallet address
```

Verify whether above 3 wallets has funds using CLI:

```sh
starsd query bank balances $STARGAZE_WALLET_CREATOR # output amount is 10000000000 ustars
starsd query bank balances $STARGAZE_WALLET_MINTER # output amount is 10000000000 ustars
starsd query bank balances $STARGAZE_WALLET_RELAYER # output amount is 10000000000 ustars
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
echo $KEY_CREATOR_MNEMONIC|junod keys add $KEY_CREATOR_NAME --recover
echo $KEY_MINTER_MNEMONIC|junod keys add $KEY_MINTER_NAME --recover
echo $KEY_RELAYER_MNEMONIC|junod keys add $KEY_RELAYER_NAME --recover
```

Now get some test JUNOX (Juno tokens are called JUNOX on testnet): https://test.juno.tools/request-tokens/

Check whether above 3 wallets has funds using CLI:

```sh
junod query bank balances $JUNO_WALLET_CREATOR
junod query bank balances $JUNO_WALLET_MINTER
junod query bank balances $JUNO_WALLET_RELAYER
```

## Osmosis

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
# recover wallet using mnemonic
echo $KEY_CREATOR_MNEMONIC|osmosisd keys add $KEY_CREATOR_NAME --recover
echo $KEY_MINTER_MNEMONIC|osmosisd keys add $KEY_MINTER_NAME --recover
echo $KEY_RELAYER_MNEMONIC|osmosisd keys add $KEY_RELAYER_NAME --recover
```

Now get some test OSMO:
- use site: https://faucet.osmosis.zone
- alternative use discord
  - invite: https://discord.gg/osmosis
  - faucet channel: https://discord.com/channels/798583171548840026/911309363464007741


Check whether above 3 wallets has funds using CLI:

```sh
osmosisd query bank balances $OSMOSIS_WALLET_CREATOR
osmosisd query bank balances $OSMOSIS_WALLET_MINTER
osmosisd query bank balances $OSMOSIS_WALLET_RELAYER
```

## IRISnet

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
echo $KEY_CREATOR_MNEMONIC|iris keys add $KEY_CREATOR_NAME --recover
echo $KEY_MINTER_MNEMONIC|iris keys add $KEY_MINTER_NAME --recover
echo $KEY_RELAYER_MNEMONIC|iris keys add $KEY_RELAYER_NAME --recover
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
iris query bank balances $IRISNET_WALLET_CREATOR
iris query bank balances $IRISNET_WALLET_MINTER
iris query bank balances $IRISNET_WALLET_RELAYER
# optional: transfer funds to relayer wallet
iris tx bank send $IRISNET_WALLET_CREATOR $IRISNET_WALLET_RELAYER 5000000uiris -y --fees 20uiris # send 5 IRIS tokens
```

NOTE: 1,000,000uiris is 1 IRIS!

## Uptick

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
echo $KEY_CREATOR_MNEMONIC|uptickd keys add $KEY_CREATOR_NAME --recover
echo $KEY_MINTER_MNEMONIC|uptickd keys add $KEY_MINTER_NAME --recover
echo $KEY_RELAYER_MNEMONIC|uptickd keys add $KEY_RELAYER_NAME --recover
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
uptickd query bank balances $UPTICK_WALLET_CREATOR
uptickd query bank balances $UPTICK_WALLET_MINTER
uptickd query bank balances $UPTICK_WALLET_RELAYER
# optional: transfer funds to minter and relayer wallet
uptickd tx bank send $UPTICK_WALLET_CREATOR $UPTICK_WALLET_MINTER 2500000000000000000auptick -y
uptickd tx bank send $UPTICK_WALLET_CREATOR $UPTICK_WALLET_RELAYER 1000000000000000000auptick -y
```

NOTE: 1,000,000,000,000,000,000 auptick is 1 UPTICK!

## OmniFlix

Use same mnemonic for recovering wallets and follow same steps as described above:

```sh
echo $KEY_CREATOR_MNEMONIC|omniflixhubd keys add $KEY_CREATOR_NAME --recover
echo $KEY_MINTER_MNEMONIC|omniflixhubd keys add $KEY_MINTER_NAME --recover
echo $KEY_RELAYER_MNEMONIC|omniflixhubd keys add $KEY_RELAYER_NAME --recover
```

OmniFlix faucet
   - Claim flix tokens on $OMNIFLIX_CHAIN_ID
   ```
    # url
    https://faucet.gon-flixnet.omniflix.io/?address=<omniflix-account-address>

    # using curl
    curl -s https://faucet.gon-flixnet.omniflix.io/?address=$OMNIFLIX_WALLET_RELAYER # replace with env key defined in ./ics721-demo.env
   ```
   - Check balance
    ```sh
    omniflixhubd q bank balances $OMNIFLIX_WALLET_RELAYER # replace with your omniflix account
    ```

NOTE: 1,000,000uflix is 1 FLIX

# Relayer Setup

Hermes:
- installation here: https://hermes.informal.systems/quick-start/installation.html
- config.toml provided here with all chains and channels for Stargaze, Juno, IRISnet and Uptick

```sh
# restore relayer wallets for hermes
hermes --config config.toml keys add --key-name $STARGAZE_KEY_NAME --chain $STARGAZE_CHAIN_ID --mnemonic-file ./relayer-mnemonic # $STARGAZE_WALLET_RELAYER
hermes --config config.toml keys add --key-name $JUNO_KEY_NAME --chain $JUNO_CHAIN_ID --mnemonic-file ./relayer-mnemonic # $JUNO_WALLET_RELAYER
hermes --config config.toml keys add --key-name $OSMOSIS_KEY_NAME --chain $OSMOSIS_CHAIN_ID --mnemonic-file ./relayer-mnemonic # $JUNO_WALLET_RELAYER
hermes --config config.toml keys add --key-name $IRISNET_KEY_NAME --chain $IRISNET_CHAIN_ID --mnemonic-file ./relayer-mnemonic # $IRISNET_WALLET_RELAYER
hermes --config config.toml keys add --key-name $UPTICK_KEY_NAME --chain $UPTICK_CHAIN_ID --mnemonic-file ./relayer-mnemonic # $UPTICK_WALLET_RELAYER
hermes --config config.toml keys add --key-name $OMNIFLIX_KEY_NAME --chain $OMNIFLIX_CHAIN_ID --mnemonic-file ./relayer-mnemonic # $OMNIFLIX_WALLET_RELAYER
```

Starting hermes

```sh
hermes --config config.toml start # from the directory the config is located

# wait a until hermes is running; this may take a while - depending how channels is configured and Hermes need to lookup
# 2023-01-20T12:59:56.811226Z  INFO ThreadId(01) Hermes has started
```
