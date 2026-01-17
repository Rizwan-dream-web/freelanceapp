Write-Host "🚀 Starting Full Build (Web + Android)..." -ForegroundColor Cyan

Write-Host "🧹 Cleaning build artifacts..." -ForegroundColor Yellow
flutter clean

Write-Host "🌐 Building Web Release..." -ForegroundColor Green
flutter build web --release

Write-Host "🤖 Building Android APK Release..." -ForegroundColor Green
flutter build apk --release

Write-Host "✅ Build Complete!" -ForegroundColor Cyan
Write-Host "📂 Web: build/web"
Write-Host "📂 APK: build/app/outputs/flutter-apk/app-release.apk"
