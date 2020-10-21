# myscript_iink

A new flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.


# Installation：
## From Subtree
git subtree add --squash --prefix=myscript-iink-flutter git@gitlab.com:woodemi/myscript-iink-flutter.git develop
## From CocoaPods (暂不支持)
pod myscript-iink-flutter

# Import MyCertificate
Copy the MYSCRIPT certificate to the project

# iOS-Swift
####（1）配置Runner-Bridging-Header.h，增加内容如下：
```
#import <myscript_iink/MyscriptIinkPlugin.h>
#import "MyCertificate.h"
```
####（2）配置AppDelegate
```
MyscriptIinkPlugin.initWithCertificate(Data(bytes: myCertificate.bytes, count: myCertificate.length))
GeneratedPluginRegistrant.register(with: self)
```
# iOS-ObjectC
####（1）导入SDK库
```
#import <myscript_iink/MyscriptIinkPlugin.h>
#import "MyCertificate.h"
```
####（2）配置AppDelegate
```
[MyscriptIinkPlugin initWithCertificate: NSData dataWithBytes:myCertificate_BYTES length:sizeof(myCertificate_BYTES)]];
[GeneratedPluginRegistrant registerWithRegistry:self];
```
# Android-kotlin
####（1）导入SDK库
####（2）配置MainActivity.kt
```
MyscriptIinkPlugin.initWithCertificate(this, MyCertificate.getBytes())
GeneratedPluginRegistrant.registerWith(this)
```

