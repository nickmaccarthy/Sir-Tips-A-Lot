# Sample Checks Analysis

This directory contains sample receipt/check images used to test and improve the receipt scanner functionality in Sir Tips-A-Lot. Each image has been analyzed to document the label variations, amounts, and formatting patterns that the scanner needs to handle.

## Quick Reference Table

| Filename | Venue | Subtotal | Tax | Gratuity | Total | Gratuity Included? |
|----------|-------|----------|-----|----------|-------|-------------------|
| bar-bill-1.webp | Sidecar Bar & Grill | $90.00 | $11.70 | - | $101.70 | No |
| bar-tab-1.jpg | Hotel Restaurant and Bar | $56.00 | $4.76 | - | $60.76 | No |
| bar-tab-2.jpg | Burrito Bar | $20.96 | $1.15 | - | $22.11 | No |
| bar-tab-3.jpg | Bar-Bill Tavern | $39.71 | $3.47 | - | $43.18 | No |
| bill-gratuity-2.jpeg | GuestCheck (handwritten) | ~$79 | - | ~15% | ~$90 | Yes |
| bill-gratuity-3.jpg | G Pay receipt | $54.00 | $5.13 | $11.88 (22%) | $71.01 | Yes |
| bill-w-gratuity-added.png | Five Acres | $67.00 | $5.93 | $14.59 (20%) | $87.52 | Yes |

---

## Detailed File Analysis

### 1. bar-bill-1.webp

**Venue:** Sidecar Bar & Grill
**Location:** 577 College Street, Toronto, Ontario
**Date:** 12/06/2011
**Image Quality:** Clear, printed thermal receipt

**Line Items:**
| Qty | Item | Price |
|-----|------|-------|
| 1 | Oysters | $6.00 |
| 1 | Smelts | $12.00 |
| 1 | Duck Terrine | $14.00 |
| 1 | Prix Dessert | $0.00 |
| 1 | AG Malbec | $25.00 |
| 1 | Soup | $8.00 |
| 1 | Tagliatelle | $16.00 |
| 1 | D&S Brownie | $9.00 |

**Financial Summary:**
| Label Used | Amount |
|------------|--------|
| `SUB-TOTAL:` | $90.00 |
| `Hst:` | $11.70 |
| `TOTAL:` | $101.70 |

**Notes:**
- Canadian receipt using HST (Harmonized Sales Tax)
- No gratuity added
- Label uses hyphen: "SUB-TOTAL" not "SUBTOTAL"
- Tax labeled as "Hst" (lowercase 'st')

---

### 2. bar-tab-1.jpg

**Venue:** Hotel Restaurant and Bar
**Location:** 1016 6th Ave, New York, NY
**Date:** 09/25/2020
**Image Quality:** Clear, printed receipt (appears to be a mock/sample)

**Line Items:**
| Qty | Item | Price |
|-----|------|-------|
| 1 | Hendrick Gin & Tonic | $10.50 |
| 1 | Ginger Mule | $9.50 |
| 1 | Glass Camus Zin | $24.00 |
| 1 | Titos Vodka Soda | $12.00 |

**Financial Summary:**
| Label Used | Amount |
|------------|--------|
| `SUB-TOTAL` | $56.00 |
| `TAX` | $4.76 |
| `Amount` | $60.76 |
| `BALANCE` | $60.76 |

**Notes:**
- Multiple total labels: "Amount" and "BALANCE" both show $60.76
- Has blank `TIP` and `TOTAL` lines for customer to fill in
- Signature line at bottom
- Credit card auth shown: VISA ####3993

---

### 3. bar-tab-2.jpg

**Venue:** Burrito Bar
**Location:** 900 Kirkwood Ave, West Hollywood, CA
**Date:** 12/14/2018
**Image Quality:** Clear, printed thermal receipt with logo

**Line Items:**
| Item | Price |
|------|-------|
| CHICKEN BURRITO | $8.79 |
| KIDS MEAL - MAKE OWN | $4.99 |
| LARGE DRINK | $2.19 |
| DOMESTIC BEER | $4.99 |

**Financial Summary:**
| Label Used | Amount |
|------------|--------|
| `SUBTOTAL:` | $20.96 |
| `TAX:` | $1.15 |
| `BALANCE DUE` | $22.11 |

**Notes:**
- Labels include colons: "SUBTOTAL:" and "TAX:"
- Total labeled as "BALANCE DUE" (not "TOTAL")
- All uppercase text
- VISA payment authorized

---

### 4. bar-tab-3.jpg

**Venue:** Bar-Bill Tavern Inc.
**Location:** 185 Main Street, East Aurora, NY 14052
**Date:** 1/19/2015
**Image Quality:** Photo of actual receipt on table, slightly angled, readable

**Line Items:**
| Item | Price |
|------|-------|
| 16oz Guinness | $4.60 |
| 16oz Labatts | $2.76 |
| Mozzarella Salad | $6.95 |
| 20 Wings | $18.95 |
| + half Teriyaki | $0.50 |
| Jalapeno Poppers | $5.95 |

**Financial Summary:**
| Label Used | Amount |
|------------|--------|
| `SubTotal` | $39.71 |
| `State Tax` | $3.47 |
| `Total` | $43.18 |
| `Total Due` | $43.18 |

**Notes:**
- Mixed case: "SubTotal" (camelCase)
- Tax labeled as "State Tax"
- Both "Total" and "Total Due" displayed
- Real photo with some shadows/angle

---

### 5. bill-gratuity-2.jpeg

**Venue:** GuestCheck (generic check pad)
**Location:** Unknown
**Date:** Unknown
**Image Quality:** Poor - handwritten, at angle, partially obscured

**Line Items (partially legible):**
- Appears to show food/drink items
- Handwritten prices difficult to read

**Financial Summary:**
| Label Used | Amount |
|------------|--------|
| `Sub Tot:` | ~$79 |
| `Gratuity` | ~15% or $15 |
| `Total` | ~$90 |

**Notes:**
- **GRATUITY INCLUDED** - rubber stamp at bottom of check
- Handwritten check - OCR challenge
- Amounts circled for emphasis
- Abbreviation used: "Sub Tot" instead of "Subtotal"
- This is the most challenging image for scanner accuracy

---

### 6. bill-gratuity-3.jpg

**Venue:** Unknown (G Pay receipt)
**Location:** Unknown
**Date:** 9/29/23
**Image Quality:** Clear, printed receipt, photo taken at slight angle

**Line Items:**
| Item | Price |
|------|-------|
| Harvest | $18.00 |
| New Old Fashioned | $18.00 |
| Day at the Races | $18.00 |

**Financial Summary:**
| Label Used | Amount |
|------------|--------|
| `Subtotal` | $54.00 |
| `22% Auto Gratuity (22.00%)` | $11.88 |
| `Tax` | $5.13 |
| `Total` | $71.01 |

**Suggested Additional Tips Section:**
| Percentage | Tip Amount | New Total |
|------------|------------|-----------|
| +2% | $1.08 | $72.09 |
| +3% | $1.62 | $72.63 |
| +5% | $2.70 | $73.71 |
| +7% | $3.78 | $74.79 |

**Notes:**
- **GRATUITY INCLUDED** - 22% auto gratuity already applied
- Explicit percentage shown in label: "22% Auto Gratuity (22.00%)"
- Additional tip suggestions printed (for adding on top of auto-gratuity)
- Note states: "Tip percentages are based on the check price before taxes"
- G Pay branding at top

---

### 7. bill-w-gratuity-added.png

**Venue:** Five Acres
**Location:** 30 Rockefeller Plaza, Suite 8|Rink Level, New York, NY 10012
**Date:** 10/24/23
**Image Quality:** Excellent, clear printed receipt

**Line Items:**
| Qty | Item | Price |
|-----|------|-------|
| 1 | Kale Avocado | $30.00 |
| 1 | Fever Tree Club Soda | $6.00 |
| 1 | Niçoise Salad | $25.00 |
| 1 | Mint Iced Tea | $6.00 |

**Financial Summary:**
| Label Used | Amount |
|------------|--------|
| `Subtotal` | $67.00 |
| `Gratuity (20.00%)` | $14.59 |
| `Tax` | $5.93 |
| `Total` | $87.52 |

**Notes:**
- **GRATUITY INCLUDED** - 20% auto gratuity
- Explicit percentage in parentheses: "Gratuity (20.00%)"
- Footer note: "20% gratuity, for our hardworking staff, is added to all checks."
- Guest count shown: 2
- Clearest example of auto-gratuity formatting

---

## Scanner Improvement Insights

### Label Variations to Detect

**Subtotal Labels:**
| Variation | File Found In |
|-----------|---------------|
| `SUB-TOTAL:` | bar-bill-1.webp |
| `SUB-TOTAL` | bar-tab-1.jpg |
| `SUBTOTAL:` | bar-tab-2.jpg |
| `SubTotal` | bar-tab-3.jpg |
| `Subtotal` | bill-gratuity-3.jpg, bill-w-gratuity-added.png |
| `Sub Tot:` | bill-gratuity-2.jpeg |

**Tax Labels:**
| Variation | File Found In |
|-----------|---------------|
| `Hst:` | bar-bill-1.webp |
| `TAX` | bar-tab-1.jpg |
| `TAX:` | bar-tab-2.jpg |
| `State Tax` | bar-tab-3.jpg |
| `Tax` | bill-gratuity-3.jpg, bill-w-gratuity-added.png |

**Total Labels:**
| Variation | File Found In |
|-----------|---------------|
| `TOTAL:` | bar-bill-1.webp |
| `Amount` | bar-tab-1.jpg |
| `BALANCE` | bar-tab-1.jpg |
| `BALANCE DUE` | bar-tab-2.jpg |
| `Total` | bar-tab-3.jpg, bill-gratuity-3.jpg, bill-w-gratuity-added.png |
| `Total Due` | bar-tab-3.jpg |

**Gratuity Labels:**
| Variation | File Found In |
|-----------|---------------|
| `Gratuity (20.00%)` | bill-w-gratuity-added.png |
| `22% Auto Gratuity (22.00%)` | bill-gratuity-3.jpg |
| `Gratuity Included` (stamp) | bill-gratuity-2.jpeg |

### Gratuity Detection Signals

The scanner should look for these indicators that gratuity is already included:

1. **Explicit gratuity line items:**
   - Lines containing "Gratuity" followed by percentage and amount
   - Lines containing "Auto Gratuity"
   - Pattern: `Gratuity (XX.XX%)` or `XX% Auto Gratuity`

2. **Keywords/phrases:**
   - "Gratuity Included"
   - "Auto Gratuity"
   - "Service Charge"
   - "gratuity...is added to all checks"

3. **Suggested "Additional Tip" section:**
   - If receipt shows suggested tips as small percentages (2%, 3%, 5%, 7%), it likely means a larger gratuity was already added

### Formatting Patterns

**Currency Formatting:**
- All amounts use USD format: `$XX.XX`
- Dollar sign always precedes amount
- Two decimal places consistently used

**Alignment:**
- Labels typically left-aligned
- Amounts typically right-aligned
- Colon sometimes used after label (e.g., `SUBTOTAL:`)

**Case Variations:**
- ALL CAPS: `SUBTOTAL`, `TAX`, `TOTAL`
- Title Case: `Subtotal`, `Tax`, `Total`
- camelCase: `SubTotal`
- Abbreviations: `Sub Tot`, `Hst`

### Edge Cases for Scanner

1. **Handwritten checks** (bill-gratuity-2.jpeg)
   - OCR accuracy significantly reduced
   - Amounts may be circled or underlined
   - Abbreviations more common

2. **Multiple total values** (bar-tab-1.jpg, bar-tab-3.jpg)
   - "Amount", "Balance", "Total", "Total Due" may all appear
   - Scanner should prefer the highest value as the final total

3. **Blank tip lines** (bar-tab-1.jpg)
   - Some receipts have blank TIP and TOTAL lines
   - Should use "Balance" or "Amount" as the bill total to tip on

4. **Tax name variations**
   - Regional tax names: HST (Canada), State Tax, etc.
   - Scanner should recognize all as tax amounts

5. **Gratuity already calculated into total**
   - When gratuity is included, the user should NOT tip on the full total
   - Scanner should detect and warn user, or calculate tip on subtotal only

---

## Recommended Scanner Regex Patterns

```swift
// Subtotal patterns
let subtotalPatterns = [
    "sub[\\-\\s]?total[:\\s]*\\$?([\\d,]+\\.\\d{2})",
    "subtotal[:\\s]*\\$?([\\d,]+\\.\\d{2})"
]

// Tax patterns
let taxPatterns = [
    "(?:tax|hst|gst|state\\s*tax)[:\\s]*\\$?([\\d,]+\\.\\d{2})"
]

// Total patterns
let totalPatterns = [
    "(?:total|balance|amount|balance\\s*due|total\\s*due)[:\\s]*\\$?([\\d,]+\\.\\d{2})"
]

// Gratuity detection patterns
let gratuityPatterns = [
    "(?:gratuity|auto\\s*gratuity|service\\s*charge)[^\\d]*([\\d]+(?:\\.\\d{2})?)[\\s]*%?",
    "gratuity\\s*included",
    "(\\d+)%\\s*auto\\s*gratuity"
]
```

---

## Test Coverage Recommendations

The scanner should be tested against all 7 images to ensure:

1. [ ] Correctly identifies subtotal in all images
2. [ ] Correctly identifies tax in 6/7 images (bill-gratuity-2 may not have visible tax)
3. [ ] Correctly identifies final total in all images
4. [ ] Detects gratuity is included in 3/7 images
5. [ ] Handles handwritten receipt (bill-gratuity-2) gracefully
6. [ ] Ignores "suggested tip" amounts that appear after auto-gratuity
