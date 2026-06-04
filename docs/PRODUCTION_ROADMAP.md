# Book My Pandit Production Roadmap

This document converts the current `Book My Pandit` codebase into a production-grade implementation plan for Play Store deployment and safe growth to at least 10,000 active users.

Current audited state:

- Flutter client application
- Supabase Auth and database used directly from the client
- Razorpay checkout opened from the mobile app
- Basic RLS and indexing present
- No trusted backend layer yet
- No production observability, queueing, or hardened deployment workflow yet

Primary risk:

The app is not yet safe for real-money production because payment success and booking confirmation are still effectively client-led. The first implementation phase must establish a trusted backend boundary.

## Step 1: Full Production Readiness Checklist

- Introduce a real backend layer for trusted operations.
- Move payment order creation and payment verification off the client.
- Replace client-trusted booking creation with server-verified idempotent booking APIs.
- Add role-based access control for `customer`, `pandit`, `admin`, and `support`.
- Tighten Supabase RLS with explicit deny-by-default policies and service-only writes where needed.
- Add request validation and sanitization for every backend endpoint.
- Add rate limiting by IP, user, token, and sensitive action.
- Add replay protection and idempotency keys for booking and payment APIs.
- Add secure session handling, token refresh rules, and revoked-session handling.
- Remove sensitive operational logic from the Flutter app.
- Add structured logging, audit logging, suspicious-activity logging, and alerting.
- Add crash reporting and performance monitoring to mobile and backend systems.
- Add production environment separation, secret management, and build-time config discipline.
- Add migration discipline, backup verification, and rollback runbooks.
- Add connection pooling, indexing review, slow-query review, and query caps.
- Add queue handling for retries, payment reconciliation, notifications, and async work.
- Add CDN and image caching strategy for read traffic.
- Add health checks, readiness checks, autoscaling strategy, and deployment rollback support.
- Add CI/CD with tests, security checks, migration checks, and signing controls.
- Add Play Store hardening: release keystore handling, network security config, privacy disclosures, obfuscation, and logging redaction.
- Add complete operator and developer documentation.

## Step 2: Security Upgrade Plan

### Current risk summary

- The app inserts bookings directly from the client after payment success.
- The client currently decides `amount`, `date`, and booking payload values before database insert.
- OAuth is client-driven with minimal abnormal-session handling.

### Required implementation

- Create trusted backend APIs or Supabase Edge Functions for:
  - `create_booking_intent`
  - `create_payment_order`
  - `verify_payment`
  - `confirm_booking`
  - `cancel_booking`
  - admin-only management endpoints
- Never trust client-submitted `amount`, `status`, `payment_reference`, or role claims.
- Derive pricing on the server from authoritative catalog data.
- Verify Razorpay signature server-side before marking any booking as confirmed.
- Add idempotency keys so duplicate taps or retries cannot create duplicate bookings.
- Add nonce and timestamp validation for sensitive mutation requests.
- Add RBAC tables and policy enforcement:
  - `user_roles`
  - `admin_permissions`
  - optional `pandit_profiles`
- Add stronger database protections:
  - service-only update paths for confirmed and completed booking state transitions
  - customer actions only through controlled APIs
  - no direct client writes to `status`, `payment_reference`, or settlement fields
- Add validation rules:
  - email validation
  - phone validation
  - date and time window validation
  - amount bounds
  - UUID validation
  - string length limits
- Sanitize text inputs before storage and before logging.
- Add abuse controls:
  - per-IP rate limiting
  - per-user rate limiting
  - auth throttling
  - payment endpoint throttling
  - optional device fingerprint or install ID telemetry
- Add secret handling rules:
  - move secrets to managed secret storage
  - keep only publishable values in app `--dart-define`
  - never embed service role keys, webhook secrets, or admin secrets in the app
- Add transport and token hardening:
  - HTTPS-only backend endpoints
  - short-lived access tokens
  - refresh token rotation through Supabase
  - sign-out-all and revoke-session admin capability
- Add suspicious-activity logging:
  - repeated failed auth
  - duplicate payment callbacks
  - policy violations
  - rate-limit triggers
  - unusual device or location changes
- Add Play Store aligned controls:
  - privacy policy and data safety mapping
  - log redaction for PII and payment IDs
  - release-only analytics and crash collection with consent where required

## Step 3: Scalability Upgrade Plan for 10,000 Users

### Scaling recommendation

Use horizontal scaling for backend and API workloads, with managed vertical headroom for the database primary.

### Why

- Mobile traffic is bursty and read-heavy.
- Payment verification and booking confirmation are mostly stateless.
- API, workers, and cache scale horizontally better than a monolithic client-to-database write path.
- The database typically scales vertically first, then with query and caching optimization.

### Required implementation

- Keep the Flutter app stateless.
- Add a stateless backend or API tier behind a load balancer.
- Move payment verification, booking confirmation, notification dispatch, and reconciliation into async workers where possible.
- Introduce caching for:
  - pandit listing
  - pandit details
  - static content and media
- Use queue-based async processing for:
  - payment reconciliation
  - webhook retries
  - notification sending
  - post-booking workflows
- Add read-efficient API design:
  - pagination
  - server-side filtering
  - bounded result sizes
  - no unbounded selects
- Add connection pooling between API or workers and Postgres.
- Add autoscaling based on:
  - CPU
  - memory
  - p95 latency
  - queue depth
  - error rate
- Add resource budgets:
  - request timeout ceilings
  - worker concurrency caps
  - circuit breakers for external providers
- Add monitoring SLOs:
  - auth success rate
  - booking creation success rate
  - payment verification success rate
  - database latency
  - crash-free sessions

### Target architecture

- Flutter Android app
- CDN for static assets and images
- Trusted backend or Supabase Edge Functions for mutations
- Managed Postgres and Supabase
- Redis or equivalent for cache, rate limits, and idempotency
- Queue and worker layer for async tasks
- Crash and performance monitoring plus centralized logs

## Step 4: Backend Stability Improvements

- Add centralized exception handling for every backend endpoint.
- Return typed error codes instead of raw provider or database errors.
- Add retry logic only for safe and idempotent operations.
- Never blindly retry payment capture.
- Add webhook processing with signature verification and replay protection.
- Add dead-letter handling for failed async jobs.
- Add health, readiness, and dependency checks.
- Add graceful shutdown handling so in-flight requests or jobs complete safely.
- Add memory-safe patterns:
  - bounded queues
  - request body limits
  - upload size limits
  - no unbounded in-memory aggregation
- Add duplicate-request prevention:
  - idempotency key on booking creation
  - unique booking intent references
  - unique verified payment event records
- Add network interruption handling:
  - client retries only for safe reads
  - resumable booking flow from server state
  - webhook-driven final consistency for payment state
- Add observability:
  - structured logs with request ID and correlation ID
  - metrics
  - traces
  - alert thresholds

## Step 5: Database Optimization Improvements

### Current state

The schema already includes RLS, constraints, and a few indexes, but production traffic requires stronger modeling and operational controls.

### Required implementation

- Add normalized role tables instead of relying only on auth identity.
- Add booking and payment workflow tables:
  - `booking_intents`
  - `payment_transactions`
  - `webhook_events`
  - optional `audit_logs`
- Add stronger constraints:
  - unique idempotency key
  - unique verified payment event ID
  - status transition checks
  - timestamp sanity checks
- Add indexes for production paths:
  - `(user_id, created_at desc)` on bookings
  - `(pandit_id, date)` on bookings
  - partial indexes for active or future bookings
  - unique index for idempotency and payment references where appropriate
- Add pagination-oriented queries instead of whole-table fetch patterns.
- Add secure access policies:
  - customers can only read their own bookings
  - pandits can read only assigned bookings if that feature exists
  - admin and support go through audited service paths
- Add connection pooling and statement timeout controls.
- Add backup strategy:
  - automated daily backups
  - point-in-time recovery where available
  - scheduled restore drills
- Add rollback strategy:
  - reversible migrations
  - release tagging before schema changes
  - feature flags for risky rollouts
- Add data retention and redaction policy for logs and PII.
- Add encrypted storage and minimized PII footprint.
- Ensure no sensitive fields are exposed in broad select queries or logs.

## Step 6: Deployment Architecture Recommendation

### Recommended production deployment

#### Mobile app

- Flutter release build
- Android App Bundle for Play Store
- obfuscation and symbol management
- strict release config separation

#### Backend

- containerized API service or Supabase Edge Functions plus worker service
- deployed behind HTTPS load balancer
- autoscaling enabled

#### Data

- managed Supabase or Postgres
- connection pooler
- backups enabled

#### Cache and rate limiting

- Redis or managed equivalent

#### Async processing

- queue plus worker

#### Monitoring

- Sentry or Crashlytics for the app
- backend metrics, logging, and tracing platform

#### Secrets

- cloud secret manager
- separate `dev`, `staging`, and `prod` secrets

#### Delivery

- CI/CD pipeline with gated promotion from staging to production

### Production config separation to add

- separate `dev`, `staging`, and `prod` Supabase projects
- separate Razorpay test and live modes
- per-environment app IDs if needed
- per-environment backend base URLs
- release signing isolated from source control

### API protection strategy

- WAF or managed rate limiting
- JWT validation at API edge
- service-to-service auth for workers and webhooks
- webhook secret verification
- request size limits
- CORS locked down for web if web build is used
- audit logs for privileged actions

### Android and Play Store hardening

- network security config
- `android:usesCleartextTraffic="false"`
- release shrink and obfuscation review
- privacy policy
- Play Data Safety form readiness
- secure keystore handling

## Step 7: Complete Technical Documentation

The documentation set must include:

- Architecture overview
  - Flutter app
  - auth flow
  - backend and API layer
  - database
  - payment flow
  - async jobs
- API documentation
  - endpoint purpose
  - auth requirements
  - request and response schemas
  - error codes
  - idempotency behavior
- Database documentation
  - schema ERD
  - table purpose
  - indexes
  - RLS policies
  - migration process
- Security documentation
  - threat model
  - RBAC model
  - secret handling rules
  - incident response basics
  - logging and redaction rules
- Deployment documentation
  - environments
  - build and release commands
  - secrets setup
  - migration rollout
  - rollback steps
- Environment variables guide
  - public mobile config vs server secrets
  - required variables per environment
  - rotation process
- Backup and recovery guide
  - backup schedule
  - restore test steps
  - RPO and RTO targets
- Scaling strategy
  - vertical vs horizontal guidance
  - autoscaling triggers
  - cache and queue usage
- Monitoring runbook
  - metrics
  - alerts
  - dashboards
  - on-call checks
- Play Store release checklist
  - signing
  - privacy disclosures
  - crash monitoring
  - release validation

## Immediate Priority Order

1. Introduce trusted backend and payment verification flow.
2. Redesign booking mutations to be server-authoritative and idempotent.
3. Add RBAC, stricter RLS, and audit logging.
4. Add rate limiting, caching, queueing, and observability.
5. Harden deployment, backups, and Android release configuration.
6. Write full operator and developer documentation.

## Suggested execution phases

### Phase 1

- Trusted backend boundary
- Payment verification flow
- Booking intent flow
- Idempotency support
- Server-side validation

### Phase 2

- RBAC tables and policy hardening
- Audit logs
- Suspicious activity logs
- Admin-safe mutation paths

### Phase 3

- Queue and worker setup
- Caching
- Monitoring and alerts
- Crash reporting

### Phase 4

- Deployment workflow
- Staging and production separation
- Backup and rollback runbooks
- Play Store release preparation

### Phase 5

- Full technical documentation
- Hand-off guides
- Operations runbook
