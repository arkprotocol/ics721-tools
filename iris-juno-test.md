# new collection

```sh
iris tx nft issue arkCollection1 --symbol ark-coll-1 --description "you BETTER check this out" --uri "https://arkprotocol.io/" --from test_creator -b block -y --mint-restricted=false --update-restricted=false --fees 20uiris
```


# mint on iris

```sh
iris tx nft mint arkCollection1 token4 --recipient=iaa1f0zfmahd9c43nmpljx3hel6h5d9vl7gzswhq7q --from=test_creator -y --fees 20uiris
```

query for token and check token is owned by minter:
```sh
iris query nft token arkCollection1 token4
```

# transfer: (Error: RPC error -32603 - Internal error: timed out waiting for tx to be included in a block)

```sh
iris tx nft-transfer transfer nft-transfer channel-37 stars1f0zfmahd9c43nmpljx3hel6h5d9vl7gz3sqvhq arkCollection1 token4 --from test_minter -b block --fees 50uiris -y
```

query for token and check token is locked:
```sh
iris query nft token arkCollection1 token4
```

# relay:

```sh
hermes --config config.toml clear packets --chain iris-1 --channel channel-37 --port nft-transfer
```

# check cw721/collection

show all cw721 contracts 
```sh
starsd query wasm list-contract-by-code 803|grep stars # last entry is new instantiated collection by ics721, use this to query all tokens:

starsd query wasm contract-state smart stars1r7ffp8vzyjlv27czsl8xq0t3atc6ce72cvtz8ntupe4vc24nac0s3jjuas '{"all_tokens":{"limit": 50}}'

# check owner of token:
starsd query wasm contract-state smart stars1r7ffp8vzyjlv27czsl8xq0t3atc6ce72cvtz8ntupe4vc24nac0s3jjuas '{"all_nft_info":{"token_id": "token4"}}'

```





-----------juno

# mint on iris

```sh
iris tx nft mint arkCollection1 token6 --recipient=iaa1f0zfmahd9c43nmpljx3hel6h5d9vl7gzswhq7q --from=test_creator -y --fees 20uiris
```

query for token and check token is owned by minter:
```sh
iris query nft token arkCollection1 token6
```

# transfer: (Error: RPC error -32603 - Internal error: timed out waiting for tx to be included in a block)

```sh
iris tx nft-transfer transfer nft-transfer channel-40 juno1f0zfmahd9c43nmpljx3hel6h5d9vl7gzn752md arkCollection1 token6 --from test_minter -b block --fees 50uiris -y
```

query for token and check token is locked:
```sh
iris query nft token arkCollection1 token6
```

# relay:

```sh
hermes --config config.toml clear packets --chain iris-1 --channel channel-40 --port nft-transfer
```

# check cw721/collection

show all cw721 contracts 
```sh
junod query wasm list-contract-by-code 116 # last entry is new instantiated collection by ics721, use this to query all tokens:

junod query wasm contract-state smart juno1m53cvy0uyrpxkj6g3zysw0472kwrxc5hm2dz9r8zjlzxvs8f3fts95hkhe '{"all_tokens":{"limit": 50}}'

# check owner of token:
junod query wasm contract-state smart juno1m53cvy0uyrpxkj6g3zysw0472kwrxc5hm2dz9r8zjlzxvs8f3fts95hkhe '{"all_nft_info":{"token_id": "token6"}}'

```

