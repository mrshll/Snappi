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
#import "DropboxController.h"
#import "CustomLocationController.h"
#import <DropboxOSX/DropboxOSX.h>

// Authentication item. I'm making this global because it needs to be shared
// across a lot of classes and I couldn't figure out how to make a class's
// variable accessed in a class method.
GTMOAuthAuthentication *mAuthEvernote;
GTMOAuthAuthentication *mAuthTwitter;
FacebookController *fbc;
DropboxController *dbc;
CustomLocationController *clc;

// holds the path to the screenshot for upload to facebook
NSString *facebookScreenshotPath;

@class PTHotKey;

@interface AppController : NSObject <NSApplicationDelegate>
{
  // drobox authentication object for making rest requests
  @private
    // buttons used to authenticate with various services
    IBOutlet NSButton *evernoteAuthButton;
    IBOutlet NSButton *twitterAuthButton;
    IBOutlet NSButton *facebookAuthButton;
    IBOutlet NSButton *dropboxAuthButton;

    // spinners to indicate pending auth requests
    IBOutlet NSProgressIndicator *evernoteSpinner;
    IBOutlet NSProgressIndicator *twitterSpinner;
    IBOutlet NSProgressIndicator *facebookSpinner;
    IBOutlet NSProgressIndicator *dropboxSpinner;

  
    IBOutlet NSTabView *instructionsTabView;
    IBOutlet NSTabView *connectTabView;

    // TODO: members to record a custom shortcut CURRENTLY UNUSED
    /* IBOutlet SRRecorderControl *screenshotShortcutRecorder; */
    /* IBOutlet SRRecorderControl *fileShortcutRecorder; */
    /* PTHotKey *screenshotGlobalHotKey; */
    /* PTHotKey *fileGlobalHotKey; */
    /* IBOutlet SRRecorderControl *screenshotDelegateDisallowRecorder; */
    /* IBOutlet SRRecorderControl *fileDelegateDisallowRecorder; */
    /* IBOutlet NSTextField *screenshotDelegateDisallowReasonField; */
    /* IBOutlet NSTextField *fileDelegateDisallowReasonField; */

    // was going to try to make a shared controller manager, but not worth it?
    /* AppController *sharedAppControllerManager; */

    // outlet to access the custom status users can enter for facebook
    IBOutlet NSTextField *facebookStatusText;
}

// button actions paired with their outlets
@property (retain) PreferencesController *preferencesController;
- (IBAction)showPreferences:(id)sender;

@property (assign) IBOutlet NSButton *tryItOutButton;
- (IBAction)takeScreenshotClicked:(id)sender;

// evernote
- (IBAction)signInOutEvernoteClicked:(id)sender;
- (void)signInToEvernote;
- (void)signOutEvernote;
- (GTMOAuthAuthentication *)authForEvernote;
- (BOOL)isSignedInEvernote;
- (void)setEvernoteAuthentication:(GTMOAuthAuthentication *)auth;
+ (BOOL)evernoteAuthSet;
+ (NSString *) getEvernoteAuthToken;

// twitter
- (IBAction)signInOutTwitterClicked:(id)sender;
- (GTMOAuthAuthentication *)authForTwitter;
- (void)signInToTwitter;
- (void)signOutTwitter;
- (BOOL)isSignedInTwitter;
- (void)setTwitterAuthentication:(GTMOAuthAuthentication *)auth;
+ (BOOL)twitterAuthSet;
+ (NSString *) getTwitterAuthToken;
+ (void)sendTweet:(NSString *) link;

// facebook
- (IBAction)signInOutFacebookClicked:(id)sender;
- (IBAction)uploadFacebookScreenshot:(id)sender;

// dropbox
- (IBAction)signInOutDropboxClicked:(id)sender;

// custom location
- (IBAction)createCustomLocation:(id)sender;

// used currently to test if twitter is working
- (void)doAnAuthenticatedAPIFetch;

// callback for authentication functions
- (void)windowController:(GTMOAuthWindowController *)windowController
        finishedWithAuth:(GTMOAuthAuthentication *)auth
                   error:(NSError *)error;
- (void)updateUI;
- (void)signInFetchStateChanged:(NSNotification *)note;
- (void)signInNetworkLost:(NSNotification *)note;

// generates the title of an upload (used for evernote and dropbox)
+ (NSString *) generateTitleForFiles:(NSMutableArray*) itemPaths
                      withExtensions:(NSMutableArray *) itemExts;

// routes the upload to the correct provider. Takes single array ARGS as the
// argument so that it can be spawned in the background using a selector
+ (void) uploadWrapper:(NSArray *) args;

// currently unused functions
- (IBAction)toggleScreenshotGlobalHotKey:(id)sender;
+ (AppController*)sharedInstance;

@end
