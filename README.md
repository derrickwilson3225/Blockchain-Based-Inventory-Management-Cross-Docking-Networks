# Blockchain-Based Inventory Management Cross-Docking Networks

A comprehensive smart contract system for managing cross-docking operations on the Stacks blockchain using Clarity.

## Overview

This system provides a complete solution for cross-docking inventory management with five core contracts:

1. **Coordinator Verification** - Validates and manages cross-dock coordinators
2. **Flow Optimization** - Optimizes inventory flow through cross-dock facilities
3. **Scheduling Management** - Manages cross-dock scheduling and time slots
4. **Quality Control** - Controls and monitors cross-dock quality standards
5. **Efficiency Measurement** - Measures and tracks cross-dock efficiency metrics

## Features

### Coordinator Verification Contract
- Register and verify cross-dock coordinators
- Manage coordinator permissions and roles
- Track coordinator performance metrics
- Suspend/reactivate coordinators

### Flow Optimization Contract
- Optimize inventory routing through cross-dock facilities
- Calculate optimal flow paths
- Manage capacity constraints
- Track flow efficiency metrics

### Scheduling Management Contract
- Create and manage time slots for cross-dock operations
- Schedule inbound and outbound shipments
- Handle scheduling conflicts
- Track scheduling efficiency

### Quality Control Contract
- Set and enforce quality standards
- Record quality inspections
- Manage quality violations
- Track quality metrics over time

### Efficiency Measurement Contract
- Calculate throughput metrics
- Measure processing times
- Track cost efficiency
- Generate performance reports

## Contract Architecture

Each contract is designed to be independent with no cross-contract calls, ensuring:
- Simplified deployment and testing
- Reduced complexity and gas costs
- Enhanced security through isolation
- Easier maintenance and upgrades

## Data Types

The system uses standard Clarity data types:
- \`uint\` for numeric values (IDs, quantities, timestamps)
- \`principal\` for user addresses
- \`(string-ascii 50)\` for names and descriptions
- \`bool\` for status flags
- Custom tuples for complex data structures

## Error Handling

Comprehensive error handling with descriptive error codes:
- \`ERR-NOT-AUTHORIZED\` (u100)
- \`ERR-INVALID-INPUT\` (u101)
- \`ERR-NOT-FOUND\` (u102)
- \`ERR-ALREADY-EXISTS\` (u103)
- \`ERR-CAPACITY-EXCEEDED\` (u104)

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation

1. Clone the repository
2. Install dependencies: \`npm install\`
3. Run tests: \`npm test\`
4. Deploy contracts: \`clarinet deploy\`

### Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for complete workflows
- Edge case testing for error conditions

### Usage Examples

#### Register a Coordinator
\`\`\`clarity
(contract-call? .coordinator-verification register-coordinator "John Doe" "Warehouse A")
\`\`\`

#### Schedule a Cross-Dock Operation
\`\`\`clarity
(contract-call? .scheduling-management create-schedule u1640995200 u1640998800 u1000)
\`\`\`

#### Record Quality Inspection
\`\`\`clarity
(contract-call? .quality-control record-inspection u1 u95 "Passed all checks")
\`\`\`

## Security Considerations

- All functions include proper authorization checks
- Input validation prevents invalid data entry
- Principal-based access control ensures security
- No external dependencies reduce attack surface

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
