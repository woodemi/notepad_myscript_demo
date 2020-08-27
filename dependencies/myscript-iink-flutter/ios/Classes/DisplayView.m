// Copyright MyScript. All right reserved.

#import "DisplayView.h"
#import "RenderView.h"
#import <iink/IINKRenderer.h>

@interface DisplayView ()

@property (strong, nonatomic) RenderView *backgroundRenderView;
@property (strong, nonatomic) RenderView *modelRenderView;
@property (strong, nonatomic) RenderView *tempRenderView;
@property (strong, nonatomic) RenderView *captureRenderView;

@property (nonatomic) BOOL didSetConstraints;
@end

@implementation DisplayView

#pragma mark - init
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self loadView];
        [self configView];
        [self initViewConstraints];
    }
    return self;
}

- (void)loadView{
    self.backgroundColor = [UIColor clearColor];
  
    self.backgroundRenderView = [[RenderView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.backgroundRenderView];
    self.backgroundRenderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundRenderView.backgroundColor = self.backgroundColor;
    
    self.modelRenderView = [[RenderView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.modelRenderView];
    self.modelRenderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.modelRenderView.backgroundColor = [UIColor clearColor];
    self.tempRenderView.opaque = NO;
    
    self.tempRenderView = [[RenderView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.tempRenderView];
    self.tempRenderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tempRenderView.backgroundColor = [UIColor clearColor];
    self.tempRenderView.opaque = NO;
    
    self.captureRenderView = [[RenderView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.captureRenderView];
    self.captureRenderView.translatesAutoresizingMaskIntoConstraints = NO;
    self.captureRenderView.backgroundColor = [UIColor clearColor];
    self.captureRenderView.opaque = NO;
}

- (void)configView {
    self.backgroundRenderView.layerType = IINKLayerTypeBackground;
    self.modelRenderView.layerType = IINKLayerTypeModel;
    self.tempRenderView.layerType = IINKLayerTypeTemporary;
    self.captureRenderView.layerType = IINKLayerTypeCapture;
}

#pragma mark - RenderTargetDelegate
- (void)invalidate:(nonnull IINKRenderer *)renderer layers:(IINKLayerType)layers {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((layers & IINKLayerTypeBackground) == IINKLayerTypeBackground) {
            if (self.backgroundRenderView.renderer == nil) {
                self.backgroundRenderView.renderer = renderer;
            }
            [self.backgroundRenderView setNeedsDisplay];
        }
        if ((layers & IINKLayerTypeModel) == IINKLayerTypeModel) {
            if (self.modelRenderView.renderer == nil) {
                self.modelRenderView.renderer = renderer;
            }
            [self.modelRenderView setNeedsDisplay];
        }
        if ((layers & IINKLayerTypeTemporary) == IINKLayerTypeTemporary) {
            if (self.tempRenderView.renderer == nil) {
                self.tempRenderView.renderer = renderer;
            }
            [self.tempRenderView setNeedsDisplay];
        }
        if ((layers & IINKLayerTypeCapture) == IINKLayerTypeCapture) {
            if (self.captureRenderView.renderer == nil) {
                self.captureRenderView.renderer = renderer;
            }
            [self.captureRenderView setNeedsDisplay];
        }
    });
}

- (void)invalidate:(nonnull IINKRenderer *)renderer area:(CGRect)rect layers:(IINKLayerType)layers {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((layers & IINKLayerTypeBackground) == IINKLayerTypeBackground) {
            if (self.backgroundRenderView.renderer == nil) {
              self.backgroundRenderView.renderer = renderer;
            }
            [self.backgroundRenderView setNeedsDisplayInRect:rect];
        }
        if ((layers & IINKLayerTypeModel) == IINKLayerTypeModel) {
            if (self.modelRenderView.renderer == nil) {
                self.modelRenderView.renderer = renderer;
            }
            [self.modelRenderView setNeedsDisplayInRect:rect];
        }
        if ((layers & IINKLayerTypeTemporary) == IINKLayerTypeTemporary) {
            if (self.tempRenderView.renderer == nil) {
                self.tempRenderView.renderer = renderer;
            }
            [self.tempRenderView setNeedsDisplayInRect:rect];
        }
        if ((layers & IINKLayerTypeCapture) == IINKLayerTypeCapture) {
            if (self.captureRenderView.renderer == nil) {
                self.captureRenderView.renderer = renderer;
            }
            [self.captureRenderView setNeedsDisplayInRect:rect];
        }
    });
}

#pragma mark - Constraints
- (void)initViewConstraints {
    if (!self.didSetConstraints) {
        self.didSetConstraints = YES;
        
        NSDictionary *views = @{@"backgroundRenderView" : self.backgroundRenderView, @"modelRenderView" : self.modelRenderView, @"tempRenderView" : self.tempRenderView, @"captureRenderView" : self.captureRenderView};
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[backgroundRenderView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundRenderView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[modelRenderView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[modelRenderView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tempRenderView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tempRenderView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[captureRenderView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[captureRenderView]|" options:0 metrics:nil views:views]];
    }
}

@end
