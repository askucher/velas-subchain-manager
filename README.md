# SubchainRegistry

This repository demonstrates how to interact with the `SubchainRegistry` smart contract (written in Solidity) using Rust and the **ethers-rs** library. It covers:

* Purpose and key features of the contract
* Fetching the latest subchain index at regular intervals
* Reading subchain details by index
* Changing the status of a subchain as a backend role

---

## Table of Contents

- [SubchainRegistry](#subchainregistry)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Fetching Latest Index Periodically](#fetching-latest-index-periodically)
  - [Reading Subchain Information](#reading-subchain-information)
  - [Metadata Schema](#metadata-schema)
  - [Example Metadata](#example-metadata)
  - [Changing Subchain Status (Backend)](#changing-subchain-status-backend)
    - [Deploy Contracts](#deploy-contracts)
    - [Test Contracts](#test-contracts)

---

## Overview

The `SubchainRegistry` contract allows users to register and maintain "subchains" by paying registration and monthly fees in ERC20 tokens (USDC and USDT). It uses role-based access control (`AccessControl`) to distinguish between the admin, backend, and founders.

Key features:

* **Registration**: Users pay a USDC fee to register a subchain (domain, symbol, chainId)
* **Monthly Payments**: Owners pay a USDT fee to extend support in 30‑day increments
* **Status Management**: Backend addresses can transition subchains through `Pending`, `Active`, `Suspended`, and `Deleted`
* **Roles**: `DEFAULT_ADMIN_ROLE`, `BACKEND_ROLE`, `FOUNDER_ROLE`

---

## Prerequisites

* **Rust** (1.65+)
* **Cargo**
* **ethers-rs** – add to `Cargo.toml`:

  ```toml
  [dependencies]
  ethers = { version = "^2", features = ["abigen", "tokio-runtime"] }
  tokio = { version = "1", features = ["full"] }
  dotenv = "^0.15"
  ```
* **.env** file with:

  ```dotenv
  RPC_URL=<Your JSON-RPC HTTP endpoint>
  CONTRACT_ADDRESS=<Deployed_SubchainRegistry_Address>
  BACKEND_PRIVATE_KEY=<Hex‑encoded_Private_Key>
  ```

---

## Setup

1. Clone this repo and enter the directory:

   ```bash
   git clone <repo-url>
   cd <repo-directory>
   ```

2. Create a `.env` file in the project root (as above).

3. Generate Rust bindings from the contract ABI:

   ```bash
   abigen!(
       SubchainRegistry,
       "./artifacts/SubchainRegistry.json",
       event_derives(serde::Deserialize, serde::Serialize)
   );
   ```

4. Build the project:

   ```bash
   cargo build --release
   ```

---

## Fetching Latest Index Periodically

Use a Tokio interval to poll the `latestIndex` on-chain at a fixed cadence (e.g., every 10 seconds). When a new index appears, you can trigger additional processing.

```rust
use ethers::prelude::*;
use std::sync::Arc;
use tokio::time::{interval, Duration};
use dotenv::dotenv;

abigen!(SubchainRegistry, "./artifacts/SubchainRegistry.json");

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv().ok();
    let provider = Provider::<Http>::try_from(std::env::var("RPC_URL")?)?;
    let client = Arc::new(provider);

    let address: Address = std::env::var("CONTRACT_ADDRESS")?.parse()?;
    let contract = SubchainRegistry::new(address, client.clone());

    let mut poll = interval(Duration::from_secs(10));
    let mut last_seen = U256::zero();

    loop {
        poll.tick().await;
        let idx: U256 = contract.latest_index().call().await?;
        if idx > last_seen {
            println!("New subchain index: {}", idx);
            last_seen = idx;
            // TODO: fetch details or handle new registration
        }
    }
}
```

---

## Reading Subchain Information

Once you have an index, call `getSubchain(index)` to retrieve the subchain details.

```rust
// Inside your async context:
let idx: U256 = /* obtained from polling */;
let sub = contract.get_subchain(idx).call().await?;

println!(
    "Subchain #{}: {} (domain: {}, chainId: {}, owner: {:?}, status: {:?})",
    idx,
    sub.0,       // name
    sub.1,       // domain
    sub.1,       // metadaUrl
    sub.3,       // chainId
    sub.4,       // owner address
    sub.5        // status enum
);
```

The tuple fields correspond to the `Subchain` struct:

1. `name` (String)
2. `domain` (String)
3. `symbol` (String)
4. `metadataUrl` (String)
5. `chainId` (u256)
6. `owner` (Address)
7. `status` (enum)
8. `registrationTime` (u256 timestamp)
9. `activeTill` (u256 timestamp)

---

## Metadata Schema

The project metadata is defined by a JSON Schema (Draft-07) that bundles your flattened Solidity contract source and all required assets as Base64-encoded data URIs. This schema ensures consistency and makes it easy to consume by tooling or front-end components.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Project Metadata",
  "description": "Metadata including a single-file Solidity contract source and asset images in Base64",
  "type": "object",
  "properties": {
    "compiledContractSource": {
      "type": "string",
      "description": "The flattened Solidity source code of your contract, all imports resolved into one file."
    },
    "logoDarkBase64": {
      "type": "string",
      "description": "Base64-encoded dark mode logo image (data URI prefix required).",
      "pattern": "^data:image\\/(png|jpeg|svg\\+xml);base64,[A-Za-z0-9+/]+={0,2}$"
    },
    "logoLightBase64": {
      "type": "string",
      "description": "Base64-encoded light mode logo image (data URI prefix required).",
      "pattern": "^data:image\\/(png|jpeg|svg\\+xml);base64,[A-Za-z0-9+/]+={0,2}$"
    },
    "projectDescription": {
      "type": "string",
      "description": "A brief description of the project."
    },
    "faviconBase64": {
      "type": "string",
      "description": "Base64-encoded favicon (data URI prefix required).",
      "pattern": "^data:image\\/(x-icon|png|jpeg);base64,[A-Za-z0-9+/]+={0,2}$"
    },
    "explorerBackgroundBase64": {
      "type": "string",
      "description": "Base64-encoded explorer plate background image (data URI prefix required).",
      "pattern": "^data:image\\/(png|jpeg|svg\\+xml);base64,[A-Za-z0-9+/]+={0,2}$"
    }
  },
  "required": [
    "compiledContractSource",
    "logoDarkBase64",
    "logoLightBase64",
    "projectDescription",
    "faviconBase64",
    "explorerBackgroundBase64"
  ],
  "additionalProperties": false
}
```

---

## Example Metadata

Below is a sample `metadata.json` file that conforms to the schema above. Replace the placeholder Base64 strings and contract source with your actual project data.

```json
{
  "compiledContractSource": "pragma solidity ^0.8.4;\n\n// SPDX-License-Identifier: MIT\n// Flattened single-file contract\n\nlibrary SafeMath {\n    function add(uint256 a, uint256 b) internal pure returns (uint256) {\n        uint256 c = a + b;\n        require(c >= a, \"SafeMath: addition overflow\");\n        return c;\n    }\n}\n\ncontract MyToken {\n    using SafeMath for uint256;\n\n    string public name = \"ExampleToken\";\n    string public symbol = \"EXT\";\n    uint8 public decimals = 18;\n    uint256 public totalSupply;\n    mapping(address => uint256) public balanceOf;\n\n    constructor(uint256 _initialSupply) {\n        totalSupply = _initialSupply;\n        balanceOf[msg.sender] = _initialSupply;\n    }\n\n    function transfer(address _to, uint256 _value) public returns (bool) {\n        require(balanceOf[msg.sender] >= _value, \"Insufficient balance\");\n        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;\n        balanceOf[_to] = balanceOf[_to] + _value;\n        return true;\n    }\n}",
  "logoDarkBase64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJYAAACWCAYAAAD+f4QbAAA...",
  "logoLightBase64": "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcv...",
  "projectDescription": "ExplorerPlate is a decentralized data-explorer interface for on-chain analytics, with dark/light theming and a reactive smart-contract backend.",
  "faviconBase64": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAA...",
  "explorerBackgroundBase64": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHC..."
}
```

**Usage:**

1. Include this JSON file in your project root or publish it alongside your frontend.
2. Consume it at runtime to dynamically load contract source, logos, favicon, and background assets.
3. Ensure any Base64 data URIs are valid and that the flattened contract source compiles successfully.



## Changing Subchain Status (Backend)

To change a subchain's status, your signer must hold the `BACKEND_ROLE`. Load the private key and attach a signer to your provider.

```rust
use ethers::signers::LocalWallet;

let key: LocalWallet = std::env::var("BACKEND_PRIVATE_KEY")?
    .parse::<LocalWallet>()?
    .with_chain_id(provider.get_chainid().await?.as_u64());
let client = Arc::new(SignerMiddleware::new(client.clone(), key));
let contract = SubchainRegistry::new(address, client.clone());

// Set status to Active (1)
let tx = contract
    .set_status(U256::from(0u64), SubchainRegistryStatus::Active)
    .send()
    .await?
    .await?;

println!("Status change transaction: {:?}", tx.transaction_hash);
```

Replace the index and `Status` variant as needed:

* `SubchainRegistryStatus::Pending` (0)
* `SubchainRegistryStatus::Active` (1)
* `SubchainRegistryStatus::Suspended` (2)
* `SubchainRegistryStatus::Deleted` (3)


### Deploy Contracts


* Feel the .env 
* Run `bash exec.sh deploy`

### Test Contracts


* Feel the .env 
* Run `bash exec.sh test`