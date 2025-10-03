# 🎓 Proof-of-Learning Token (PLT)

A Clarity smart contract that issues tokens based on verified quiz results and project submissions, creating a decentralized proof-of-learning system on the Stacks blockchain.

## 🌟 Features

- **📝 Quiz-based Token Issuance**: Earn tokens based on quiz performance (70%+ score required)
- **🔧 Project Verification**: Submit project hashes for reviewer verification
- **👥 Reviewer System**: Authorized reviewers can verify submissions and award tokens
- **🏆 Learning Tracking**: Track quiz attempts and project submissions per learner
- **🔒 SIP-010 Compliant**: Fully compatible with Stacks token standards

## 🚀 Token Economics

- **Quiz Rewards**: Score × 1,000,000 tokens (minimum 70% score)
- **Project Rewards**: 50,000,000 tokens per verified project
- **Decimals**: 6 (1 PLT = 1,000,000 micro-tokens)

## 🛠️ Usage

### For Contract Owner

```clarity
;; Add a reviewer
(contract-call? .proof-of-learning-token add-reviewer 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Remove a reviewer
(contract-call? .proof-of-learning-token remove-reviewer 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Mint tokens directly (owner only)
(contract-call? .proof-of-learning-token mint u1000000 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### For Reviewers

```clarity
;; Submit quiz result
(contract-call? .proof-of-learning-token submit-quiz-result 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "javascript-basics-001" u85)

;; Verify quiz result (triggers token minting if score >= 70%)
(contract-call? .proof-of-learning-token verify-quiz-result 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "javascript-basics-001")

;; Submit project for verification
(contract-call? .proof-of-learning-token submit-project 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "abc123def456...")

;; Verify project submission (triggers 50M token minting)
(contract-call? .proof-of-learning-token verify-project-submission 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "abc123def456...")
```

### For Learners

```clarity
;; Transfer tokens
(contract-call? .proof-of-learning-token transfer u1000000 tx-sender 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 none)

;; Check your balance
(contract-call? .proof-of-learning-token get-balance tx-sender)
```

## 📊 Read-Only Functions

```clarity
;; Get quiz result
(contract-call? .proof-of-learning-token get-quiz-result 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "quiz-001")

;; Get project submission status
(contract-call? .proof-of-learning-token get-project-submission 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 "hash123")

;; Check if address is a reviewer
(contract-call? .proof-of-learning-token is-reviewer 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Get learner stats
(contract-call? .proof-of-learning-token get-learner-quiz-count 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
(contract-call? .proof-of-learning-token get-learner-project-count 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 🔧 Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd proof-of-learning-token

# Install dependencies
npm install

# Run tests
clarinet test

# Check contract
clarinet check
```

### Testing
```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/proof-of-learning-token_test.ts
```

## 🔐 Security Features

- **Owner-only functions**: Critical operations restricted to contract owner
- **Reviewer authorization**: Only authorized reviewers can verify submissions
- **Duplicate prevention**: Prevents multiple submissions for same quiz/project
- **Score validation**: Quiz scores must be between 0-100
- **Verification control**: Submissions can only be verified once

## 📈 Error Codes

- `u100`: Owner only operation
- `u101`: Not token owner
- `u102`: Insufficient balance
- `u103`: Reviewer not found
- `u104`: Already verified
- `u105`: Submission not found
- `u106`: Invalid quiz score
- `u107`: Quiz already taken
- `u108`: Unauthorized operation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Run `clarinet check` and `clarinet test`
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License.

---

*Built with ❤️ on Stacks blockchain*
