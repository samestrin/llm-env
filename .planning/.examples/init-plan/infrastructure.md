# Infrastructure: Add Preview Environments for Pull Requests

## Context

Our team of 12 developers shares 2 staging environments. This creates bottlenecks during code review and QA, with developers waiting hours for environment availability.

## Problem Statement

Current workflow:
1. Developer opens PR
2. Waits for staging environment
3. Deploys to shared staging
4. Reviewer tests
5. Another developer waiting bumps them off staging
6. Re-deploy, re-test cycle

Average PR review time has increased from 4 hours to 2 days due to environment contention.

## Proposed Solution

Implement ephemeral preview environments that:
- Spin up automatically when PR is opened
- Deploy the PR branch with isolated resources
- Provide unique URL for testing
- Tear down when PR is merged/closed

## Requirements

### Functional
- Automatic deployment on PR open/update
- Unique URL per PR (e.g., `pr-123.preview.example.com`)
- Database seeded with test data
- Environment deleted on PR close
- Status check posted to GitHub PR

### Non-Functional
- Deploy time: < 5 minutes
- Cost: < $50/month (estimate 10 concurrent previews)
- Security: No production data access

## Technical Approach

### Option A: Vercel/Netlify Preview Deployments
- Pros: Zero infrastructure management, fast
- Cons: Frontend only, need separate backend solution
- Cost: Included in Pro plan

### Option B: AWS ECS + RDS (Containerized)
- Pros: Full stack, matches production
- Cons: More complex, higher baseline cost
- Cost: ~$100/month at current scale

### Option C: Kubernetes Namespaces
- Pros: Isolated, scalable, matches production
- Cons: Requires K8s expertise, cluster overhead
- Cost: ~$150/month (shared cluster)

### Recommended: Option A + Serverless Backend

Use Vercel for frontend previews + AWS Lambda for API previews. Best balance of simplicity and cost.

## Implementation Components

1. **GitHub Actions Workflow**
   - Trigger on PR events
   - Build and deploy to preview infrastructure
   - Post deployment URL to PR

2. **Preview Infrastructure**
   - Frontend: Vercel automatic previews
   - Backend: Lambda functions with unique API Gateway stage
   - Database: Shared RDS with schema-per-PR or SQLite for previews

3. **Cleanup Automation**
   - Lambda triggered on PR close
   - Removes API Gateway stage
   - Drops preview database schema

4. **DNS Configuration**
   - Wildcard certificate for `*.preview.example.com`
   - Dynamic DNS records via Route 53 API

## Constraints

- Must work with existing GitHub repository
- Cannot affect production infrastructure
- Must support current Node.js 18 runtime
- Preview URLs must use HTTPS

## Out of Scope

- Production deployment changes
- Staging environment modifications
- Performance testing environments
- Long-running preview environments (max 7 days)

## Success Criteria

- [ ] PR opens trigger automatic deployment
- [ ] Preview URL available within 5 minutes
- [ ] Reviewer can test full functionality
- [ ] Environment cleaned up within 1 hour of PR close
- [ ] Monthly cost stays under $75

## Rollback Plan

Preview environments are additive. If issues occur:
1. Disable GitHub Action trigger
2. Existing staging workflow continues unchanged
3. Debug and re-enable when fixed

## Security Considerations

- Preview environments use test data only
- No access to production databases
- API keys are preview-specific (rate limited)
- URLs are not indexed (robots.txt)
- Authentication required (same as staging)

## Timeline Milestones

1. GitHub Action + Vercel frontend previews
2. Lambda backend preview deployment
3. Database isolation per preview
4. Cleanup automation
5. Documentation and team training
