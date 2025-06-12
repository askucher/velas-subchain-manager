**Frontend Integration Guide for SubchainRegistry Contract**

This guide walks a frontend developer through integrating the `SubchainRegistry` Solidity contract and project metadata into a web layout using **ethers.js**, with metadata hosted on Pinata.

---

## 1. Prerequisites

* **Node.js** ≥ 14 & **npm** (or **yarn**)

* A React or Next.js project (this guide uses React)

* **ethers.js** installed:

  ```bash
  npm install ethers
  # or
  yarn add ethers
  ```

* Contract **ABI** (flattened) and **address** on your target network

* `metadata.json` following the provided schema

Place `metadata.json` at `src/metadata.json`.

---

## 2. Boilerplate Setup

1. **Create an `ethers` provider and signer** in `src/ethers.js`:

   ```js
   import { ethers } from 'ethers';
   const provider = new ethers.providers.Web3Provider(window.ethereum, 'any');
   export const signer = provider.getSigner();
   ```

2. **Load contract ABI & addresses** in `src/config.js`:

   ```js
   import SubchainRegistryABI from './SubchainRegistryABI.json';

   // Deployed addresses
   export const CONTRACT_ADDRESS = '0xYourDeployedAddress';
   export const USDC_ADDRESS = '0xYourUSDCAddress';
   export const USDT_ADDRESS = '0xYourUSDTAddress';

   export const CONTRACT_ABI = SubchainRegistryABI;
   // Minimal ERC20 ABI for allowance & approve
   export const ERC20_ABI = [
     'function allowance(address owner, address spender) view returns (uint256)',
     'function approve(address spender, uint256 amount) returns (bool)'
   ];
   ```

3. **Instantiate contracts** in `src/contracts.js`:

   ```js
   import { ethers } from 'ethers';
   import { CONTRACT_ADDRESS, CONTRACT_ABI, USDC_ADDRESS, USDT_ADDRESS, ERC20_ABI } from './config';
   import { signer, provider } from './ethers';

   export const subchainRegistry = new ethers.Contract(
     CONTRACT_ADDRESS,
     CONTRACT_ABI,
     signer
   );

   export const usdcContract = new ethers.Contract(
     USDC_ADDRESS,
     ERC20_ABI,
     signer
   );

   export const usdtContract = new ethers.Contract(
     USDT_ADDRESS,
     ERC20_ABI,
     signer
   );
   ```

---

## 3. Attaching ABI with Highlighted Functions

Here’s a minimal ABI slice highlighting the core methods, including `registrationFee()` for the upfront cost:

```jsonc
// HighlightedABI.json
[
  {
    "name": "registerSubchain",
    "type": "function",
    "inputs": [
      {"name":"name","type":"string"},
      {"name":"domain","type":"string"},
      {"name":"symbol","type":"string"},
      {"name":"metadataUrl","type":"string"},
      {"name":"chainId","type":"uint256"}
    ]
  },
  {
    "name": "totalSubchains",
    "type": "function",
    "stateMutability": "view",
    "outputs": [{"type":"uint256"}]
  },
  {
    "name": "getSubchain",
    "type": "function",
    "stateMutability": "view",
    "inputs": [{"name":"index","type":"uint256"}],
    "outputs": [ /* Subchain tuple */ ]
  },
  {
    "name": "registrationFee",
    "type": "function",
    "stateMutability": "view",
    "outputs": [{"type":"uint256"}]
  }
]
```

Import and use this ABI when instantiating:

```js
import HighlightedABI from './HighlightedABI.json';
export const subchainRegistry = new ethers.Contract(
  CONTRACT_ADDRESS,
  HighlightedABI,
  signer
);
```

---

## 4. Importing Metadata & Pinata Hosting

1. **Upload `metadata.json` to Pinata**:

   * Sign in at [https://pinata.cloud](https://pinata.cloud)
   * Go to **Upload** → **File**, select `metadata.json`
   * Copy the resulting IPFS hash (CID)

2. **Fetch metadata** in your app via Pinata gateway:

   ```js
   const CID = 'QmYourMetadataCID';
   export const METADATA_URL = `https://gateway.pinata.cloud/ipfs/${CID}`;
   ```

3. **Use metadata assets** in `AppLayout`: referenced earlier.

---

## 5. Example: Register a New Subchain with Allowance Flow

Enhance the form to:

1. Fetch the required USDC fee via `registrationFee()`
2. Check current USDC & USDT allowances
3. Prompt `approve` if allowance < fee
4. Call `registerSubchain`

```jsx
import React, { useState } from 'react';
import { subchainRegistry, usdcContract, signer } from '../contracts';

export default function RegisterForm() {
  const [form, setForm] = useState({ name: '', domain: '', symbol: '', metadataUrl: '', chainId: '' });
  const [txHash, setTxHash] = useState(null);
  const [loading, setLoading] = useState(false);

  const onChange = e => setForm({ ...form, [e.target.name]: e.target.value });

  const register = async () => {
    setLoading(true);
    // 1. Fetch fee
    const fee = await subchainRegistry.registrationFee();
    const user = await signer.getAddress();

    // 2. Check USDC allowance
    const allowance = await usdcContract.allowance(user, subchainRegistry.address);

    // 3. Approve if needed
    if (allowance.lt(fee)) {
      const approveTx = await usdcContract.approve(subchainRegistry.address, fee);
      await approveTx.wait();
    }

    // 4. Call registerSubchain
    const tx = await subchainRegistry.registerSubchain(
      form.name,
      form.domain,
      form.symbol,
      form.metadataUrl,
      parseInt(form.chainId)
    );
    const receipt = await tx.wait();
    setTxHash(receipt.transactionHash);
    setLoading(false);
  };

  return (
    <div className="p-4 bg-white rounded-lg shadow">
      <h2 className="text-xl mb-2">Register Subchain</h2>
      {['name','domain','symbol','metadataUrl','chainId'].map(field => (
        <input
          key={field}
          name={field}
          placeholder={field}
          value={form[field]}
          onChange={onChange}
          className="block w-full mb-2 p-2 border rounded"
        />
      ))}
      <button
        onClick={register}
        disabled={loading}
        className="p-2 bg-blue-600 text-white rounded"
      >
        {loading ? 'Processing…' : 'Submit'}
      </button>
      {txHash && <p className="mt-2">Tx Hash: {txHash}</p>}
    </div>
  );
}
```

The code now highlights the use of `registrationFee()`, checks and sets ERC‑20 allowance for USDC, and then proceeds to register.

---

## 6. Reading & Displaying Subchains with Metadata

```jsx
import React, { useEffect, useState } from 'react';
import { subchainRegistry } from '../contracts';

export default function SubchainList() {
  const [items, setItems] = useState([]);

  useEffect(() => {
    (async () => {
      const count = await subchainRegistry.totalSubchains();
      const list = [];
      for (let i = 0; i < count; i++) {
        const [ name, domain, symbol, metadataUrl, chainId, owner, status, regTime, activeTill ] =
          await subchainRegistry.getSubchain(i);
        // Fetch metadata JSON stored on Pinata or any URL
        const metadata = await fetch(metadataUrl).then(r => r.json());
        list.push({ index: i, name, domain, symbol, chainId, owner, status, metadata });
      }
      setItems(list);
    })();
  }, []);

  return (
    <div className="p-4">
      <h2 className="text-xl mb-2">Subchains</h2>
      <ul>
        {items.map(s => (
          <li key={s.index} className="mb-4 p-4 border rounded bg-gray-50">
            <strong>{s.name}</strong> ({s.domain}) — Status: {s.status}
            <p className="text-sm">Symbol: {s.symbol} • Chain ID: {s.chainId}</p>
            {/* display custom metadata fields */}
            {s.metadata.logo && (
              <img src={s.metadata.logo} alt="Subchain logo" className="h-8 mt-2" />
            )}
            {s.metadata.description && <p>{s.metadata.description}</p>}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

---

## 7. Environment & Deployment Tips

* Store `CONTRACT_ADDRESS`, `METADATA_CID`, and RPC URLs in `.env`.
* Use `provider = new ethers.providers.JsonRpcProvider(process.env.REACT_APP_RPC_URL)` for readonly calls.
* Prompt users to connect wallets with `await provider.send('eth_requestAccounts', [])`.

---

By following these steps, you’ll integrate the key functions (`registerSubchain`, `totalSubchains`, `getSubchain`), host metadata on Pinata, and display subchain details and custom metadata in your frontend.
