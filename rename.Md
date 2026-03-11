# Rename And Link Change Map

This file tracks UI rename and link edits so the exact source locations are easy to find later.

## Search Box / Shields Surface

- `Search bar end icon replaced with VKRM logo and wrapped as an Android drawable`
  - `/vkrmbrowser/src/brave/android/java/brave-res/drawable-nodpi/vkrm_ntp_shields_logo.png`
  - `/vkrmbrowser/src/brave/android/java/brave-res/drawable/vkrm_ntp_shields_icon.xml`
  - `/vkrmbrowser/src/brave/android/BUILD.gn`

- `Homepage fake search box action row changed to SearchBar | protection_logo | 3 dots`
  - `/vkrmbrowser/src/chrome/android/java/res/layout/fake_search_box_layout.xml`

- `Homepage VKRM logo now forwards to the real Shields popup and mirrors Up/Down state`
  - `/vkrmbrowser/src/brave/android/java/org/chromium/chrome/browser/ntp/BraveNewTabPageLayout.java`
  - `/vkrmbrowser/src/brave/android/java/org/chromium/chrome/browser/toolbar/top/BraveToolbarLayoutImpl.java`

- `Shields popup title / accessibility / down-state copy renamed from Brave to VKRM where requested`
  - `/vkrmbrowser/src/brave/browser/ui/android/strings/android_brave_strings.grd`

## Earlier Rename / Link Files

- `Welcome flow wording and optional GitHub action`
  - `/vkrmbrowser/src/brave/android/java/org/chromium/chrome/browser/firstrun/WelcomeOnboardingActivity.java`
  - `/vkrmbrowser/src/brave/android/java/brave-res/values/vkrm_theme_strings.xml`

- `Help & Feedback support URL`
  - `/vkrmbrowser/src/brave/android/java/org/chromium/chrome/browser/feedback/BraveHelpAndFeedbackLauncherImpl.java`
  - `/vkrmbrowser/src/brave/android/java/org/chromium/chrome/browser/BraveIntentHandler.java`
  - `/vkrmbrowser/src/brave/android/java/org/chromium/chrome/browser/privacy/settings/BravePrivacySettings.java`

- `Android settings / password / homepage / news rename surfaces`
  - `/vkrmbrowser/src/brave/browser/ui/android/strings/android_brave_strings.grd`
  - `/vkrmbrowser/src/brave/browser/ui/android/strings/android_chrome_strings.grd`
  - `/vkrmbrowser/src/brave/components/resources/brave_news_strings.grdp`
  - `/vkrmbrowser/src/brave/components/resources/brave_welcome_strings.grdp`

- `Clear browsing data toolbar title cleanup`
  - `/vkrmbrowser/src/chrome/android/java/src/org/chromium/chrome/browser/site_settings/ManageSpaceActivity.java`
