# Flutter app with watchOS

Showcase of building a cross-platform Flutter appplication with a native watchOS application.

Flutter communicates natively with iOS part of mobile application. The native iOS part of mobile application uses 'WatchConnectivity' to then further communicate with watchOS.

## Possible errors

— If you get an error after running flutter pub get, on `GeneratedPluginRegistrant.register(with: self)` it is because of XCode, the app should build successfully!

— You need to be logged in with your apple id in XCode. You need to go to settings on the device, general, profiles and devices, and trust your app.

— If there are some errors still, do:
	Delete /flutter/bin/cache/artifacts directory and run flutter doctor in terminal

- If app won't run beacuse the target is not iphoneos, check your build SDK and deployment targets in Xcode for watch and watch extension in build settings (they both need to be watchOS), and also add the bundle ID of your companion app in the watch extension info.plist file (unless it gets fixed by Fllutter side by now):
	https://github.com/flutter/flutter/issues/99031
