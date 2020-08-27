#import <Flutter/Flutter.h>
#import <iink/IINK.h>

@class IInkViewFactory;

extern NSString *const kPackageName;
extern IINKEngine *engine;
extern IInkViewFactory *iInkViewFactory;

@interface MyscriptIinkPlugin : NSObject<FlutterPlugin>
+ (void)initWithCertificate:(nonnull NSData *)certificate;
@end
