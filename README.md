# 🧾 On-Chain Invoice System

A smart contract solution for generating and paying invoices directly on the Stacks blockchain, ensuring transparent and immutable records.

## ✨ Features

- 📝 **Create Invoices**: Generate invoices with amount, recipient, description, and due date
- 💰 **Pay Invoices**: Secure STX payments directly through the blockchain
- ❌ **Cancel Invoices**: Creators can cancel unpaid invoices
- 📊 **Status Tracking**: Real-time invoice status (pending, paid, cancelled, overdue)
- 🔍 **Query Functions**: Comprehensive read-only functions for invoice management
- ⏰ **Automatic Overdue Detection**: Smart contract automatically detects overdue invoices
- 📋 **User Dashboard**: Track created and received invoices per user

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

### Paying an Invoice

```clarity
(contract-call? .Invoice pay-invoice u1) ;; invoice ID
```

### Checking Invoice Status

```clarity
(contract-call? .Invoice get-invoice u1)
```

## 📋 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-invoice` | Create a new invoice | `recipient`, `amount`, `description`, `due-date` |
| `pay-invoice` | Pay an existing invoice | `invoice-id` |
| `cancel-invoice` | Cancel an unpaid invoice (creator only) | `invoice-id` |
| `update-invoice-description` | Update invoice description (creator only) | `invoice-id`, `new-description` |

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

### Dashboard Queries

Get all your created invoices:
```clarity
(contract-call? .Invoice get-user-invoices tx-sender)
```

Get all invoices you need to pay:
```clarity
(contract-call? .Invoice get-pending-invoices-for-user tx-sender)
```

Check for overdue invoices:
```clarity
(contract-call? .Invoice get-overdue-invoices-for-user tx-sender)
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
