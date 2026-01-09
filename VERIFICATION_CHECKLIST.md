# ✅ Login Verification Checklist

Use this checklist to verify all login methods work after enabling Firestore.

---

## 🔧 Pre-Testing: Enable Required Services

### Step 1: Enable Firestore API
- [ ] Go to: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=freelancer-app-a7c71
- [ ] Click **"ENABLE"** button
- [ ] Wait 1-2 minutes

### Step 2: Create Firestore Database
- [ ] Go to: https://console.firebase.google.com/project/freelancer-app-a7c71
- [ ] Click **"Firestore Database"** in left sidebar
- [ ] Click **"Create database"**
- [ ] Select **"Start in test mode"**
- [ ] Choose location (e.g., `us-central`)
- [ ] Click **"Enable"**

### Step 3: Verify Other APIs
- [ ] **Firebase Authentication API** - Should be enabled
  - Check: https://console.developers.google.com/apis/api/identitytoolkit.googleapis.com/overview?project=freelancer-app-a7c71
- [ ] **Google Sign-In API** - Should be enabled
  - Check: https://console.developers.google.com/apis/api/oauth2.googleapis.com/overview?project=freelancer-app-a7c71

---

## 🧪 Testing Checklist

### Test 1: Google Login
- [ ] Open app
- [ ] Click **"Continue with Google"**
- [ ] Select Google account
- [ ] **Expected:** Should login successfully
- [ ] **Expected:** Should navigate to dashboard
- [ ] **Check Console:** Should see no Firestore errors
- [ ] **Check Firestore:** Should see user document in `users` collection

**If fails:**
- Check browser console (F12) for errors
- Verify Google Sign-In is enabled in Firebase Console
- Check SHA-1 keys are added (for Android)

---

### Test 2: Email Registration
- [ ] Open app
- [ ] Click **"Email Login"**
- [ ] Click **"Need an account? Register"**
- [ ] Enter:
  - Name: `Test User`
  - Email: `test@example.com`
  - Password: `Test123456`
- [ ] Click **"Create Account"**
- [ ] **Expected:** Should show "Verification email sent" message
- [ ] **Expected:** Should navigate to Email Verification Screen
- [ ] **Check Email:** Should receive verification email
- [ ] **Check Firestore:** Should see user document created (even if not verified yet)

**If fails:**
- Check email spam folder
- Verify email provider is enabled in Firebase Console
- Check browser console for errors

---

### Test 3: Email Login (Unverified)
- [ ] Try to login with unverified email
- [ ] **Expected:** Should show "Please verify your email" message
- [ ] **Expected:** Should NOT allow login
- [ ] **Expected:** Should send new verification email

---

### Test 4: Email Login (Verified)
- [ ] Click verification link in email
- [ ] **Expected:** Email should be verified
- [ ] Go back to app
- [ ] Click **"I've Verified My Email"** button
- [ ] **Expected:** Should navigate to dashboard
- [ ] **Expected:** Should see user profile loaded

---

### Test 5: Phone Login
- [ ] Open app
- [ ] Click **"Phone Login"**
- [ ] Enter phone number: `+1234567890` (use test number)
- [ ] Click **"Send Verification Code"**
- [ ] **Expected:** OTP input should appear
- [ ] **Expected:** Should receive OTP (if phone auth configured)
- [ ] Enter OTP code
- [ ] Click **"Verify & Continue"**
- [ ] **Expected:** Should login successfully

**Note:** Phone auth requires additional Firebase setup (reCAPTCHA, etc.)

---

### Test 6: Profile Management
- [ ] After logging in, go to **Settings**
- [ ] Click **"View Profile"**
- [ ] **Expected:** Should see profile screen with name and email
- [ ] Edit name
- [ ] Click **"Save"**
- [ ] **Expected:** Should save successfully
- [ ] **Check Firestore:** Should see updated profile document

---

### Test 7: Logout
- [ ] Go to **Settings**
- [ ] Scroll to **Account** section
- [ ] Click **"Logout"**
- [ ] **Expected:** Should show confirmation dialog
- [ ] Click **"Logout"** in dialog
- [ ] **Expected:** Should navigate to Login Screen
- [ ] **Expected:** Should clear auth session

---

## 🔍 Debugging: Check Console Logs

### Browser Console (F12)
Look for these messages:

**Good Signs:**
- ✅ No Firestore errors
- ✅ "User logged in successfully"
- ✅ Profile created/updated messages

**Warning Signs:**
- ⚠️ "Warning: Could not create Firestore profile" - Firestore not enabled
- ⚠️ "PERMISSION_DENIED" - Firestore rules issue
- ⚠️ "SERVICE_DISABLED" - API not enabled

### Flutter Logs
Run: `flutter run -d chrome` and watch for:
- Authentication success messages
- Firestore connection messages
- Any error stack traces

---

## 📊 Verify in Firebase Console

### Check Authentication
1. Go to: https://console.firebase.google.com/project/freelancer-app-a7c71/authentication/users
2. **Expected:** Should see test users listed
3. **Expected:** Email verified status should be correct

### Check Firestore
1. Go to: https://console.firebase.google.com/project/freelancer-app-a7c71/firestore
2. **Expected:** Should see `users` collection
3. **Expected:** Should see user documents with:
   - `uid`
   - `name`
   - `email`
   - `createdAt`

---

## ✅ Success Criteria

All tests pass if:
- [x] Google login works
- [x] Email registration works
- [x] Email verification works
- [x] Email login works (after verification)
- [x] Phone login works (if configured)
- [x] Profile management works
- [x] Logout works
- [x] No Firestore errors in console
- [x] User documents appear in Firestore

---

## 🚨 Common Issues & Solutions

### Issue: "Firestore API not enabled"
**Solution:** Enable Firestore API (Step 1 above)

### Issue: "Permission denied" in Firestore
**Solution:** 
- Go to Firestore → Rules
- Update rules to allow read/write (for testing):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Issue: Google login shows "Could not connect"
**Solution:**
- Check SHA-1 keys are added in Firebase Console
- Verify `google-services.json` is correct
- Enable Google Sign-In provider in Firebase Auth

### Issue: Email verification not sending
**Solution:**
- Check email provider is enabled in Firebase Auth
- Check spam folder
- Verify email domain is not blocked

---

## 📝 Test Results Template

```
Date: ___________
Tester: ___________

Google Login: [ ] Pass [ ] Fail
Email Registration: [ ] Pass [ ] Fail
Email Verification: [ ] Pass [ ] Fail
Email Login: [ ] Pass [ ] Fail
Phone Login: [ ] Pass [ ] Fail
Profile Management: [ ] Pass [ ] Fail
Logout: [ ] Pass [ ] Fail

Issues Found:
_____________________________________________
_____________________________________________
_____________________________________________
```

---

**After completing all tests, your login system should be fully functional!** 🎉
