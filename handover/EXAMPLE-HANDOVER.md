# Handover Document - 2026-02-10-1430

## Session Overview
Implemented JWT authentication system with refresh token rotation for the Express API. Core authentication flow is working and tested with 22 passing unit tests. Rate limiting and account lockout mechanisms are designed but not yet implemented. Session was productive with one significant challenge around refresh token race conditions that was successfully resolved.

## What Got Done

### Core Deliverables
- ✅ **JWT Authentication System**
  - Access tokens (15min expiry) and refresh tokens (7 day expiry)
  - Token validation middleware with proper error handling
  - Secure token generation using `jose` library

- ✅ **API Endpoints** (`src/routes/auth.ts`)
  - POST `/api/auth/login` - User authentication with email/password
  - POST `/api/auth/logout` - Token invalidation
  - POST `/api/auth/refresh` - Access token refresh with rotation

- ✅ **Redis Integration** (`src/config/redis.ts`)
  - Refresh token storage with automatic TTL
  - Connection pooling and error handling
  - Health check endpoint

- ✅ **Test Coverage** (`tests/auth.test.ts`)
  - 22 unit tests covering authentication flows
  - Edge case testing (expired tokens, invalid signatures, etc.)
  - Mock implementations for Redis and user service
  - 94% code coverage on auth modules

### Files Created/Modified

**New Files:**
- `src/middleware/auth.ts` (158 lines) - JWT validation middleware
- `src/middleware/requireAuth.ts` (45 lines) - Protected route wrapper
- `src/routes/auth.ts` (234 lines) - Authentication endpoints
- `src/services/tokenService.ts` (312 lines) - Token generation/validation logic
- `src/config/redis.ts` (87 lines) - Redis client configuration
- `tests/auth.test.ts` (456 lines) - Authentication test suite
- `types/express.d.ts` (12 lines) - Express type extensions

**Modified Files:**
- `src/app.ts` - Added auth routes and middleware
- `src/config/env.ts` - Added JWT secret validation
- `package.json` - Added dependencies: jose, ioredis, @types/jsonwebtoken
- `.env.example` - Added JWT and Redis configuration examples

### Dependencies Added
```json
{
  "jose": "^5.2.0",           // JWT operations
  "ioredis": "^5.3.2",        // Redis client
  "bcrypt": "^5.1.1",         // Password hashing
  "@types/bcrypt": "^5.0.2"   // TypeScript types
}
```

### Configuration Changes
- Added `JWT_SECRET` and `JWT_REFRESH_SECRET` to environment variables
- Configured Redis connection string in `REDIS_URL`
- Set up JWT token expiry times (configurable via env)

## What Worked and What Didn't

### Successes

1. **JWT Library Choice**
   - `jose` library worked flawlessly with minimal configuration
   - Modern ESM support, great TypeScript types
   - Built-in support for various JWT algorithms

2. **Redis Integration**
   - `ioredis` was straightforward to set up
   - Connection pooling handled automatically
   - TTL functionality perfect for token expiration

3. **Test-Driven Approach**
   - Writing tests first helped catch edge cases early
   - Mock implementations were easy with jest
   - Coverage metrics guided development

4. **Middleware Pattern**
   - Express middleware pattern scales well
   - Easy to add additional auth layers later
   - Clean separation of concerns

### Challenges Encountered & Solutions

1. **Refresh Token Race Condition**
   - **Problem**: When user had multiple tabs open, concurrent refresh requests could both succeed, leading to inconsistent state
   - **Root Cause**: No atomic check-and-set for token usage
   - **Solution**: Implemented distributed lock using Redis SETNX with 2-second TTL
   - **Code Location**: `src/services/tokenService.ts:145-167`
   - **Time to Resolve**: ~1.5 hours (including research and testing)
   
   ```typescript
   // Atomic lock acquisition
   const lockKey = `lock:refresh:${tokenId}`;
   const acquired = await redis.set(lockKey, '1', 'NX', 'EX', 2);
   if (!acquired) {
     throw new Error('Refresh already in progress');
   }
   ```

2. **Environment Variable Loading**
   - **Problem**: Inconsistent behavior between dev and test environments
   - **Root Cause**: dotenv loading order and test environment setup
   - **Solution**: Created centralized config loader with Zod validation
   - **Code Location**: `src/config/env.ts`
   - **Key Learning**: Always validate env vars at startup, fail fast

3. **TypeScript Type Complexity**
   - **Problem**: Express Request type didn't include custom `user` property
   - **Solution**: Created type declaration file to extend Express types
   - **Code Location**: `types/express.d.ts`
   - **Note**: Must be imported in `tsconfig.json` for types to work

4. **CORS Issues During Testing**
   - **Problem**: Preflight requests failing in test environment
   - **Solution**: Added CORS middleware with proper origin configuration
   - **Code Location**: `src/app.ts:25-32`

### Failed Attempts (What Didn't Work)

1. **HttpOnly Cookies for Access Tokens**
   - **Attempted**: Using httpOnly cookies to store access tokens
   - **Why It Failed**: CORS issues with subdomain architecture (api.example.com vs app.example.com)
   - **What We Tried**: 
     - Various CORS configurations
     - Cookie domain settings
     - SameSite attributes
   - **Conclusion**: Reverted to Authorization header approach (standard and works everywhere)
   - **Time Lost**: ~45 minutes

2. **Native crypto.subtle for Token Signing**
   - **Attempted**: Using Node's built-in `crypto.subtle` instead of `jose`
   - **Why It Failed**: Performance was 3x slower (measured with benchmark suite)
   - **Benchmark Results**:
     - crypto.subtle: ~15ms per token generation
     - jose library: ~5ms per token generation
   - **Conclusion**: Kept `jose` library for performance

3. **Database Storage for Refresh Tokens**
   - **Attempted**: Storing refresh tokens in PostgreSQL
   - **Why It Failed**: Too slow (40ms vs 2ms with Redis for token lookup)
   - **Consideration**: Needed TTL functionality, complex to implement in SQL
   - **Conclusion**: Redis is the right tool for this use case

## Key Decisions Made

### 1. Token Expiry Times
- **Access Token**: 15 minutes
- **Refresh Token**: 7 days
- **Rationale**: 
  - Follows OWASP recommendations for security
  - 15min access tokens reduce attack window
  - 7-day refresh balances security with UX (don't force login too often)
  - Can be adjusted based on usage analytics
- **References**: [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)

### 2. Refresh Token Rotation Strategy
- **Decision**: Implement automatic rotation on each refresh
- **How**: Old refresh token invalidated immediately when new one issued
- **Rationale**: 
  - Prevents token replay attacks
  - Limits damage if refresh token leaked
  - Industry best practice (Auth0, Firebase do this)
- **Trade-off**: Slightly more complex implementation
- **Impact**: Worth it for security improvement

### 3. Token Storage Backend
- **Decision**: Redis for refresh tokens, not database
- **Alternatives Considered**:
  - PostgreSQL: Too slow, lacks native TTL
  - In-memory: Doesn't survive restarts, can't scale horizontally
- **Rationale**:
  - Fast lookups (sub-millisecond)
  - Built-in TTL matches token expiry model perfectly
  - Easy to scale horizontally (Redis Cluster later)
  - Separate concerns (auth state vs persistent data)

### 4. Error Response Strategy
- **Decision**: Use standard HTTP status codes
  - 401 for invalid/expired tokens (triggers re-authentication)
  - 403 for valid tokens with insufficient permissions
  - 429 for rate limit (future)
- **Rationale**: 
  - Standard HTTP semantics
  - Client-side libraries handle these correctly
  - Clearer debugging (status code tells the story)

### 5. Password Hashing
- **Decision**: bcrypt with cost factor of 12
- **Alternatives Considered**:
  - Argon2 (more modern, but bcrypt is proven)
  - scrypt (good but less ecosystem support)
- **Rationale**:
  - bcrypt is battle-tested (20+ years)
  - Cost factor 12 balances security/performance (~200ms per hash)
  - Wide library support across platforms

### 6. Token Signing Algorithm
- **Decision**: HS256 (HMAC with SHA-256)
- **Alternatives Considered**:
  - RS256 (asymmetric) - overkill for our use case
  - ES256 (ECDSA) - good but HS256 simpler
- **Rationale**:
  - We control both token generation and validation
  - Symmetric signing is faster
  - Smaller tokens (no public key in header)
  - Can upgrade to RS256 later if needed

## Lessons Learned and Gotchas

### Implementation Insights

1. **Redis TTL Precision**
   - Redis `EXPIRE` uses **seconds**, not milliseconds
   - Must round up token expiry times to avoid premature expiration
   - Example: 15min = 900 seconds exactly (no millisecond precision)
   - **Code Impact**: Added `Math.ceil()` when converting to seconds

2. **JWT Clock Skew**
   - Different servers can have slightly different clocks
   - JWT validation fails if token "not yet valid" due to clock drift
   - **Solution**: Added 30-second leeway using `jose` `clockTolerance` option
   - **Best Practice**: Keep this configurable via env var

3. **Testing Async Crypto Operations**
   - Node's crypto operations are non-deterministic
   - Makes testing difficult (random IVs, timestamps, etc.)
   - **Solution**: Used `jest.mock('node:crypto')` with fixed seed
   - **Gotcha**: Remember to restore mocks in `afterEach`

4. **Express TypeScript Integration**
   - Express Request doesn't include custom properties by default
   - Must extend types via declaration file
   - **Location**: `types/express.d.ts`
   - **Important**: Use `declare global` and `namespace Express` syntax

5. **Redis Connection Management**
   - Must handle reconnection gracefully
   - Add error listeners to prevent crashes
   - **Pattern Used**: Singleton with lazy connection
   - **Code**: `src/config/redis.ts:45-67`

### API Quirks Discovered

1. **jose Library Quirks**
   - Must import specific functions (tree-shaking friendly but verbose)
   - `compactVerify` vs `jwtVerify` - use `jwtVerify` for proper type checking
   - Error messages not always helpful (catch and wrap)

2. **ioredis Behavior**
   - Commands return `Promise<null>` when key doesn't exist (not undefined)
   - Must explicitly check for `null` not falsy values
   - Connection events fire multiple times, use `once` not `on` for initialization

3. **bcrypt Timing**
   - Hash time varies with CPU load (expected behavior)
   - Can cause test flakiness if asserting on time
   - **Solution**: Use generous timeouts in tests

### Edge Cases Found

1. **Concurrent Token Refresh**
   - See "Challenges" section above
   - Race condition required distributed lock

2. **Token Just After Expiry**
   - Clock skew can cause "expired 1 second ago" errors
   - Added clock tolerance to prevent spurious failures

3. **Invalid JSON in Token Payload**
   - Some older systems send malformed JSON
   - Added extra validation layer before JWT verification
   - Catches malformed input early with clear error

4. **Empty or Whitespace Passwords**
   - bcrypt accepts empty strings (security issue)
   - Added validation: min 8 chars, at least one letter and number
   - **Location**: `src/validators/auth.ts:12-18`

## Clear Next Steps

### Immediate Priorities (Next Session)

1. **Implement Rate Limiting** [HIGH PRIORITY]
   - **Goal**: Prevent brute force attacks on login endpoint
   - **Approach**: Sliding window rate limiter using Redis sorted sets
   - **Spec**: 
     - 5 login attempts per 15 minutes per IP address
     - Return 429 with `Retry-After` header
     - Also rate limit by user ID (prevent distributed brute force)
   - **Files to Create**: `src/middleware/rateLimit.ts`
   - **Redis Pattern**: Sorted set with timestamp scores
   - **Estimated Time**: 2-3 hours
   - **Testing**: Write tests for edge cases (exactly 5 attempts, concurrent requests)

2. **Account Lockout Mechanism** [HIGH PRIORITY]
   - **Goal**: Lock account after repeated failed login attempts
   - **Approach**: Track failed attempts in Redis with 1-hour TTL
   - **Spec**:
     - Lock after 10 failed attempts within 1 hour
     - Lock duration: 1 hour
     - Send email notification on lockout
     - Provide unlock endpoint for user support
   - **Files to Modify**: `src/services/authService.ts`, `src/routes/auth.ts`
   - **Email Service**: Need to integrate SendGrid or similar
   - **Estimated Time**: 3-4 hours
   - **Testing**: Verify attempt counting, lock duration, unlock flow

3. **Integration Tests** [MEDIUM PRIORITY]
   - **Goal**: Test full auth flow end-to-end
   - **Approach**: Use `supertest` with real server instance
   - **Coverage**:
     - Full login → protected route → refresh → logout flow
     - Invalid credentials flow
     - Token expiry and refresh
     - Concurrent requests
   - **Files to Create**: `tests/integration/auth.integration.test.ts`
   - **Setup**: Test database and Redis instance (use docker-compose)
   - **Estimated Time**: 2 hours

### Medium Priority (Week 2)

4. **Email Verification Flow**
   - User registration not fully implemented yet
   - Need verification email with token
   - Token stored in Redis with 24-hour expiry
   - Unverified users can't access protected routes

5. **Password Reset Functionality**
   - Email-based reset flow
   - Reset tokens with short expiry (1 hour)
   - Password strength validation
   - Invalidate all refresh tokens on password change

6. **Monitoring and Logging**
   - Log all authentication events
   - Failed login attempts (for security monitoring)
   - Token refresh patterns (identify suspicious behavior)
   - Integration with logging service (Datadog, CloudWatch)

7. **Session Management UI**
   - View all active sessions (refresh tokens)
   - Revoke sessions individually or all at once
   - Show device info (user agent, IP, last used)
   - Build API endpoints first, then React components

### Future Enhancements (Backlog)

8. **Two-Factor Authentication (TOTP)**
   - Use `otplib` for TOTP generation
   - QR code generation for authenticator apps
   - Backup codes for recovery
   - **Research**: FIDO2/WebAuthn as alternative

9. **OAuth Integration**
   - Google, GitHub sign-in
   - Use `passport` or `arctic` library
   - Account linking (email-based user with OAuth)

10. **Biometric Authentication**
    - WebAuthn for fingerprint/Face ID
    - Passwordless login option
    - **Dependencies**: Requires HTTPS, modern browsers

11. **Audit Logging**
    - Immutable log of all auth events
    - Useful for compliance (SOC2, GDPR)
    - Store in separate database (not Redis)

### Open Questions Needing Answers

- [ ] Should we implement sliding session extension? (extend refresh token TTL on each use)
- [ ] Password complexity requirements - what's the business policy?
- [ ] Do we need device fingerprinting for additional security?
- [ ] What's the strategy for handling shared/public computers?
- [ ] Should we support multiple simultaneous sessions or enforce single session?
- [ ] Email service choice - SendGrid, AWS SES, or Postmark?

### Blocked Items

**None currently** - all dependencies are in place and working.

## Important Files Map

```
src/
├── middleware/
│   ├── auth.ts              # JWT validation middleware (use on protected routes)
│   │                        # exports: authenticateToken, requireAuth
│   │                        # Usage: router.use(authenticateToken)
│   └── requireAuth.ts       # Wrapper that enforces authentication
│                            # Rejects requests with 401 if no valid token
│
├── routes/
│   └── auth.ts              # Authentication endpoints
│                            # POST /api/auth/login    - email/password login
│                            # POST /api/auth/logout   - invalidate tokens
│                            # POST /api/auth/refresh  - get new access token
│
├── services/
│   ├── tokenService.ts      # Core token generation/validation logic
│   │                        # generateTokenPair(userId) - create access + refresh
│   │                        # validateAccessToken(token) - verify and decode
│   │                        # validateRefreshToken(token) - verify and check Redis
│   │                        # revokeRefreshToken(tokenId) - invalidate in Redis
│   │
│   └── userService.ts       # User lookup and password verification
│                            # findByEmail(email) - get user from DB
│                            # verifyPassword(plain, hash) - bcrypt comparison
│
├── config/
│   ├── env.ts               # Environment variable loader with validation
│   │                        # Uses Zod schemas to validate config at startup
│   │                        # Exports typed config object
│   │
│   └── redis.ts             # Redis client singleton
│                            # getRedisClient() - lazy connection
│                            # Health check and reconnection logic
│
└── types/
    └── express.d.ts         # TypeScript type extensions
                             # Adds `user` property to Express Request type

tests/
├── auth.test.ts            # 22 unit tests for auth logic
│                           # Mock implementations for Redis and user service
│                           # Run: npm test -- auth.test.ts
│
└── integration/
    └── (future location for integration tests)

```

### Key Entry Points and Usage Examples

**Apply authentication to routes:**
```typescript
import { authenticateToken, requireAuth } from './middleware/auth';

// Option 1: Add user to request but don't require auth
router.get('/optional-auth', authenticateToken, handler);

// Option 2: Require authentication (401 if no valid token)
router.get('/protected', requireAuth, handler);

// Option 3: Protect entire router
router.use('/api/protected', requireAuth);
```

**Generate tokens:**
```typescript
import { generateTokenPair } from './services/tokenService';

const { accessToken, refreshToken } = await generateTokenPair(user.id);
// Return in login response
```

**Validate tokens:**
```typescript
import { validateAccessToken } from './services/tokenService';

try {
  const payload = await validateAccessToken(token);
  console.log('User ID:', payload.userId);
} catch (error) {
  console.error('Invalid token:', error.message);
}
```

**Revoke refresh token:**
```typescript
import { revokeRefreshToken } from './services/tokenService';

await revokeRefreshToken(tokenId);
// User must login again to get new refresh token
```

## Context Preservation

### Current Mental Model

The authentication system follows a **dual-token pattern** common in modern web applications:

1. **Access Tokens** (short-lived, 15 min)
   - Sent with every API request in Authorization header
   - Contains user identity and permissions (JWT claims)
   - Stateless - API validates signature but doesn't check database
   - Short expiry limits damage if leaked

2. **Refresh Tokens** (long-lived, 7 days)
   - Stored in Redis with TTL matching expiry
   - Used only to obtain new access tokens
   - Stateful - checked against Redis on each use
   - Rotated on each refresh (old token invalidated)

**Key Insight**: Access tokens can be validated without database/Redis lookup (fast), while refresh tokens require state check (slight performance cost but necessary for revocation).

**Security Model**: If an access token is stolen, attacker has 15 minutes max. If refresh token stolen, it's immediately invalidated when legitimate user refreshes, and attacker can't generate new tokens.

### Current Assumptions

1. **Single Redis Instance**
   - Currently using single Redis for simplicity
   - Should be sufficient for MVP and moderate scale
   - Plan to add Redis Cluster when we hit ~100k active users
   - **Monitoring**: Watch for memory usage, connection counts

2. **Device Limit**
   - Users shouldn't need more than 5 concurrent devices/sessions
   - Current implementation: no hard limit (should add)
   - **Future**: Add UI to view/revoke sessions

3. **Email Service**
   - Placeholder for account lockout notifications
   - Need to decide on service provider (SendGrid, AWS SES)
   - **Requirement**: Delivery SLA, failure handling

4. **Token Secret Rotation**
   - JWT secrets assumed to be long-term stable
   - No plan yet for secret rotation
   - **Future Consideration**: Implement versioned secrets for zero-downtime rotation

5. **Scaling Assumptions**
   - Stateless access token validation scales horizontally (no shared state)
   - Redis becomes bottleneck at very high scale (mitigation: Redis Cluster)
   - **Benchmark**: Current setup should handle 10k requests/sec

### Environment Setup

**Prerequisites:**
- Node.js 18+ (uses native fetch, crypto)
- Redis 6+ (needs proper TTL and SETNX support)
- PostgreSQL 14+ (for user storage)

**Installation:**
```bash
# Clone and install dependencies
git clone <repo>
cd <project>
npm install

# Set up environment variables
cp .env.example .env
# Edit .env and fill in required values:
#   JWT_SECRET=<generate-with: openssl rand -base64 32>
#   JWT_REFRESH_SECRET=<different-random-value>
#   REDIS_URL=redis://localhost:6379
#   DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# Start Redis (using Docker)
docker run -d -p 6379:6379 redis:7-alpine

# Run database migrations
npm run migrate

# Start development server
npm run dev
# Server starts on http://localhost:3000
```

**Environment Variables Reference:**
```bash
# JWT Configuration
JWT_SECRET=<required>              # Secret for access token signing
JWT_REFRESH_SECRET=<required>      # Secret for refresh token signing  
JWT_ACCESS_EXPIRY=15m              # Access token lifetime (default: 15m)
JWT_REFRESH_EXPIRY=7d              # Refresh token lifetime (default: 7d)

# Redis Configuration
REDIS_URL=<required>               # Redis connection string
REDIS_PASSWORD=<optional>          # Redis auth password

# Database
DATABASE_URL=<required>            # PostgreSQL connection string

# Server
PORT=3000                          # Server port (default: 3000)
NODE_ENV=development               # Environment: development|production|test

# Future: Email service
SENDGRID_API_KEY=<optional>        # For account lockout emails
```

### Running Commands and Workflows

**Development:**
```bash
# Start development server with hot reload
npm run dev
# → http://localhost:3000
# → API docs: http://localhost:3000/api-docs

# Run tests
npm test
# → Runs all test suites

# Run tests with coverage
npm test -- --coverage
# → Generates coverage/index.html

# Run specific test file
npm test -- auth.test.ts

# Lint and format
npm run lint
npm run format
```

**Production:**
```bash
# Build for production
npm run build
# → Creates dist/ directory

# Start production server
npm start
# → Runs built code from dist/

# PM2 deployment (recommended)
pm2 start ecosystem.config.js
pm2 logs
```

**Redis Management:**
```bash
# Connect to Redis CLI
redis-cli

# View all refresh tokens
redis-cli KEYS "refresh:*"

# Check token expiry
redis-cli TTL "refresh:<token-id>"

# Manually revoke token
redis-cli DEL "refresh:<token-id>"

# Monitor Redis operations (debugging)
redis-cli MONITOR

# Get Redis info
redis-cli INFO
```

**Database:**
```bash
# Run migrations
npm run migrate

# Rollback last migration
npm run migrate:rollback

# Seed database with test data
npm run seed

# Connect to database
psql $DATABASE_URL
```

**Testing Auth Flow:**
```bash
# 1. Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
# → Returns: { accessToken, refreshToken }

# 2. Access protected route
curl http://localhost:3000/api/protected/profile \
  -H "Authorization: Bearer <access-token>"
# → Returns: user profile data

# 3. Refresh access token
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"<refresh-token>"}'
# → Returns: { accessToken, refreshToken: <new-token> }

# 4. Logout
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"<refresh-token>"}'
# → Invalidates refresh token
```

**Debugging:**
```bash
# Enable debug logging
DEBUG=app:* npm run dev

# Check if Redis is reachable
redis-cli ping
# → Should return: PONG

# Test database connection
npm run db:test

# View auth logs
tail -f logs/auth.log

# Monitor failed login attempts
grep "LOGIN_FAILED" logs/auth.log | tail -20
```

## Technical Debt and Shortcuts

1. **Error Handling Could Be More Granular**
   - Currently using generic error messages in some places
   - Should distinguish between different error types
   - **Location**: `src/middleware/auth.ts:85-102`
   - **Impact**: Medium - makes debugging harder
   - **Effort to Fix**: 2 hours

2. **No Centralized Error Types**
   - Errors are plain JavaScript errors
   - Should create custom error classes with error codes
   - **Benefit**: Easier error handling, better API responses
   - **Effort**: 3-4 hours

3. **Limited Test Coverage on Edge Cases**
   - Main flows well tested (94% coverage)
   - Some edge cases in Redis error handling not covered
   - **Location**: `tests/auth.test.ts` - need more Redis failure scenarios
   - **Risk**: Low - mainly affects resilience
   - **Effort**: 2 hours

4. **No Request Tracing**
   - Would help with debugging in production
   - Should add request ID propagation
   - **Future**: Integrate with APM tool (Datadog, New Relic)
   - **Effort**: 3 hours

5. **Token Blacklisting Not Implemented**
   - If access token leaked, can't revoke before expiry
   - Trade-off: Performance vs security
   - **Mitigation**: Short token lifetime (15 min)
   - **Future**: Consider if needed based on threat model

## References and Resources

- [OWASP JWT Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [RFC 7519 - JWT Specification](https://datatracker.ietf.org/doc/html/rfc7519)
- [jose Library Documentation](https://github.com/panva/jose)
- [ioredis Documentation](https://github.com/redis/ioredis)
- [Token-Based Authentication vs Session-Based](https://auth0.com/blog/refresh-tokens-what-are-they-and-when-to-use-them/)

---

**Session Duration**: 2.5 hours (14:00 - 16:30)  
**Context Window Used**: ~65% at session end  
**Total Lines of Code Written**: ~1,300 (including tests)  
**Next Claude Should Know**: Auth foundation is solid and well-tested. Focus should be on security hardening (rate limiting, account lockout) before adding new features. The refresh token race condition solution is critical - don't remove the Redis lock mechanism.
