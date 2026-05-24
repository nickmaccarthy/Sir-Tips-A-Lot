# Change: Add round-total option

## Why
Users can already round the tip up to the next dollar, but some prefer the final amount paid to land on a clean whole-dollar total. The calculator should support that workflow without making users manually adjust the tip.

## What Changes
- Add a setting to round the final total up to the next whole dollar by increasing the tip.
- Keep round-tip and round-total settings mutually exclusive.
- Apply the selected default rounding mode to new calculator sessions and reset behavior.
- Update calculated totals, split amounts, saved bills, and sharing text to reflect total rounding.

## Impact
- Affected specs: tip-rounding
- Affected code: `TipCalculatorViewModel`, `ContentView`, `SettingsView`, tip calculator tests
