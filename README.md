# AgoraPIPAndSystemScreenShareIOS

# Purpose
This demo show cases the usage of Agora with PIP and ScreenShare working together on iOS.

# Usage
In order to use this with cocoapods please do the following.

1) Have xcode 14.x installed,(later versions of xcode may break the repo if so open an issue) and have cocoapods 1.11.3 installed
2) Download the repo and run "pod install"
3) Open the works space
4) The config files will be missing borth for the app and the extension, so first add the files via `touch`.
*  `touch PIPScreenShareExtension/Config.xcconfig`
*  `touch AgoraPIPAndSystemScreenShare/Config.xcconfig`

5) Then add the following to the newly recreated files.
```
//
//  Config.xcconfig
//  AgoraPIPAndSystemScreenShare
//
//  Created by shaun on 1/11/23.
//

// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974

AGORA_APP_ID=<your id from the agora console no quotes>

```

```
//
//  Config.xcconfig
//  PIPScreenShareExtension
//
//  Created by shaun on 1/11/23.
//

// Configuration settings file format documentation can be found at:
// https://help.apple.com/xcode/#/dev745c5c974

AGORA_APP_ID=<your id from the agora console no quotes>

```
