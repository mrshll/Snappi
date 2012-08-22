//
//  AppDelegate.h
//  Snappi
//
//  Created by Marshall Moutenot on 5/26/12.
//


// class that draws notifications
@class MAAttachedWindow;
@class CMDroppableView;
@class IntroWindowController;

@interface AppDelegate : NSObject {
  // introduction window in Introduction.xib
  IBOutlet NSWindow *introWindow;

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

// handle on the Introduction.xib window controller
@property (retain) IntroWindowController *introWindowController;

// combobox in the complete view with share. Selects friends to post to
@property (assign) IBOutlet NSComboBox *friendSelector;

// handles the 'send' button on the complete view with share.
-(IBAction)sendCustomInfoPressed:(id)sender;

// allows users to cancel a request like adding custom info
-(IBAction)cancel:(id)sender;
//- (CLLocationManager *) getLocationManager;
- (void) showIntro;

// shows and hides MAAttachedWindow at a point with a view
- (void)showAttachedWindowAtPoint:(NSPoint)pt withView:(NSView *) view;
- (void)hideAttachedWindow;

// wrappers for different notifications
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

// getter functions
- (NSMenu *)          getStatusMenu;
- (CMDroppableView *) getStatusView;
- (NSStatusItem *)    getStatusItem;
- (NSWindow *)        getIntroWindow;
- (NSString *) getTmpPath;
- (BOOL) isCustomInfoSubmitted;
- (void) resetCustomInfoSubmitted;
- (BOOL) isFirstRun;

@end
