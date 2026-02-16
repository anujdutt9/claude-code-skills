# Session Handover Documentation Skill

## Purpose
This skill enables Claude to generate comprehensive handover documents that capture everything accomplished in a coding session, preventing context loss and preserving institutional knowledge between sessions.

## When to Use This Skill
- At the end of any coding session when the user types `/handover`
- When context window is filling up and session needs to wrap
- Before major architecture changes or pivots
- When switching between different features or components
- Automatically via pre-compact hook (see setup instructions)

## Core Principle
Think of handover documents as shift-change reports for engineering work. They tell the next Claude instance (or the same Claude in a new session) exactly where things stand so nothing gets lost between sessions.

## Handover Document Structure

### 1. Session Overview
- Brief 2-3 sentence summary of what this session was about
- Primary goal or objective
- Overall outcome (completed, in-progress, blocked, etc.)

### 2. What Got Done
- Concrete accomplishments and deliverables
- Files created, modified, or deleted (with paths)
- Features implemented or bugs fixed
- Tests written or passing
- Dependencies added or updated
- Configuration changes

### 3. What Worked and What Didn't
- **Successes**: Approaches that worked well, patterns that proved effective
- **Challenges**: Bugs encountered and how they were resolved
- **Failed attempts**: What was tried but didn't work (and why)
- **Technical debt incurred**: Shortcuts taken that need revisiting

### 4. Key Decisions Made
- Architecture decisions and rationale
- Technology choices (libraries, frameworks, approaches)
- Trade-offs considered and chosen
- Design patterns applied
- Performance or security considerations

### 5. Lessons Learned and Gotchas
- Insights gained during implementation
- Edge cases discovered
- API quirks or library limitations
- Environment-specific issues
- Documentation gaps found

### 6. Clear Next Steps
- Immediate priorities (ordered by importance)
- Specific tasks to tackle in next session
- Open questions that need answers
- Blocked items and their blockers
- Future enhancements or refactoring needs

### 7. Important Files Map
- Critical files and their purposes
- Where key functionality lives
- Configuration file locations
- Documentation locations
- Test file organization

### 8. Context Preservation
- Current mental model of the system
- Assumptions being made
- External dependencies or integrations
- Environment setup requirements
- Running commands or workflows

## File Naming Convention
Save handover documents as: `HANDOVER-YYYY-MM-DD-HHMM.md` in the `.claude/` directory.

Examples with timestamps:
- `HANDOVER-2026-02-10-0930.md` (9:30 AM session)
- `HANDOVER-2026-02-10-1430.md` (2:30 PM session)
- `HANDOVER-2026-02-11-1000.md` (Next day, 10:00 AM)

## Writing Style Guidelines

### Be Specific and Concrete
❌ "Fixed some bugs"
✅ "Fixed race condition in token refresh logic (auth.ts:145) where concurrent requests could cause double-refresh attempts"

❌ "Updated the API"
✅ "Migrated /users endpoint from REST to GraphQL, maintaining backward compatibility via adapter pattern in api/adapters/users.ts"

### Include Code Locations
Always reference specific files and line numbers when relevant:
- "Modified the validation logic in `src/validators/schema.ts:78-92`"
- "Added new hook `useAuthState` in `hooks/auth.tsx`"

### Capture Decision Rationale
Don't just say what was done, explain why:
- "Chose Redis over in-memory cache because we need persistence across container restarts and multi-instance support"
- "Decided against using Zod here because the validation is simple and adding the dependency would increase bundle size by 10KB"

### Document Failed Attempts
These save time in future sessions:
- "Attempted to use React.lazy for code splitting but ran into SSR hydration issues. Reverted to standard imports for now."
- "Tried using the native Fetch API but needed more granular timeout control, switched to axios"

### Be Honest About Technical Debt
- "Quick fix in place using string comparison, but should be refactored to use proper enum types"
- "Skipped comprehensive error handling to unblock testing, needs proper error boundaries"

## Example Handover Document

```markdown
# Handover Document - 2026-02-10

## Session Overview
Implemented user authentication system with JWT tokens and refresh token rotation. Core functionality is working and tested, but rate limiting and account lockout features are still pending.

## What Got Done
- ✅ Set up JWT authentication with access + refresh tokens
- ✅ Created auth middleware (`middleware/auth.ts`)
- ✅ Implemented login/logout endpoints (`routes/auth.ts`)
- ✅ Added token refresh endpoint with rotation
- ✅ Created protected route wrapper (`middleware/requireAuth.ts`)
- ✅ Wrote unit tests for token validation (22 passing)
- ✅ Added Redis for refresh token storage
- ✅ Documented API in OpenAPI spec

**Files Modified:**
- `src/middleware/auth.ts` - JWT validation and middleware
- `src/routes/auth.ts` - Authentication endpoints
- `src/services/tokenService.ts` - Token generation/validation logic
- `src/config/redis.ts` - Redis client setup
- `tests/auth.test.ts` - Authentication test suite

## What Worked and What Didn't

### Successes
- JWT library (@auth/core) worked smoothly with minimal config
- Redis integration was straightforward using ioredis
- Test coverage tool integration helped catch edge cases early

### Challenges & Solutions
- **Issue**: Token refresh race condition when multiple tabs made concurrent requests
  - **Solution**: Added distributed lock using Redis SETNX with 2-second TTL
  - **Location**: `src/services/tokenService.ts:145-167`

- **Issue**: Environment variable loading inconsistent across dev/test
  - **Solution**: Created centralized config loader with validation using zod
  - **Location**: `src/config/env.ts`

### Failed Attempts
- Tried using httpOnly cookies for access tokens but ran into CORS issues with our subdomain architecture. Reverted to Authorization header approach.
- Attempted to use built-in crypto.subtle for token signing but performance was 3x slower than jose library. Kept jose.

## Key Decisions Made

1. **Token Expiry Times**
   - Access token: 15 minutes (short for security)
   - Refresh token: 7 days (balance between security and UX)
   - Rationale: Follows OWASP recommendations, reduces attack window

2. **Refresh Token Rotation**
   - Implemented automatic rotation on each refresh
   - Old tokens invalidated immediately
   - Rationale: Prevents token replay attacks

3. **Token Storage**
   - Using Redis for refresh tokens instead of database
   - Rationale: Fast lookups, built-in TTL, easy to scale horizontally

4. **Error Handling Strategy**
   - 401 for invalid/expired tokens (triggers re-auth)
   - 403 for valid tokens with insufficient permissions
   - Rationale: Standard HTTP semantics, client can handle appropriately

## Lessons Learned and Gotchas

1. **Redis TTL Precision**: Redis EXPIRE uses seconds, not milliseconds. Had to round up token expiry times to avoid premature expiration.

2. **JWT Clock Skew**: Added 30-second leeway for token validation to handle clock drift between servers (jose `clockTolerance` option).

3. **Testing Async Token Generation**: Had to use `jest.mock('node:crypto')` to make crypto operations deterministic in tests.

4. **TypeScript Gotcha**: Express Request type doesn't include custom properties by default. Had to extend it in `types/express.d.ts` to add `user` property.

## Clear Next Steps

### Immediate (Next Session)
1. **Add rate limiting** - Implement sliding window rate limiter for login endpoint (5 attempts per 15 min per IP)
   - Use Redis sorted sets for window tracking
   - Return 429 with Retry-After header

2. **Account lockout mechanism** - Lock account after 10 failed login attempts within 1 hour
   - Store attempt count in Redis with 1-hour TTL
   - Send email notification on lockout

3. **Add integration tests** - Test full auth flow end-to-end with supertest

### Medium Priority
4. Email verification flow (registration not fully implemented yet)
5. Password reset functionality
6. Add monitoring/logging for failed auth attempts
7. Implement session management UI (view/revoke active sessions)

### Future Enhancements
- Two-factor authentication (TOTP)
- OAuth integration (Google, GitHub)
- Biometric authentication support

### Blocked Items
- None currently

## Important Files Map

```
src/
├── middleware/
│   ├── auth.ts              # JWT validation middleware (use on protected routes)
│   └── requireAuth.ts       # Wrapper that enforces authentication
├── routes/
│   └── auth.ts              # POST /login, /logout, /refresh endpoints
├── services/
│   ├── tokenService.ts      # Core token generation/validation logic
│   └── userService.ts       # User lookup and password verification
├── config/
│   ├── env.ts               # Environment variable loader with validation
│   └── redis.ts             # Redis client singleton
└── types/
    └── express.d.ts         # TypeScript type extensions

tests/
└── auth.test.ts            # 22 unit tests for auth logic
```

**Key Entry Points:**
- Apply auth middleware: `app.use('/api/protected', requireAuth)`
- Generate tokens: `tokenService.generateTokenPair(userId)`
- Validate token: `tokenService.validateAccessToken(token)`

## Context Preservation

### Mental Model
The auth system follows a dual-token pattern: short-lived access tokens for API requests and long-lived refresh tokens for obtaining new access tokens. Refresh tokens are stored in Redis and rotated on each use to prevent replay attacks.

### Current Assumptions
- Single Redis instance is sufficient (no clustering yet)
- Users won't need to be logged in on more than 5 devices (current refresh token limit)
- Email service integration will be available for account lockout notifications

### Environment Setup
```bash
# Required environment variables
JWT_SECRET=<random-256-bit-string>
JWT_REFRESH_SECRET=<different-random-256-bit-string>
REDIS_URL=redis://localhost:6379

# Start services
docker-compose up -d redis
npm run dev

# Run tests
npm test -- --coverage
```

### Running Commands
- `npm run dev` - Starts server with hot reload on port 3000
- `npm test` - Runs test suite
- `redis-cli KEYS "refresh:*"` - View stored refresh tokens
- `curl -X POST http://localhost:3000/api/auth/login -d '{"email":"test@example.com","password":"test123"}'` - Test login

## Open Questions
1. Should we implement sliding session extension (extend refresh token on each use)?
2. What's the plan for handling password complexity requirements?
3. Do we need device fingerprinting for additional security?

---
**Session Duration**: 2.5 hours
**Context Window Used**: ~65%
**Next Claude Should Know**: Auth foundation is solid. Focus on security hardening (rate limiting, lockout) before adding new features.
```

## Anti-Patterns to Avoid

### Don't Be Vague
❌ "Made progress on the feature"
❌ "Fixed various issues"
❌ "Updated some files"

### Don't Skip the Why
❌ "Changed from approach A to approach B"
✅ "Changed from approach A to approach B because B has O(1) lookup time vs O(n) for A, critical for our scale"

### Don't Forget Future You
Remember you're writing for a Claude instance that has no memory of this session. Be explicit about context that seems obvious now.

### Don't Omit Failures
Failed attempts contain valuable information. Document them to save future debugging time.

## Integration with Pre-Compact Hook

When set up as a pre-compact hook (using the companion hook script), this handover document will be automatically generated before Claude Code compacts the conversation. This ensures:

1. No context loss during compaction
2. Seamless continuation across conversation boundaries
3. Institutional knowledge preservation
4. Reduced need to explain previous decisions

## Tips for Best Handovers

1. **Write while coding, not after** - Jot notes during the session, compile at end
2. **Be future-oriented** - What will future-you wish you had written down?
3. **Include timestamps** - When did things happen? What's the timeline?
4. **Link to external resources** - PRs, tickets, documentation, Stack Overflow threads
5. **Update existing handovers** - If resuming work, reference previous handover docs
6. **Test your next steps** - Can someone else (or future-you) pick up from here?

## Quality Checklist

Before finalizing a handover document, verify:
- [ ] All file paths are accurate and complete
- [ ] Next steps are actionable and specific
- [ ] Key decisions include rationale
- [ ] Failed attempts are documented with reasons
- [ ] Code locations reference specific files/lines
- [ ] Environment setup is documented
- [ ] No assumed context that won't be available later
- [ ] Technical debt is acknowledged

## Conclusion

Great handover documents are the difference between seamless continuation and starting from scratch. Invest the 10-15 minutes at session end to create a comprehensive handover - your future self (and future Claude instances) will thank you.
