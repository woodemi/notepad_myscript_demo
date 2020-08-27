#import <Flutter/Flutter.h>
#import "MyscriptIinkPlugin.h"
#import "IInkViewFactory.h"
#import "EditorController.h"

NSString *const kPackageName = @"myscript_iink";
IINKEngine *engine;
IInkViewFactory *iInkViewFactory;

@implementation MyscriptIinkPlugin

static NSObject<FlutterPluginRegistrar> *iink_registrar;
static NSMutableDictionary *iink_controllers;

+ (void)initWithCertificate:(nonnull NSData *)certificate {
    engine = [[IINKEngine alloc] initWithCertificate:certificate];
    if (engine == nil) {
        NSLog(@"Invalid certificate");
        //  TODO   engine初始化失败，需增加重新初始化机制
        return;
    }
    
    // Configure the iink runtime environment
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *configurationPath = [bundlePath stringByAppendingString:@"/recognition-assets/conf"];
    [engine.configuration setStringArray:@[configurationPath] forKey:@"configuration-manager.search-path" error:nil];
    [engine.configuration setBoolean:false forKey:@"text.guides.enable" error:nil];
    [engine.configuration setString:NSTemporaryDirectory() forKey:@"content-package.temp-folder" error:nil];
    [engine.configuration setBoolean:false forKey:@"gesture.enable" error:nil]; // 设置 智能手势
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    iink_registrar = registrar;
    iInkViewFactory = [IInkViewFactory initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:iInkViewFactory withId:@"iink_view"];
    
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:kPackageName binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:[MyscriptIinkPlugin new] channel:channel];
}

#pragma mark
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"createEditorControllerChannel" isEqualToString:call.method]) {
        NSDictionary * dictionary = call.arguments;
        NSString *channelName = dictionary[@"channelName"];
        [self createChannel:channelName];
        result(nil);
    } else if ([@"closeEditorControllerChannel" isEqualToString:call.method]) {
        NSDictionary * dictionary = call.arguments;
        NSString *channelName = dictionary[@"channelName"];
        [self createChannel:channelName];
        result(nil);
    } else if ([@"setEngineConfiguration_Language" isEqualToString:call.method]) {
        NSDictionary *dictionary = call.arguments;
        NSString *lang = dictionary[@"lang"];
        [engine.configuration setString:lang forKey:@"lang" error:nil];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (EditorController *)createChannel:(NSString *)channelName {
    if (!iink_controllers) {
        iink_controllers = [NSMutableDictionary dictionary];
    }
    if ([iink_controllers.allKeys containsObject:channelName]) {
        return [iink_controllers valueForKey:channelName];
    }
    
    EditorController *controller = [EditorController new];
    [controller initMethodChannelWidthMessenger:iink_registrar.messenger channelName:channelName];
    [iink_controllers setObject:controller forKey:channelName];
    return controller;
}

- (void)closeChannel:(NSString *)channelName {
    if (!iink_controllers) {
        return;
    }
    if ([iink_controllers.allKeys containsObject:channelName]) {
        EditorController *controller = [iink_controllers valueForKey:channelName];
        [controller close];
        [iink_controllers removeObjectForKey:channelName];
    }
}
@end
