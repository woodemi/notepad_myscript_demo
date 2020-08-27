#import "EditorController.h"
#import "MyscriptIinkPlugin.h"
#import "ReferenceImplementation/FontMetricsProvider.h"
#import "DisplayView.h"
#import "EditorView.h"
#import "IInkViewFactory.h"
#import "Canvas.h"
#import <MobileCoreServices/MobileCoreServices.h>

NSString *const kEditorController = @"editor_controller";

IINKPointerType parsePointerType(NSString *string) {
    if ([string isEqualToString:@"pen"]) {
        return IINKPointerTypePen;
    } else if ([string isEqualToString:@"touch"]) {
        return IINKPointerTypeTouch;
    } else if ([string isEqualToString:@"eraser"]) {
        return IINKPointerTypeEraser;
    }
    return IINKPointerTypePen;
}

IINKPointerEventType parseEventType(NSString *eventType) {
    if ([eventType isEqualToString:@"down"]) {
        return IINKPointerEventTypeDown;
    } else if ([eventType isEqualToString:@"move"]) {
        return IINKPointerEventTypeMove;
    } else if ([eventType isEqualToString:@"up"]) {
        return IINKPointerEventTypeUp;
    }
    return IINKPointerEventTypeCancel;
}

@interface EditorController () <IINKIRenderTarget>

@property(nonatomic, strong) IINKEditor *editor;
@property(nonatomic, strong) DisplayView *renderTarget;

@end

@implementation EditorController

- (void)initMethodChannelWidthMessenger:(NSObject <FlutterBinaryMessenger> *)messenger channelName:(NSString *)channelName {
    FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
    __weak typeof(self) weakSelf = self;
    [methodChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
        [weakSelf handleMethodCall:call result:result];
    }];
}

- (void)close {
    [self.editor waitForIdle];
    [self.editor.part.package saveWithError:nil];
    [self.editor.renderer setDelegate:nil];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSLog(@"handleMethodCall method = %@", call.method);
    NSDictionary *arguments = call.arguments;
    if ([@"initRenderEditor" isEqualToString:call.method]) {
        NSNumber *viewScale = arguments[@"viewScale"];
        NSNumber *DpiX = arguments[@"DpiX"];
        NSNumber *DpiY = arguments[@"DpiY"];
        [self initRenderEditorWithDpiX:DpiX.floatValue WithDpiY:DpiY.floatValue];
        self.editor.renderer.viewScale = viewScale.doubleValue;
        result(nil);
    } else if ([@"createPackage" isEqualToString:call.method]) {
        IINKContentPackage *contentPackage = [engine createPackage:arguments[@"path"] error:nil];
        self.editor.part = [contentPackage createPart:@"Text" error:nil];
        IINKLayerType layers = IINKLayerTypeBackground | IINKLayerTypeTemporary |IINKLayerTypeCapture | IINKLayerTypeModel;
        [self.renderTarget invalidate:self.editor.renderer layers:layers];
        result(nil);
    } else if ([@"openPackage" isEqualToString:call.method]) {
        IINKContentPackage *contentPackage = [engine openPackage:arguments[@"path"] error:nil];
        self.editor.part = [contentPackage getPartAt:0 error:nil];
        IINKLayerType layers = IINKLayerTypeBackground | IINKLayerTypeTemporary |IINKLayerTypeCapture | IINKLayerTypeModel;
        [self.renderTarget invalidate:self.editor.renderer layers:layers];
        result(nil);
    } else if ([@"bindPlatformView" isEqualToString:call.method]) {
        NSNumber *viewId = arguments[@"id"];
        EditorView *editorView = (EditorView *)[iInkViewFactory findViewById: [viewId integerValue]];
        self.renderTarget = editorView.displayView;
        IINKLayerType layers = IINKLayerTypeBackground | IINKLayerTypeTemporary |IINKLayerTypeCapture | IINKLayerTypeModel;
        [self.renderTarget invalidate:self.editor.renderer layers:layers];
        result(nil);
    } else if ([@"unbindPlatformView" isEqualToString:call.method]) {
        NSNumber *viewId = arguments[@"id"];
        [iInkViewFactory releaseViewById: [viewId integerValue]];
        self.renderTarget = nil;
        result(nil);
    } else if ([@"setPenStyle" isEqualToString:call.method]) {
        NSDictionary *dictionary = call.arguments;
        self.editor.penStyle = dictionary[@"penStyle"];
        result(nil);
    } else if ([@"getPenStyle" isEqualToString:call.method]) {
        result(self.editor.penStyle);
    } else if ([@"syncPointerEvent" isEqualToString:call.method]) {
        NSDictionary *dictionary = call.arguments;
        [self handleSyncPointerEvent:dictionary];
        result(nil);
    } else if ([@"syncPointerEvents" isEqualToString:call.method]) {
        [self handleSyncPointerEvents:call.arguments];
        result(nil);
    } else if ([@"exportText" isEqualToString:call.method]) {
        [[self.editor.part package] saveWithError:nil];
        NSError *error;
        NSString * convert = [self.editor export_:nil mimeType:IINKMimeTypeText error:&error];
        if (!error) {
            result(convert);
        }else {
            result([FlutterError errorWithCode: [NSString stringWithFormat:@"%ld", error.code] message:error.localizedDescription details:nil]);
        }
    } else if ([@"exportJIIX" isEqualToString:call.method]) {
        dispatch_queue_t queue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [[self.editor.part package] saveWithError:nil];
            NSError *error;
            NSString *jsonStr = [self.editor export_:nil mimeType:IINKMimeTypeJIIX error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    result(jsonStr);
                }else {
                    result([FlutterError errorWithCode: [NSString stringWithFormat:@"%ld", error.code] message:error.localizedDescription details:nil]);
                }
            });
        });
    } else if ([@"exportPNG" isEqualToString:call.method]) {
        dispatch_queue_t queue=  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            NSNumber *deviceWidth_mm = call.arguments[@"DeviceWidth_mm"];
            FlutterStandardTypedData *skinImageData = call.arguments[@"skinBytes"];
            
            CGSize contentSize = [self contentImageSize:[deviceWidth_mm floatValue]];
            UIImage *pngImage = [self createaContentImage:self.editor.renderer drawFrame: CGRectMake(0, 0, contentSize.width, contentSize.height)];
            
            NSData *data = UIImagePNGRepresentation(pngImage);
            dispatch_async(dispatch_get_main_queue(), ^{
                result([FlutterStandardTypedData typedDataWithBytes:data]);
            });
        });
    } else if ([@"exportJPG" isEqualToString:call.method]) {
        dispatch_queue_t queue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            UIImage *fullImage = [self createFullImage:call.arguments];
            NSData *data = UIImageJPEGRepresentation(fullImage, 0.5);
            dispatch_async(dispatch_get_main_queue(), ^{
                result([FlutterStandardTypedData typedDataWithBytes:data]);
            });
        });
    } else if ([@"exportGIF" isEqualToString:call.method]) {
        dispatch_queue_t queue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            NSString *gifPath = call.arguments[@"gifPath"];
            NSArray *images = [self createGifImages:call.arguments];
            NSString *gifFilePath = [self createGifImages:images delays:nil loopCount:0 gifPath: gifPath];
            dispatch_async(dispatch_get_main_queue(), ^{
                result(gifFilePath);
            });
        });
    } else if ([@"clear" isEqualToString:call.method]) {
        dispatch_queue_t queue= dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [self.editor clear];
            IINKContentPackage *package = [self.editor.part package];
            [package removePart:self.editor.part error:nil];
            [package createPart:@"Text" error:nil];
            self.editor.part = [package getPartAt:0 error:nil];
            [[self.editor.part package] saveWithError:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                result(nil);
            });
        });
    } else if ([@"canUndo" isEqualToString:call.method]) {
        result(@([self.editor canUndo]));
    } else if ([@"undo" isEqualToString:call.method]) {
        if ([self.editor canUndo]) {
            [self.editor undo];
        }
        result(@([self.editor canUndo]));
    } else if ([@"canRedo" isEqualToString:call.method]) {
        result(@([self.editor canRedo]));
    } else if ([@"redo" isEqualToString:call.method]) {
        if ([self.editor canRedo]) {
            [self.editor redo];
        }
        result(@([self.editor canRedo]));
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initRenderEditorWithDpiX:(float)dpiX WithDpiY:(float)dpiY {
    IINKRenderer *renderer = [engine createRendererWithDpiX:dpiX dpiY:dpiY target:self error:nil];

    self.editor = [engine createEditor:renderer];
    [self.editor setFontMetricsProvider:[FontMetricsProvider new]];
}

- (void)handleSyncPointerEvent: (NSDictionary *)dictionary {
    NSString *eventType = dictionary[@"eventType"];
    float x = ((NSNumber *) dictionary[@"x"]).floatValue;
    float y = ((NSNumber *) dictionary[@"y"]).floatValue;
    long t = ((NSNumber *) dictionary[@"t"]).longValue;
    float f = ((NSNumber *) dictionary[@"f"]).floatValue;
    IINKPointerType pointerType = parsePointerType((NSString *) dictionary[@"pointerType"]);
    NSInteger pointerId = ((NSNumber *) dictionary[@"pointerId"]).integerValue;

    CGPoint point = CGPointMake(x, y);
    if ([eventType isEqualToString:@"down"]) {
        [self.editor pointerDown:point at:t force:f type:pointerType pointerId:pointerId error:nil];
    } else if ([eventType isEqualToString:@"move"]) {
        [self.editor pointerMove:point at:t force:f type:pointerType pointerId:pointerId error:nil];
    } else if ([eventType isEqualToString:@"up"]) {
        [self.editor pointerUp:point at:t force:f type:pointerType pointerId:pointerId error:nil];
        [self.editor.part.package saveWithError:nil];
    } else if ([eventType isEqualToString:@"cancel"]) {
        [self.editor pointerCancel:pointerId error:nil];
    }
}

- (void)handleSyncPointerEvents:(NSArray *)array {
    NSUInteger count = array.count;
    size_t size = sizeof(IINKPointerEvent);
    IINKPointerEvent *events = malloc(count * size);

    for (NSUInteger i = 0; i < array.count; i++) {
        IINKPointerEvent *pointer = events + i;
        pointer->eventType = parseEventType((NSString *) array[i][@"eventType"]);
        pointer->x = ((NSNumber *) array[i][@"x"]).floatValue;
        pointer->y = ((NSNumber *) array[i][@"y"]).floatValue;
        pointer->t = ((NSNumber *) array[i][@"t"]).longValue;
        pointer->f = ((NSNumber *) array[i][@"f"]).floatValue;
        pointer->pointerType = parsePointerType(((NSString *) array[i][@"pointerType"]));
        pointer->pointerId = ((NSString *) array[i][@"pointerId"]).intValue;
    }
    [self.editor pointerEvents:events count:count doProcessGestures:NO error:nil];
    [self.editor.part.package saveWithError:nil];

    free(events);
}

#pragma Mark 图像部分
//  内容图-frame
- (CGSize)contentImageSize: (CGFloat)deviceWidth_mm {
    CGRect mainFrame = [[UIScreen mainScreen] bounds];
    // 暂定为3.0
    CGFloat PhysicalScreenRatio = 3.0;
    return CGSizeMake(mainFrame.size.width * PhysicalScreenRatio, mainFrame.size.width * PhysicalScreenRatio * (21000.0 / 15800.0));
}

//  内容图
- (UIImage *)createaContentImage:(IINKRenderer *)renderer drawFrame:(CGRect)frame {
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, [UIScreen mainScreen].scale);
    [renderer drawBackground:frame canvas: [Canvas new]];
    [renderer drawModel:frame canvas: [Canvas new]];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

//  合并：skin + 内容图
-(UIImage *)createaImageWithSkin:(UIImage *)skinImage skinArea:(CGRect)skinArea contentImage:(UIImage *)contentImage contentArea:(CGRect)contentArea {
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(skinArea.size, NO, [UIScreen mainScreen].scale);
    [skinImage drawInRect:skinArea];
    [contentImage drawInRect:contentArea];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// 完整图·部分
- (UIImage *)createFullImage:(NSDictionary *)dictionary {
    NSNumber *deviceWidth_mm = dictionary[@"DeviceWidth_mm"];
    NSNumber *editArea_xOffsetScale = dictionary[@"EditArea_xOffsetScale"];
    FlutterStandardTypedData *skinImageData = dictionary[@"skinBytes"];
    UIImage *skinImage = [UIImage imageWithData:skinImageData.data];
    
    CGSize contentSize = [self contentImageSize:[deviceWidth_mm floatValue]];
    UIImage *contentImage = [self createaContentImage:self.editor.renderer drawFrame: CGRectMake(0, 0, contentSize.width, contentSize.height)];
    
    CGRect mainFrame = [[UIScreen mainScreen] bounds];
    CGRect skinArea = CGRectMake(0, 0, mainFrame.size.width, mainFrame.size.width * (21000.0 / 15800.0));
    CGFloat editArea_xOffset = skinArea.size.width * [editArea_xOffsetScale floatValue];
    CGRect contentArea = CGRectMake(0, editArea_xOffset, skinArea.size.width - editArea_xOffset, skinArea.size.height);
    UIImage *fullImage = [self createaImageWithSkin:skinImage skinArea:skinArea contentImage:contentImage contentArea:contentArea];
    return fullImage;
}

#pragma Mark gif·部分
- (NSArray<UIImage *>*)createGifImages:(NSDictionary *)dictionary {
    NSArray *arr = dictionary[@"parts"];
    NSMutableArray *mArr = [NSMutableArray array];
    for (int i = 0; i < [arr count]; i++) {
        @autoreleasepool {
            [self handleSyncPointerEvents:arr[i]];
            [self.editor.part.package saveWithError:nil];
            UIImage *gifImg = [self createFullImage:dictionary];
            [mArr addObject:gifImg];
        }
    }
    return [mArr copy];
}

//  根据“图片数组”生成gif
- (NSString *)createGifImages:(NSArray *)images delays:(NSArray *)delays loopCount:(NSUInteger)loopCount gifPath:(NSString *)gifPath{
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:gifPath],
                                                                        kUTTypeGIF, images.count, NULL);
    if(!loopCount) {
        loopCount = 0;
    }
    NSDictionary *gifProperties = @{ (__bridge id)kCGImagePropertyGIFDictionary: @{
                                             (__bridge id)kCGImagePropertyGIFLoopCount: @(loopCount), // 0 means loop forever
                                             }
                                     };
    float delay = 0.1; //默认每一帧间隔0.1秒
    for (int i=0; i<images.count; i++) {
        UIImage *itemImage = images[i];
        if(delays && i<delays.count){
            delay = [delays[i] floatValue];
        }
        //每一帧对应的延迟时间
        NSDictionary *frameProperties = @{(__bridge id)kCGImagePropertyGIFDictionary: @{
                                                  (__bridge id)kCGImagePropertyGIFDelayTime: @(delay), // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                                                  }
                                          };
        CGImageDestinationAddImage(destination,itemImage.CGImage, (__bridge CFDictionaryRef)frameProperties);
    }
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    return gifPath;
}

#pragma mark - RenderTargetDelegate
- (void)invalidate:(nonnull IINKRenderer *)renderer area:(CGRect)area layers:(IINKLayerType)layers {
    [self.renderTarget invalidate:renderer area:area layers:layers];
}

- (void)invalidate:(nonnull IINKRenderer *)renderer layers:(IINKLayerType)layers {
    [self.renderTarget invalidate:renderer layers:layers];
}

@end
