# query tokens

```sh
# bug, only shows first 10 tokens!!!
clear;source ./ark-cli.sh; ark select chain stargaze; ark query collection tokens --collection $ARK_GON_COLLECTION | jq

clear;source ./ark-cli.sh; ark select chain juno; ark query collection tokens --collection $ARK_GON_COLLECTION | jq

clear;source ./ark-cli.sh; ark select chain irisnet; ark query collection tokens --collection $ARK_GON_COLLECTION | jq

clear;source ./ark-cli.sh; ark select chain uptick; ark query collection tokens --collection $ARK_GON_COLLECTION | jq

clear;source ./ark-cli.sh; ark select chain omniflix; ark query collection tokens --collection $ARK_GON_COLLECTION | jq

```

# query token

```sh
clear;source ./ark-cli.sh; ark select chain stargaze; ark query collection token --collection $ARK_GON_COLLECTION --token arkNFT001 | jq

clear;source ./ark-cli.sh; ark select chain juno; ark query collection token --collection $ARK_GON_COLLECTION --token arkNFT001 | jq

clear;source ./ark-cli.sh; ark select chain irisnet; ark query collection token --collection $ARK_GON_COLLECTION --token arkNFT019 | jq

clear;source ./ark-cli.sh; ark select chain uptick; ark query collection token --collection $ARK_GON_COLLECTION --token nft9 | jq

clear;source ./ark-cli.sh; ark select chain omniflix; ark query collection token --collection $ARK_GON_COLLECTION --token onftfe7c8ff29f35449c9c7955359c7a375a | jq

```

# query channels

```sh
clear;source ./ark-cli.sh; ark select chain stargaze; ark query channel channels

clear;source ./ark-cli.sh; ark select chain juno; ark query channel channels

clear;source ./ark-cli.sh; ark select chain irisnet; ark query channel channels

clear;source ./ark-cli.sh; ark select chain uptick; ark query channel channels

clear;source ./ark-cli.sh; ark select chain omniflix; ark query channel channels
```

# query channel

```sh
clear;source ./ark-cli.sh; ark select chain stargaze; ark query channel channel --channel channel-207 | jq

clear;source ./ark-cli.sh; ark select chain juno; ark query channel channel --channel channel-90 | jq

clear;source ./ark-cli.sh; ark select chain irisnet; ark query channel channel --channel channel-22 | jq

clear;source ./ark-cli.sh; ark select chain uptick; ark query channel channel --channel channel-3 | jq

clear;source ./ark-cli.sh; ark select chain omniflix; ark query channel channel --channel channel-24 | jq

```

# query collections

```sh
clear;source ./ark-cli.sh; ark select chain stargaze; ark query collection collections --owner stars1ve46fjrhcrum94c7d8yc2wsdz8cpuw73503e8qn9r44spr6dw0lsvmvtqh --limit 10 | jq

clear;source ./ark-cli.sh; ark select chain juno; ark query collection collections --owner $WALLET_MINTER --owner juno1stv6sk0mvku34fj2mqrlyru6683866n306mfv52tlugtl322zmks26kg7a --limit 10 | jq

clear;source ./ark-cli.sh; ark select chain irisnet; ark query collection collections --owner iaa1lfzfh4ceu60er5ewl5h0py9se4qm043rrecp26 --limit 2 | jq

clear;source ./ark-cli.sh; ark select chain uptick; ark query collection collections --owner $WALLET_MINTER | jq

clear;source ./ark-cli.sh; ark select chain omniflix; ark query collection collections --owner $WALLET_MINTER | jq
```

# create collection

```sh
clear;source ./ark-cli.sh; ark select chain stargaze; ark create collection --from $WALLET_MINTER --symbol symbol --name name --label label | jq

clear;source ./ark-cli.sh; ark select chain juno; ark create collection --from $WALLET_MINTER --symbol symbol --name name --label label | jq

clear;source ./ark-cli.sh; ark select chain irisnet; ark create collection --from $WALLET_MINTER --uri "https://arkprotocol.io" --name "Ark Protocol - building multichain utilities" --symbol "arkprotocol_symbol" --collection arkprotocol022 | jq

clear;source ./ark-cli.sh; ark select chain uptick; ark create collection --from $WALLET_MINTER --uri "https://arkprotocol.io" --name "Ark Protocol - building multichain utilities" --symbol "arkprotocol_symbol" --collection arkprotocol008 | jq

clear;source ./ark-cli.sh; ark select chain omniflix; ark create collection --from $WALLET_MINTER --uri "https://arkprotocol.io" --name "Ark Protocol - building multichain utilities" --symbol "arkprotocol_symbol" | jq
```

# mint token

```sh
clear;source ./ark-cli.sh; ark select chain stargaze; ark mint collection --owner $WALLET_MINTER --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token ark001 | jq

clear;source ./ark-cli.sh; ark select chain juno; ark mint collection --owner $WALLET_MINTER --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token ark001 | jq

clear;source ./ark-cli.sh; ark select chain irisnet; ark mint collection --owner $WALLET_MINTER --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token ark002 | jq

clear;source ./ark-cli.sh; ark select chain uptick; ark mint collection --owner $WALLET_MINTER --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token ark020 | jq

clear;source ./ark-cli.sh; ark select chain omniflix; ark mint collection --owner $WALLET_MINTER --from $WALLET_MINTER --uri "https://arkprotocol.io" --collection $ARK_GON_COLLECTION | jq

```

# class id

```sh

```

# transfer

```sh
clear;source ./ark-cli.sh; ark select chain stargaze; ark transfer ics721 token --recipient juno183e7ccwsnngj2q8lfxnmekunspnfxs6q9akx5y --target-chain juno --source-channel $CHANNEL_1_TO_JUNO --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token ark001

clear;source ./ark-cli.sh; ark select chain juno; ark transfer ics721 token --recipient iaa183e7ccwsnngj2q8lfxnmekunspnfxs6qxd4v3f --target-chain irisnet --source-channel $CHANNEL_1_TO_IRISNET --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token ark001

clear;source ./ark-cli.sh; ark select chain irisnet; ark transfer ics721 token --recipient uptick1h7c0ltrj6z707eh3z4cyv4jkqwfv6lj76se7lr --target-chain uptick --source-channel $CHANNEL_1_TO_UPTICK --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token ark001

clear;source ./ark-cli.sh; ark select chain uptick; ark transfer ics721 token --recipient omniflix183e7ccwsnngj2q8lfxnmekunspnfxs6qw3yyyx --target-chain omniflix --source-channel $CHANNEL_1_TO_OMNIFLIX --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token ark020

clear;source ./ark-cli.sh; ark select chain omniflix; ark transfer ics721 token --recipient stars183e7ccwsnngj2q8lfxnmekunspnfxs6q8nzqcf --target-chain stargaze --source-channel $CHANNEL_1_TO_STARGAZE --from $WALLET_MINTER --collection $ARK_GON_COLLECTION --token onft52e74520f0364d41bc85e1087a96e037

```

