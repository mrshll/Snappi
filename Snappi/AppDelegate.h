//
//  AppDelegate.h
//  Snappi
//
//  Created by Marshall Moutenot on 5/26/12.
//

#import <WebKit/WebKit.h>

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
  IBOutlet NSView *createCustomLocationView;
    
  IBOutlet NSView *preferencesView;
  IBOutlet NSView *introductionView;
  IBOutlet WebView *introductionWebView;
    
  // outlet to populate the messages in basic notification
  IBOutlet NSTextField *notificationMsg;
  IBOutlet NSTextField *loadingMessage;
  IBOutlet WebView *youtubeWebView;
  // image in complete view. thumb of uploaded image
  IBOutlet NSImageView *uploadThumb;
  // image in complete view with share. thumb of uploaded image
  IBOutlet NSImageView *uploadThumbWithShare;
  // loading bar on uploading view
  IBOutlet NSProgressIndicator *loadingBar;
@public
  // button to share on twitter
  IBOutlet NSButton *twitterShareButton;
}

// handle on the Introduction.xib window controller
@property (retain) IntroWindowController *introWindowController;

// combobox in the complete view with share. Selects friends to post to
@property (assign) IBOutlet NSComboBox *friendSelector;

// handles the 'send' button on the complete view with share.
-(IBAction)sendCustomInfoPressed:(id)sender;

// allows users to cancel a request like adding custom info
-(IBAction)cancel:(id)sender;

// displays instructions
-(IBAction)showIntroductionButtonPressed:(id)sender;

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
- (void) showLoading:(NSString*) text;
- (void) hideLoading;
- (void) showComplete: (NSImage *) thumb;
- (void) hideComplete;
- (void) showCompleteWithShare: (NSImage *) thumb;
- (void) hideCompleteWithShare;
- (void) showPreferences;
- (void) showCreateCustomLocation;
- (void) showIntroduction;
    
// getter functions
- (NSMenu *)          getStatusMenu;
- (CMDroppableView *) getStatusView;
- (NSStatusItem *)    getStatusItem;
- (NSWindow *)        getIntroWindow;
- (NSString *) getTmpPath;
- (BOOL) isCustomInfoSubmitted;
- (void) resetCustomInfoSubmitted;
- (BOOL) isFirstRun;

// lets us share via twitter
- (void) setTwitterButtonLink: (NSString *) link;
- (NSString *) getTwitterButtonLink;

@end
