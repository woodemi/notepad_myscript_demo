#import <Flutter/Flutter.h>
#import <iink/IINKIRenderTarget.h>

extern NSString *const kEditorController;

@interface EditorController : NSObject

- (void)initMethodChannelWidthMessenger:(NSObject <FlutterBinaryMessenger> *)messenger channelName:(NSString *)channelName;
- (void)close;

@end
