# 🛠️ Technical Manifesto: The Freelancer App Architecture

This document outlines the technical stack, architectural decisions, and platform choices that power the Freelancer App.

---

## 🏗️ Core Technology Stack

### **Framework: Flutter (by Google)**
*   **Why?** We chose Flutter for its **Multi-platform Mastery**. It allows us to maintain a single codebase that compiles into high-performance native code for **Android** and high-speed JavaScript/Canvas for the **Web**.
*   **Performance**: Flutter's Impeller/Skia engines ensure 60FPS animations, critical for our glassmorphic iOS-style UI.

### **Language: Dart**
*   **Why?** Dart provides a powerful combination of "Just-In-Time" (JIT) compilation for hot reload during development and "Ahead-of-Time" (AOT) compilation for lightning-fast production builds.

---

## 📦 Data & Storage Architecture

### **Local Database: Hive (NoSQL)**
*   **Why?** Hive is an ultra-fast, lightweight NoSQL database written entirely in Dart.
*   **Offline-First**: Unlike standard SQL databases, Hive allows for instantaneous data reads/writes without waiting for a server. This makes the app feel "fluid" even in the basement or on a plane.
*   **Security**: Supports AES-256 encryption out of the box for sensitive user data.

### **Cloud Backend: Firebase (Google Cloud)**
*   **Why?** We use Firebase for its real-time synchronization capabilities.
*   **Firestore**: Acts as our global project/invoice mirror.
*   **Firebase Auth**: Provides industry-standard security for Google, Phone (OTP), and Email logins.
*   **Firebase Storage**: Used for hosting client-ready PDF invoices and project assets.

---

## 📐 Software Architecture: The Repository Pattern

We moved away from direct database calls inside the UI and moved to a **Repository Pattern**.
*   **UI Layer**: Only cares about *displaying* data.
*   **Repository Layer**: Handles the logic of *where* to get data (Local Hive vs. Cloud Firestore).
*   **Why?** This makes the app maintainable. If we ever want to switch from Hive to another database, we only change 1 file (the repository) instead of 50 screen files.

---

## 🎨 Design Philosophy: Glassmorphism 2.0

*   **Foundation**: Vanilla Flutter `BackdropFilter` and `CustomPainter`.
*   **The Aesthetic**: High-sigma blurring (blur strength 20-30), 10-15% opacity white tints, and "hairline" borders (0.5 - 1.0 width).
*   **Why?** To provide a premium, modern experience that usually requires a team of designers, but is handled programmatically here.

---

## 🌐 Platform Targets

1.  **Android**: Target SDK 34+. Optimized for mobile haptics and local push notifications for deadlines.
2.  **Web (Wasm/JS)**: Responsive release build. Optimized for desktop multitasking and large-screen financial management.

---

## ⚡ Build & Release Pipeline

*   **Automation**: PowerShell-based release script (`scripts/build_all.ps1`).
*   **Consistency**: `flutter clean` is enforced before every release to ensure no stale data or "ghost" bugs enter the production APK or Web folder.

---

## 🔮 Future-Proofing (Phase 3 Prep)

The architecture is designed to integrate:
*   **AI (LLMs)**: via `google_generative_ai` for the Proposal Architect.
*   **OCR**: via `google_ml_kit` for Receipt Scanning.
*   **Kanban**: via `reorderables` for drag-and-drop management.
