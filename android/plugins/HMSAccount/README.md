# HMS Account Plugin for Godot 4 (Huawei ID Sign-In)

This directory contains the Godot 4 Android Plugin bridge for **Huawei Mobile Services (HMS) Account Kit**.

## Architecture Overview
- **GDScript Singleton**: `res://scripts/hms_account_manager.gd` (Autoload `HMSAccountManager`).
- **Android Plugin Class**: `com.godot.game.hms.HMSAccountPlugin` (extends `org.godotengine.godot.plugin.GodotPlugin`).
- **Plugin Descriptor**: `HMSAccountPlugin.gdap`.

## AppGallery Connect (AGC) Setup
1. Open the [HUAWEI Developer Console / AppGallery Connect](https://developer.huawei.com/consumer/en/service/josp/agc/index.html).
2. Create/Select the project matching package name `com.aismandils.hangtuahredemtionV2`.
3. Under **Project Settings -> Manage APIs**, ensure **Account Kit** is switched **ON**.
4. Under **General Information**, add your debug / release keystore **SHA-256 certificate fingerprint**:
   ```bash
   keytool -list -v -keystore <your_keystore_file>.keystore
   ```
5. Download `agconnect-services.json` and place it in your Godot Android build template (`android/build/`).

## How to Build the `.aar`
Compile `HMSAccountPlugin.java` with Godot Android library dependencies:
```bash
./gradlew assembleRelease
```
Copy the compiled `HMSAccountPlugin-release.aar` into `android/plugins/HMSAccount/HMSAccountPlugin.aar`.
When exporting Android APK from Godot, ensure **Use Gradle Build** is enabled in `export_presets.cfg`.
