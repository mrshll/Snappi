//
//  AppController.h
//  Snappi
//
//  Created by Marshall Moutenot on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreferencesController.h"
#import "EvernoteScreenshot.h"
#import "GTMOAuthWindowController.h"
#import "SRRecorderControl.h"
#import "FacebookController.h"



// Authentication item. I'm making this global because it needs to be shared
// across a lot of classes and I couldn't figure out how to make a class's variable
// accessed in a class method.
GTMOAuthAuthentication *mAuthEvernote;
GTMOAuthAuthentication *mAuthTwitter;
FacebookController *fbc;
NSString *facebookScreenshotPath;

@class PTHotKey;

@interface AppController : NSObject <NSApplicationDelegate>
{
@private
    IBOutlet NSButton *mSignInOutEvernoteButton;
    IBOutlet NSButton *mSignInOutTwitterButton;
    IBOutlet NSWindow *mPrefWindow;
    IBOutlet NSProgressIndicator *mSpinner;
    IBOutlet NSTextField *mUsernameField;
    
    IBOutlet NSTabView *instructionsTabView;
    IBOutlet NSTabView *connectTabView;
	IBOutlet SRRecorderControl *screenshotShortcutRecorder;
	IBOutlet SRRecorderControl *fileShortcutRecorder;
	PTHotKey *screenshotGlobalHotKey;
	PTHotKey *fileGlobalHotKey;
    IBOutlet SRRecorderControl *screenshotDelegateDisallowRecorder;
    IBOutlet SRRecorderControl *fileDelegateDisallowRecorder;
	IBOutlet NSTextField *screenshotDelegateDisallowReasonField;
	IBOutlet NSTextField *fileDelegateDisallowReasonField;
    
    IBOutlet NSButton *facebookAuthButton;
    AppController *sharedAppControllerManager;
    IBOutlet NSTextField *statusText;
}
@property (retain) PreferencesController *preferencesController;
@property (assign) IBOutlet NSButton *tryItOutButton;

- (IBAction)showPreferences:(id)sender;
- (IBAction)signInOutEvernoteClicked:(id)sender;
- (IBAction)signInOutTwitterClicked:(id)sender;
- (IBAction)takeScreenshotClicked:(id)sender;
- (IBAction)signInOutFacebookClicked:(id)sender;

- (GTMOAuthAuthentication *)authForEvernote;
- (void)signInToEvernote;
- (void)signOutEvernote;
- (BOOL)isSignedInEvernote;
- (void)setEvernoteAuthentication:(GTMOAuthAuthentication *)auth;
+ (BOOL)evernoteAuthSet;
+ (NSString *) getEvernoteAuthToken;

- (GTMOAuthAuthentication *)authForTwitter;
- (void)signInToTwitter;
- (void)signOutTwitter;
- (BOOL)isSignedInTwitter;
- (void)setTwitterAuthentication:(GTMOAuthAuthentication *)auth;
+ (BOOL)twitterAuthSet;
+ (NSString *) getTwitterAuthToken;
+ (void)sendTweet:(NSString *) link;

- (IBAction) uploadFacebookScreenshot: (id) sender;
    
- (void)doAnAuthenticatedAPIFetch;

- (void)windowController:(GTMOAuthWindowController *)windowController
        finishedWithAuth:(GTMOAuthAuthentication *)auth
                   error:(NSError *)error;
- (void)updateUI;
- (void)displayErrorThatTheCodeNeedsAnEvernoteConsumerKeyAndSecret;
- (void)signInFetchStateChanged:(NSNotification *)note;
- (void)signInNetworkLost:(NSNotification *)note;

+ (NSString *) generateTitle:(NSMutableArray*) itemPaths :(NSMutableArray *) itemExts;
+ (void) takeScreenshotWrapper:(NSArray *) args;

- (IBAction)toggleScreenshotGlobalHotKey:(id)sender;

+ (AppController*)sharedInstance;
    
@end
