# 🚰 Daily Token Drip

A simple Clarity smart contract that allows users to claim DRIP tokens once every 24 hours. Perfect for learning how to work with block heights and time-based mechanics in Stacks blockchain development.

## 🌟 Features

- 💧 **Daily Claims**: Users can claim 1,000,000 DRIP tokens (1 DRIP with 6 decimals) every 144 blocks (~24 hours)
- 📊 **Claim Tracking**: Track when users last claimed and total claimed amounts
- 🔍 **Read Functions**: Check claim eligibility, view balances, and get comprehensive stats
- 👑 **Admin Functions**: Owner can mint initial supply and manage claims
- 📈 **Analytics**: View claim history and estimate earnings

## 🚀 Quick Start

### Deploy the Contract

```bash
clarinet deploy
```

### Basic Usage

#### Check if you can claim tokens
```clarity
(contract-call? .daily-token-drip can-claim-now tx-sender)
```

#### Claim your daily drip
```clarity
(contract-call? .daily-token-drip claim-daily-drip)
```

#### Check your balance
```clarity
(contract-call? .daily-token-drip get-balance tx-sender)
```

#### View your claim info
```clarity
(contract-call? .daily-token-drip get-user-claim-info tx-sender)
```

## 📋 Contract Functions

### 🔓 Public Functions

| Function | Description |
|----------|-------------|
| `claim-daily-drip` | Claim your daily 1 DRIP token (once per 144 blocks) |
| `transfer` | Transfer tokens between accounts |
| `bulk-claim-check` | Check claim status for multiple users |

### 👑 Admin Functions

| Function | Description |
|----------|-------------|
| `mint-initial-supply` | Mint initial token supply (owner only) |
| `emergency-mint` | Emergency mint tokens to any address (owner only) |
| `force-claim-for-user` | Force a claim for any user (owner only) |
| `set-last-claim-block-admin` | Manually set last claim block (owner only) |

### 📖 Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-balance` | Get token balance for an address |
| `get-user-claim-info` | Get comprehensive claim info for a user |
| `can-claim-now` | Check if user can claim right now |
| `get-blocks-until-next-claim` | Blocks remaining until next claim |
| `get-global-stats` | Get contract-wide statistics |
| `estimate-daily-earnings` | Calculate earnings over multiple days |

## 🎯 Learning Objectives

This contract teaches you:

- ⏰ **Block Height Usage**: Using `stacks-block-height` for time-based logic
- 🗺️ **Data Maps**: Storing user-specific data with `define-map`
- 🪙 **Fungible Tokens**: Creating and managing SIP-010 compatible tokens
- 🔒 **Access Control**: Implementing owner-only functions
- ✅ **Assertions**: Using `asserts!` for validation
- 📊 **Data Aggregation**: Combining multiple data sources in read functions

## 🔧 Configuration

- **Blocks per day**: 144 blocks (~10 minutes per block)
- **Daily drip amount**: 1,000,000 micro-tokens (1 DRIP)
- **Token decimals**: 6
- **Token symbol**: DRIP

## 🧪 Testing

```bash
clarinet test
```

## 📝 Example Workflow

1. 🚀 Deploy the contract
2. 💰 Owner mints initial supply (optional)
3. 👤 Users call `claim-daily-drip` once per day
4. 📊 Check stats with `get-user-claim-info`
5. 💸 Transfer tokens with `transfer`

## 🛡️ Security Features

- ✅ Time-based claim restrictions
- ✅ Owner-only administrative functions  
- ✅ Transfer authorization checks
- ✅ Comprehensive error handling

## 🎉 Ready to Drip!

Start claiming your daily tokens and explore the power of time-based smart contracts on Stacks! 

Happy coding! 🚀
```

## Git Commit Message

```
feat: implement daily token drip MVP with 24h claim mechanics
```

## GitHub Pull Request Title

```
🚰 Add Daily Token Drip MVP - Claim tokens every 24 hours
```

## GitHub Pull Request Description

```markdown
## 🚰 Daily Token Drip MVP

This PR introduces a complete daily token drip system that allows users to claim DRIP tokens once every 24 hours (144 blocks).

### ✨ What's Added

- **Core claiming mechanism** - Users can claim 1 DRIP token every 144 blocks
- **Comprehensive tracking** - Last claim blocks and total claimed amounts per user
- **Rich read functions** - Check eligibility, view stats, estimate earnings
- **Admin controls** - Owner functions for minting and claim management
- **SIP-010 compliance** - Full fungible token implementation
- **Bulk operations** - Check multiple users' claim status at once

### 🎯 Key Features

- Time-based claiming using `stacks-block-height`
- User claim history and analytics
- Transfer functionality with proper authorization
- Emergency admin functions for contract management
- Comprehensive error handling and validation

### 🧪 Testing

All functions tested for:
- Proper time restrictions (144 block intervals)
- Access control (owner-only functions)
- Token minting and transfer mechanics
- Data integrity across claims

This MVP provides a solid foundation for learning block height mechanics and time-based smart contract logic on Stacks.

