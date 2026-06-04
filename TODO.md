# Book My Pandit - Pending Tasks Todo

## P0 - Critical (Do First)

- [x] Fix Google sign-in flow return handling.
  - Current issue: `GoogleAuthService.signIn()` always returns `null`, so login cannot produce a usable app user.
  - Files: `lib/services/google_auth_service.dart`, `lib/data/repositories/auth_repository_impl.dart`, `lib/presentation/providers/auth_provider.dart`

- [x] Persist authenticated users to `public.users` in Supabase after login.
  - Add upsert logic so app profile data is stored and can be reused.
  - Files: `lib/data/repositories/auth_repository_impl.dart`, `lib/services/supabase_service.dart`

- [x] Secure hardcoded secrets and credentials.
  - Move Supabase URL/key and Razorpay key to environment/config management.
  - Rotate exposed keys and avoid committing real keys. (manual pending in Supabase/Razorpay dashboards)
  - Files: `lib/services/supabase_service.dart`, `lib/services/razorpay_service.dart`

- [x] Configure Razorpay with real key and robust error handling.
  - Current issue: `YOUR_RAZORPAY_TEST_KEY` placeholder blocks real payments.
  - Files: `lib/services/razorpay_service.dart`, `lib/presentation/providers/booking_provider.dart`

- [x] Connect Pandit listing screen to live Supabase data.
  - Current issue: list is hardcoded with `itemCount: 3` and static values.
  - Files: `lib/presentation/screens/pandit_listing_screen.dart`, `lib/services/supabase_service.dart`, `lib/models/pandit_model.dart`

## P1 - Core Product Completion

- [x] Implement booking creation in database after payment success.
  - Insert into `bookings` with user, pandit, date, status, amount, payment reference.
  - Files: `lib/presentation/providers/booking_provider.dart`, `lib/services/supabase_service.dart`, `lib/models/booking_model.dart`

- [x] Pass selected pandit details from listing to checkout.
  - Current issue: checkout amount/date are hardcoded.
  - Files: `lib/presentation/screens/pandit_listing_screen.dart`, `lib/presentation/screens/checkout_screen.dart`, `lib/router.dart`

- [x] Add booking status lifecycle update flow.
  - Example: `pending -> confirmed -> completed/cancelled`.
  - Files: booking provider/service layer + Supabase policies

- [x] Add sign-out/session handling guards in routing.
  - Prevent unauthorized access to protected routes like pandits/checkout.
  - Files: `lib/router.dart`, `lib/presentation/providers/auth_provider.dart`

## P1 - Data Layer and Architecture

- [x] Complete clean-architecture layering beyond auth.
  - Add domain contracts + data impls for pandits and bookings repositories.
  - Folders currently mostly minimal.
  - Files: `lib/domain/repositories/*`, `lib/data/repositories/*`

- [x] Improve model serialization.
  - Add `toJson()` and safer parsing for runtime type mismatches.
  - Files: `lib/models/user_model.dart`, `lib/models/pandit_model.dart`, `lib/models/booking_model.dart`

- [x] Replace generic `List<dynamic>` responses with typed results.
  - Files: `lib/services/supabase_service.dart`

## P2 - UX and Reliability

- [x] Replace network image dependencies for critical icons/assets.
  - Current login and list rely on external image URLs.
  - Add local assets and fallback UI.
  - Files: `lib/presentation/screens/login_screen.dart`, `lib/presentation/screens/pandit_listing_screen.dart`, `assets/`

- [x] Improve user-facing error states and loading states.
  - Avoid only `print()`; show snackbars/messages and retry options.
  - Files: providers/services/screens

- [x] Dispose payment resources safely.
  - Ensure `Razorpay.clear()` is called via provider/app lifecycle.
  - Files: `lib/services/razorpay_service.dart`, `lib/presentation/providers/booking_provider.dart`

- [x] Add form validation for checkout details.
  - Validate date/time/phone/email before payment call.
  - Files: `lib/presentation/screens/checkout_screen.dart`

## P2 - Testing and Quality
port on this machine.

## P3 - Release and DevOps

- [x] Improve README with setup and run instructions.
  - Add architecture, env variables, Supabase schema migration, payment setup.
  - Files: `README.md`

- [x] Configure Android release identity/signing.
  - Existing TODOs in gradle for app id/signing.
  - Files: `android/app/build.gradle.kts`
- [x] Replace default counter widget test with real app tests.
  - Current test does not match app UI/flow.
  - Files: `test/widget_test.dart`

- [x] Add unit tests for auth and booking providers.
  - Validate loading flags, success/failure transitions, and error handling.

- [x] Add integration tests for login -> browse pandits -> checkout.

- [x] Enable strict linting and remove `print()` based logging.
  - Files: `analysis_options.yaml`, providers/services files

- [x] Fix environment blocker for local analysis on Windows.
  - `flutter analyze` still requires Windows Developer Mode/symlink sup

- [x] Add CI for format, analyze, and tests.

## Completed Recently

- [x] Base schema migration prepared for `users`, `pandits`, `bookings` with RLS and indexes.
  - File: `supabase/migrations/20260330_init_schema.sql`
