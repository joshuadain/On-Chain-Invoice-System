# 🧾 On-Chain Invoice System

A smart contract solution for generating and paying invoices directly on the Stacks blockchain, ensuring transparent and immutable records.

## ✨ Features

- 📝 **Create Invoices**: Generate invoices with amount, recipient, description, and due date
- 💰 **Pay Invoices**: Secure STX payments directly through the blockchain
- ❌ **Cancel Invoices**: Creators can cancel unpaid invoices
- 📊 **Status Tracking**: Real-time invoice status (pending, paid, cancelled, overdue)
- 🔄 **Recurring Invoices**: Automated subscription billing with weekly/monthly/yearly intervals
- ⏸️ **Pause/Resume**: Control recurring invoice cycles
- 🔍 **Query Functions**: Comprehensive read-only functions for invoice management
- ⏰ **Automatic Overdue Detection**: Smart contract automatically detects overdue invoices
- 📋 **User Dashboard**: Track created and received invoices per user
- 📈 **Billing History**: Complete audit trail for all recurring payments

## 🚀 Quick Start

### Creating an Invoice

```clarity
(contract-call? .Invoice create-invoice 
  'SP1ABCD... ;; recipient principal
  u1000000    ;; amount in microSTX (1 STX)
  "Website design services" ;; description
  u1735689600 ;; due date (Unix timestamp)
)
```

### Creating a Recurring Invoice

```clarity
(contract-call? .Invoice create-recurring-invoice 
  'SP1ABCD... ;; recipient principal
  u1000000    ;; amount in microSTX (1 STX)
  "Monthly subscription" ;; description
  u2629746    ;; monthly interval (INTERVAL_MONTHLY)
)
```

### Paying an Invoice

```clarity
(contract-call? .Invoice pay-invoice u1) ;; invoice ID
```

### Generating Next Recurring Invoice

```clarity
(contract-call? .Invoice generate-recurring-invoice u1) ;; recurring ID
```

## 📋 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-invoice` | Create a new invoice | `recipient`, `amount`, `description`, `due-date` |
| `pay-invoice` | Pay an existing invoice | `invoice-id` |
| `cancel-invoice` | Cancel an unpaid invoice (creator only) | `invoice-id` |
| `update-invoice-description` | Update invoice description (creator only) | `invoice-id`, `new-description` |
| `create-recurring-invoice` | Create automated recurring invoice | `recipient`, `amount`, `description`, `interval` |
| `generate-recurring-invoice` | Generate next invoice in recurring cycle | `recurring-id` |
| `pause-recurring-invoice` | Pause recurring invoice cycle | `recurring-id` |
| `resume-recurring-invoice` | Resume paused recurring invoice | `recurring-id` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-invoice` | Get complete invoice details | Invoice object |
| `get-invoice-payment` | Get payment details for an invoice | Payment object |
| `get-user-invoices` | Get all invoices created by a user | List of invoice IDs |
| `get-user-received-invoices` | Get all invoices received by a user | List of invoice IDs |
| `get-invoice-status` | Get current status of an invoice | Status code |
| `get-total-invoices` | Get total number of invoices | Total count |
| `is-invoice-paid` | Check if invoice is paid | Boolean |
| `get-invoice-amount` | Get invoice amount | Amount in microSTX |
| `get-pending-invoices-for-user` | Get pending invoices for a user | List of invoice IDs |
| `get-overdue-invoices-for-user` | Get overdue invoices for a user | List of invoice IDs |
| `get-recurring-invoice` | Get recurring invoice details | Recurring invoice object |
| `get-user-recurring-invoices` | Get all recurring invoices for a user | List of recurring IDs |
| `get-recurring-invoice-history` | Get all generated invoices from recurring | List of invoice IDs |
| `get-due-recurring-invoices` | Get recurring invoices ready to generate | List of recurring IDs |
| `get-total-recurring-invoices` | Get total number of recurring invoices | Total count |

## 📊 Invoice Status Codes

- `0` - **Pending**: Invoice created, awaiting payment
- `1` - **Paid**: Invoice has been paid
- `2` - **Cancelled**: Invoice cancelled by creator
- `3` - **Overdue**: Invoice past due date and unpaid

## ⚠️ Error Codes

- `u100` - Not authorized
- `u101` - Invoice not found
- `u102` - Invoice already paid
- `u103` - Invoice cancelled
- `u104` - Insufficient amount
- `u105` - Invalid amount
- `u106` - Cannot cancel paid invoice
- `u107` - Invoice overdue
- `u108` - Recurring invoice not found
- `u109` - Recurring invoice paused
- `u110` - Invalid interval

## 🔧 Usage Examples

### Business Workflow

1. **Service Provider creates invoice**:
   ```clarity
   (contract-call? .Invoice create-invoice 
     'SP2CLIENT123... 
     u5000000 
     "Monthly consulting services" 
     u1738281600)
   ```

2. **Client pays invoice**:
   ```clarity
   (contract-call? .Invoice pay-invoice u1)
   ```

3. **Check payment status**:
   ```clarity
   (contract-call? .Invoice get-invoice-payment u1)
   ```

### Subscription Management

1. **Create monthly subscription**:
   ```clarity
   (contract-call? .Invoice create-recurring-invoice 
     'SP2CLIENT123... 
     u2500000 
     "Premium subscription" 
     u2629746) ;; INTERVAL_MONTHLY
   ```

2. **Generate monthly invoice**:
   ```clarity
   (contract-call? .Invoice generate-recurring-invoice u1)
   ```

3. **Pause subscription**:
   ```clarity
   (contract-call? .Invoice pause-recurring-invoice u1)
   ```

### Dashboard Queries

Get all your created invoices:
```clarity
(contract-call? .Invoice get-user-invoices tx-sender)
```

Get recurring invoices ready to generate:
```clarity
(contract-call? .Invoice get-due-recurring-invoices tx-sender)
```

Get subscription history:
```clarity
(contract-call? .Invoice get-recurring-invoice-history u1)
```

## 🛠️ Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet)
- Stacks CLI

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy --testnet
```

## 🔐 Security Features

- ✅ Only invoice creators can cancel their invoices
- ✅ Prevents double payments
- ✅ Automatic overdue detection
- ✅ Immutable payment records
- ✅ Secure STX transfers

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.
