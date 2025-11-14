# 🪞 MirrorEconomy Framework

A decentralized reflection-based economic system built on Stacks blockchain that enables users to create digital asset mirrors and participate in reflection mechanics for earning rewards.

## 🌟 Overview

MirrorEconomy Framework revolutionizes digital asset interaction through innovative mirroring and reflection mechanics. Users can create mirrors of assets, participate in reflection activities, and earn rewards through a sophisticated tokenized economy.

## 🚀 Features

### 🎯 Core Functionality
- **Asset Registration**: Register digital assets with metadata and value tracking
- **Mirror Creation**: Create mirrors of existing assets with custom reflection multipliers
- **Reflection Mechanics**: Participate in reflections to earn rewards based on activity
- **Token Economy**: Native mirror tokens with staking and reward systems
- **Reputation System**: Build reputation through successful mirror creation and reflections

### 🔧 Advanced Features  
- **Dynamic Multipliers**: Reflection rewards increase with consistent participation
- **Staking System**: Stake mirror tokens to enhance earning potential
- **Time-bound Mirrors**: Set expiration dates for mirrors to create urgency
- **Pool Management**: Global reflection pool for reward distribution

## 📋 Contract Functions

### 🔍 Read-Only Functions

- `get-mirror(mirror-id)` - Retrieve mirror details by ID
- `get-user-mirrors(user)` - Get user's owned mirrors and statistics
- `get-reflection(reflection-id)` - Fetch reflection transaction details
- `get-asset(asset-id)` - Get registered asset information
- `get-user-balance(user)` - Check user's token balances and rewards
- `get-mirror-reflector(mirror-id, reflector)` - Get reflector stats for specific mirror
- `get-total-mirrors()` - Current total number of mirrors
- `get-total-reflections()` - Current total number of reflections
- `get-reflection-pool()` - Current reflection pool balance
- `get-global-reflection-rate()` - Current global reflection rate
- `calculate-reflection-reward(amount, multiplier)` - Calculate potential reward
- `is-mirror-active(mirror-id)` - Check if mirror is active and unexpired

### ✍️ Public Functions

#### Asset Management
- `register-asset(asset-id, value, metadata)` - Register new digital asset
- `create-mirror(original-asset, mirror-asset, reflection-multiplier, duration)` - Create asset mirror
- `deactivate-mirror(mirror-id)` - Deactivate owned mirror

#### Reflection System
- `create-reflection(mirror-id, amount)` - Participate in mirror reflection
- `claim-reflection-reward(reflection-id)` - Claim earned reflection rewards

#### Token Operations
- `mint-mirror-tokens(user, amount)` - Mint tokens (admin only)
- `stake-tokens(amount)` - Stake mirror tokens
- `unstake-tokens(amount)` - Unstake previously staked tokens

#### Administrative
- `update-global-reflection-rate(new-rate)` - Update global reflection rate
- `update-mirror-fee(new-fee)` - Update mirror creation fee
- `transfer-ownership(new-owner)` - Transfer contract ownership

## 🎮 Usage Examples

### 📝 Registering an Asset

```clarity
(contract-call? .mirror-economy register-asset u1 u1000 "My Digital Art NFT")
```

### 🪞 Creating a Mirror

```clarity
(contract-call? .mirror-economy create-mirror u1 u2 u150 u1000)
```
*Creates mirror linking asset 1 to asset 2 with 1.5% multiplier for 1000 blocks*

### ✨ Creating a Reflection

```clarity
(contract-call? .mirror-economy create-reflection u1 u100)
```
*Reflects 100 tokens into mirror ID 1*

### 💰 Claiming Rewards

```clarity
(contract-call? .mirror-economy claim-reflection-reward u1)
```

### 🔒 Staking Tokens

```clarity
(contract-call? .mirror-economy stake-tokens u500)
```

## 🏗️ Architecture

### 📊 Data Structures

#### Mirrors Map
Stores mirror configurations including creator, assets, multipliers, and activity status.

#### User Mirrors Map  
Tracks user-owned mirrors, creation statistics, and reputation scores.

#### Reflections Map
Records all reflection transactions with timestamps and reward calculations.

#### Asset Registry Map
Maintains registered assets with ownership, value, and reflection statistics.

#### User Balances Map
Manages user token balances, rewards, and staking amounts.

#### Mirror Reflectors Map
Tracks individual user activity per mirror with multiplier bonuses.

### 🔢 Economic Model

- **Base Reflection Rate**: 1% (100 basis points)
- **Multiplier Range**: 1-200% (100-20000 basis points)  
- **Reputation Bonus**: +10 points per mirror created
- **Activity Multiplier**: +0.05% per reflection (capped at 2x)
- **Mirror Fee**: 1000 units (adjustable by admin)

## 🛡️ Security Features

- **Authorization Checks**: Function-level access control
- **Input Validation**: Amount and parameter validation
- **State Consistency**: Atomic operations with rollback protection
- **Owner Controls**: Administrative functions restricted to contract owner
- **Balance Verification**: Sufficient balance checks before operations

## ⚠️ Error Codes

- `u400`: Invalid amount provided
- `u401`: Unauthorized access attempt  
- `u402`: Insufficient balance for operation
- `u403`: Mirror expired or time-related error
- `u404`: Requested resource not found
- `u405`: Invalid reflection parameters
- `u406`: Mirror inactive or deactivated
- `u409`: Resource already exists

## 🚀 Getting Started

1. **Deploy Contract**: Deploy the MirrorEconomy contract to Stacks
2. **Register Assets**: Add your digital assets to the registry
3. **Create Mirrors**: Set up mirrors with appropriate multipliers
4. **Start Reflecting**: Begin earning through reflection participation
5. **Manage Rewards**: Claim and stake earned tokens for compound growth

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
npm install
npm test
```

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for discussion.

---

**Built with 💜 on Stacks Blockchain**