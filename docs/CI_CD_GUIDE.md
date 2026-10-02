# ReadNext — CI/CD, Multi-Platform Packaging & Release Guide

> This guide explains the automated multi-platform build pipeline, packaging configurations, artifact storage, and the manual release process for **ReadNext**.

---

## 🏗️ Architecture & Release Lifecycle

The CI/CD pipeline strictly enforces the following separation of concerns:

```
[Developer Git Push]
         │
         ▼
[GitHub Actions: build.yml] ───────────────► Triggered on every push to main
         │
         ├──► 1. Windows Runner (windows-latest) ──► ReadNext-Setup-v1.0.0.exe + Portable .zip
         ├──► 2. Linux Runner (ubuntu-latest)     ──► ReadNext-v1.0.0-Linux-x64.deb + .tar.gz
         ├──► 3. macOS Runner (macos-14)          ──► ReadNext-macOS.dmg + .zip
         ├──► 4. Android Runner (ubuntu-latest)   ──► ReadNext-Android.apk
         └──► 5. iOS Runner (macos-14)            ──► ReadNext-iOS-unsigned.ipa
         │
         ▼
[GitHub Actions Artifacts Storage] (30-day retention, ZERO automatic releases created)
         │
         ▼ (Developer tests and verifies builds)
         │
[Manual Release Trigger: release.yml] ────► Triggered manually via GitHub Actions UI
         │                                    - Select version tag (e.g., v1.0.0)
         │                                    - Select platforms to include (Checkboxes)
         │                                    - Enter release notes & title
         ▼
[Official GitHub Release Published] ──────► Binaries attached directly to the release
```

---

## 📂 Repository Structure

```text
ReadNext/
├── .github/
│   └── workflows/
│       ├── build.yml                 # Automated CI: Builds all platforms & uploads artifacts
│       └── release.yml               # Manual Release: Triggered by developer to publish
│
├── packaging/
│   ├── windows/
│   │   └── inno_setup.iss            # Inno Setup wizard installer script (Next -> Install -> Finish)
│   └── linux/
│       ├── read_next.desktop         # Standard XDG desktop launcher entry
│       └── build_deb.sh              # Debian .deb & portable .tar.gz packager
│
├── windows/
│   └── runner/resources/app_icon.ico # High-res multi-resolution product logo icon
├── web/
│   ├── favicon.png                   # Official product favicon
│   └── icons/                        # High-resolution PWA product icons
│
├── docs/
│   └── CI_CD_GUIDE.md                # This comprehensive pipeline guide
│
├── lib/                              # Flutter application source code
├── test/                             # Automated test suite (all 30 unit & widget tests)
├── pubspec.yaml                      # Project specification & dependencies
└── features.md                       # Comprehensive feature matrix
```

---

## 📦 Supported Build Targets & Packaging Details

### 1. Windows (`.exe` Installer & Portable `.zip`)
- **Build Output**: `ReadNext-Setup-v1.0.0.exe` and `ReadNext-Windows-Portable.zip`.
- **Packaging Engine**: Inno Setup Compiler (`iscc`).
- **User Experience**:
  1. **Welcome Screen**: Clean enterprise wizard with the official ReadNext icon.
  2. **Destination Folder**: Defaults to `C:\Program Files\ReadNext` (or per-user AppData).
  3. **Tasks**: Optional checkbox to create a desktop shortcut.
  4. **Installation**: Rapid LZMA2 solid compression extraction with progress bar.
  5. **Finish Screen**: Optional *"Launch ReadNext"* checkbox with immediate execution.
  6. **Uninstaller**: Full uninstaller registered in Windows Add/Remove Programs.

### 2. Linux (`.deb` Package & `.tar.gz` Archive)
- **Build Output**: `ReadNext-v1.0.0-Linux-x64.deb` and `ReadNext-v1.0.0-Linux-x64.tar.gz`.
- **Packaging Engine**: `dpkg-deb` and standard GNU `tar`.
- **System Integration**: Installs binary into `/usr/lib/read_next/`, registers launcher in `/usr/share/applications/read_next.desktop`, and installs desktop icon in `/usr/share/pixmaps/read_next.png`.

### 3. macOS (`.dmg` Disk Image & `.zip`)
- **Build Output**: `ReadNext-macOS.dmg` and `ReadNext-macOS.zip`.
- **Packaging Engine**: Native Apple `hdiutil` creating UDZO compressed disk images.
- **User Experience**: Standard macOS disk image mountable with drag-and-drop to `/Applications`.

### 4. Android (`.apk`)
- **Build Output**: `ReadNext-Android.apk`.
- **Packaging Engine**: Gradle release build with Java 17.

### 5. iOS (`.ipa`)
- **Build Output**: `ReadNext-iOS-unsigned.ipa`.
- **Packaging Engine**: Xcode archive package with `.app` inside standard `Payload/` folder.

---

## 🔐 Required Secrets & Environment Variables

For standard testing and open distribution, builds work out-of-the-box. When you are ready to sign releases for official app stores or corporate code signing, configure the following **Repository Secrets** in **GitHub → Settings → Secrets and variables → Actions**:

### 1. Android Release Signing (Optional)
| Secret Name | Description |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded `.jks` release keystore file (`base64 -w 0 my-release-key.jks`) |
| `ANDROID_KEYSTORE_PASSWORD`| Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias name |
| `ANDROID_KEY_PASSWORD` | Key password |

### 2. Apple / macOS / iOS Code Signing (Optional)
| Secret Name | Description |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded Developer/Distribution `.p12` certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the exported `.p12` certificate |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64-encoded `.mobileprovision` file |
| `APPLE_TEAM_ID` | 10-character Apple Developer Team ID |

### 3. Windows Authenticode Signing (Optional)
| Secret Name | Description |
|---|---|
| `WINDOWS_CERTIFICATE_BASE64` | Base64-encoded `.pfx` code signing certificate |
| `WINDOWS_CERTIFICATE_PASSWORD` | Password for the `.pfx` certificate |

---

## 🚀 Step-by-Step Instructions

### Step 1: Push Code to GitHub
Run the following commands to connect your local repository to GitHub:

```bash
# 1. Stage all files
git add .

# 2. Create the initial commit
git commit -m "feat: complete ReadNext PDF reader with multi-platform CI/CD and corporate theme"

# 3. Add your GitHub remote repository
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPOSITORY>.git

# 4. Push to the main branch
git push -u origin main
```

---

### Step 2: Automatic Build & Artifact Verification
1. Open your repository on GitHub.
2. Navigate to the **Actions** tab.
3. You will see the **"Multi-Platform Automated Build & Test"** workflow running automatically across all 5 runners (Windows, Linux, macOS, Android, iOS).
4. When complete, click on the workflow run.
5. In the **Artifacts** section at the bottom, download any platform build to test on your local machine:
   - `readnext-windows-build` (contains `ReadNext-Setup-v1.0.0.exe`)
   - `readnext-linux-build` (contains `.deb` and `.tar.gz`)
   - `readnext-macos-build` (contains `.dmg` and `.zip`)
   - `readnext-android-build` (contains `.apk`)
   - `readnext-ios-build` (contains `.ipa`)
6. **Notice**: No release is created.

---

### Step 3: Triggering a Manual Release
When you have tested the artifacts and are ready to publish an official release:

1. Open your repository on GitHub.
2. Go to the **Actions** tab.
3. In the left sidebar, click **"Manual Multi-Platform Release"**.
4. Click the **"Run workflow"** dropdown button on the right.
5. Configure your release:
   - **Release Tag Version**: Enter the version tag (e.g., `v1.0.0` or `v1.1.0`).
   - **Release Title**: Enter title (e.g., `ReadNext v1.0.0 - Production Release`).
   - **Release Changelog**: Enter release notes or summary of changes.
   - **Draft / Pre-release**: Check if you want a draft to review first.
   - **Platform Checkboxes**: Select which platforms to compile and attach:
     - ☑️ Include Windows (`.exe` installer & portable `.zip`)
     - ☑️ Include Linux (`.deb` package & portable `.tar.gz`)
     - ☑️ Include macOS (`.dmg` disk image & `.zip`)
     - ☑️ Include Android (`.apk`)
     - ☑️ Include iOS (`.ipa`)
6. Click **"Run workflow"**.
7. Once the jobs finish, navigate to the **Releases** page of your repository.
8. Your release is now live with all chosen platform installers attached and ready for users to download!
