#import "IInkViewFactory.h"
#import "EditorView.h"

@interface IInkViewFactory()

@property (nonatomic, strong)NSObject <FlutterBinaryMessenger> *messenger;
@property (nonatomic, strong)NSMutableDictionary <NSNumber *, NSObject <FlutterPlatformView> *> *platformViews;

@end

@implementation IInkViewFactory
+ (id)initWithMessenger:(NSObject <FlutterBinaryMessenger> *)messenger {
    IInkViewFactory *iInkViewFactory = [IInkViewFactory new];
    iInkViewFactory.messenger = messenger;
    return iInkViewFactory;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (NSMutableDictionary <NSNumber *, NSObject <FlutterPlatformView> *> *)platformViews {
    if (!_platformViews) {
        _platformViews = [NSMutableDictionary dictionary];
    }
    return _platformViews;
}

- (NSObject <FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    NSString *type = args[@"type"];
    if ([type isEqualToString: kEditorView]) {
        EditorView *view = [EditorView initWithMessenger:_messenger viewIdentifier:viewId];
        self.platformViews[@(viewId)] = view;
        return view;
    }
    return nil;
}

- (NSObject <FlutterPlatformView> *)findViewById:(int64_t)viewId {
    return self.platformViews[@(viewId)];
}

- (void)releaseViewById:(int64_t)viewId {
    [self.platformViews removeObjectForKey:@(viewId)];
}
@end
