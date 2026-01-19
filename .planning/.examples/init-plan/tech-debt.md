# Tech Debt: Migrate from Moment.js to date-fns

## Current State

The codebase uses Moment.js for date manipulation across 45+ files. Moment.js is:
- In maintenance mode (no new features)
- 67KB gzipped (affects bundle size)
- Mutable API (source of bugs)

## Pain Points

### Bundle Size
- Current: 67KB for Moment.js
- Target: ~7KB for date-fns (tree-shakeable)
- Impact: 60KB reduction = faster page loads

### Developer Experience
- Moment mutates dates in place, causing subtle bugs
- New developers unfamiliar with Moment (modern tutorials use date-fns)
- TypeScript types are community-maintained, occasionally wrong

### Maintenance Risk
- Moment officially recommends migration
- Security vulnerabilities won't receive patches
- Dependency conflicts with newer packages

## Evidence

### Recent bugs caused by Moment mutability:
- #892 - Calendar off-by-one due to mutated date object
- #1045 - Report date range incorrect after filter applied
- #1123 - Scheduled job ran twice due to timezone mutation

### Bundle analysis:
```
moment: 67.2 KB (12% of vendor bundle)
moment-timezone: 34.1 KB (6% of vendor bundle)
Total: 101.3 KB
```

## Proposed Solution

Replace Moment.js with date-fns throughout the codebase.

### Why date-fns:
- Tree-shakeable (only import what you use)
- Immutable by design
- Native Date objects (no wrapper)
- Excellent TypeScript support
- Active development

### Migration Strategy

1. **Add date-fns** alongside Moment (no breaking changes)
2. **Create adapter layer** with consistent API for both
3. **Migrate file-by-file** using adapter
4. **Remove Moment** once all files migrated
5. **Remove adapter** (optional cleanup)

## Scope

### In Scope
- Replace all `moment()` calls with date-fns equivalents
- Update timezone handling (use date-fns-tz)
- Update date formatting strings
- Update unit tests

### Out of Scope
- UI/UX changes to date pickers (separate effort)
- Database date storage format
- API response date formats

## Files Affected

High-level inventory (45 files total):

| Directory | File Count | Complexity |
|-----------|------------|------------|
| src/components/ | 18 | Low (display only) |
| src/services/ | 12 | Medium (business logic) |
| src/utils/date/ | 5 | High (core utilities) |
| src/api/ | 6 | Low (serialization) |
| tests/ | 4 | Medium (test helpers) |

### High-risk files:
- `src/utils/date/dateHelpers.ts` - core utility, used everywhere
- `src/services/scheduling/RecurrenceCalculator.ts` - complex logic
- `src/components/Calendar/CalendarGrid.tsx` - heavy date math

## Success Criteria

- [ ] Zero Moment.js imports in codebase
- [ ] Bundle size reduced by 50KB+
- [ ] All existing date-related tests pass
- [ ] No date-related bugs introduced (monitor for 2 weeks post-deploy)

## Risks

| Risk | Mitigation |
|------|------------|
| Format string differences | Create mapping table, test thoroughly |
| Timezone edge cases | Keep moment-timezone temporarily, migrate separately |
| Hidden dependencies | Search for dynamic imports, check lazy-loaded code |

## Rollback Plan

Adapter layer allows partial rollback. If issues found:
1. Revert specific file to Moment
2. Adapter automatically handles mixed usage
3. Debug and re-attempt migration

## References

- [date-fns documentation](https://date-fns.org/)
- [Moment.js project status](https://momentjs.com/docs/#/-project-status/)
- [Migration guide](https://github.com/date-fns/date-fns/blob/main/docs/unicodeTokens.md)
