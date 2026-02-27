# 🏨 HotelChain Loyalty Token (HCLT)

HotelChain Loyalty Token (HCLT) is a custom ERC20-based loyalty token designed for a hotel ecosystem.

The contract implements controlled peer-to-peer transfers, treasury-managed approvals, a configurable burn mechanism with governance delay, and an on-chain VIP tier system based on token balances.

---

## 📌 Overview

HCLT is built on top of OpenZeppelin's ERC20 implementation and introduces additional business logic:

- Maximum capped supply
- Owner-restricted minting
- Configurable burn rate with time-delay governance
- Restricted client-to-client transfers
- Treasury-managed transfer approvals with expiration
- On-chain VIP tier classification
- Service payment mechanism with automatic burn + treasury split

---

## ⚙️ Technical Specifications

- Solidity version: `0.8.34`
- Standard: ERC20 (OpenZeppelin)
- License: LGPL-3.0-only
- Max Supply: `100,000,000 HCLT`
- Decimals: 18

---

## 🔐 Core Architecture

### 1️⃣ Max Supply

The total supply is capped at:

```
100,000,000 * 10^18
```

Minting is restricted to the contract owner and cannot exceed `MAX_SUPPLY`.

---

### 2️⃣ Controlled Transfers

Client-to-client transfers are **not freely allowed**.

Transfers are only permitted if:

- It is a mint (from `address(0)`)
- It is a burn (to `address(0)`)
- One party is the hotel treasury
- A valid treasury approval exists

All peer-to-peer transfers require a pre-approved authorization issued by the owner or treasury.

---

### 3️⃣ Treasury Approval System

The contract implements a custom approval structure:

```solidity
struct TransferApproval {
    uint amount;
    uint expiry;
    bool used;
}
```

Approvals:

- Are specific to `from → to`
- Must match the exact amount
- Expire after 24 hours
- Can only be used once

This prevents:
- Unauthorized transfers
- Replay usage
- Partial transfer abuse

---

### 4️⃣ Burn Mechanism with Governance Delay

The token includes a configurable burn rate applied during service payments.

When a user calls:

```
payService(uint256 amount)
```

The amount is split into:

- A percentage burned
- The remainder sent to the treasury

The burn rate:

- Can be proposed by the owner
- Has a mandatory 7-day delay before execution
- Allows one modification during the delay window

This prevents sudden tokenomic manipulation.

---

### 5️⃣ VIP Tier System

Users are automatically classified based on token balance:

| Tier      | Required Balance |
|-----------|------------------|
| Standard  | < 500 HCLT       |
| Silver    | ≥ 500 HCLT       |
| Gold      | ≥ 2000 HCLT      |
| Platinum  | ≥ 5000 HCLT      |

VIP level is calculated on-chain via:

```solidity
function getVipLevel(address user) public view returns (uint8);
```

---

## 🏗️ Contract Roles

### Owner
- Mint tokens
- Propose burn rate changes
- Execute burn rate changes

### Hotel Treasury
- Receives service payments
- Can authorize peer-to-peer transfers

---

## 🧪 Security Design Decisions

- Override of `_update()` to centralize transfer restrictions
- No reliance on default ERC20 allowances for P2P transfers
- Exact amount matching for approvals
- Time-limited approvals
- Single-use approval mechanism
- Governance delay for tokenomics changes

---

## 📂 Dependencies

- OpenZeppelin ERC20
- OpenZeppelin Ownable

Install via:

```bash
npm install @openzeppelin/contracts
```

---

## 🚀 Future Improvements

- Role-based access control (AccessControl instead of Ownable)
- Off-chain signature approvals (EIP-712)
- Upgradeable proxy architecture
- Event indexing for approval creation
- Frontend integration for treasury dashboard

---

## 📜 License

LGPL-3.0-only
