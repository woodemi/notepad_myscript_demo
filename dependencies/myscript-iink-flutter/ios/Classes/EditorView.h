#import <Flutter/Flutter.h>

extern NSString *const kEditorView;

@class DisplayView;

@interface EditorView : NSObject<FlutterPlatformView>

@property (nonatomic, strong) DisplayView *displayView;
+ (instancetype)initWithMessenger:(NSObject <FlutterBinaryMessenger> *)messenger viewIdentifier:(int64_t)viewId;

@end
