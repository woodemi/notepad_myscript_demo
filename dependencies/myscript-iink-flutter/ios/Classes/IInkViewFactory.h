#import <Flutter/Flutter.h>

@interface IInkViewFactory : NSObject<FlutterPlatformViewFactory>

+ (id)initWithMessenger:(NSObject <FlutterBinaryMessenger> *)messenger;

- (NSObject <FlutterPlatformView> *)findViewById:(int64_t)viewId;

- (void)releaseViewById:(int64_t)viewId;
@end