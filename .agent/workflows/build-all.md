---
description: Build both Web and Android APK to ensure all distribution files are up to date.
---

To build the latest version of the app for both Web and Android, follow these steps:

// turbo
1. Run the build script:
```powershell
.\scripts\build_all.ps1
```

This will:
- Clean the project (`flutter clean`) to remove old cached files.
- Build the Web release (`flutter build web --release`).
- Build the Android APK (`flutter build apk --release`).

After completion, your latest artifacts will be available in:
- `build/web`
- `build/app/outputs/flutter-apk/app-release.apk`
