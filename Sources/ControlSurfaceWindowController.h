#import <Cocoa/Cocoa.h>

@class ATEMController;

NS_ASSUME_NONNULL_BEGIN

@interface ControlSurfaceWindowController : NSWindowController
- (instancetype)initWithControllers:(NSArray<ATEMController *> *)controllers;
- (void)scrollMultiviewIntoView;
- (instancetype)initWithWindow:(nullable NSWindow *)window NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
