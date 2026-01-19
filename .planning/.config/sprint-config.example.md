# Sprint Configuration

This file configures project-specific settings for sprint execution. Copy to `.planning/.config/sprint-config.md` and customize for your project.

---

## Build & Run Commands

Define commands for building and running the project.

| Command | Description | Working Directory |
|---------|-------------|-------------------|
| `wasp start` | Start dev server (frontend + backend) | `app/` |
| `wasp db migrate-dev` | Run database migrations | `app/` |
| `wasp db seed` | Seed database with test data | `app/` |
| `wasp build` | Production build | `app/` |
| `wasp test` | Run unit tests | `app/` |
| `npm run lint` | Run linter | `app/` |
| `npm run typecheck` | Run TypeScript checks | `app/` |

---

## Services & Ports

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 3000 | React development server |
| Backend | 3001 | Node.js API server |
| Database | 5432 | PostgreSQL |
| Redis | 6379 | Cache/sessions (if applicable) |

---

## Health Checks

| Service | Health Check Command | Expected Output |
|---------|---------------------|-----------------|
| Frontend | `curl -s http://localhost:3000` | HTML content |
| Backend | `curl -s http://localhost:3001/api/health` | `{"status":"ok"}` |
| Database | `pg_isready -h localhost -p 5432` | Exit code 0 |

---

## Pre-Sprint Checklist

Run these checks before starting sprint execution:

- [ ] `git status` - Working directory clean
- [ ] `wasp db migrate-dev` - Migrations up to date
- [ ] `npm install` (in app/) - Dependencies installed
- [ ] `.env` configured with required variables
- [ ] Database running and accessible
- [ ] No port conflicts (3000, 3001 free)

---

## Post-Sprint Checklist

Run these checks after sprint completion:

- [ ] `npm run lint` - No linting errors
- [ ] `npm run typecheck` - No type errors
- [ ] `wasp build` - Production build succeeds
- [ ] `wasp test` - All unit tests pass
- [ ] Manual smoke test of key features
- [ ] Documentation updated if needed

---

## Environment Variables

Required environment variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `JWT_SECRET` | Secret for JWT tokens | Yes |
| `SENDGRID_API_KEY` | Email service API key | Optional |
| `STRIPE_SECRET_KEY` | Payment processing | Optional |
| `OPENAI_API_KEY` | AI features | Optional |

---

## Testing Strategy

| Test Type | Command | When to Run |
|-----------|---------|-------------|
| Unit Tests | `wasp test` | After each user story |
| Type Check | `npm run typecheck` | After TypeScript changes |
| Lint | `npm run lint` | Before commits |
| E2E Tests | `/execute-frontend-tests` | After sprint completion |

---

## Deployment

| Environment | Branch | Deploy Command |
|-------------|--------|----------------|
| Development | `develop` | Auto-deploy on push |
| Staging | `staging` | `wasp deploy staging` |
| Production | `main` | `wasp deploy production` |

---

## Project-Specific Notes

### Database

- Uses PostgreSQL 14+
- Prisma ORM for database access
- Migrations in `app/migrations/`

### Authentication

- Email/password authentication
- OAuth providers: Google, GitHub (if configured)
- Session-based auth with JWT tokens

### File Structure

```
app/
├── src/
│   ├── client/     # React frontend
│   ├── server/     # Node.js backend
│   └── shared/     # Shared types/utilities
├── migrations/     # Database migrations
└── main.wasp       # Wasp configuration
```

### Common Issues

- **Port 3000 in use**: Kill existing process or change port in config
- **Database connection failed**: Ensure PostgreSQL is running
- **Migration errors**: Try `wasp db reset` for clean slate (destroys data)

---

## Recovery Procedures

### If dev server crashes:

```bash
# Kill any orphaned processes
pkill -f "wasp"
pkill -f "node.*vite"

# Restart
cd app && wasp start
```

### If database is corrupted:

```bash
cd app
wasp db reset      # Warning: destroys all data
wasp db migrate-dev
wasp db seed
```

### If dependencies are broken:

```bash
cd app
rm -rf node_modules
rm package-lock.json
npm install
```
