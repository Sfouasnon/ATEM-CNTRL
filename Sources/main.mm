#import <Cocoa/Cocoa.h>
#import "ATEMController.h"
#import "ControlSurfaceWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSArray<ATEMController *> *controllers;
@property(nonatomic, strong) ControlSurfaceWindowController *windowController;
@end


@implementation AppDelegate

- (void)installMainMenu
{
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];

    NSMenuItem *applicationItem = [[NSMenuItem alloc] initWithTitle:@"ATEM CNTRL" action:nil keyEquivalent:@""];
    NSMenu *applicationMenu = [[NSMenu alloc] initWithTitle:@"ATEM CNTRL"];
    [applicationMenu addItemWithTitle:@"About ATEM CNTRL" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [applicationMenu addItem:NSMenuItem.separatorItem];
    NSMenuItem *hide = [applicationMenu addItemWithTitle:@"Hide ATEM CNTRL" action:@selector(hide:) keyEquivalent:@"h"];
    hide.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [applicationMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@""];
    [applicationMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [applicationMenu addItem:NSMenuItem.separatorItem];
    NSMenuItem *quit = [applicationMenu addItemWithTitle:@"Quit ATEM CNTRL" action:@selector(terminate:) keyEquivalent:@"q"];
    quit.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    applicationItem.submenu = applicationMenu;
    [mainMenu addItem:applicationItem];

    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenu addItemWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenu addItem:NSMenuItem.separatorItem];
    [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    editItem.submenu = editMenu;
    [mainMenu addItem:editItem];

    NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
    [windowMenu addItemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) keyEquivalent:@""];
    windowItem.submenu = windowMenu;
    [mainMenu addItem:windowItem];
    NSApp.windowsMenu = windowMenu;
    NSApp.mainMenu = mainMenu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    (void)notification;
    [self installMainMenu];
    self.controllers = @[[[ATEMController alloc] init], [[ATEMController alloc] init]];
    self.windowController = [[ControlSurfaceWindowController alloc] initWithControllers:self.controllers];
    [self.windowController showWindow:self];
    [self.windowController.window makeKeyAndOrderFront:self];
    [self.windowController.window orderFrontRegardless];
    [NSApp activateIgnoringOtherApps:YES];

    if ([[NSProcessInfo processInfo].arguments containsObject:@"--demo"])
        for (ATEMController *controller in self.controllers)
            [controller enterDemoMode];

    NSArray<NSString *> *arguments = NSProcessInfo.processInfo.arguments;
    NSUInteger renderIndex = [arguments indexOfObject:@"--render-preview"];
    BOOL renderMultiview = NO;
    if (renderIndex == NSNotFound) {
        renderIndex = [arguments indexOfObject:@"--render-multiview-preview"];
        renderMultiview = renderIndex != NSNotFound;
    }
    if (renderIndex != NSNotFound && renderIndex + 1 < arguments.count) {
        NSString *outputPath = arguments[renderIndex + 1];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSView *contentView = self.windowController.window.contentView;
            [contentView layoutSubtreeIfNeeded];
            if (renderMultiview)
                [self.windowController scrollMultiviewIntoView];
            NSBitmapImageRep *bitmap = [contentView bitmapImageRepForCachingDisplayInRect:contentView.bounds];
            [contentView cacheDisplayInRect:contentView.bounds toBitmapImageRep:bitmap];
            NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            BOOL written = [png writeToFile:outputPath atomically:YES];
            fprintf(stderr, "preview render: %s\n", written ? outputPath.UTF8String : "failed");
            [NSApp terminate:self];
        });
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    (void)sender;
    return YES;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    (void)notification;
    [self.windowController.window makeKeyAndOrderFront:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    (void)notification;
    for (ATEMController *controller in self.controllers)
        [controller shutdown];
}

@end


int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;
    @autoreleasepool {
        NSArray<NSString *> *arguments = NSProcessInfo.processInfo.arguments;
        if ([arguments containsObject:@"--self-test"])
            return ATEMRunSelfTest();
        if ([arguments containsObject:@"--diagnostics"])
            return ATEMPrintDiagnostics();

        NSApplication *application = NSApplication.sharedApplication;
        application.activationPolicy = NSApplicationActivationPolicyRegular;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
