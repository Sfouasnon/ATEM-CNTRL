#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ATEMTransitionStyle) {
    ATEMTransitionStyleMix = 0,
    ATEMTransitionStyleDip = 1,
    ATEMTransitionStyleWipe = 2,
    ATEMTransitionStyleDVE = 3,
    ATEMTransitionStyleStinger = 4,
};

typedef NS_OPTIONS(NSUInteger, ATEMTransitionSelection) {
    ATEMTransitionSelectionBackground = 1 << 0,
    ATEMTransitionSelectionKey1 = 1 << 1,
    ATEMTransitionSelectionKey2 = 1 << 2,
    ATEMTransitionSelectionKey3 = 1 << 3,
    ATEMTransitionSelectionKey4 = 1 << 4,
};

typedef NS_OPTIONS(uint32_t, ATEMMultiviewLayout) {
    ATEMMultiviewLayoutProgramTop = 0x0C,
    ATEMMultiviewLayoutProgramBottom = 0x03,
    ATEMMultiviewLayoutProgramLeft = 0x0A,
    ATEMMultiviewLayoutProgramRight = 0x05,
    ATEMMultiviewLayoutTopLeftSmall = 0x01,
    ATEMMultiviewLayoutTopRightSmall = 0x02,
    ATEMMultiviewLayoutBottomLeftSmall = 0x04,
    ATEMMultiviewLayoutBottomRightSmall = 0x08,
};

@interface ATEMInputState : NSObject
@property(nonatomic, readonly) int64_t inputID;
@property(nonatomic, copy, readonly) NSString *longName;
@property(nonatomic, copy, readonly) NSString *shortName;
@property(nonatomic, readonly) uint32_t availabilityMask;
- (instancetype)initWithID:(int64_t)inputID
                  longName:(NSString *)longName
                 shortName:(NSString *)shortName
          availabilityMask:(uint32_t)availabilityMask NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface ATEMKeyState : NSObject
@property(nonatomic, readonly) NSUInteger index;
@property(nonatomic, readonly, getter=isOnAir) BOOL onAir;
- (instancetype)initWithIndex:(NSUInteger)index onAir:(BOOL)onAir NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface ATEMDownstreamKeyState : NSObject
@property(nonatomic, readonly) NSUInteger index;
@property(nonatomic, readonly, getter=isOnAir) BOOL onAir;
@property(nonatomic, readonly, getter=isTied) BOOL tied;
@property(nonatomic, readonly, getter=isTransitioning) BOOL transitioning;
@property(nonatomic, readonly) uint32_t framesRemaining;
- (instancetype)initWithIndex:(NSUInteger)index
                        onAir:(BOOL)onAir
                         tied:(BOOL)tied
                transitioning:(BOOL)transitioning
              framesRemaining:(uint32_t)framesRemaining NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface ATEMAuxState : NSObject
@property(nonatomic, readonly) NSUInteger index;
@property(nonatomic, copy, readonly) NSString *name;
@property(nonatomic, readonly) int64_t sourceID;
@property(nonatomic, readonly) uint32_t inputAvailabilityMask;
- (instancetype)initWithIndex:(NSUInteger)index
                         name:(NSString *)name
                     sourceID:(int64_t)sourceID
        inputAvailabilityMask:(uint32_t)inputAvailabilityMask NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface ATEMMultiviewWindowState : NSObject
@property(nonatomic, readonly) NSUInteger index;
@property(nonatomic, readonly) int64_t sourceID;
@property(nonatomic, readonly) BOOL supportsVUMeter;
@property(nonatomic, readonly, getter=isVUMeterEnabled) BOOL vuMeterEnabled;
@property(nonatomic, readonly) BOOL supportsSafeArea;
@property(nonatomic, readonly, getter=isSafeAreaEnabled) BOOL safeAreaEnabled;
@property(nonatomic, readonly) uint32_t safeAreaType;
@property(nonatomic, readonly) BOOL supportsLabelOverlay;
@property(nonatomic, readonly, getter=isLabelVisible) BOOL labelVisible;
@property(nonatomic, readonly, getter=isBorderVisible) BOOL borderVisible;
@end

@interface ATEMMultiviewState : NSObject
@property(nonatomic, readonly) NSUInteger index;
@property(nonatomic, readonly) ATEMMultiviewLayout layout;
@property(nonatomic, readonly) BOOL canChangeLayout;
@property(nonatomic, readonly) BOOL supportsQuadrantLayout;
@property(nonatomic, readonly) BOOL canRouteInputs;
@property(nonatomic, readonly) uint32_t inputAvailabilityMask;
@property(nonatomic, readonly) BOOL supportsVUMeters;
@property(nonatomic, readonly) BOOL canAdjustVUMeterOpacity;
@property(nonatomic, readonly) double vuMeterOpacity;
@property(nonatomic, readonly) BOOL canToggleSafeArea;
@property(nonatomic, readonly) uint32_t supportedSafeAreaTypes;
@property(nonatomic, readonly) BOOL supportsProgramPreviewSwap;
@property(nonatomic, readonly, getter=isProgramPreviewSwapped) BOOL programPreviewSwapped;
@property(nonatomic, readonly) BOOL canChangeOverlayProperties;
@property(nonatomic, copy, readonly) NSArray<ATEMMultiviewWindowState *> *windows;
@end

@interface ATEMState : NSObject
@property(nonatomic, readonly, getter=isConnected) BOOL connected;
@property(nonatomic, readonly, getter=isConnecting) BOOL connecting;
@property(nonatomic, readonly, getter=isDemo) BOOL demo;
@property(nonatomic, copy, readonly) NSString *productName;
@property(nonatomic, copy, readonly) NSString *statusMessage;
@property(nonatomic, copy, readonly) NSArray<ATEMInputState *> *inputs;
@property(nonatomic, readonly) uint32_t mixEffectInputAvailabilityMask;
@property(nonatomic, readonly) int64_t programInputID;
@property(nonatomic, readonly) int64_t previewInputID;
@property(nonatomic, readonly) double transitionPosition;
@property(nonatomic, readonly) uint32_t transitionFramesRemaining;
@property(nonatomic, readonly, getter=isInTransition) BOOL inTransition;
@property(nonatomic, readonly) ATEMTransitionStyle nextTransitionStyle;
@property(nonatomic, readonly) ATEMTransitionSelection nextTransitionSelection;
@property(nonatomic, readonly) uint32_t transitionRate;
@property(nonatomic, readonly, getter=isFadeToBlack) BOOL fadeToBlack;
@property(nonatomic, readonly, getter=isFadeToBlackTransitioning) BOOL fadeToBlackTransitioning;
@property(nonatomic, readonly) uint32_t fadeToBlackFramesRemaining;
@property(nonatomic, copy, readonly) NSArray<ATEMKeyState *> *upstreamKeys;
@property(nonatomic, copy, readonly) NSArray<ATEMDownstreamKeyState *> *downstreamKeys;
@property(nonatomic, copy, readonly) NSArray<ATEMAuxState *> *auxOutputs;
@property(nonatomic, copy, readonly) NSArray<ATEMMultiviewState *> *multiviews;
@end

@interface ATEMController : NSObject

@property(nonatomic, copy, nullable) void (^stateHandler)(ATEMState *state);
@property(nonatomic, readonly) ATEMState *latestState;

- (void)connectToAddress:(NSString *)address;
- (void)disconnect;
- (void)enterDemoMode;

- (void)setProgramInput:(int64_t)inputID;
- (void)setPreviewInput:(int64_t)inputID;
- (void)performCut;
- (void)performAutoTransition;
- (void)performFadeToBlack;
- (void)setTransitionPosition:(double)position;
- (void)setNextTransitionStyle:(ATEMTransitionStyle)style;
- (void)setNextTransitionSelection:(ATEMTransitionSelection)selection;
- (void)setTransitionRate:(uint32_t)frames;
- (void)setUpstreamKey:(NSUInteger)index onAir:(BOOL)onAir;
- (void)setDownstreamKey:(NSUInteger)index onAir:(BOOL)onAir;
- (void)setDownstreamKey:(NSUInteger)index tied:(BOOL)tied;
- (void)performDownstreamKeyAuto:(NSUInteger)index;
- (void)setAuxOutput:(NSUInteger)index source:(int64_t)sourceID;
- (void)setMultiview:(NSUInteger)index layout:(ATEMMultiviewLayout)layout;
- (void)setMultiview:(NSUInteger)index programPreviewSwapped:(BOOL)swapped;
- (void)setMultiview:(NSUInteger)index vuMeterOpacity:(double)opacity;
- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window source:(int64_t)sourceID;
- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window vuMeterEnabled:(BOOL)enabled;
- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window safeAreaEnabled:(BOOL)enabled;
- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window labelVisible:(BOOL)visible;
- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window borderVisible:(BOOL)visible;

- (void)shutdown;

+ (BOOL)isRuntimeInstalled;
+ (NSString *)runtimePath;

@end

FOUNDATION_EXPORT int ATEMRunSelfTest(void);
FOUNDATION_EXPORT int ATEMPrintDiagnostics(void);

NS_ASSUME_NONNULL_END
