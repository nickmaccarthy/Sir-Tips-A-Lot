## ADDED Requirements

### Requirement: Round Final Total Up
The system SHALL provide a setting that rounds the final total up to the next whole currency unit by increasing the calculated tip amount.

#### Scenario: Total has cents
- **GIVEN** the bill is 45.67
- **AND** the calculated tip before rounding is 8.2206
- **WHEN** round-total mode is enabled
- **THEN** the final total SHALL be 54.00
- **AND** the displayed tip SHALL be 8.33

#### Scenario: Total is already whole
- **GIVEN** the bill is 100.00
- **AND** the calculated tip before rounding is 20.00
- **WHEN** round-total mode is enabled
- **THEN** the final total SHALL remain 120.00
- **AND** the displayed tip SHALL remain 20.00

### Requirement: Mutually Exclusive Rounding Modes
The system SHALL prevent round-tip and round-total modes from being enabled at the same time.

#### Scenario: Round total is enabled after round tip
- **GIVEN** round-tip mode is enabled
- **WHEN** the user enables round-total mode
- **THEN** round-tip mode SHALL be disabled
- **AND** round-total mode SHALL be enabled

#### Scenario: Round tip is enabled after round total
- **GIVEN** round-total mode is enabled
- **WHEN** the user enables round-tip mode
- **THEN** round-total mode SHALL be disabled
- **AND** round-tip mode SHALL be enabled
