## 1. Implementation
- [x] 1.1 Add model state and calculation logic for rounding the total up to the next whole dollar.
- [x] 1.2 Add persisted settings toggles for round-tip and round-total defaults, enforcing mutual exclusivity.
- [x] 1.3 Update the calculator UI to initialize and reset with the selected rounding mode.
- [x] 1.4 Update saved bills, split amounts, and share output to use rounded-total results.
- [x] 1.5 Add or update view model tests for total rounding and mutually exclusive rounding behavior.

## 2. Verification
- [x] 2.1 Run the relevant XCTest target or the narrowest available test command.
- [x] 2.2 Validate the OpenSpec change and typecheck the app Swift sources.
