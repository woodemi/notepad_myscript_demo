#import "EditorView.h"
#import "MyscriptIinkPlugin.h"
#import "DisplayView.h"

NSString *const kEditorView = @"editor_view";

@implementation EditorView
+ (instancetype)initWithMessenger:(NSObject <FlutterBinaryMessenger> *)messenger viewIdentifier:(int64_t)viewId {
    return [EditorView new];
}

- (UIView *)view {
    return self.displayView;
}

- (DisplayView *)displayView {
    if (!_displayView) {
        _displayView = [[DisplayView alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
        [self addObserver:self forKeyPath:@"displayView.layer.bounds" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _displayView;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"view.layer.bounds"]) {
        // TODO
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"displayView.layer.bounds"];
}

@end
