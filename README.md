# Cosmos Hub
![banner](./docs/images/cosmos-hub-image.jpg)

[![license](https://img.shields.io/github/license/cosmos/gaia.svg)](https://github.com/cosmos/gaia/blob/master/LICENSE)
[![LoC](https://tokei.rs/b1/github/cosmos/gaia)](https://github.com/cosmos/gaia)

This branch contains a modified version of `Gaia` that references a [version](https://github.com/ChorusOne/cosmos-sdk/tree/wasm-ibc) of `cosmos-sdk` with an additional IBC module which enables uploading and running of light client as a WASM smart contract.

**Note**: Requires [Go 1.14+](https://golang.org/dl/)

## Installation & Running
For installation, just run `make install`. This will install `gaiad` and `gaiacli` in `$GOPATH/bin`. To run local testnet/node you can follow instructions from [here](https://hub.cosmos.network/master/gaia-tutorials/deploy-testnet.html).

## Upload wasm bytecode of substrate light client
Once you have gaia up and running, we need to upload [substrate_light_client]'s build using gaiacli.
```
gaiacli tx ibc wasm store "target/wasm32-unknown-unknown/release/substrate_client.wasm"  --gas=2000000  --from=<account with $ for gas> --chain-id "<your chain id>" --yes
```

## Start Gaia light client daemon
Quantum tunnel interacts with light client daemon instead of interacting with gaia daemon directly. So, we also need to start Gaia LCD locally. 
```
gaiacli rest-server --chain-id="<your chain id>" --laddr=tcp://localhost:1317  --node tcp://localhost:26657 --read-timeout 10000 --write-timeout 10000
```

## Check status of the client:
There are two rpc endpoints available in Gaia LCD to query status of light client instances:
1. `http://localhost:1317/ibc/clients`: Gives array of all clients exist in the system. Sample response:
```json
{
  "height": "76",
  "result": [
    {
      "type": "ibc/client/wasm/ClientState",
      "value": {
        "id": "vffykhgkrc",
        "trusting_period": "2592000000000000",
        "unbonding_period": "2595600000000000",
        "MaxClockDrift": "30000000000",
        "frozen_height": "0",
        "last_header": {
          "Data": "<last header data>"
        },
        "validity_predicate_address": "Q4GAgIAQAAAAAAAAAAAAAAAAAAA="
      }
    },
    {
      "type": "ibc/client/wasm/ClientState",
      "value": {
        "id": "bggehqndmp",
        "trusting_period": "43230005550666000",
        "unbonding_period": "5323600000000000",
        "MaxClockDrift": "30000000000",
        "frozen_height": "0",
        "last_header": {
          "Data": "<last header data>"
        },
        "validity_predicate_address": "EpGAgIAQgBABAghAIAGAAAgAAEA="
      }
    }
  ]
}
```

2. `http://localhost:1317/ibc/wasm/client/{client_id}`: Gets status of a particular client referred by its `id`. 

For example, Let's take first client with id `vffykhgkrc` from the sample response of 1st api call. In that case, url would be: `http://localhost:1317/ibc/wasm/client/vffykhgkrc` and response would be: 
```json
{
  "height": "200",
  "result": "{\"best_header_height\":165,\"best_header_hash\":[130,154,171,213,11,253,140,13,103,86,2,142,169,186,243,243,198,245,76,49,38,231,98,156,110,21,70,169,224,206,174,141],\"last_finalized_header_hash\":[],\"best_header_commitment_root\":[83,250,120,181,184,202,74,105,205,244,131,140,177,137,88,254,157,92,224,21,93,231,252,89,60,56,164,212,16,9,86,122],\"current_authority_set\":\"LightAuthoritySet { set_id: 0, authorities: [(Public(88dc3417d5058ec4b4503e0c12ea1a0a89be200fe98922423d4334014fa6b0ee (5FA9nQDV...)), 1)] }\"}"
}
```
You can parse the stringified json to get the data about light client for example: best header, last finalized header, current authority set etc etc.

[substrate_light_client]: https://github.com/ChorusOne/substrate-light-client
