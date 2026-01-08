# How to Install Flutter on Windows

## 1. Download Flutter SDK
1.  Go to the official website: [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows)
2.  Click the blue button to download the **stable zip file** (e.g., `flutter_windows_3.x.x-stable.zip`).

## 2. Extract the SDK
1.  Create a folder: `C:\src` (Do **not** put it in `Program Files` due to permission issues).
2.  Extract the zip file there.
    - You should end up with: `C:\src\flutter`

## 3. Update Path Variable (Crucial Step)
1.  Press **Windows Key**, type **"env"**, and select **"Edit the system environment variables"**.
2.  Click the **"Environment Variables..."** button.
3.  Under **"User variables"** (top section), find the variable named **"Path"** and select it.
4.  Click **"Edit"**.
5.  Click **"New"** and type: `C:\src\flutter\bin`
6.  Click **OK** on all windows to close them.

## 4. Verify Installation
1.  Close any open PowerShell or Command Prompt windows.
2.  Open a **new** PowerShell window.
3.  Type: `flutter doctor`
4.  If it starts running, you are successful!
    - It might ask you to run `flutter doctor --android-licenses`, just follow its instructions.

## 5. Once Done
- Come back here and reply **"INSTALLED"**.
- Then run these commands in your project folder:
    1. `cd "C:\Users\YNG\Desktop\All Projects\inoviceapp"`
    2. `flutter pub get`
    3. `flutter run`
