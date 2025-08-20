# 🆔 Decentralized Digital ID Badges

A Clarity smart contract for issuing verifiable blockchain-based ID badges for employees, students, volunteers, and more! 🎯

## ✨ Features

- 🏷️ **Issue Digital Badges** - Create verifiable ID badges on the blockchain
- 👥 **Multi-Role Support** - Perfect for employees, students, volunteers, and any organization
- 🔐 **Authorized Issuers** - Only approved entities can issue badges
- ⏰ **Expiration Control** - Set optional expiration dates for badges
- 🚫 **Badge Revocation** - Revoke badges when needed
- 📊 **Batch Operations** - Issue multiple badges at once
- 🔍 **Easy Verification** - Verify badge authenticity and validity

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <your-repo-url>
cd Decentralized-Digital-ID-Badges
clarinet check
```

## 📋 Contract Functions

### 👑 Admin Functions

#### `add-authorized-issuer`
```clarity
(add-authorized-issuer principal)
```
Add a new authorized issuer (contract owner only).

#### `remove-authorized-issuer`
```clarity
(remove-authorized-issuer principal)
```
Remove an authorized issuer (contract owner only).

### 🎫 Badge Management

#### `issue-badge`
```clarity
(issue-badge recipient badge-type expires-at metadata)
```
Issue a new badge to a recipient.
- `recipient`: Principal receiving the badge
- `badge-type`: Type of badge (e.g., "employee", "student", "volunteer")
- `expires-at`: Optional expiration block height
- `metadata`: Additional badge information

#### `batch-issue-badges`
```clarity
(batch-issue-badges recipients-list)
```
Issue multiple badges at once (up to 10).

#### `revoke-badge`
```clarity
(revoke-badge badge-id)
```
Revoke a specific badge (issuer or owner only).

### 🔍 Verification & Queries

#### `verify-badge`
```clarity
(verify-badge badge-id)
```
Verify a badge's authenticity and validity.

#### `get-badge`
```clarity
(get-badge badge-id)
```
Get complete badge information.

#### `get-user-badges`
```clarity
(get-user-badges user)
```
Get all badge IDs for a specific user.

#### `is-badge-valid`
```clarity
(is-badge-valid badge-id)
```
Check if a badge is currently valid (not revoked/expired).

## 💡 Usage Examples

### For Organizations

1. **Add your organization as an issuer:**
```clarity
(contract-call? .digital-id-badges add-authorized-issuer 'SP1ORGANIZATION)
```

2. **Issue employee badges:**
```clarity
(contract-call? .digital-id-badges issue-badge 
  'SP1EMPLOYEE 
  "employee" 
  (some u1000000) 
  "Software Engineer, Tech Department")
```

3. **Issue student ID badges:**
```clarity
(contract-call? .digital-id-badges issue-badge 
  'SP1STUDENT 
  "student" 
  (some u2000000) 
  "Computer Science, Class of 2024")
```

### For Verification

```clarity
(contract-call? .digital-id-badges verify-badge u1)
```

## 🏗️ Contract Architecture

- **Storage Maps**: Efficiently store badges and user associations
- **Authorization System**: Role-based access control for issuers
- **Expiration Handling**: Automatic expiration checking
- **Batch Operations**: Gas-efficient bulk badge issuance
- **Metadata Support**: Flexible badge information storage

## 🔧 Development

### Testing

```bash
clarinet test
```

### Deployment

```bash
clarinet deploy --testnet
```

## 📊 Badge Types

The contract supports any badge type via string identifiers:

- 🏢 `"employee"` - Company employee badges
- 🎓 `"student"` - Educational institution badges  
- 🤝 `"volunteer"` - Volunteer organization badges
- 🏆 `"certification"` - Professional certifications
- 🎪 `"event-attendee"` - Event participation badges
- 🔰 `"member"` - Membership badges

## 🛡️ Security Features

- ✅ Owner-only administrative functions
- ✅ Issuer authorization system
- ✅ Badge expiration enforcement
- ✅ Revocation capabilities
- ✅ Input validation and error handling

## 📈 Scalability

- Supports up to 100 badges per user
- Batch issuance for efficiency
- Optimized storage patterns
- Gas-efficient operations

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Run tests: `clarinet test`
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

---

Built with ❤️ using [Clarity](https://clarity-lang.org/) and [Stacks](https://stacks.co/)
