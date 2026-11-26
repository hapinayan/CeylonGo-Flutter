# CeylonGo Flutter – Team Handoff Documentation

**Date:** November 21, 2026  
**Repository:** `https://github.com/hapinayan/CeylonGo-Flutter.git`  
**Flutter SDK:** 3.x+ (Dart 3.7 compatible)  
**Main Entry Point:** `lib/main.dart`  
**Standalone Artisan Demo Entry Point:** `lib/main_demo.dart`  

---

## 1. Executive Summary & Completed Modules

This release consolidates core mobile user journeys for CeylonGo:

### A. Animated CeylonGo Home Screen
- **Full-Width Deep Blue Header (`#073B91`)**: Features the pure white "CeylonGo" branding, notification bell with unread dot, and quick profile avatar access.
- **8 Core Sections**:
  1. Header with Android status bar integration
  2. Search bar ("Where do you want to go?")
  3. Six Module Shortcuts (Homestays, Eco Tourism, Activities, Tour Guides, Rentals, Artisan)
  4. AI Trip Planner Banner (CTA button, floating glowing orb, itinerary/budget/route/tips chips)
  5. Quick Actions (My Bookings, Saved, Promotions, Community)
  6. Popular Destinations carousel (Jaffna, Ella, Kandy)
  7. Featured Homestays carousel (pricing, rating, amenities, booking action)
  8. Floating Bottom Navigation Bar (Home, Explore, AI Planner, Community, Profile)
- **Fluid Micro-Animations**: Smooth entrance slide/fade transitions, staggered section reveals, and press feedback.

### B. Offline Demo Authentication Flow
- **Reused Login & Register Screens**: Zero UI degradation to the production auth screens.
- **Deterministic Offline Demo Credentials**:
  - Email: `demo@ceylongo.com`
  - Password: `Demo@1234`
- **Security & Scope**: Arbitrary credentials are NEVER accepted as authenticated sessions. Real backend authentication via `AuthService` remains intact.
- **Session Persistence**: Saves local token `demo-offline-jwt-token` and `UserModel` to secure storage, automatically routing past `AuthGate` to Home.

### C. Full White Minimal Traveler Profile Page
- **Clean White Header**: Back navigation, notification bell, and settings gear. Wave/blue banners removed.
- **Traveler Card**: Circular avatar with camera edit badge, verified traveler badge, and traveler level ("Explorer").
- **Travel Statistics**: Trips completed, Reviews contributed, and Saved places counters.
- **Account Settings & Security**: Profile editing, Notifications, Language ("English - US"), Currency ("LKR"), Dark Mode toggle, Privacy policy, Terms, and Help center.
- **Safe Logout Dialog**: Confirmation modal clearing secure tokens and routing safely to `/login`.

### D. Artisan Discovery & Craft Experience Module
- **Artisan Discovery Screen (`/artisan`)**: Search, craft category filters (Pottery, Batiks, Masks, Handlooms, Woodcarving, Jewelry), search-as-you-type, and GPS nearby radius filtering.
- **Artisan Business Detail (`/artisan/business?id=...`)**: Business story, workshop hours, phone/email actions, map directions, showcase items, customer reviews with star breakdown.
- **Product Catalog & Detail (`/artisan/products`, `/artisan/product?id=...`)**: Pricing in LKR, stock status badges, workshop reservation CTA.
- **Reservation System (`/artisan/reservations`, `/artisan/reserve`)**: Interactive booking form for craft workshops, date/time pickers, attendee counters, and cancellation workflow.
- **Wishlist & Reviews (`/artisan/wishlist`)**: Save favorite artisan businesses and submit local reviews with star ratings.

### E. Travel Community & Social Feed Module
- **Community Feed Screen (`/community`)**: Clean white header ("CeylonGo | Community"), search shortcut, and notification drawer.
- **3 Dynamic Feed Tabs**: "For You", "Following", and "Saved" with royal-blue pill indicator.
- **Trending Hashtags**: Horizontal scrollable chips (`#All`, `#Jaffna`, `#Ella`, `#TravelSriLanka`, `#BeachLife`, `#Nature`, `#SriLankanCrafts`).
- **Rich Post Cards**: Author avatars, "Partner" badge for verified artisans, 16:9 photography with graceful offline fallbacks, like/unlike toggle, comments sheet, bookmarking, and "View Workshop" CTA.
- **Floating Compose Action**: Bottom sheet for publishing travel posts with photo presets, captions, location tagging, and hashtag chips.
- **Public Author Profile & Search**: Author showcase grid and real-time offline query search across posts.

---

## 2. Offline Demo Limitations

The current release is equipped with an in-memory mock architecture designed for client demos, manual QA, and offline walkthroughs without requiring the backend server or databases:

1. **State Persistence**:
   - `ArtisanDemoService` and `CommunityDemoService` maintain in-memory state.
   - Hot restarts (`R`) or full app relaunches will reset mock mutations (new posts, comments, reservations) back to the curated default seed data.
2. **Mock Media**:
   - Post and listing images use public Unsplash URLs with graceful local gradient fallbacks when offline or when network requests fail.
3. **Geo-Location**:
   - The Nearby Artisan filter uses `geolocator: ^14.0.2` with simulated default coordinates (Colombo / Galle / Kandy) if device GPS permission is denied or simulated in an emulator.

---

## 3. Test Suite Verification & Quality Metrics

All test suites have been verified with 100% pass rates:

- **Static Analysis (`flutter analyze`)**:
  ```
  Analyzing CeylonGo-Flutter...
  No issues found! (ran in 3.9s)
  ```
  - 0 errors, 0 warnings, 0 linter issues.
- **Automated Tests (`flutter test`)**:
  ```
  00:26 +176: All tests passed!
  ```
  - **176 Total Tests Passed, 0 Failed, 0 Skipped.**
  - **Responsive Verification**: Verified on 320px (narrow), 360x800 (Samsung Galaxy A22), 375px, 430px, 800px (tablet), and 1200px (desktop) without any RenderFlex overflows.

---

## 4. Instructions for Next Developer

### Running the App Locally / On Device
```powershell
# Run with full app launch (Auth -> Home -> Community -> Artisan)
flutter run -d <device_id> -t lib/main.dart

# Direct Artisan demo standalone launch
flutter run -d <device_id> -t lib/main_demo.dart
```

### Running Tests
```powershell
# Analyze codebase
flutter analyze

# Run full test suite
flutter test

# Run specific feature tests
flutter test test/community_feed_screen_test.dart
flutter test test/home_screen_test.dart
flutter test test/profile_screen_test.dart
```

### Transitioning to Live Backend APIs
1. **Authentication**: `lib/features/auth/services/auth_service.dart` is pre-configured with FastAPI contracts (`POST /api/v1/auth/login`, `POST /api/v1/auth/register`, `GET /api/v1/auth/me`). Replace `ArtisanDemoService.isDemoMode` guards when the live server environment URL is configured.
2. **Artisan Service**: `lib/features/artisan/services/artisan_service.dart` contains real HTTP methods for listing discovery, products, and reservations. To enable live mode, inject `isDemo: false` or point `apiBaseUrl` to the backend gateway.
3. **Community Service**: Define backend API contracts for feed pagination, post creation, and comments by replacing `CommunityDemoService` calls with an `HttpCommunityService` implementing identical interfaces.

