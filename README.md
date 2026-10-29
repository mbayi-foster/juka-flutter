# juka

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Release build (Android signing)

Release builds read their signing credentials from `android/key.properties`, which is
git-ignored. Fill in the alias and passwords before shipping:

```properties
storeFile=../juka.jks
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=<key alias>
```

`storeFile` is resolved relative to `android/app/`, so `../juka.jks` points to `android/juka.jks`.
Keep the keystore and this file out of version control. While the passwords/alias are blank,
release builds fall back to the debug keystore so `flutter run --release` still works.

Then build with:

```sh
flutter build apk --release
# or
flutter build appbundle --release
```

