# Bug Report: Payment Processing Timeout on Large Orders

## Summary

Orders with 50+ line items fail with timeout errors during payment processing, causing customer frustration and lost revenue.

## Environment

- **Production**: us-east-1, version 2.4.1
- **First reported**: 2024-01-15
- **Affected users**: ~5% of enterprise customers (high-value segment)

## Reproduction Steps

1. Create a cart with 50+ distinct items
2. Proceed to checkout
3. Enter valid payment information
4. Click "Complete Purchase"
5. **Result**: Spinner shows for 30+ seconds, then "Payment processing failed" error

## Expected Behavior

Payment should complete within 10 seconds regardless of order size.

## Actual Behavior

- Orders with < 30 items: Process normally (2-3 seconds)
- Orders with 30-50 items: Slow but usually succeed (10-20 seconds)
- Orders with 50+ items: Timeout and fail after ~35 seconds

## Impact Assessment

| Metric | Value |
|--------|-------|
| Affected orders/week | ~120 |
| Average order value | $2,400 |
| Weekly revenue impact | ~$45,000 (some retry, some abandon) |
| Customer complaints | 8 tickets this month |
| Churn risk | 2 enterprise accounts mentioned in renewal discussions |

## Technical Investigation

### Preliminary findings:

1. Payment gateway timeout is 30 seconds (not configurable)
2. Order validation runs synchronously before payment
3. Each line item triggers individual inventory check
4. 50 items = 50 sequential database queries

### Suspected root cause:

Sequential inventory validation is O(n) with no batching. Combined with network latency to inventory service, this exceeds gateway timeout.

### Relevant code:

- `src/services/checkout/PaymentProcessor.ts` - orchestrates flow
- `src/services/inventory/InventoryChecker.ts` - sequential queries
- `src/api/payments/stripe.ts` - gateway integration

## Proposed Fix Approaches

### Option A: Batch inventory queries
- Modify `InventoryChecker` to accept array of SKUs
- Single query for all items
- Estimated effort: 1 day
- Risk: Low

### Option B: Async inventory with optimistic payment
- Start payment immediately
- Validate inventory in parallel
- Rollback payment if inventory fails
- Estimated effort: 3 days
- Risk: Medium (rollback complexity)

### Recommended: Option A

## Success Criteria

- [ ] Orders with 100+ items complete in < 10 seconds
- [ ] No increase in inventory over-sell rate
- [ ] Payment success rate returns to 99.5%+

## Workaround

Customer support can split large orders into multiple smaller orders. This is manual and creates a poor customer experience.

## Related Issues

- #1234 - "Checkout performance improvements" (closed, partially addressed this)
- #1567 - "Inventory service optimization" (open, related backend work)
