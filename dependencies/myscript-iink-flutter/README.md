# myscript_iink

A new flutter plugin project.

## Installation：
### Copy `myscript-iink-flutter` into project
### From Subtree
git subtree add --squash --prefix=myscript-iink-flutter git@gitlab.com:woodemi/myscript-iink-flutter.git develop
### From CocoaPods (暂不支持)
pod myscript-iink-flutter

### Import MyCertificate
Copy the MYSCRIPT certificate to the project

## iOS-Swift
####（1）配置Runner-Bridging-Header.h，增加内容如下：
```
#import <myscript_iink/MyscriptIinkPlugin.h>
#import "MyCertificate.h"
```
####（2）配置AppDelegate
```
MyscriptIinkPlugin.saveCertificate(Data(bytes: myCertificate.bytes, count: myCertificate.length))
GeneratedPluginRegistrant.register(with: self)
```
## iOS-ObjectC
####（1）导入SDK库
```
#import <myscript_iink/MyscriptIinkPlugin.h>
#import "MyCertificate.h"
```
####（2）配置AppDelegate
```
[MyscriptIinkPlugin saveCertificate: NSData dataWithBytes:myCertificate_BYTES length:sizeof(myCertificate_BYTES)]];
[GeneratedPluginRegistrant registerWithRegistry:self];
```
## Android-kotlin
####（1）导入SDK库
####（2）配置MainActivity.kt
```
MyscriptIinkPlugin.saveCertificate(this, MyCertificate.getBytes())
GeneratedPluginRegistrant.registerWith(this)
```

# Init MyCertificate
## MyscriptIink.initMyscript();

# Use Myscript

## 'setEngineConfiguration_Language'
MyscriptIink.setEngineConfiguration_Language('zh_CN');

## 'setPenStyle'
## 'getPenStyle'
## 'exportText'
## 'exportPNG'
## 'exportJPG'
## 'exportJIIX'
...
