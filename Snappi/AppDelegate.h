//
//  AppDelegate.h
//  Snappi
//
//  Created by Marshall Moutenot on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>
#import "IntroWindowController.h"
#import "LaunchAtLoginController.h"
#import "CMDroppableView.h"

// class that draws notifications
@class MAAttachedWindow;

@interface AppDelegate : NSObject {
    // introduction window in Introduction.xib
    IBOutlet NSWindow *mIntroWindow;
    
    // indicates if this is the first time the app was run
    BOOL MDFirstRun;
    
    // holds the temp path generated for screenshot and hashes
    NSString * tmpPath;
    
    // used to populate and modify the status menu and items
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
    CMDroppableView * statusView;
    
    // window that is used for notifications
    MAAttachedWindow *attachedWindow;
    
    // different notification views in StatusBar.xib
    IBOutlet NSView *hoverView;
    IBOutlet NSView *uploadingView;
    IBOutlet NSView *completeView;
    IBOutlet NSView *completeViewWithShare;
    IBOutlet NSView *addCustomInfo;
    
    // outlet to populate the messages in basic notification
    IBOutlet NSTextField *notificationMsg;
    // image in complete view. thumb of uploaded image
    IBOutlet NSImageView *uploadThumb;
    // image in complete view with share. thumb of uploaded image
    IBOutlet NSImageView *uploadThumbWithShare;
    // loading bar on uploading view
    IBOutlet NSProgressIndicator *loadingBar;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IntroWindowController *introWindowController;
@property (assign) IBOutlet NSComboBox *friendSelector;

-(IBAction)sendCustomInfoPressed:(id)sender;
-(IBAction)hideNotification:(id)sender;
- (NSMenu *) getStatusMenu;
-(CMDroppableView *) getStatusView;
- (NSStatusItem *) getStatusItem;
//- (CLLocationManager *) getLocationManager;
- (void) showIntro;
- (void)showAttachedWindowAtPointWithView:(NSPoint)pt:(NSView *) view;
- (void)hideAttachedWindow;
- (NSString *) getTmpPath;
- (void) showMessage:(NSString *)msg;
- (void) hideMessage;
- (void) showAddInfo;
- (void) hideAddInfo;
- (void) showLoading;
- (void) hideLoading;
- (void) showComplete: (NSImage *) thumb;
- (void) hideComplete;
- (void) showCompleteWithShare: (NSImage *) thumb;
- (void) hideCompleteWithShare;

- (BOOL) isCustomInfoSubmitted;
- (void) resetCustomInfoSubmitted;
- (BOOL) isFirstRun;


@end
