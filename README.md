# Flutter app with watchOS

Flutter communicates natively with iOS part of mobile application. The native iOS part of mobile applicastion uses 'WatchConnectivity' to then further communicate with watchOS.

##Possible errors

— After running flutter pub get, on `GeneratedPluginRegistrant.register(with: self)` it is because of XCode, the app should build successfully!

— You need to be logged in with your apple id in XCode. You need to go to settings on the device, general, profiles and devices, and trust your app.

— If there are some errors still, do:
	Delete /flutter/bin/cache/artifacts directory and run flutter doctor in terminal

- If app wont run bcs target is not iphoneos or smth like that, check your build SDK and deployment targets in Xcode for watch and watch extension (they both need to be watchOS), and also add this (unless it gets fixed by flutter side by now):
	https://github.com/flutter/flutter/issues/99031
