# Book My Pandit

Flutter app for discovering pandits, booking ceremonies, and paying through Razorpay with Supabase-backed data.

## Architecture

The project follows a lightweight clean architecture split:

- `lib/presentation` for screens, providers, and UI state
- `lib/domain` for repository contracts
- `lib/data` for repository implementations
- `lib/services` for Supabase, Razorpay, and auth helpers
- `lib/models` for typed app entities

Primary flow:

1. Google sign-in creates or refreshes the authenticated Supabase session.
2. The user profile is upserted into `public.users`.
3. Pandits are loaded from Supabase and shown in the listing screen.
4. The user selects a pandit, chooses a date/time, and opens Razorpay checkout.
5. On success, a booking is inserted into `public.bookings`.

## Prerequisites

- Flutter SDK 3.x
- Android Studio or VS Code with Flutter support
- A Supabase project
- A Razorpay account

## Environment Variables

The app reads runtime config via `--dart-define`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `RAZORPAY_KEY_ID`

Example:

```bash
flutter run \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your_anon_key \
	--dart-define=RAZORPAY_KEY_ID=your_razorpay_key
```

## Supabase Setup

1. Open Supabase SQL Editor.
2. Run [supabase/migrations/20260330_init_schema.sql](supabase/migrations/20260330_init_schema.sql).
3. If the schema already exists, also run [supabase/migrations/20260330_add_booking_payment_reference.sql](supabase/migrations/20260330_add_booking_payment_reference.sql).
4. Run [supabase/migrations/20260401_phase1_security_hardening.sql](supabase/migrations/20260401_phase1_security_hardening.sql) for production-safe booking mutation guards and idempotency indexes.
5. Run [supabase/migrations/20260401_webhook_dedupe_replay_protection.sql](supabase/migrations/20260401_webhook_dedupe_replay_protection.sql) for webhook dedupe and replay protection logs.
6. Enable Google auth in Supabase if you want live sign-in.

Tables used by the app:

- `users`
- `pandits`
- `bookings`

## Payment Setup

1. Create a Razorpay account.
2. Copy the publishable key into `RAZORPAY_KEY_ID`.
3. Replace test credentials before going live.
4. The app will only open checkout if the key is passed at runtime.

## Android Release Signing

Release signing is configured through `android/key.properties`.

1. Copy [android/key.properties.example](android/key.properties.example) to `android/key.properties`.
2. Fill in your keystore values:
	 - `storePassword`
	 - `keyPassword`
	 - `keyAlias`
	 - `storeFile`
3. Keep `android/key.properties` out of source control.
4. Build a release APK or app bundle:

```bash
flutter build apk --release \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=your_anon_key \
	--dart-define=RAZORPAY_KEY_ID=your_razorpay_key
```

## Run Locally

```bash
flutter pub get
flutter run
```

## Tests

Run the smoke and provider tests on Chrome in this environment:

```bash
flutter test -d chrome test/widget_test.dart test/auth_provider_test.dart test/booking_provider_test.dart
```

## Notes

- The app stores authenticated users in Supabase after login.
- Do not commit real Supabase or Razorpay secrets.
- On Windows, `flutter analyze` may require Developer Mode because of symlink support.

## Phase 1 Security Baseline

This repository now includes Phase 1 controls for production preparation:

- Database hardening migration adds:
	- partial unique index on `bookings.payment_reference`
	- partial unique index on (`bookings.user_id`, `bookings.idempotency_key`)
	- guard trigger to keep `amount`, `date`, `payment_reference`, and `payment_verified_at` immutable from authenticated client updates
	- stricter user update policy so customer role can only cancel own pending or confirmed bookings
- CI now includes:
	- dependency review on pull requests
	- secret scanning (`gitleaks`) on repository changes

Remaining mandatory production step:

- Deploy the new Edge Functions and configure all required secrets in the target Supabase environment. The Flutter app is now wired to backend-verified payment confirmation paths.

## Supabase Edge Functions (Phase 1)

Implemented functions:

- `create_payment_order`: creates Razorpay order server-side with authoritative amount.
- `verify_payment_and_confirm_booking`: verifies Razorpay signature and confirms booking server-side.
- `razorpay_webhook`: verifies webhook signature and deduplicates events before processing.

Set function secrets before deploy:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`

Deploy examples:

```bash
supabase functions deploy create_payment_order
supabase functions deploy verify_payment_and_confirm_booking
supabase functions deploy razorpay_webhook
```

Webhook endpoint setup:

- Configure Razorpay webhook URL to your deployed `razorpay_webhook` function endpoint.
- Keep retries enabled in Razorpay dashboard; duplicate events are safely ignored via DB dedupe function.
