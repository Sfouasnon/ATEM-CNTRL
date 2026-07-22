#import "ATEMController.h"

#import <Cocoa/Cocoa.h>
#import <atomic>
#import <cstring>
#import <vector>

#include "BMDSwitcherAPI.h"

static NSString *const kATEMRuntimePath = @"/Library/Application Support/Blackmagic Design/Switchers/BMDSwitcherAPI.bundle";


@interface ATEMInputState ()
@property(nonatomic, readwrite) int64_t inputID;
@property(nonatomic, copy, readwrite) NSString *longName;
@property(nonatomic, copy, readwrite) NSString *shortName;
@property(nonatomic, readwrite) uint32_t availabilityMask;
@end

@implementation ATEMInputState
- (instancetype)initWithID:(int64_t)inputID
                  longName:(NSString *)longName
                 shortName:(NSString *)shortName
          availabilityMask:(uint32_t)availabilityMask
{
    self = [super init];
    if (self) {
        _inputID = inputID;
        _longName = [longName copy];
        _shortName = [shortName copy];
        _availabilityMask = availabilityMask;
    }
    return self;
}
@end


@interface ATEMKeyState ()
@property(nonatomic, readwrite) NSUInteger index;
@property(nonatomic, readwrite, getter=isOnAir) BOOL onAir;
@end

@implementation ATEMKeyState
- (instancetype)initWithIndex:(NSUInteger)index onAir:(BOOL)onAir
{
    self = [super init];
    if (self) {
        _index = index;
        _onAir = onAir;
    }
    return self;
}
@end


@interface ATEMDownstreamKeyState ()
@property(nonatomic, readwrite) NSUInteger index;
@property(nonatomic, readwrite, getter=isOnAir) BOOL onAir;
@property(nonatomic, readwrite, getter=isTied) BOOL tied;
@property(nonatomic, readwrite, getter=isTransitioning) BOOL transitioning;
@property(nonatomic, readwrite) uint32_t framesRemaining;
@end

@implementation ATEMDownstreamKeyState
- (instancetype)initWithIndex:(NSUInteger)index
                        onAir:(BOOL)onAir
                         tied:(BOOL)tied
                transitioning:(BOOL)transitioning
              framesRemaining:(uint32_t)framesRemaining
{
    self = [super init];
    if (self) {
        _index = index;
        _onAir = onAir;
        _tied = tied;
        _transitioning = transitioning;
        _framesRemaining = framesRemaining;
    }
    return self;
}
@end


@interface ATEMAuxState ()
@property(nonatomic, readwrite) NSUInteger index;
@property(nonatomic, copy, readwrite) NSString *name;
@property(nonatomic, readwrite) int64_t sourceID;
@property(nonatomic, readwrite) uint32_t inputAvailabilityMask;
@end

@implementation ATEMAuxState
- (instancetype)initWithIndex:(NSUInteger)index
                         name:(NSString *)name
                     sourceID:(int64_t)sourceID
        inputAvailabilityMask:(uint32_t)inputAvailabilityMask
{
    self = [super init];
    if (self) {
        _index = index;
        _name = [name copy];
        _sourceID = sourceID;
        _inputAvailabilityMask = inputAvailabilityMask;
    }
    return self;
}
@end


@interface ATEMMultiviewWindowState ()
@property(nonatomic, readwrite) NSUInteger index;
@property(nonatomic, readwrite) int64_t sourceID;
@property(nonatomic, readwrite) BOOL supportsVUMeter;
@property(nonatomic, readwrite, getter=isVUMeterEnabled) BOOL vuMeterEnabled;
@property(nonatomic, readwrite) BOOL supportsSafeArea;
@property(nonatomic, readwrite, getter=isSafeAreaEnabled) BOOL safeAreaEnabled;
@property(nonatomic, readwrite) uint32_t safeAreaType;
@property(nonatomic, readwrite) BOOL supportsLabelOverlay;
@property(nonatomic, readwrite, getter=isLabelVisible) BOOL labelVisible;
@property(nonatomic, readwrite, getter=isBorderVisible) BOOL borderVisible;
@end

@implementation ATEMMultiviewWindowState
@end


@interface ATEMMultiviewState ()
@property(nonatomic, readwrite) NSUInteger index;
@property(nonatomic, readwrite) ATEMMultiviewLayout layout;
@property(nonatomic, readwrite) BOOL canChangeLayout;
@property(nonatomic, readwrite) BOOL supportsQuadrantLayout;
@property(nonatomic, readwrite) BOOL canRouteInputs;
@property(nonatomic, readwrite) uint32_t inputAvailabilityMask;
@property(nonatomic, readwrite) BOOL supportsVUMeters;
@property(nonatomic, readwrite) BOOL canAdjustVUMeterOpacity;
@property(nonatomic, readwrite) double vuMeterOpacity;
@property(nonatomic, readwrite) BOOL canToggleSafeArea;
@property(nonatomic, readwrite) uint32_t supportedSafeAreaTypes;
@property(nonatomic, readwrite) BOOL supportsProgramPreviewSwap;
@property(nonatomic, readwrite, getter=isProgramPreviewSwapped) BOOL programPreviewSwapped;
@property(nonatomic, readwrite) BOOL canChangeOverlayProperties;
@property(nonatomic, copy, readwrite) NSArray<ATEMMultiviewWindowState *> *windows;
@end

@implementation ATEMMultiviewState
@end


@interface ATEMState ()
@property(nonatomic, readwrite, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, getter=isConnecting) BOOL connecting;
@property(nonatomic, readwrite, getter=isDemo) BOOL demo;
@property(nonatomic, copy, readwrite) NSString *productName;
@property(nonatomic, copy, readwrite) NSString *statusMessage;
@property(nonatomic, copy, readwrite) NSArray<ATEMInputState *> *inputs;
@property(nonatomic, readwrite) uint32_t mixEffectInputAvailabilityMask;
@property(nonatomic, readwrite) int64_t programInputID;
@property(nonatomic, readwrite) int64_t previewInputID;
@property(nonatomic, readwrite) double transitionPosition;
@property(nonatomic, readwrite) uint32_t transitionFramesRemaining;
@property(nonatomic, readwrite, getter=isInTransition) BOOL inTransition;
@property(nonatomic, readwrite) ATEMTransitionStyle nextTransitionStyle;
@property(nonatomic, readwrite) ATEMTransitionSelection nextTransitionSelection;
@property(nonatomic, readwrite) uint32_t transitionRate;
@property(nonatomic, readwrite, getter=isFadeToBlack) BOOL fadeToBlack;
@property(nonatomic, readwrite, getter=isFadeToBlackTransitioning) BOOL fadeToBlackTransitioning;
@property(nonatomic, readwrite) uint32_t fadeToBlackFramesRemaining;
@property(nonatomic, copy, readwrite) NSArray<ATEMKeyState *> *upstreamKeys;
@property(nonatomic, copy, readwrite) NSArray<ATEMDownstreamKeyState *> *downstreamKeys;
@property(nonatomic, copy, readwrite) NSArray<ATEMAuxState *> *auxOutputs;
@property(nonatomic, copy, readwrite) NSArray<ATEMMultiviewState *> *multiviews;
@end

@implementation ATEMState
@end


@class ATEMController;

static bool InterfaceIDsEqual(const REFIID &left, const REFIID &right)
{
    return std::memcmp(&left, &right, sizeof(REFIID)) == 0;
}

static bool InterfaceIDEqualsUUID(const REFIID &left, CFUUIDRef right)
{
    CFUUIDBytes bytes = CFUUIDGetUUIDBytes(right);
    return InterfaceIDsEqual(left, bytes);
}


class SwitcherMonitor final : public IBMDSwitcherCallback
{
public:
    explicit SwitcherMonitor(ATEMController *owner) : owner_(owner), refCount_(1) {}

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, LPVOID *value) override;
    ULONG STDMETHODCALLTYPE AddRef(void) override { return ++refCount_; }
    ULONG STDMETHODCALLTYPE Release(void) override
    {
        ULONG count = --refCount_;
        if (count == 0)
            delete this;
        return count;
    }
    HRESULT STDMETHODCALLTYPE Notify(BMDSwitcherEventType eventType, BMDSwitcherVideoMode coreVideoMode) override;

private:
    __unsafe_unretained ATEMController *owner_;
    std::atomic<ULONG> refCount_;
};


class MixEffectBlockMonitor final : public IBMDSwitcherMixEffectBlockCallback
{
public:
    explicit MixEffectBlockMonitor(ATEMController *owner) : owner_(owner), refCount_(1) {}

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, LPVOID *value) override;
    ULONG STDMETHODCALLTYPE AddRef(void) override { return ++refCount_; }
    ULONG STDMETHODCALLTYPE Release(void) override
    {
        ULONG count = --refCount_;
        if (count == 0)
            delete this;
        return count;
    }
    HRESULT STDMETHODCALLTYPE Notify(BMDSwitcherMixEffectBlockEventType eventType) override;

private:
    __unsafe_unretained ATEMController *owner_;
    std::atomic<ULONG> refCount_;
};


struct AuxAPIRecord
{
    IBMDSwitcherInputAux *api = nullptr;
    __strong NSString *name = nil;
    uint32_t inputAvailabilityMask = 0;
};

struct DemoMultiview
{
    ATEMMultiviewLayout layout = ATEMMultiviewLayoutProgramTop;
    bool programPreviewSwapped = false;
    double vuMeterOpacity = 0.75;
    std::vector<int64_t> sources;
    std::vector<bool> vuMeters;
    std::vector<bool> safeAreas;
    std::vector<bool> labels;
    std::vector<bool> borders;
};


@interface ATEMController ()
{
    dispatch_queue_t _controlQueue;
    dispatch_source_t _pollTimer;
    BOOL _shutdown;

    IBMDSwitcherDiscovery *_discovery;
    IBMDSwitcher *_switcher;
    IBMDSwitcherMixEffectBlock *_mixEffectBlock;
    IBMDSwitcherTransitionParameters *_transitionParameters;
    IBMDSwitcherTransitionMixParameters *_mixParameters;
    IBMDSwitcherTransitionDipParameters *_dipParameters;
    IBMDSwitcherTransitionWipeParameters *_wipeParameters;
    IBMDSwitcherTransitionDVEParameters *_dveParameters;
    IBMDSwitcherTransitionStingerParameters *_stingerParameters;
    SwitcherMonitor *_switcherMonitor;
    MixEffectBlockMonitor *_mixEffectBlockMonitor;
    std::vector<IBMDSwitcherKey *> _upstreamKeyAPIs;
    std::vector<IBMDSwitcherDownstreamKey *> _downstreamKeyAPIs;
    std::vector<AuxAPIRecord> _auxAPIs;
    std::vector<IBMDSwitcherMultiView *> _multiviewAPIs;

    BOOL _connecting;
    BOOL _demo;
    NSString *_productName;
    NSString *_statusMessage;
    NSArray<ATEMInputState *> *_inputStates;
    uint32_t _mixEffectInputAvailabilityMask;

    int64_t _demoProgram;
    int64_t _demoPreview;
    double _demoTransitionPosition;
    BOOL _demoInTransition;
    ATEMTransitionStyle _demoStyle;
    ATEMTransitionSelection _demoSelection;
    uint32_t _demoRate;
    BOOL _demoFTB;
    std::vector<bool> _demoKeys;
    std::vector<bool> _demoDSKOnAir;
    std::vector<bool> _demoDSKTied;
    std::vector<int64_t> _demoAuxSources;
    std::vector<DemoMultiview> _demoMultiviews;
}

@property(nonatomic, strong, readwrite) ATEMState *latestState;

- (void)sdkStateChanged;
- (void)switcherDisconnectedByDevice;
- (void)publishStateLocked;
- (void)disconnectLockedWithMessage:(NSString *)message;
@end


HRESULT SwitcherMonitor::QueryInterface(REFIID iid, LPVOID *value)
{
    if (!value)
        return E_POINTER;
    if (InterfaceIDsEqual(iid, IID_IBMDSwitcherCallback)) {
        *value = static_cast<IBMDSwitcherCallback *>(this);
        AddRef();
        return S_OK;
    }
    if (InterfaceIDEqualsUUID(iid, IUnknownUUID)) {
        *value = static_cast<IUnknown *>(this);
        AddRef();
        return S_OK;
    }
    *value = nullptr;
    return E_NOINTERFACE;
}

HRESULT SwitcherMonitor::Notify(BMDSwitcherEventType eventType, BMDSwitcherVideoMode coreVideoMode)
{
    (void)coreVideoMode;
    if (eventType == bmdSwitcherEventTypeDisconnected)
        [owner_ switcherDisconnectedByDevice];
    else
        [owner_ sdkStateChanged];
    return S_OK;
}

HRESULT MixEffectBlockMonitor::QueryInterface(REFIID iid, LPVOID *value)
{
    if (!value)
        return E_POINTER;
    if (InterfaceIDsEqual(iid, IID_IBMDSwitcherMixEffectBlockCallback)) {
        *value = static_cast<IBMDSwitcherMixEffectBlockCallback *>(this);
        AddRef();
        return S_OK;
    }
    if (InterfaceIDEqualsUUID(iid, IUnknownUUID)) {
        *value = static_cast<IUnknown *>(this);
        AddRef();
        return S_OK;
    }
    *value = nullptr;
    return E_NOINTERFACE;
}

HRESULT MixEffectBlockMonitor::Notify(BMDSwitcherMixEffectBlockEventType eventType)
{
    (void)eventType;
    [owner_ sdkStateChanged];
    return S_OK;
}


static NSString *StringFromOwnedCFString(CFStringRef value)
{
    if (!value)
        return @"";
    NSString *result = [(__bridge NSString *)value copy];
    CFRelease(value);
    return result;
}

static ATEMTransitionStyle AppTransitionStyle(BMDSwitcherTransitionStyle style)
{
    switch (style) {
        case bmdSwitcherTransitionStyleDip: return ATEMTransitionStyleDip;
        case bmdSwitcherTransitionStyleWipe: return ATEMTransitionStyleWipe;
        case bmdSwitcherTransitionStyleDVE: return ATEMTransitionStyleDVE;
        case bmdSwitcherTransitionStyleStinger: return ATEMTransitionStyleStinger;
        case bmdSwitcherTransitionStyleMix:
        default: return ATEMTransitionStyleMix;
    }
}

static BMDSwitcherTransitionStyle SDKTransitionStyle(ATEMTransitionStyle style)
{
    switch (style) {
        case ATEMTransitionStyleDip: return bmdSwitcherTransitionStyleDip;
        case ATEMTransitionStyleWipe: return bmdSwitcherTransitionStyleWipe;
        case ATEMTransitionStyleDVE: return bmdSwitcherTransitionStyleDVE;
        case ATEMTransitionStyleStinger: return bmdSwitcherTransitionStyleStinger;
        case ATEMTransitionStyleMix:
        default: return bmdSwitcherTransitionStyleMix;
    }
}

static ATEMTransitionSelection AppTransitionSelection(BMDSwitcherTransitionSelection selection)
{
    return (ATEMTransitionSelection)(NSUInteger)selection;
}

static BMDSwitcherTransitionSelection SDKTransitionSelection(ATEMTransitionSelection selection)
{
    return (BMDSwitcherTransitionSelection)(NSUInteger)selection;
}

static NSUInteger ActiveQuadrantWindowCount(ATEMMultiviewLayout layout)
{
    uint32_t mask = (uint32_t)layout & 0x0FU;
    NSUInteger splitQuadrants = 0;
    while (mask != 0) {
        splitQuadrants += mask & 1U;
        mask >>= 1U;
    }
    return 4 + splitQuadrants * 3;
}

static NSString *ConnectionFailureMessage(BMDSwitcherConnectToFailure failure)
{
    switch (failure) {
        case bmdSwitcherConnectToFailureNoResponse:
            return @"No response from the switcher. Check its address and network connection.";
        case bmdSwitcherConnectToFailureIncompatibleFirmware:
            return @"The switcher firmware is incompatible with the installed ATEM runtime.";
        case bmdSwitcherConnectToFailureCorruptData:
            return @"The switcher returned corrupt connection data.";
        case bmdSwitcherConnectToFailureStateSync:
            return @"The switcher could not synchronize its state.";
        case bmdSwitcherConnectToFailureStateSyncTimedOut:
            return @"The switcher state synchronization timed out.";
        default:
            return @"The connection failed for an unknown reason.";
    }
}


@implementation ATEMController

- (instancetype)init
{
    self = [super init];
    if (!self)
        return nil;

    _controlQueue = dispatch_queue_create("com.local.atem-cntrl.control", DISPATCH_QUEUE_SERIAL);
    _switcherMonitor = new SwitcherMonitor(self);
    _mixEffectBlockMonitor = new MixEffectBlockMonitor(self);
    _productName = @"";
    _statusMessage = [ATEMController isRuntimeInstalled]
        ? @"Enter the switcher IP address to connect."
        : @"Blackmagic Switchers runtime not found. Install ATEM Software Control first.";
    _inputStates = @[];
    _demoRate = 25;
    _demoSelection = ATEMTransitionSelectionBackground;
    self.latestState = [self emptyStateWithMessage:_statusMessage];

    __weak ATEMController *weakSelf = self;
    dispatch_async(_controlQueue, ^{
        ATEMController *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        strongSelf->_discovery = CreateBMDSwitcherDiscoveryInstance();
        if (!strongSelf->_discovery)
            strongSelf->_statusMessage = @"Could not load BMDSwitcherAPI. Reinstall ATEM Software Control.";
        [strongSelf publishStateLocked];
    });

    _pollTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _controlQueue);
    dispatch_source_set_timer(_pollTimer,
                              dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC),
                              250 * NSEC_PER_MSEC,
                              75 * NSEC_PER_MSEC);
    dispatch_source_set_event_handler(_pollTimer, ^{
        ATEMController *strongSelf = weakSelf;
        if (strongSelf && (strongSelf->_switcher || strongSelf->_demo))
            [strongSelf publishStateLocked];
    });
    dispatch_resume(_pollTimer);

    return self;
}

- (ATEMState *)emptyStateWithMessage:(NSString *)message
{
    ATEMState *state = [[ATEMState alloc] init];
    state.productName = @"";
    state.statusMessage = message ?: @"";
    state.inputs = @[];
    state.mixEffectInputAvailabilityMask = 0;
    state.programInputID = -1;
    state.previewInputID = -1;
    state.nextTransitionStyle = ATEMTransitionStyleMix;
    state.nextTransitionSelection = ATEMTransitionSelectionBackground;
    state.transitionRate = 25;
    state.upstreamKeys = @[];
    state.downstreamKeys = @[];
    state.auxOutputs = @[];
    state.multiviews = @[];
    return state;
}

+ (NSString *)runtimePath
{
    return kATEMRuntimePath;
}

+ (BOOL)isRuntimeInstalled
{
    return [[NSFileManager defaultManager] fileExistsAtPath:kATEMRuntimePath];
}

- (void)connectToAddress:(NSString *)address
{
    NSString *trimmed = [address stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) {
        dispatch_async(_controlQueue, ^{
            self->_statusMessage = @"Enter a switcher IP address or host name.";
            [self publishStateLocked];
        });
        return;
    }

    dispatch_async(_controlQueue, ^{
        if (self->_shutdown)
            return;

        [self disconnectLockedWithMessage:@""];
        self->_connecting = YES;
        self->_demo = NO;
        self->_statusMessage = [NSString stringWithFormat:@"Connecting to %@…", trimmed];
        [self publishStateLocked];

        if (!self->_discovery)
            self->_discovery = CreateBMDSwitcherDiscoveryInstance();
        if (!self->_discovery) {
            self->_connecting = NO;
            self->_statusMessage = @"BMDSwitcherAPI could not be loaded. Reinstall ATEM Software Control.";
            [self publishStateLocked];
            return;
        }

        IBMDSwitcher *newSwitcher = nullptr;
        BMDSwitcherConnectToFailure failure = bmdSwitcherConnectToFailureNoResponse;
        HRESULT result = self->_discovery->ConnectTo((__bridge CFStringRef)trimmed, &newSwitcher, &failure);
        self->_connecting = NO;
        if (FAILED(result) || !newSwitcher) {
            self->_statusMessage = ConnectionFailureMessage(failure);
            [self publishStateLocked];
            return;
        }

        self->_switcher = newSwitcher;
        self->_switcher->AddCallback(self->_switcherMonitor);
        if (![self configureConnectedSwitcherLocked]) {
            [self disconnectLockedWithMessage:@"Connected, but no mix/effects block was available."];
            [self publishStateLocked];
            return;
        }
        self->_statusMessage = @"Connected. Camera-control initialization is intentionally isolated from this core surface.";
        [self publishStateLocked];
    });
}

- (BOOL)configureConnectedSwitcherLocked
{
    CFStringRef productName = nullptr;
    if (SUCCEEDED(_switcher->GetProductName(&productName)))
        _productName = StringFromOwnedCFString(productName);
    else
        _productName = @"ATEM Switcher";

    IBMDSwitcherMixEffectBlockIterator *meIterator = nullptr;
    if (FAILED(_switcher->CreateIterator(IID_IBMDSwitcherMixEffectBlockIterator, (void **)&meIterator)) || !meIterator)
        return NO;
    HRESULT nextResult = meIterator->Next(&_mixEffectBlock);
    meIterator->Release();
    if (nextResult != S_OK || !_mixEffectBlock)
        return NO;
    _mixEffectBlock->AddCallback(_mixEffectBlockMonitor);

    _mixEffectBlock->QueryInterface(IID_IBMDSwitcherTransitionParameters, (void **)&_transitionParameters);
    _mixEffectBlock->QueryInterface(IID_IBMDSwitcherTransitionMixParameters, (void **)&_mixParameters);
    _mixEffectBlock->QueryInterface(IID_IBMDSwitcherTransitionDipParameters, (void **)&_dipParameters);
    _mixEffectBlock->QueryInterface(IID_IBMDSwitcherTransitionWipeParameters, (void **)&_wipeParameters);
    _mixEffectBlock->QueryInterface(IID_IBMDSwitcherTransitionDVEParameters, (void **)&_dveParameters);
    _mixEffectBlock->QueryInterface(IID_IBMDSwitcherTransitionStingerParameters, (void **)&_stingerParameters);

    BMDSwitcherInputAvailability meAvailability = bmdSwitcherInputAvailabilityMixEffectBlock0;
    _mixEffectBlock->GetInputAvailabilityMask(&meAvailability);
    _mixEffectInputAvailabilityMask = (uint32_t)meAvailability;
    NSMutableArray<ATEMInputState *> *inputs = [NSMutableArray array];
    IBMDSwitcherInputIterator *inputIterator = nullptr;
    if (SUCCEEDED(_switcher->CreateIterator(IID_IBMDSwitcherInputIterator, (void **)&inputIterator)) && inputIterator) {
        IBMDSwitcherInput *input = nullptr;
        while (inputIterator->Next(&input) == S_OK && input) {
            BMDSwitcherInputId inputID = 0;
            BMDSwitcherInputAvailability availability = (BMDSwitcherInputAvailability)0;
            BMDSwitcherPortType portType = bmdSwitcherPortTypeExternal;
            CFStringRef longName = nullptr;
            CFStringRef shortName = nullptr;
            input->GetInputId(&inputID);
            input->GetInputAvailability(&availability);
            input->GetPortType(&portType);
            input->GetLongName(&longName);
            input->GetShortName(&shortName);
            NSString *longValue = StringFromOwnedCFString(longName);
            NSString *shortValue = StringFromOwnedCFString(shortName);

            if (portType != bmdSwitcherPortTypeAuxOutput &&
                portType != bmdSwitcherPortTypeMultiview &&
                (uint32_t)availability != 0) {
                [inputs addObject:[[ATEMInputState alloc] initWithID:inputID
                                                          longName:longValue.length ? longValue : [NSString stringWithFormat:@"Input %lld", inputID]
                                                         shortName:shortValue.length ? shortValue : longValue
                                                  availabilityMask:(uint32_t)availability]];
            }

            if (portType == bmdSwitcherPortTypeAuxOutput) {
                IBMDSwitcherInputAux *aux = nullptr;
                if (SUCCEEDED(input->QueryInterface(IID_IBMDSwitcherInputAux, (void **)&aux)) && aux) {
                    AuxAPIRecord record;
                    record.api = aux;
                    record.name = longValue.length ? longValue : [NSString stringWithFormat:@"Aux %lu", (unsigned long)_auxAPIs.size() + 1];
                    BMDSwitcherInputAvailability auxAvailability = (BMDSwitcherInputAvailability)0;
                    aux->GetInputAvailabilityMask(&auxAvailability);
                    record.inputAvailabilityMask = (uint32_t)auxAvailability;
                    _auxAPIs.push_back(record);
                }
            }
            input->Release();
            input = nullptr;
        }
        inputIterator->Release();
    }
    _inputStates = [inputs copy];

    IBMDSwitcherKeyIterator *keyIterator = nullptr;
    if (SUCCEEDED(_mixEffectBlock->CreateIterator(IID_IBMDSwitcherKeyIterator, (void **)&keyIterator)) && keyIterator) {
        IBMDSwitcherKey *key = nullptr;
        while (keyIterator->Next(&key) == S_OK && key) {
            _upstreamKeyAPIs.push_back(key);
            key = nullptr;
        }
        keyIterator->Release();
    }

    IBMDSwitcherDownstreamKeyIterator *dskIterator = nullptr;
    if (SUCCEEDED(_switcher->CreateIterator(IID_IBMDSwitcherDownstreamKeyIterator, (void **)&dskIterator)) && dskIterator) {
        IBMDSwitcherDownstreamKey *dsk = nullptr;
        while (dskIterator->Next(&dsk) == S_OK && dsk) {
            _downstreamKeyAPIs.push_back(dsk);
            dsk = nullptr;
        }
        dskIterator->Release();
    }

    IBMDSwitcherMultiViewIterator *multiviewIterator = nullptr;
    if (SUCCEEDED(_switcher->CreateIterator(IID_IBMDSwitcherMultiViewIterator, (void **)&multiviewIterator)) && multiviewIterator) {
        IBMDSwitcherMultiView *multiview = nullptr;
        while (multiviewIterator->Next(&multiview) == S_OK && multiview) {
            _multiviewAPIs.push_back(multiview);
            multiview = nullptr;
        }
        multiviewIterator->Release();
    }

    return YES;
}

- (void)disconnect
{
    dispatch_async(_controlQueue, ^{
        [self disconnectLockedWithMessage:@"Disconnected."];
        [self publishStateLocked];
    });
}

- (void)disconnectLockedWithMessage:(NSString *)message
{
    _connecting = NO;
    _demo = NO;
    _demoMultiviews.clear();

    for (IBMDSwitcherMultiView *multiview : _multiviewAPIs)
        multiview->Release();
    _multiviewAPIs.clear();

    for (AuxAPIRecord &record : _auxAPIs) {
        if (record.api)
            record.api->Release();
        record.api = nullptr;
        record.name = nil;
        record.inputAvailabilityMask = 0;
    }
    _auxAPIs.clear();

    for (IBMDSwitcherKey *key : _upstreamKeyAPIs)
        key->Release();
    _upstreamKeyAPIs.clear();
    for (IBMDSwitcherDownstreamKey *dsk : _downstreamKeyAPIs)
        dsk->Release();
    _downstreamKeyAPIs.clear();

    if (_transitionParameters) { _transitionParameters->Release(); _transitionParameters = nullptr; }
    if (_mixParameters) { _mixParameters->Release(); _mixParameters = nullptr; }
    if (_dipParameters) { _dipParameters->Release(); _dipParameters = nullptr; }
    if (_wipeParameters) { _wipeParameters->Release(); _wipeParameters = nullptr; }
    if (_dveParameters) { _dveParameters->Release(); _dveParameters = nullptr; }
    if (_stingerParameters) { _stingerParameters->Release(); _stingerParameters = nullptr; }
    if (_mixEffectBlock) {
        _mixEffectBlock->RemoveCallback(_mixEffectBlockMonitor);
        _mixEffectBlock->Release();
        _mixEffectBlock = nullptr;
    }
    if (_switcher) {
        _switcher->RemoveCallback(_switcherMonitor);
        _switcher->Release();
        _switcher = nullptr;
    }

    _productName = @"";
    _inputStates = @[];
    _mixEffectInputAvailabilityMask = 0;
    if (message.length)
        _statusMessage = message;
}

- (void)sdkStateChanged
{
    dispatch_async(_controlQueue, ^{
        if (self->_switcher)
            [self publishStateLocked];
    });
}

- (void)switcherDisconnectedByDevice
{
    dispatch_async(_controlQueue, ^{
        [self disconnectLockedWithMessage:@"The switcher disconnected."];
        [self publishStateLocked];
    });
}

- (void)enterDemoMode
{
    dispatch_async(_controlQueue, ^{
        [self disconnectLockedWithMessage:@""];
        self->_demo = YES;
        self->_productName = @"ATEM Mini Extreme — Demo";
        self->_statusMessage = @"Demo mode: controls are simulated and no hardware commands are sent.";
        NSArray<NSString *> *names = @[@"Camera 1", @"Camera 2", @"Camera 3", @"Camera 4",
                                        @"Camera 5", @"Camera 6", @"Camera 7", @"Camera 8",
                                        @"Black", @"Color 1", @"Color 2", @"Media Player 1", @"Media Player 2"];
        NSMutableArray<ATEMInputState *> *inputs = [NSMutableArray array];
        [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger index, BOOL *stop) {
            (void)stop;
            int64_t inputID = (int64_t)index + 1;
            [inputs addObject:[[ATEMInputState alloc] initWithID:inputID
                                                       longName:name
                                                      shortName:name
                                               availabilityMask:0xFFFFFFFFU]];
        }];
        self->_inputStates = [inputs copy];
        self->_mixEffectInputAvailabilityMask = 0xFFFFFFFFU;
        self->_demoProgram = 1;
        self->_demoPreview = 2;
        self->_demoTransitionPosition = 0;
        self->_demoInTransition = NO;
        self->_demoStyle = ATEMTransitionStyleMix;
        self->_demoSelection = ATEMTransitionSelectionBackground;
        self->_demoRate = 25;
        self->_demoFTB = NO;
        self->_demoKeys = std::vector<bool>(4, false);
        self->_demoDSKOnAir = std::vector<bool>(2, false);
        self->_demoDSKTied = std::vector<bool>(2, false);
        self->_demoAuxSources = std::vector<int64_t>(2, 1);
        self->_demoMultiviews.clear();
        for (NSUInteger multiviewIndex = 0; multiviewIndex < 2; ++multiviewIndex) {
            DemoMultiview multiview;
            multiview.layout = multiviewIndex == 0 ? ATEMMultiviewLayoutProgramTop : ATEMMultiviewLayoutProgramBottom;
            for (NSUInteger window = 0; window < 16; ++window) {
                multiview.sources.push_back((int64_t)((window + multiviewIndex * 4) % names.count) + 1);
                multiview.vuMeters.push_back(window < 8);
                multiview.safeAreas.push_back(false);
                multiview.labels.push_back(true);
                multiview.borders.push_back(true);
            }
            self->_demoMultiviews.push_back(multiview);
        }
        [self publishStateLocked];
    });
}

- (void)publishStateLocked
{
    ATEMState *state = [[ATEMState alloc] init];
    state.connected = (_switcher != nullptr) || _demo;
    state.connecting = _connecting;
    state.demo = _demo;
    state.productName = _productName ?: @"";
    state.statusMessage = _statusMessage ?: @"";
    state.inputs = _inputStates ?: @[];
    state.mixEffectInputAvailabilityMask = _mixEffectInputAvailabilityMask;
    state.programInputID = -1;
    state.previewInputID = -1;
    state.transitionPosition = 0;
    state.transitionFramesRemaining = 0;
    state.inTransition = NO;
    state.nextTransitionStyle = ATEMTransitionStyleMix;
    state.nextTransitionSelection = ATEMTransitionSelectionBackground;
    state.transitionRate = 25;
    state.fadeToBlack = NO;
    state.fadeToBlackTransitioning = NO;
    state.fadeToBlackFramesRemaining = 0;

    NSMutableArray<ATEMKeyState *> *keys = [NSMutableArray array];
    NSMutableArray<ATEMDownstreamKeyState *> *dsks = [NSMutableArray array];
    NSMutableArray<ATEMAuxState *> *auxes = [NSMutableArray array];
    NSMutableArray<ATEMMultiviewState *> *multiviews = [NSMutableArray array];

    if (_demo) {
        state.programInputID = _demoProgram;
        state.previewInputID = _demoPreview;
        state.transitionPosition = _demoTransitionPosition;
        state.inTransition = _demoInTransition;
        state.nextTransitionStyle = _demoStyle;
        state.nextTransitionSelection = _demoSelection;
        state.transitionRate = _demoRate;
        state.fadeToBlack = _demoFTB;
        for (NSUInteger index = 0; index < _demoKeys.size(); ++index)
            [keys addObject:[[ATEMKeyState alloc] initWithIndex:index onAir:_demoKeys[index]]];
        for (NSUInteger index = 0; index < _demoDSKOnAir.size(); ++index) {
            [dsks addObject:[[ATEMDownstreamKeyState alloc] initWithIndex:index
                                                                   onAir:_demoDSKOnAir[index]
                                                                    tied:_demoDSKTied[index]
                                                           transitioning:NO
                                                         framesRemaining:0]];
        }
        for (NSUInteger index = 0; index < _demoAuxSources.size(); ++index) {
            [auxes addObject:[[ATEMAuxState alloc] initWithIndex:index
                                                           name:[NSString stringWithFormat:@"Aux %lu", (unsigned long)index + 1]
                                                       sourceID:_demoAuxSources[index]
                                          inputAvailabilityMask:0xFFFFFFFFU]];
        }
        for (NSUInteger index = 0; index < _demoMultiviews.size(); ++index) {
            const DemoMultiview &demoMultiview = _demoMultiviews[index];
            ATEMMultiviewState *multiview = [[ATEMMultiviewState alloc] init];
            multiview.index = index;
            multiview.layout = demoMultiview.layout;
            multiview.canChangeLayout = YES;
            multiview.supportsQuadrantLayout = YES;
            multiview.canRouteInputs = YES;
            multiview.inputAvailabilityMask = 0xFFFFFFFFU;
            multiview.supportsVUMeters = YES;
            multiview.canAdjustVUMeterOpacity = YES;
            multiview.vuMeterOpacity = demoMultiview.vuMeterOpacity;
            multiview.canToggleSafeArea = YES;
            multiview.supportedSafeAreaTypes = 0x00000003U;
            multiview.supportsProgramPreviewSwap = YES;
            multiview.programPreviewSwapped = demoMultiview.programPreviewSwapped;
            multiview.canChangeOverlayProperties = YES;
            NSMutableArray<ATEMMultiviewWindowState *> *windows = [NSMutableArray array];
            NSUInteger activeWindowCount = MIN(ActiveQuadrantWindowCount(demoMultiview.layout), demoMultiview.sources.size());
            for (NSUInteger windowIndex = 0; windowIndex < activeWindowCount; ++windowIndex) {
                ATEMMultiviewWindowState *window = [[ATEMMultiviewWindowState alloc] init];
                window.index = windowIndex;
                window.sourceID = demoMultiview.sources[windowIndex];
                window.supportsVUMeter = YES;
                window.vuMeterEnabled = demoMultiview.vuMeters[windowIndex];
                window.supportsSafeArea = YES;
                window.safeAreaEnabled = demoMultiview.safeAreas[windowIndex];
                window.safeAreaType = 0x00000001U;
                window.supportsLabelOverlay = YES;
                window.labelVisible = demoMultiview.labels[windowIndex];
                window.borderVisible = demoMultiview.borders[windowIndex];
                [windows addObject:window];
            }
            multiview.windows = windows;
            [multiviews addObject:multiview];
        }
    } else if (_mixEffectBlock) {
        BMDSwitcherInputId programID = -1;
        BMDSwitcherInputId previewID = -1;
        double position = 0;
        uint32_t frames = 0;
        bool boolValue = false;
        _mixEffectBlock->GetProgramInput(&programID);
        _mixEffectBlock->GetPreviewInput(&previewID);
        _mixEffectBlock->GetTransitionPosition(&position);
        _mixEffectBlock->GetTransitionFramesRemaining(&frames);
        _mixEffectBlock->GetInTransition(&boolValue);
        state.programInputID = programID;
        state.previewInputID = previewID;
        state.transitionPosition = position;
        state.transitionFramesRemaining = frames;
        state.inTransition = boolValue;

        boolValue = false;
        _mixEffectBlock->GetFadeToBlackFullyBlack(&boolValue);
        state.fadeToBlack = boolValue;
        boolValue = false;
        _mixEffectBlock->GetFadeToBlackInTransition(&boolValue);
        state.fadeToBlackTransitioning = boolValue;
        _mixEffectBlock->GetFadeToBlackFramesRemaining(&frames);
        state.fadeToBlackFramesRemaining = frames;

        BMDSwitcherTransitionStyle style = bmdSwitcherTransitionStyleMix;
        BMDSwitcherTransitionSelection selection = bmdSwitcherTransitionSelectionBackground;
        if (_transitionParameters) {
            _transitionParameters->GetNextTransitionStyle(&style);
            _transitionParameters->GetNextTransitionSelection(&selection);
        }
        state.nextTransitionStyle = AppTransitionStyle(style);
        state.nextTransitionSelection = AppTransitionSelection(selection);

        uint32_t rate = 25;
        switch (style) {
            case bmdSwitcherTransitionStyleDip:
                if (_dipParameters) _dipParameters->GetRate(&rate);
                break;
            case bmdSwitcherTransitionStyleWipe:
                if (_wipeParameters) _wipeParameters->GetRate(&rate);
                break;
            case bmdSwitcherTransitionStyleDVE:
                if (_dveParameters) _dveParameters->GetRate(&rate);
                break;
            case bmdSwitcherTransitionStyleStinger:
                if (_stingerParameters) _stingerParameters->GetMixRate(&rate);
                break;
            case bmdSwitcherTransitionStyleMix:
            default:
                if (_mixParameters) _mixParameters->GetRate(&rate);
                break;
        }
        state.transitionRate = rate;

        for (NSUInteger index = 0; index < _upstreamKeyAPIs.size(); ++index) {
            bool onAir = false;
            _upstreamKeyAPIs[index]->GetOnAir(&onAir);
            [keys addObject:[[ATEMKeyState alloc] initWithIndex:index onAir:onAir]];
        }
        for (NSUInteger index = 0; index < _downstreamKeyAPIs.size(); ++index) {
            bool onAir = false;
            bool tied = false;
            bool transitioning = false;
            uint32_t remaining = 0;
            _downstreamKeyAPIs[index]->GetOnAir(&onAir);
            _downstreamKeyAPIs[index]->GetTie(&tied);
            _downstreamKeyAPIs[index]->IsTransitioning(&transitioning);
            _downstreamKeyAPIs[index]->GetFramesRemaining(&remaining);
            [dsks addObject:[[ATEMDownstreamKeyState alloc] initWithIndex:index
                                                                   onAir:onAir
                                                                    tied:tied
                                                           transitioning:transitioning
                                                         framesRemaining:remaining]];
        }
        for (NSUInteger index = 0; index < _auxAPIs.size(); ++index) {
            BMDSwitcherInputId sourceID = -1;
            _auxAPIs[index].api->GetInputSource(&sourceID);
            [auxes addObject:[[ATEMAuxState alloc] initWithIndex:index
                                                           name:_auxAPIs[index].name ?: [NSString stringWithFormat:@"Aux %lu", (unsigned long)index + 1]
                                                       sourceID:sourceID
                                          inputAvailabilityMask:_auxAPIs[index].inputAvailabilityMask]];
        }
        for (NSUInteger index = 0; index < _multiviewAPIs.size(); ++index) {
            IBMDSwitcherMultiView *api = _multiviewAPIs[index];
            ATEMMultiviewState *multiview = [[ATEMMultiviewState alloc] init];
            multiview.index = index;

            bool boolValue = false;
            api->CanChangeLayout(&boolValue);
            multiview.canChangeLayout = boolValue;
            BMDSwitcherMultiViewLayout layout = bmdSwitcherMultiViewLayoutProgramTop;
            api->GetLayout(&layout);
            multiview.layout = (ATEMMultiviewLayout)layout;
            boolValue = false;
            api->SupportsQuadrantLayout(&boolValue);
            multiview.supportsQuadrantLayout = boolValue;
            boolValue = false;
            api->CanRouteInputs(&boolValue);
            multiview.canRouteInputs = boolValue;
            BMDSwitcherInputAvailability availability = (BMDSwitcherInputAvailability)0;
            api->GetInputAvailabilityMask(&availability);
            multiview.inputAvailabilityMask = (uint32_t)availability;
            boolValue = false;
            api->SupportsVuMeters(&boolValue);
            multiview.supportsVUMeters = boolValue;
            boolValue = false;
            api->CanAdjustVuMeterOpacity(&boolValue);
            multiview.canAdjustVUMeterOpacity = boolValue;
            double opacity = 1.0;
            api->GetVuMeterOpacity(&opacity);
            multiview.vuMeterOpacity = opacity;
            boolValue = false;
            api->CanToggleSafeAreaEnabled(&boolValue);
            multiview.canToggleSafeArea = boolValue;
            uint32_t safeAreaTypes = 0;
            api->GetSupportedSafeAreaTypes(&safeAreaTypes);
            multiview.supportedSafeAreaTypes = safeAreaTypes;
            boolValue = false;
            api->SupportsProgramPreviewSwap(&boolValue);
            multiview.supportsProgramPreviewSwap = boolValue;
            boolValue = false;
            api->GetProgramPreviewSwapped(&boolValue);
            multiview.programPreviewSwapped = boolValue;
            boolValue = false;
            api->CanChangeOverlayProperties(&boolValue);
            multiview.canChangeOverlayProperties = boolValue;

            uint32_t windowCount = 0;
            api->GetWindowCount(&windowCount);
            if (multiview.supportsQuadrantLayout)
                windowCount = MIN(windowCount, (uint32_t)ActiveQuadrantWindowCount(multiview.layout));
            windowCount = MIN(windowCount, 64U);
            NSMutableArray<ATEMMultiviewWindowState *> *windows = [NSMutableArray arrayWithCapacity:windowCount];
            for (uint32_t windowIndex = 0; windowIndex < windowCount; ++windowIndex) {
                ATEMMultiviewWindowState *window = [[ATEMMultiviewWindowState alloc] init];
                window.index = windowIndex;
                BMDSwitcherInputId sourceID = -1;
                api->GetWindowInput(windowIndex, &sourceID);
                window.sourceID = sourceID;
                boolValue = false;
                api->CurrentInputSupportsVuMeter(windowIndex, &boolValue);
                window.supportsVUMeter = boolValue;
                boolValue = false;
                api->GetVuMeterEnabled(windowIndex, &boolValue);
                window.vuMeterEnabled = boolValue;
                boolValue = false;
                api->CurrentInputSupportsSafeArea(windowIndex, &boolValue);
                window.supportsSafeArea = boolValue;
                boolValue = false;
                api->GetSafeAreaEnabled(windowIndex, &boolValue);
                window.safeAreaEnabled = boolValue;
                BMDSwitcherMultiViewSafeAreaType safeAreaType = bmdSwitcherMultiViewSafeAreaTypeAspect16x9;
                api->GetSafeAreaType(windowIndex, &safeAreaType);
                window.safeAreaType = (uint32_t)safeAreaType;
                boolValue = false;
                api->CurrentInputSupportsLabelOverlay(windowIndex, &boolValue);
                window.supportsLabelOverlay = boolValue;
                boolValue = false;
                api->GetLabelVisible(windowIndex, &boolValue);
                window.labelVisible = boolValue;
                boolValue = false;
                api->GetBorderVisible(windowIndex, &boolValue);
                window.borderVisible = boolValue;
                [windows addObject:window];
            }
            multiview.windows = windows;
            [multiviews addObject:multiview];
        }
    }

    state.upstreamKeys = keys;
    state.downstreamKeys = dsks;
    state.auxOutputs = auxes;
    state.multiviews = multiviews;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_shutdown)
            return;
        self.latestState = state;
        void (^handler)(ATEMState *) = self.stateHandler;
        if (handler)
            handler(state);
    });
}

- (void)setProgramInput:(int64_t)inputID
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo) self->_demoProgram = inputID;
        else if (self->_mixEffectBlock) self->_mixEffectBlock->SetProgramInput(inputID);
        [self publishStateLocked];
    });
}

- (void)setPreviewInput:(int64_t)inputID
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo) self->_demoPreview = inputID;
        else if (self->_mixEffectBlock) self->_mixEffectBlock->SetPreviewInput(inputID);
        [self publishStateLocked];
    });
}

- (void)performCut
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo) std::swap(self->_demoProgram, self->_demoPreview);
        else if (self->_mixEffectBlock) self->_mixEffectBlock->PerformCut();
        [self publishStateLocked];
    });
}

- (void)performAutoTransition
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo) {
            self->_demoInTransition = YES;
            self->_demoTransitionPosition = 0.5;
            [self publishStateLocked];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 450 * NSEC_PER_MSEC), self->_controlQueue, ^{
                if (!self->_demo) return;
                std::swap(self->_demoProgram, self->_demoPreview);
                self->_demoInTransition = NO;
                self->_demoTransitionPosition = 0;
                [self publishStateLocked];
            });
        } else if (self->_mixEffectBlock) {
            self->_mixEffectBlock->PerformAutoTransition();
            [self publishStateLocked];
        }
    });
}

- (void)performFadeToBlack
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo) self->_demoFTB = !self->_demoFTB;
        else if (self->_mixEffectBlock) self->_mixEffectBlock->PerformFadeToBlack();
        [self publishStateLocked];
    });
}

- (void)setTransitionPosition:(double)position
{
    double clamped = MAX(0.0, MIN(1.0, position));
    dispatch_async(_controlQueue, ^{
        if (self->_demo) {
            self->_demoTransitionPosition = clamped;
            self->_demoInTransition = clamped > 0.001 && clamped < 0.999;
            if (clamped >= 0.999) {
                std::swap(self->_demoProgram, self->_demoPreview);
                self->_demoTransitionPosition = 0;
                self->_demoInTransition = NO;
            }
        } else if (self->_mixEffectBlock) {
            self->_mixEffectBlock->SetTransitionPosition(clamped);
        }
        [self publishStateLocked];
    });
}

- (void)setNextTransitionStyle:(ATEMTransitionStyle)style
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo) self->_demoStyle = style;
        else if (self->_transitionParameters) self->_transitionParameters->SetNextTransitionStyle(SDKTransitionStyle(style));
        [self publishStateLocked];
    });
}

- (void)setNextTransitionSelection:(ATEMTransitionSelection)selection
{
    if (selection == 0)
        selection = ATEMTransitionSelectionBackground;
    dispatch_async(_controlQueue, ^{
        if (self->_demo) self->_demoSelection = selection;
        else if (self->_transitionParameters) self->_transitionParameters->SetNextTransitionSelection(SDKTransitionSelection(selection));
        [self publishStateLocked];
    });
}

- (void)setTransitionRate:(uint32_t)frames
{
    uint32_t safeFrames = MAX(1U, MIN(250U, frames));
    dispatch_async(_controlQueue, ^{
        if (self->_demo) {
            self->_demoRate = safeFrames;
        } else if (self->_transitionParameters) {
            BMDSwitcherTransitionStyle style = bmdSwitcherTransitionStyleMix;
            self->_transitionParameters->GetNextTransitionStyle(&style);
            switch (style) {
                case bmdSwitcherTransitionStyleDip:
                    if (self->_dipParameters) self->_dipParameters->SetRate(safeFrames);
                    break;
                case bmdSwitcherTransitionStyleWipe:
                    if (self->_wipeParameters) self->_wipeParameters->SetRate(safeFrames);
                    break;
                case bmdSwitcherTransitionStyleDVE:
                    if (self->_dveParameters) self->_dveParameters->SetRate(safeFrames);
                    break;
                case bmdSwitcherTransitionStyleStinger:
                    if (self->_stingerParameters) self->_stingerParameters->SetMixRate(safeFrames);
                    break;
                case bmdSwitcherTransitionStyleMix:
                default:
                    if (self->_mixParameters) self->_mixParameters->SetRate(safeFrames);
                    break;
            }
        }
        [self publishStateLocked];
    });
}

- (void)setUpstreamKey:(NSUInteger)index onAir:(BOOL)onAir
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoKeys.size()) self->_demoKeys[index] = onAir;
        else if (index < self->_upstreamKeyAPIs.size()) self->_upstreamKeyAPIs[index]->SetOnAir(onAir);
        [self publishStateLocked];
    });
}

- (void)setDownstreamKey:(NSUInteger)index onAir:(BOOL)onAir
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoDSKOnAir.size()) self->_demoDSKOnAir[index] = onAir;
        else if (index < self->_downstreamKeyAPIs.size()) self->_downstreamKeyAPIs[index]->SetOnAir(onAir);
        [self publishStateLocked];
    });
}

- (void)setDownstreamKey:(NSUInteger)index tied:(BOOL)tied
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoDSKTied.size()) self->_demoDSKTied[index] = tied;
        else if (index < self->_downstreamKeyAPIs.size()) self->_downstreamKeyAPIs[index]->SetTie(tied);
        [self publishStateLocked];
    });
}

- (void)performDownstreamKeyAuto:(NSUInteger)index
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoDSKOnAir.size()) self->_demoDSKOnAir[index] = !self->_demoDSKOnAir[index];
        else if (index < self->_downstreamKeyAPIs.size()) self->_downstreamKeyAPIs[index]->PerformAutoTransition();
        [self publishStateLocked];
    });
}

- (void)setAuxOutput:(NSUInteger)index source:(int64_t)sourceID
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoAuxSources.size()) self->_demoAuxSources[index] = sourceID;
        else if (index < self->_auxAPIs.size()) self->_auxAPIs[index].api->SetInputSource(sourceID);
        [self publishStateLocked];
    });
}

- (void)setMultiview:(NSUInteger)index layout:(ATEMMultiviewLayout)layout
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoMultiviews.size())
            self->_demoMultiviews[index].layout = layout;
        else if (index < self->_multiviewAPIs.size())
            self->_multiviewAPIs[index]->SetLayout((BMDSwitcherMultiViewLayout)layout);
        [self publishStateLocked];
    });
}

- (void)setMultiview:(NSUInteger)index programPreviewSwapped:(BOOL)swapped
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoMultiviews.size())
            self->_demoMultiviews[index].programPreviewSwapped = swapped;
        else if (index < self->_multiviewAPIs.size())
            self->_multiviewAPIs[index]->SetProgramPreviewSwapped(swapped);
        [self publishStateLocked];
    });
}

- (void)setMultiview:(NSUInteger)index vuMeterOpacity:(double)opacity
{
    double clamped = MAX(0.0, MIN(1.0, opacity));
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoMultiviews.size())
            self->_demoMultiviews[index].vuMeterOpacity = clamped;
        else if (index < self->_multiviewAPIs.size())
            self->_multiviewAPIs[index]->SetVuMeterOpacity(clamped);
        [self publishStateLocked];
    });
}

- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window source:(int64_t)sourceID
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoMultiviews.size() && window < self->_demoMultiviews[index].sources.size())
            self->_demoMultiviews[index].sources[window] = sourceID;
        else if (index < self->_multiviewAPIs.size())
            self->_multiviewAPIs[index]->SetWindowInput((uint32_t)window, sourceID);
        [self publishStateLocked];
    });
}

- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window vuMeterEnabled:(BOOL)enabled
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoMultiviews.size() && window < self->_demoMultiviews[index].vuMeters.size())
            self->_demoMultiviews[index].vuMeters[window] = enabled;
        else if (index < self->_multiviewAPIs.size())
            self->_multiviewAPIs[index]->SetVuMeterEnabled((uint32_t)window, enabled);
        [self publishStateLocked];
    });
}

- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window safeAreaEnabled:(BOOL)enabled
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoMultiviews.size() && window < self->_demoMultiviews[index].safeAreas.size())
            self->_demoMultiviews[index].safeAreas[window] = enabled;
        else if (index < self->_multiviewAPIs.size())
            self->_multiviewAPIs[index]->SetSafeAreaEnabled((uint32_t)window, enabled);
        [self publishStateLocked];
    });
}

- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window labelVisible:(BOOL)visible
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoMultiviews.size() && window < self->_demoMultiviews[index].labels.size())
            self->_demoMultiviews[index].labels[window] = visible;
        else if (index < self->_multiviewAPIs.size())
            self->_multiviewAPIs[index]->SetLabelVisible((uint32_t)window, visible);
        [self publishStateLocked];
    });
}

- (void)setMultiview:(NSUInteger)index window:(NSUInteger)window borderVisible:(BOOL)visible
{
    dispatch_async(_controlQueue, ^{
        if (self->_demo && index < self->_demoMultiviews.size() && window < self->_demoMultiviews[index].borders.size())
            self->_demoMultiviews[index].borders[window] = visible;
        else if (index < self->_multiviewAPIs.size())
            self->_multiviewAPIs[index]->SetBorderVisible((uint32_t)window, visible);
        [self publishStateLocked];
    });
}

- (void)shutdown
{
    if (_shutdown)
        return;
    _shutdown = YES;
    self.stateHandler = nil;
    if (_pollTimer) {
        dispatch_source_cancel(_pollTimer);
        _pollTimer = nil;
    }
    dispatch_sync(_controlQueue, ^{
        [self disconnectLockedWithMessage:@""];
        if (self->_discovery) {
            self->_discovery->Release();
            self->_discovery = nullptr;
        }
    });
    if (_switcherMonitor) {
        _switcherMonitor->Release();
        _switcherMonitor = nullptr;
    }
    if (_mixEffectBlockMonitor) {
        _mixEffectBlockMonitor->Release();
        _mixEffectBlockMonitor = nullptr;
    }
}

- (void)dealloc
{
    [self shutdown];
}

@end


int ATEMRunSelfTest(void)
{
    @autoreleasepool {
        BOOL runtimeExists = [ATEMController isRuntimeInstalled];
        printf("runtime bundle: %s\n", runtimeExists ? "ok" : "missing");
        if (!runtimeExists)
            return 1;

        IBMDSwitcherDiscovery *discovery = CreateBMDSwitcherDiscoveryInstance();
        printf("discovery instance: %s\n", discovery ? "ok" : "failed");
        if (!discovery)
            return 2;
        discovery->Release();

        if (SDKTransitionStyle(ATEMTransitionStyleWipe) != bmdSwitcherTransitionStyleWipe)
            return 3;
        if (AppTransitionStyle(bmdSwitcherTransitionStyleDVE) != ATEMTransitionStyleDVE)
            return 4;
        printf("transition mapping: ok\n");

        ATEMController *controller = [[ATEMController alloc] init];
        ATEMController *secondController = [[ATEMController alloc] init];
        __block ATEMState *observedState = nil;
        __block ATEMState *secondObservedState = nil;
        controller.stateHandler = ^(ATEMState *state) {
            observedState = state;
        };
        secondController.stateHandler = ^(ATEMState *state) {
            secondObservedState = state;
        };
        [controller enterDemoMode];
        [secondController enterDemoMode];
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:1.0];
        while ((!observedState.isDemo || !secondObservedState.isDemo || observedState.inputs.count == 0) && deadline.timeIntervalSinceNow > 0)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        if (!observedState.isDemo || observedState.inputs.count != 13 ||
            observedState.upstreamKeys.count != 4 || observedState.downstreamKeys.count != 2 ||
            observedState.multiviews.count != 2 || observedState.multiviews.firstObject.windows.count != 10 ||
            !secondObservedState.isDemo) {
            [controller shutdown];
            [secondController shutdown];
            return 5;
        }
        [controller setPreviewInput:4];
        [controller performCut];
        deadline = [NSDate dateWithTimeIntervalSinceNow:1.0];
        while (observedState.programInputID != 4 && deadline.timeIntervalSinceNow > 0)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        if (observedState.programInputID != 4) {
            [controller shutdown];
            [secondController shutdown];
            return 6;
        }
        [controller setMultiview:0 layout:(ATEMMultiviewLayout)0];
        deadline = [NSDate dateWithTimeIntervalSinceNow:1.0];
        while (observedState.multiviews.firstObject.windows.count != 4 && deadline.timeIntervalSinceNow > 0)
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        if (observedState.multiviews.firstObject.windows.count != 4) {
            [controller shutdown];
            [secondController shutdown];
            return 7;
        }
        ATEMMultiviewLayout allQuadrants = (ATEMMultiviewLayout)(ATEMMultiviewLayoutTopLeftSmall |
                                                                 ATEMMultiviewLayoutTopRightSmall |
                                                                 ATEMMultiviewLayoutBottomLeftSmall |
                                                                 ATEMMultiviewLayoutBottomRightSmall);
        [controller setMultiview:0 layout:allQuadrants];
        [controller setMultiview:0 window:15 source:7];
        [controller setMultiview:0 window:0 labelVisible:NO];
        [controller setMultiview:0 vuMeterOpacity:0.35];
        deadline = [NSDate dateWithTimeIntervalSinceNow:1.0];
        while ((observedState.multiviews.firstObject.layout != allQuadrants ||
                observedState.multiviews.firstObject.windows.count != 16 ||
                observedState.multiviews.firstObject.windows[15].sourceID != 7 ||
                observedState.multiviews.firstObject.windows.firstObject.isLabelVisible ||
                observedState.multiviews.firstObject.vuMeterOpacity > 0.351) && deadline.timeIntervalSinceNow > 0) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        }
        if (observedState.multiviews.firstObject.layout != allQuadrants ||
            observedState.multiviews.firstObject.windows.count != 16 ||
            observedState.multiviews.firstObject.windows[15].sourceID != 7 ||
            observedState.multiviews.firstObject.windows.firstObject.isLabelVisible ||
            observedState.multiviews.firstObject.vuMeterOpacity > 0.351) {
            [controller shutdown];
            [secondController shutdown];
            return 8;
        }
        if (secondObservedState.programInputID != 1 ||
            secondObservedState.multiviews.firstObject.layout != ATEMMultiviewLayoutProgramTop) {
            [controller shutdown];
            [secondController shutdown];
            return 9;
        }
        [controller shutdown];
        [secondController shutdown];
        printf("asynchronous demo controller: ok\n");
        printf("independent dual sessions: ok\n");
        printf("multiview configuration model: ok\n");
        printf("self-test: passed\n");
        return 0;
    }
}

int ATEMPrintDiagnostics(void)
{
    @autoreleasepool {
        NSProcessInfo *processInfo = NSProcessInfo.processInfo;
        NSBundle *runtimeBundle = [NSBundle bundleWithPath:ATEMController.runtimePath];
        NSString *runtimeVersion = [runtimeBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if (runtimeVersion.length == 0)
            runtimeVersion = [runtimeBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (runtimeVersion.length == 0)
            runtimeVersion = @"unknown";
        printf("ATEM CNTRL diagnostics\n");
        printf("macOS: %s\n", processInfo.operatingSystemVersionString.UTF8String);
#if defined(__arm64__)
        printf("architecture: arm64\n");
#elif defined(__x86_64__)
        printf("architecture: x86_64\n");
#else
        printf("architecture: unknown\n");
#endif
        printf("runtime path: %s\n", ATEMController.runtimePath.UTF8String);
        printf("runtime installed: %s\n", ATEMController.isRuntimeInstalled ? "yes" : "no");
        printf("runtime version: %s\n", runtimeVersion.UTF8String);
        printf("independent switcher sessions: 2\n");
        printf("multiview configuration API: enabled\n");
        printf("camera-control API touched: no\n");
        return ATEMController.isRuntimeInstalled ? 0 : 1;
    }
}
