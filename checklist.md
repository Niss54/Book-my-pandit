
## Phase 1 Execution Status (Started: 2026-04-01)

- [x] Add DB hardening migration for booking mutation controls.
- [x] Add duplicate prevention indexes (`payment_reference`, `user_id + idempotency_key`).
- [x] Add CI security gates (dependency review + secret scanning).
- [x] Document Phase 1 baseline in README.
- [x] Implement trusted backend endpoint for Razorpay signature verification.
- [x] Route booking confirmation through backend only (remove client-authoritative confirmation).
- [x] Add webhook processing with dedupe table and replay protection.
- [ ] Add role model (`customer`, `pandit`, `admin`, `support`) with policy tests.
- [ ] Add incident/runbook docs and key rotation SOP.

Phase 1 note:
- Code and migrations are implemented in repo. Supabase deploy + function secret setup still required in environment before production use.

Step 1: Full production readiness checklist

Governance and scope
Define production SLOs: uptime, p95 latency, error budget, RTO, RPO.
Define compliance scope: Play Store Data Safety, privacy policy, retention policy.
Define threat model and abuse model for auth, payment, booking, admin flows.
Architecture hardening baseline
Move all privileged logic out of client into server-side functions.
Keep mobile app as untrusted client; enforce all business rules server-side.
Separate dev/staging/prod projects and credentials.
Identity and access
Enforce strong auth session policy, token expiry, refresh handling.
Implement RBAC with least privilege.
Enforce row-level authorization in database for every table.
Data protection
Classify PII, payment-linked metadata, operational logs.
Encrypt secrets at rest and in transit.
Mask/redact sensitive fields in logs and analytics.
API security
Add API gateway/WAF, rate limiting, bot mitigation.
Input validation + sanitization + idempotency keys.
Replay protection and anti-automation controls.
Reliability and scale
Add retries with backoff, circuit breakers, timeout budgets.
Add queue/event layer for non-critical async work.
Add caching and query optimization.
Add autoscaling strategy and capacity plan for 10k active users.
Observability and operations
Structured logs, metrics, traces, alerts.
On-call runbooks, incident response, rollback runbook.
Crash reporting and release health gates.
Delivery and release
CI with lint, tests, security scan, SAST/dependency scan.
CD with staged rollout and feature flags.
Play Store release checklist with signing, policy declarations, privacy disclosures.
Backup and DR
Automated backups + restore drills.
Point-in-time recovery tests.
Regional risk and failover plan.
Validation gates
Load test, chaos test, security test, penetration test.
Go-live checklist and cutover plan.
Post-launch stabilization window.
Step 2: Security upgrade plan

Core architecture change (most important)
Introduce trusted backend layer (Edge Functions or API service) for:
payment order creation/verification
booking confirmation transitions
admin operations
anti-abuse controls
Remove any sensitive business decision from Flutter client.
Authentication and session security
Use Supabase Auth with strict redirect allowlists.
Short-lived access tokens, secure refresh strategy.
Device/session revocation support.
Detect abnormal session behavior (geo/IP/user-agent drift).
Authorization (RBAC + RLS)
Roles: user, pandit, admin, ops.
Enforce role claims in JWT and verify server-side.
Harden RLS policies for users, pandits, bookings:
user reads/writes own rows only
privileged updates through backend role only
Disable broad table access from anonymous paths.
Secret and key management
Keep all secrets in secret manager (not in source, not in client).
Rotate exposed keys immediately.
Split environments with separate keys/projects.
Payment secret stays server-side only.
API abuse and replay protection
Per-IP + per-user + per-endpoint rate limits.
Idempotency key for booking/payment finalize endpoint.
Nonce/timestamp checks for replay-sensitive requests.
CAPTCHA/challenge on suspicious patterns.
API gateway rules for brute force and scraping.
Input and payload security
Central schema validation for every request.
Strict type and range checks for dates, amounts, IDs.
Reject unknown fields, oversized payloads.
Sanitize text input before persistence/display.
Payment security
Verify webhook signatures server-side.
Never trust client payment success callback alone.
Mark booking confirmed only after server verification.
Audit trail for payment state transitions.
Logging and detection
Security event logging: failed auth spikes, policy violations, rate-limit hits.
Redaction policy for tokens, emails, phone numbers.
Alerting thresholds for abuse and anomaly detection.
Play Store compliance controls
Data minimization.
Explicit consent and account deletion flow.
Privacy policy + Data Safety form consistency.
Remove non-essential permissions.
Step 3: Scalability upgrade plan for 10,000 users

Recommended scaling model
API layer: horizontal scaling (stateless services/functions).
Database: vertical first for primary, then read replicas + connection pooling.
Cache layer: Redis for hot reads/rate-limit counters/session hints.
Capacity strategy
Baseline expected throughput and concurrency by endpoint.
Define p95/p99 targets for login, list pandits, create booking, payment finalize.
Pre-scale policy for festival/peak demand windows.
Workload split
Synchronous path: auth, availability check, booking create.
Async path: notifications, analytics, reconciliation, reports.
Queue-based worker model for async operations.
Performance improvements
API response caching where safe.
Pagination and filtered queries for listings.
Reduce client overfetch and N+1 patterns.
CDN for static assets/media.
Resilience under spikes
Backpressure and graceful degradation.
Retry budgets with jittered exponential backoff.
Priority handling: booking/payment endpoints prioritized over non-critical traffic.
Vertical vs horizontal recommendation

Primary recommendation: horizontal for API tier + controlled vertical/hybrid for DB.
Reason: user growth and peak spikes are better handled by stateless scale-out, while DB needs careful consistency-oriented scaling.
Step 4: Backend stability improvements

Error handling standardization
Unified error schema and domain error codes.
No silent catch blocks; all failures classified and surfaced.
Safe client messages, detailed server logs.
Timeout, retry, and circuit breaker policies
Per-dependency timeout budgets.
Retry only idempotent operations or with idempotency keys.
Circuit breaker for unstable dependencies (payment, external APIs).
Idempotency and duplicate prevention
Idempotency key on booking/payment finalize.
Unique constraints for transaction references.
At-least-once webhook processing with dedupe table.
Queue and worker reliability
Dead-letter queue for poison messages.
Retry with max-attempt policy.
Worker health checks and autoscaling.
Crash recovery
Stateless service restart-safe design.
Auto restart and readiness/liveness checks.
Rolling deployment with health gate.
Network interruption handling
Client retry for safe calls.
Offline-safe UX for transient failures.
Explicit re-sync after reconnect.
Step 5: Database optimization improvements

Schema and constraints
Strong constraints for statuses, foreign keys, and uniqueness.
Booking/payment reference uniqueness to block duplicates.
Add created_at/updated_at consistency triggers where needed.
Indexing strategy
Composite indexes for common filters/sorts:
bookings by user_id + created_at
bookings by pandit_id + date
bookings by payment_reference
pandits by is_active + rating
Review index bloat periodically.
Query optimization
Use explain plans on top endpoints.
Avoid wide selects in hot paths.
Add pagination and keyset pagination for large lists.
Access security
Harden RLS policies and test them.
Restrict direct table writes from client where business-sensitive.
Backend-only mutation paths for critical state transitions.
Reliability, backup, rollback
Daily full + frequent incremental backups.
PITR enabled.
Weekly restore drill.
Migration rollback scripts and safe deployment order.
Connection management
Use pooling for high concurrency.
Protect DB with connection limits and queueing.
Step 6: Deployment architecture recommendation

Recommended production architecture

Flutter app (Android release)
Secure build variants for dev/stage/prod.
Runtime env through compile-time defines only for public config.
No privileged secrets in app binary.
Edge/API layer
Supabase Edge Functions or dedicated API service.
API gateway + WAF in front.
Rate limiting, bot controls, request validation.
Data layer
Supabase Postgres primary.
Optional read replica for heavy reads.
Redis cache for hot paths and abuse counters.
Async and observability
Queue workers for async tasks.
Central logs + metrics + tracing.
Crash reporting (mobile + backend) with alert routing.
CI/CD
CI pipeline already added for format/analyze/tests.
Extend with:
dependency vulnerability scan
secret scanning
migration check
staged deployment
rollback action
Step 7: Complete technical documentation

You should maintain these docs as separate versioned files:

Architecture overview
System components, trust boundaries, data flow diagrams.
API documentation
Endpoint contracts, auth requirements, rate limits, idempotency behavior, error codes.
Database documentation
ERD, table glossary, indexes, constraints, RLS policies, migration history.
Security documentation
Threat model, controls mapping, key rotation SOP, incident response playbook.
Operations documentation
Monitoring dashboards, alert thresholds, on-call runbooks, outage procedures.
Deployment documentation
Environment setup, secret management, release train, rollback steps.
Compliance documentation
Data retention and deletion policy.
Play Store Data Safety mapping and privacy policy checklist.
What I need from you to execute the full implementation now

Confirm deployment target: Supabase-only backend with Edge Functions, or separate backend service.
Confirm infra preference: GCP/AWS/Azure/Cloudflare.
Confirm expected peak profile: concurrent users and peak requests/sec.
Confirm payment flow requirement: server webhook verification mandatory (recommended yes).
Confirm roles needed beyond user/admin/pandit.
Confirm whether media/file upload is required (for strict upload hardening).
Confirm if you want me to start by creating production docs files and security migrations first, then backend hardening in phases.