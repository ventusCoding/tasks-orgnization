# App identity (T9.2.01)

Record of the identifiers, names, brand assets and web presence of Everslot. **Owner:** project lead.
Name chosen 2026-09-22 (arch §14.1); the trademark check is still open (see the last section).

## Identifiers

> **Irreversible.** The Google Play package name and the App Store bundle id can never change once a build
> is uploaded: a new id means a new app, a new listing, no reviews and no update path for existing users.
> The App Store Connect SKU is permanent too. Confirm them before the first upload.

| What | Value | Set in |
|---|---|---|
| Android application id | `app.everslot` | `app/android/app/build.gradle.kts` (`applicationId`) |
| Android dev application id | `app.everslot.dev` | `dev` flavor, `applicationIdSuffix = ".dev"` |
| Android namespace | `app.everslot` | `build.gradle.kts` (`namespace`, code only) |
| iOS bundle id | `app.everslot` | `Runner.xcodeproj` (`PRODUCT_BUNDLE_IDENTIFIER`) |
| iOS dev bundle id | `app.everslot.dev` | dev scheme/xcconfig when iOS flavors land (ADR-019) |
| iOS test bundle | `app.everslot.RunnerTests` | `Runner.xcodeproj` |
| URL scheme | `everslot://` | `AndroidManifest.xml`, `Info.plist` (`CFBundleURLTypes`) |
| Background task id | `app.everslot.sync` | `Info.plist` (`BGTaskSchedulerPermittedIdentifiers`) |
| App Group (widgets) | `group.app.everslot.shared` | created with the first widget ([8.2] T8.2.02) |
| Firebase projects | `everslot-dev`, `everslot-prod` | arch §7.1, `docs/ops/firebase_prod.md` |
| Supabase projects | `everslot-dev`, `everslot-prod` | arch §7.1, `docs/ops/supabase_prod.md` |
| fastlane | `app.everslot` | `app/android/fastlane/Appfile`, `app/ios/fastlane/Appfile` |

Dev and prod install side by side on Android (different application ids and the "Everslot Dev" label);
on iOS once the dev scheme exists.

## Names

| Where | Value |
|---|---|
| Home screen (prod) | `Everslot` — Android `resValue app_name`, iOS `CFBundleDisplayName` |
| Home screen (dev) | `Everslot Dev` — Android dev flavor |
| Store name EN (27/30) | `Everslot — Planner & Habits` |
| Store name FR (29/30) | `Everslot — Agenda & habitudes` |
| Store name AR (22/30) | `Everslot — مخطط وعادات` |
| Tagline EN / FR | *Own every slot of your day.* / *Maîtrisez chaque créneau de votre journée.* |
| Tagline AR | *تحكّم في كل دقيقة من يومك.* |

Alternatives if a name is refused (≤ 30 characters): `Everslot: Planner & Habits`,
`Everslot — Plan, Lists, Habits`, `Everslot : agenda et habitudes`, `Everslot — المخطط والعادات`.
The listings themselves live in `app/android/fastlane/metadata/android/` and `app/ios/fastlane/metadata/`
(`docs/ops/store_compliance.md` § Store listings).

## Icons and splash

Sources are the SVGs in `app/assets/branding/`; PNGs are rendered from them. Regenerate everything with
`tool/gen_branding.sh` (needs `fvm`, `rsvg-convert` from `brew install librsvg`, and Python PIL to strip
the alpha channel of the store icon).

| Source | Used for |
|---|---|
| `icon.svg` | iOS app icon and App Store icon (1024 px, no alpha) |
| `icon_dark.svg`, `icon_tinted.svg` | iOS 18+ dark and tinted icon variants |
| `icon_legacy.svg`, `icon_legacy_dev.svg` | Android legacy icons (prod, dev with DEV badge) |
| `adaptive_background.svg`, `adaptive_foreground.svg` | Android adaptive icon |
| `adaptive_foreground_dev.svg` | Android dev flavor adaptive foreground (DEV badge) |
| `adaptive_monochrome.svg` | Android 13+ themed icon |
| `splash.svg` | native splash (`flutter_native_splash`), background `#3B5BDB` / dark `#1A1F4D` |

Store and web assets not produced by the script:

- Play hi-res icon 512 × 512:
  `rsvg-convert -w 512 -h 512 app/assets/branding/icon.svg -o play-icon-512.png`.
- Play feature graphic 1024 × 500 and screenshots: see `docs/ops/store_compliance.md` § Screenshots.
- Website favicon: `site/favicon.svg` is `icon.svg` with rounded corners — update both together.

Checks after regenerating: open every `mipmap-*` density and the iOS `AppIcon` set (crisp, no halo), run
the dev and prod Android builds side by side, and confirm `icon.png` has no alpha
(`sips -g hasAlpha app/assets/branding/icon.png`).

## Website and app links

The static site (`site/`, T9.2.09) hosts the privacy policy, terms, support and account-deletion pages
and the association files for verified links ([8.2] T8.2.01). `.github/workflows/pages.yml` deploys it.

1. **Domain.** Register the domain (arch §14.1 suggests `everslot.app`) and serve the site at its root:
   `/.well-known/` must be reachable at `https://YOUR_SITE_DOMAIN/.well-known/…` without redirects, and
   `404.html` uses root-absolute links. Point DNS at GitHub Pages (GitHub docs: "Managing a custom domain"),
   then Settings › Pages: Source = *GitHub Actions*, custom domain, *Enforce HTTPS*.
2. **Placeholders.** Replace the domain everywhere it appears (site and App Store URLs):

   ```bash
   grep -rl YOUR_SITE_DOMAIN site app/ios/fastlane/metadata \
     | xargs sed -i '' 's/YOUR_SITE_DOMAIN/everslot.app/g'     # GNU sed: -i without ''
   ```

   Then fill by hand: `[DEVELOPER NAME]`, `[CONTACT EMAIL]`, `[EFFECTIVE DATE]`, `[SUPABASE REGION]`,
   `[COUNTRY/GOVERNING LAW]` (legal pages), `APP_STORE_ID` (download button, after the App Store record
   exists), `<TEAM_ID>` in `apple-app-site-association`, `<SHA256_CERT_FINGERPRINT>` and
   `<DEV_SHA256_CERT_FINGERPRINT>` in `assetlinks.json`. Remaining ones:
   `grep -rnE '\[[A-Z /]+\]|YOUR_SITE_DOMAIN|APP_STORE_ID|<[A-Z_0-9]+>' site`.
3. **Legal review.** After a lawyer has reviewed the privacy policy, terms and deletion page, delete the
   `<p class="template-note" …>` line of each page.
4. **Publish.** Set the repository variable `PAGES_ENABLED=true` and push (or run the workflow). The
   workflow refuses to publish while placeholders or template notes remain, unless run manually with
   *allow_placeholders* for a preview.

Values for the association files:

- `<TEAM_ID>`: Apple Developer › Membership details. Both `app.everslot` and `app.everslot.dev` are listed.
- `<SHA256_CERT_FINGERPRINT>`: Play Console › Test and release › App integrity › App signing › *App signing
  key certificate* (SHA-256). Add the upload key's SHA-256 as a second entry only if links must verify on
  locally signed release builds.
- `<DEV_SHA256_CERT_FINGERPRINT>`: the dev signing key, e.g.
  `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android`.

App side (not done yet; T8.2.01, owner: app platform):

- iOS: *Associated Domains* capability with `applinks:YOUR_SITE_DOMAIN` in the Runner entitlements (append
  `?mode=developer` for dev builds while testing).
- Android: an `https` intent filter with `android:autoVerify="true"`, `android:host="YOUR_SITE_DOMAIN"` and
  path prefixes matching the association file (`/today`, `/plan`, `/task`, `/lists`, `/habits`, `/quit`,
  `/insights`, `/inbox`, `/search`, `/settings`). `DeepLinkParser` already accepts `https` links.

Verification after each deploy:

```bash
curl -sI https://YOUR_SITE_DOMAIN/.well-known/apple-app-site-association   # 200, no redirect
curl -s https://app-site-association.cdn-apple.com/a/v1/YOUR_SITE_DOMAIN    # what iOS devices receive
DAL=https://digitalassetlinks.googleapis.com/v1/statements:list
curl -s "$DAL?source.web.site=https://YOUR_SITE_DOMAIN&relation=delegate_permission/common.handle_all_urls"
adb shell pm verify-app-links --re-verify app.everslot && adb shell pm get-app-links app.everslot
```

GitHub Pages serves the extensionless association file as `application/octet-stream`; Apple's CDN accepts
it in practice, which the CDN request above confirms. The CDN refreshes within about a day.

## Before the first upload

- [ ] Professional trademark search for "Everslot" (US, EU, FR, MENA) — arch §14.1.
- [ ] Domain registered, site live, support/privacy/deletion URLs reachable in EN/FR/AR.
- [ ] App Store Connect: bundle id `app.everslot` registered (Certificates, Identifiers & Profiles), app
      record created with SKU `everslot-ios` and primary language English (U.S.); `APP_STORE_ID` noted.
- [ ] Play Console: app created with package `app.everslot`, default language English (United States),
      Play App Signing enabled (T9.2.02).
- [ ] Store names and listings uploaded from the fastlane metadata (`fastlane android metadata`,
      `fastlane ios metadata`) after the URL placeholders are replaced.
