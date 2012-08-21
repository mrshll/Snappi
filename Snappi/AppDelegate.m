//
//  AppDelegate.m
//  Snappi
//
//  Created by Marshall Moutenot on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "EvernoteScreenshot.h"
#import "CMDroppableView.h"
#import "MAAttachedWindow.h"
#import "UKCrashReporter.h"
#import "Sparkle/Sparkle.h"
//#import "CustomView.h"

BOOL statusBar = FALSE;

NSString * const MDFirstRunKey            = @"MDFirstRun";
NSString * const MDShouldShowInspectorKey  = @"MDShouldShowInspector";
NSString * const MDBrowserShouldShowIconsKey  = @"MDBrowserShouldShowIcons";

@implementation AppDelegate
@synthesize friendSelector;
@synthesize introWindowController;


+ (void)initialize {
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];

    [defaultValues setObject:[NSNumber numberWithBool:YES]
                      forKey:MDFirstRunKey];

    [defaultValues setObject:[NSNumber numberWithBool:NO]
                      forKey:MDShouldShowInspectorKey];

    [defaultValues setObject:[NSNumber numberWithBool:YES]
                      forKey:MDBrowserShouldShowIconsKey];

    // Load default defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
    
}
- (id)init {
    if (self = [super init]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        MDFirstRun = [[userDefaults objectForKey:MDFirstRunKey] boolValue];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // add geolocation to the tag
//    locationManager = [[CLLocationManager alloc] init];
//    locationManager.delegate = self;
    UKCrashReporterCheckForCrash();
    // debugging for Sparkle
    
    
    if (MDFirstRun) {
        [[NSUserDefaults standardUserDefaults]
         setObject:[NSNumber numberWithBool:NO]
         forKey:MDFirstRunKey];
        [self showIntro];
        
    } else {
    }
    
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"startOnLogin"] boolValue]){
        if(![launchController launchAtLogin])
            [launchController setLaunchAtLogin:YES];
    } else {
        if([launchController launchAtLogin])
            [launchController setLaunchAtLogin:NO];
    }
    [launchController release];
    
    NSString *tempDirectoryTemplate =
    [NSTemporaryDirectory() stringByAppendingPathComponent:@"snappitempdirectory.XXXXXX"];
    const char *tempDirectoryTemplateCString =
    [tempDirectoryTemplate fileSystemRepresentation];
    char *tempDirectoryNameCString =
    (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
    strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
    
    char *result = mkdtemp(tempDirectoryNameCString);
    if (!result)
    {
        // handle directory creation failure
    }
    
    [self setTmpPath: [[NSFileManager defaultManager]
     stringWithFileSystemRepresentation:tempDirectoryNameCString
                       length:strlen(result)]];
    free(tempDirectoryNameCString);
    
}

-(void)awakeFromNib{
    if (!statusBar){
        
        id quitMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Exit" action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
        [statusMenu addItem: quitMenuItem];
        [statusMenu addItem: [NSMenuItem separatorItem]];
        
        // Create an NSStatusItem.
        float width = 18.0;
        float height = [[NSStatusBar systemStatusBar] thickness];
        NSLog(@"%f",height);
        NSRect viewFrame = NSMakeRect(0, 0, width, height);
        statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:width] retain];
        statusView = [[[CMDroppableView alloc] initWithFrame:viewFrame] autorelease];
        [statusView setMenu:statusMenu];
        [statusView setStatusItem:statusItem];
        NSString *inFilePath = [[NSBundle mainBundle] pathForResource: @"snappi_icon_18" ofType:@"png"];
        NSImage *img = [[[NSImage alloc] initWithContentsOfFile:inFilePath] autorelease];
        [statusView setImage: img];
        NSString *inFilePathB = [[NSBundle mainBundle] pathForResource: @"snappi_icon_g_18" ofType:@"png"];
        NSImage *imgB = [[[NSImage alloc] initWithContentsOfFile:inFilePathB] autorelease];
        [statusView setAltImage:imgB];
        
        [statusItem setView:statusView];
//        NSString *inFilePath = [[NSBundle mainBundle] pathForResource: @"snappi_icon_18" ofType:@"png"];
//        NSImage *iconImage = [[[NSImage alloc] initWithContentsOfFile:inFilePath] autorelease];
//        statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
//        
//        [statusItem setMenu:statusMenu];
//        [statusItem setImage:iconImage];
//        [statusItem setHighlightMode:YES];
//        
//        DragStatusView* dragView = [[DragStatusView alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
//        [statusItem setView:dragView];
//        [dragView release];
//        
    }
    statusBar = TRUE;
}

- (void)showAttachedWindowAtPointWithView:(NSPoint)pt:(NSView *)view
{
    // Attach/detach window.
    if (attachedWindow) [self hideAttachedWindow];
    if (!attachedWindow) {
        attachedWindow = [[MAAttachedWindow alloc] initWithView:view
                                                attachedToPoint:pt
                                                       inWindow:nil
                                                         onSide:MAPositionBottom
                                                     atDistance:5.0];
        [attachedWindow makeKeyAndOrderFront:self];
        [attachedWindow setLevel:NSFloatingWindowLevel];
        [attachedWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    }
}
- (void)hideAttachedWindow{
    if(attachedWindow){
        [attachedWindow orderOut:self];
        [attachedWindow release];
        attachedWindow = nil;
    }
}


          
- (void) showIntro {
    [NSApp activateIgnoringOtherApps:YES];
    if(!self.introWindowController)
        self.introWindowController = [[[IntroWindowController alloc] initWithWindowNibName:@"Instructions"] autorelease];
    [self.introWindowController showWindow:self];
}

- (void) showMessage:(NSString *)msg {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
//    
//    if (attachedWindow)
//        [appDelegate hideHover];
    
    notificationMsg.stringValue = msg;
    NSRect frame = [[statusView window] frame];
    NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
    [appDelegate showAttachedWindowAtPointWithView:pt:hoverView]; 
}

- (void) hideMessage{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideAttachedWindow];  
}

- (void) showAddInfo{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    //    
    //    if (attachedWindow)
    //        [appDelegate hideHover];
    
    NSRect frame = [[statusView window] frame];
    NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
    NSArray *friends = [fbc getFriends];
    for (int i = 0; i < [friends count]; i++){
        NSString *name = [[friends objectAtIndex:i] objectForKey:@"name"];
        [friendSelector addItemWithObjectValue:name];
    }
    [appDelegate showAttachedWindowAtPointWithView:pt:addCustomInfo]; 
}

- (void) hideAddInfo{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideAttachedWindow];
    [fbc setSelectedFriend:[friendSelector objectValueOfSelectedItem]];
}

- (void) showLoading {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    
//    if(attachedWindow)
//        [appDelegate hideHover];
    
    NSRect frame = [[statusView window] frame];
    NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
    [loadingBar startAnimation:self];
    [appDelegate showAttachedWindowAtPointWithView:pt:uploadingView]; 
}

- (void) hideLoading {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideAttachedWindow];  
}

- (void) showComplete: (NSImage *) thumb{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    
//    if(attachedWindow)
//        [appDelegate hideLoading];
//    
    if (thumb == nil) {
        [uploadThumb setImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"snappi_icon_g_250" ofType:@"png"]] autorelease]];
    }
    else {
        [uploadThumb setImage:thumb];
    }
    NSRect frame = [[statusView window] frame];
    NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
    [appDelegate showAttachedWindowAtPointWithView:pt:completeView]; 
}

- (void) hideComplete{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideAttachedWindow];  
}

- (void) showCompleteWithShare: (NSImage *) thumb{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    
    //    if(attachedWindow)
    //        [appDelegate hideLoading];
    //
    if (thumb == nil) {
        [uploadThumbWithShare setImage:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"snappi_icon_g_250" ofType:@"png"]] autorelease]];
    }
    else {
        [uploadThumbWithShare setImage:thumb];
    }
    NSRect frame = [[statusView window] frame];
    NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
    [appDelegate showAttachedWindowAtPointWithView:pt:completeViewWithShare];
}

- (void) hideCompleteWithShare{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideAttachedWindow];
}

- (IBAction)hideNotification:(id)sender{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideAttachedWindow];  
}

//////////////////////////////////////////////////////////////////////
// GETTER METHODS
//////////////////////////////////////////////////////////////////////

-(NSMenu *) getStatusMenu{
    return statusMenu;
}

-(CMDroppableView *) getStatusView{
    return statusView;
}

-(NSStatusItem *) getStatusItem{
    return statusItem;
}

//-(CLLocationManager *) getLocationManager{
//    return locationManager;
//}

- (void) setTmpPath: (NSString *) path{
    tmpPath = path;
    [tmpPath retain];
}

- (NSString*) getTmpPath{
    return tmpPath;
}

- (BOOL) isFirstRun{
    return MDFirstRun;
}

@end


