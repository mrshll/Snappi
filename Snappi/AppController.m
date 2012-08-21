//
//  AppController.m
//  Snappi
//
//  Created by Marshall Moutenot on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import <Carbon/Carbon.h>
#import "Finder.h"
#import "PTHotKeyCenter.h"
#import "PTHotKey.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);
@implementation AppController
@synthesize preferencesController;
@synthesize tryItOutButton;

static AppController *sharedAppControllerManager = nil;

static NSString *const kKeychainItemName = @"Evernote OAuth";
static NSString *const kTwitterKeychainItemName = @"Snappi Twitter OAuth";
static NSString *const kTwitterServiceName = @"Twitter";


+ (AppController*)sharedInstance {
    
    if (sharedAppControllerManager == nil) {        
        sharedAppControllerManager = [[AppController alloc] init];
    }
    
    return sharedAppControllerManager;
    
}

-(IBAction)showPreferences:(id)sender{
    [NSApp activateIgnoringOtherApps:YES];
        
    if(self.preferencesController)
        [self.preferencesController release];
    self.preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
    [self.preferencesController showWindow:self];
    if ([AppController evernoteAuthSet]){
        NSArray *notebooks = [[EvernoteScreenshot sharedInstance] listNotebooks];
        [self.preferencesController populateNotebooks:notebooks];
    }
}

- (void)dealloc {
    if(preferencesController)
        [preferencesController release];
    [super dealloc];
}

-(void)awakeFromNib {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];

    // register screenshot hotkey
    EventHotKeyRef myHotKeyRef;     
    EventHotKeyID myHotKeyID;     
    EventTypeSpec eventType;
    eventType.eventClass=kEventClassKeyboard;     
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(&myHotKeyHandler,1,&eventType,NULL,NULL);
    myHotKeyID.signature='mhk1';     
    myHotKeyID.id=1;
    RegisterEventHotKey(1, controlKey+cmdKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
    
    // had to remove the shortcut to upload files, as it is not allowed in the app sandbox
//    myHotKeyID.signature='mhk2';     
//    myHotKeyID.id=2;
//    RegisterEventHotKey(0, controlKey+cmdKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
    
    // facebook connection
    if (fbc == nil){
        fbc = [[FacebookController alloc] init];
        if (![appDelegate isFirstRun]) {
            [self signInFacebook];
        }
        NSLog(@"Authorized with Facebook");
    }
    
    if (mAuthEvernote == nil){
        GTMOAuthAuthentication *auth;
        auth = [GTMOAuthWindowController authForGoogleFromKeychainForName:kKeychainItemName];
        if ([auth canAuthorize]) {
            // Select the Google radio button
            NSLog(@"Authorized with Evernote");
        } else {
            auth = [self authForEvernote];
            if (auth) {
                BOOL didAuth = [GTMOAuthWindowController authorizeFromKeychainForName:kKeychainItemName
                                                                       authentication:auth];
                if (didAuth) {
                }
            }
        }
        // save the authentication object, which holds the auth tokens
        [self setEvernoteAuthentication:auth];
        
        // this is optional:
        //
        // we'll watch for the "hidden" fetches that occur to obtain tokens
        // during authentication, and start and stop our indeterminate progress
        // indicator during the fetches
        //
        // usually, these fetches are very brief
//        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
//        [nc addObserver:self
//               selector:@selector(signInEvernoteFetchStateChanged:)
//                   name:kGTMOAuthFetchStarted
//                 object:nil];
//        [nc addObserver:self
//               selector:@selector(signInEvernoteFetchStateChanged:)
//                   name:kGTMOAuthFetchStopped
//                 object:nil];
//        [nc addObserver:self
//               selector:@selector(signInNetworkLost:)
//                   name:kGTMOAuthNetworkLost
//                 object:nil];
    }
    if (mAuthTwitter == nil){
        GTMOAuthAuthentication *auth2;
        auth2 = [GTMOAuthWindowController authForGoogleFromKeychainForName:kTwitterKeychainItemName];
        if ([auth2 canAuthorize]){
            NSLog(@"Authorized with Twitter");
        } else {
            auth2 = [self authForTwitter];
            if (auth2) {
                BOOL didTwitterAuth = [GTMOAuthWindowController authorizeFromKeychainForName:kTwitterKeychainItemName authentication:auth2];
                
                if(didTwitterAuth){
                }
            }
        }
        [self setTwitterAuthentication:auth2];
    }
    
    [self updateUI];

}

- (IBAction)signInOutFacebookClicked:(id)sender{
    if ([fbc isSignedIn]){
        [fbc purge];
        [facebookAuthButton setTitle:@"Sign in to Facebook"];
    }
    else{
        [self signInFacebook];
        [facebookAuthButton setTitle:@"Sign out of Facebook"];
    }
}

- (void)signInFacebook{
    [fbc getAccessToken];
    [fbc populateFriends];
    NSLog(@"Authorized with Facebook");
}

- (IBAction)takeScreenshotClicked:(id)sender{
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    if ([mAuthEvernote hasAccessToken]){
        NSString *sguid = [[NSProcessInfo processInfo] globallyUniqueString];
        NSMutableArray *screenshotPath = [[NSMutableArray alloc] initWithObjects: 
                                          [NSString stringWithFormat: @"%@/%@.png",[appDelegate getTmpPath],sguid], nil] ;
        NSMutableArray *screenshotExt  = [[NSMutableArray alloc] initWithObjects: @"png", nil] ;
        NSArray *args = [NSArray arrayWithObjects:screenshotPath, screenshotExt, [NSNumber numberWithBool:false], nil];
        [AppController takeScreenshotWrapper:args];
    }
    else {
        [appDelegate showMessage:@"Don't forget to sign in!"];
        [appDelegate performSelector:@selector(hideComplete)
                          withObject:nil afterDelay:3];
        [tryItOutButton setTitle:@"Share a screenshot"];
    }
}

// handles when the shortcut action is pressed
OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {   
    
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    OSStatus result; 
    
    // vars for file case
//    FinderApplication *finder;
//    NSArray *items;
//    SBElementArray *selection;
//    NSURL *url;
    
    EventHotKeyID hkCom;
    GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
                      sizeof(hkCom),NULL,&hkCom);
    
    NSString *sguid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSMutableArray *screenshotPath = [[[NSMutableArray alloc] initWithObjects: 
                                      [NSString stringWithFormat: @"%@/%@.png",[appDelegate getTmpPath], sguid], nil] autorelease];
    NSMutableArray *screenshotExt  = [[[NSMutableArray alloc] initWithObjects: @"png", nil] autorelease];
    
    NSArray *args = [NSArray arrayWithObjects:screenshotPath, screenshotExt, [NSNumber numberWithBool:false], nil];
    switch (hkCom.id){
        default:
            result = noErr;
            break;
        case 1:
            [AppController takeScreenshotWrapper:args];
            result = noErr;
            break;
        // removing because it's not allowed by the apple sandboxing protocol
//        case 2:
//            finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.finder"];
//            selection = [[finder selection] get];
//            items = [selection arrayByApplyingSelector:@selector(URL)];
//            NSMutableArray *itemPaths = [[[NSMutableArray alloc] init] autorelease];
//            NSMutableArray *itemExts  = [[[NSMutableArray alloc] init] autorelease];
//            for (NSString * item in items) {
//                url = [NSURL URLWithString:item];
//                NSString *path = [url path]; 
//                [itemPaths addObject:path];
//                [itemExts addObject:[path pathExtension]];
//                NSLog(@"%@",url);
//            }
//            [AppController takeScreenshot:itemPaths :itemExts :true];
//            result = noErr; 
//            break;
    }
    return result;
}

+ (void) takeScreenshotWrapper:(NSArray *)args{
    NSString *fileDestination = [[NSUserDefaults standardUserDefaults] valueForKey:@"fileDestination"];
    NSString *screenshotDestination = [[NSUserDefaults standardUserDefaults] valueForKey:@"screenshotDestination"];
    // if there is one file, with a png extension, and in the tmp directory then it is a screenshot.
    BOOL isFile = [[args objectAtIndex:2] boolValue];
    // we have a screenshot, we need to route it appropriately
    if(!isFile){
        switch([screenshotDestination integerValue]){
            default:
                break;
            case 0:
                if(args && [args count] == 3)
                    [AppController takeEvernoteScreenshot:(NSMutableArray *)[args objectAtIndex:0] :(NSMutableArray*)[args objectAtIndex:1] :[[args objectAtIndex:2] boolValue]];
                    break;
            case 1:
                [AppController takeFacebookScreenshot:(NSMutableArray *)[args objectAtIndex:0]];
                break;
        }
    // otherwise we have a file
    } else {
        switch([fileDestination integerValue]){
            default:
                break;
            case 0:
                if(args && [args count] == 3)
                    [AppController takeEvernoteScreenshot:(NSMutableArray *)[args objectAtIndex:0] :(NSMutableArray*)[args objectAtIndex:1] :[[args objectAtIndex:2] boolValue]];
                break;
            case 1:
                // upload to dropbox
                break;
        }
    }
        
}

+ (NSTask *) getScreenShot:(NSArray *)paths{
    // Checking the connection
    NSString *launchPath = @"/usr/sbin/screencapture";
    
    // Set up the task
    NSTask *task = [[[NSTask alloc] init] autorelease];
    [task setLaunchPath:launchPath];
    NSArray	*args = [NSArray arrayWithObjects:@"-s", [paths objectAtIndex:0], nil];
    [task setArguments: args];
    
    // Set the output pipe.
    NSPipe *outPipe = [[[NSPipe alloc] init] autorelease];
    [task setStandardOutput:outPipe];
    
    [task launch];
    return task;
    
}
   
+ (void) takeFacebookScreenshot:(NSArray *)paths {
    @try{
        AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        if ([fbc isSignedIn]){
            // take screenshot
            NSTask *task = [self getScreenShot:paths];
            [task waitUntilExit];
            
            NSFileManager *man = [[NSFileManager alloc] init];
            if([[man attributesOfItemAtPath:[paths objectAtIndex:0] error:NULL] fileSize] != 0){
                facebookScreenshotPath = [paths objectAtIndex:0];
                [facebookScreenshotPath retain];
                
                // prompt for status text 
                [appDelegate showAddInfo];
            } else {
                // handle this differently?
            }
        } else {
            [appDelegate showMessage:@"Don't forget to sign in to facebook"];
        }
    }
    @catch (NSException *e){
        NSLog(@"%@",e);
    }
}

- (IBAction) uploadFacebookScreenshot: (id) sender {
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideAddInfo];
    [fbc postImage:facebookScreenshotPath:[statusText stringValue]];
    NSImage *thumb = [[[NSImage alloc] initWithContentsOfFile:facebookScreenshotPath] autorelease];
    [appDelegate showComplete:thumb];
    [appDelegate performSelector:@selector(hideComplete)
                      withObject:nil afterDelay:4];
}

- (IBAction) shareToFacebook: (id)sender {
    [fbc postStatus:@""];
}
    

+ (void) takeEvernoteScreenshot:(NSMutableArray *) itemPaths :(NSMutableArray *) itemExts:(BOOL) isFile{
     
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideMessage];
    if (![self evernoteAuthSet]){ 
        [appDelegate hideMessage];
        [appDelegate showMessage:@"Don't forget to sign into Evernote!"];
        [appDelegate performSelector:@selector(hideMessage)
                          withObject:nil afterDelay:4];
    }

    @try{
        NSString *notebookTitle = [[NSUserDefaults standardUserDefaults] valueForKey:@"notebookTitle"];
        NSString *putLinkInClipboard = [[NSUserDefaults standardUserDefaults] valueForKey:@"putLinkInClipboard"];
        NSString *shortenLink = [[NSUserDefaults standardUserDefaults] valueForKey:@"shortenLink"];
        NSString *addPreview = [[NSUserDefaults standardUserDefaults] valueForKey:@"addInfoOnUpload"];
        if (!addPreview) addPreview = @"1";
//        EvernoteScreenshot *es = [[[EvernoteScreenshot alloc] init] autorelease];
        EvernoteScreenshot *es = [EvernoteScreenshot sharedInstance];
        NSFileManager *man = [[NSFileManager alloc] init];
        UInt64 totalFileSize = 0;
        for (NSString *path in itemPaths){
            NSDictionary *attrs = [man attributesOfItemAtPath: path error: NULL];
            UInt32 result = [attrs fileSize];
            totalFileSize += result;
            [es.currentScreenshotPaths addObject:path];
        }
        for (NSString *ext in itemExts)
            [es.currentScreenshotExts addObject:[ext lowercaseString]];
        
        if ((!(totalFileSize > 50000000) && (totalFileSize != 0)) || !isFile){
            NSString* title; 
            if (isFile) title = [AppController generateTitle:itemPaths :itemExts];
            else {
                title = @"SnappiScreenshot";
                NSTask *task = [es getScreenShot];
                [task waitUntilExit];
            }
            for (NSString *path in itemPaths){
                NSTask *hashTask = [es createHash:path];
                [hashTask waitUntilExit];
            }
            // if we want to add post-note adding functionality.
            //            
            //            if([[[NSUserDefaults standardUserDefaults] valueForKey:@"addInfoOnUpload"] boolValue]){
            //                [appDelegate showAddInfo]
            //                // get data and make it the title/content
            //                [appDelegate resetCustomInfoSubmitted];
            //            }
            
            if((!isFile && [[man attributesOfItemAtPath:[itemPaths objectAtIndex:0] error:NULL] fileSize] != 0) || isFile){
                [appDelegate hideMessage];
                [appDelegate showLoading];
                NSArray *args = [NSArray arrayWithObjects:notebookTitle, putLinkInClipboard, shortenLink, title, addPreview, nil];
                NSArray *retVals = [es generateNoteWrapper:args];
                [appDelegate hideLoading];
                if (!retVals || [retVals count] < 1 || ![retVals objectAtIndex:0]){
                    [appDelegate hideMessage];
                    [appDelegate showMessage:@"File could not be uploaded.\nFolders not yet supported."];
                    [appDelegate performSelector:@selector(hideMessage)
                                      withObject:nil afterDelay:3];
                } else {
                    NSImage* thumb;
                    if([retVals count] == 2)
                        thumb = [retVals objectAtIndex:1];
                    else {
                        NSString *defThumbPath = [[NSBundle mainBundle] pathForResource: @"snappi_icon_g_50" ofType:@"png"];
                        thumb = [[NSImage alloc] initWithContentsOfFile:defThumbPath];
                    }
                    BOOL fileWasUploaded = [[retVals objectAtIndex:0] boolValue];
                    if (fileWasUploaded){
                        [appDelegate hideMessage];
                        [appDelegate showCompleteWithShare:thumb];
                        [appDelegate performSelector:@selector(hideComplete)
                                          withObject:nil afterDelay:4];
                    } else {
                        [appDelegate hideMessage];
                        [appDelegate showMessage:@"\n File could not be uploaded."];
                        [appDelegate performSelector:@selector(hideMessage)
                                          withObject:nil afterDelay:3];
                    }
                }
            }
        } else {
            [appDelegate hideMessage];
            [appDelegate showMessage:@"You have exceeded Evernote's maximum size\n"];
            [appDelegate performSelector:@selector(hideComplete)
                              withObject:nil afterDelay:4];
        }
        [[EvernoteScreenshot sharedInstance].currentScreenshotPaths removeAllObjects];
        [[EvernoteScreenshot sharedInstance].currentScreenshotExts removeAllObjects];
    }
    @catch (NSException *e){
        [appDelegate hideLoading];
        [appDelegate showMessage:@"Something went wrong!\nCheck your internet?"];
        NSLog(@"%@",e);
        [appDelegate performSelector:@selector(hideMessage)
                          withObject:nil afterDelay:4];
        
    }
}

+ (NSString *) generateTitle:(NSMutableArray*) itemPaths :(NSMutableArray *) itemExts{
    if ([itemPaths count] == 1) 
        return [[[itemPaths objectAtIndex:0] lastPathComponent] stringByDeletingPathExtension];
    else if ([itemPaths count] > 1){
        NSArray *exts = [[[NSSet alloc] initWithArray:itemExts] allObjects];
        if ([exts count] == 1){
            NSString *ext = [exts objectAtIndex:0];
            if([ext isEqualToString:@"mp3"] || [ext isEqualToString:@"wav"] || [ext isEqualToString:@"mpeg"] 
                                            || [ext isEqualToString:@"amr"] || [ext isEqualToString:@"flac"]){
                return @"Songs";
            }
            if([ext isEqualToString:@"doc"] || [ext isEqualToString:@"docx"] || [ext isEqualToString:@"pdf"] 
                                            || [ext isEqualToString:@"rtf"]  || [ext isEqualToString:@"txt"]){
                return @"Documents";
            }
            if([ext isEqualToString:@"avi"] || [ext isEqualToString:@"mp4"] || [ext isEqualToString:@"flv"] 
                                            || [ext isEqualToString:@"mkv"]){
                return @"Videos";
            }
            if([ext isEqualToString:@"cpp"] || [ext isEqualToString:@"h"]   || [ext isEqualToString:@"m"] 
                                            || [ext isEqualToString:@"js"]  || [ext isEqualToString:@"jsm"]
                                            || [ext isEqualToString:@"c"]   || [ext isEqualToString:@"java"] 
                                            || [ext isEqualToString:@"scm"]){
                return @"Code";
            }
            if([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"png"]   || [ext isEqualToString:@"gif"] 
                                            || [ext isEqualToString:@"jpeg"]  || [ext isEqualToString:@"psd"]) {
                return @"Images";
            }
        }
    }
    return @"Files";
}

// upload a file to the Evernote cloud
+ (void) uploadFile: (NSURL *) url{
    
}


//////////////////////////////////////////////////////////////////////
// authentication functions 
//////////////////////////////////////////////////////////////////////

- (void)doAnAuthenticatedAPIFetch {
    if([self isSignedInTwitter]){
        NSString *urlStr =@"http://api.twitter.com/1/statuses/home_timeline.json";
        
        
        NSURL *url = [NSURL URLWithString:urlStr];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [mAuthTwitter authorizeRequest:request];
        
        // Note that for a request with a body, such as a POST or PUT request, the
        // library will include the body data when signing only if the request has
        // the proper content type header:
        //
        //   [request setValue:@"application/x-www-form-urlencoded"
        //  forHTTPHeaderField:@"Content-Type"];
        
        // Synchronous fetches like this are a really bad idea in Cocoa applications
        //
        // For a very easy async alternative, we could use GTMHTTPFetcher
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:&response
                                                         error:&error];
        
        if (data) {
            // API fetch succeeded
            NSString *str = [[[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"API response: %@", str);
        } else {
            // fetch failed
            NSLog(@"API fetch error: %@", error);
        }
    } else {
        NSLog (@"Not logged in to twitter");
    }
}

- (void)windowController:(GTMOAuthWindowController *)windowController
        finishedWithAuth:(GTMOAuthAuthentication *)auth
                   error:(NSError *)error {
    NSString *scope = [auth scope];
    if (error != nil) {
        // Authentication failed (perhaps the user denied access, or closed the
        // window before granting access)
        NSLog(@"Authentication error: %@", error);
        NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // show the body of the server's authentication failure response
            NSString *str = [[[NSString alloc] initWithData:responseData
                                                   encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"%@", str);
        }
        
        if([scope isEqualToString:@"https://www.evernote.com"])
            [self setEvernoteAuthentication:nil];
        else if ([scope isEqualToString:@"https://api.twitter.com/"])
            [self setTwitterAuthentication:nil];
    } else {
        // Authentication succeeded
        //
        // At this point, we either use the authentication object to explicitly
        // authorize requests, like
        //
        //   [auth authorizeRequest:myNSURLMutableRequest]
        //
        // or store the authentication object into a Google API service object like
        //
        //   [[self contactService] setAuthorizer:auth];
        
        // save the authentication object
        if([scope isEqualToString:@"https://www.evernote.com"])
            [self setEvernoteAuthentication:auth];
        else if ([scope isEqualToString:@"http://api.twitter.com/"])
            [self setTwitterAuthentication:auth];
        
        // Just to prove we're signed in, we'll attempt an authenticated fetch for the
        // signed-in user
        //[self doAnAuthenticatedAPIFetch];
        
    }
    
    [self updateUI];
}


- (void)updateUI {
    // update the text showing the signed-in state and the button title
    if ([self isSignedInEvernote]) {
        // signed in
        BOOL isVerified = [[mAuthEvernote userEmailIsVerified] boolValue];
        if (!isVerified) {
            // email address is not verified
            //
            // The email address is listed with the account info on the server, but
            // has not been confirmed as belonging to the owner of this account.
        }
        //[mTokenField setStringValue:(token != nil ? token : @"")];
        //[mUsernameField setStringValue:(email != nil ? email : @"")];
        [mSignInOutEvernoteButton setTitle:@"Sign out of Evernote"];
        [connectTabView selectTabViewItemAtIndex:1];
    } else {
        // signed out
        //[mUsernameField setStringValue:@"-Not signed in-"];
        //[mTokenField setStringValue:@"-No token-"];
        [mSignInOutEvernoteButton setTitle:@"Sign in to Evernote"];
    }
    if ([self isSignedInTwitter]) {
        // signed in
        BOOL isVerified = [[mAuthTwitter userEmailIsVerified] boolValue];
        if (!isVerified) {
            // email address is not verified
            //
            // The email address is listed with the account info on the server, but
            // has not been confirmed as belonging to the owner of this account.
        }
        //[mTokenField setStringValue:(token != nil ? token : @"")];
        //[mUsernameField setStringValue:(email != nil ? email : @"")];
        [mSignInOutTwitterButton setTitle:@"Sign out of Twitter"];
        [instructionsTabView selectTabViewItemAtIndex:2];
    } else {
        // signed out
        //[mUsernameField setStringValue:@"-Not signed in-"];
        //[mTokenField setStringValue:@"-No token-"];
        [mSignInOutTwitterButton setTitle:@"Sign in to Twitter"];
    }
}

///////EVERNOTE/////////////

- (IBAction)signInOutEvernoteClicked:(id)sender {
    if (![self isSignedInEvernote]) {
        // sign in
        [self signInToEvernote];
    } else {
        // sign out
        [self signOutEvernote];
    }
    [self updateUI];
}

- (GTMOAuthAuthentication *)authForEvernote{
    
    NSString *myConsumerKey = @"mmoutenot";
    NSString *myConsumerSecret = @"618a872dcaee5ea1";
    
    if ([myConsumerKey length] == 0 || [myConsumerSecret length] == 0) {
        return nil;
    }
    
    GTMOAuthAuthentication *auth;
    auth = [[[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
                                                        consumerKey:myConsumerKey
                                                         privateKey:myConsumerSecret] autorelease];
    
    // setting the service name lets us inspect the auth object later to know
    // what service it is for
    [auth setServiceProvider:@"Evernote"];
    return auth;
}

- (void)signInToEvernote {
    
    [self signOutEvernote];
    
    NSURL *requestURL = [NSURL URLWithString:@"https://www.evernote.com/oauth"];
    NSURL *accessURL = [NSURL URLWithString:@"https://www.evernote.com/oauth"];
    NSURL *authorizeURL = [NSURL URLWithString:@"https://www.evernote.com/OAuth.action?format=mobile"];
    NSString *scope = @"https://www.evernote.com";
    
    GTMOAuthAuthentication *auth = [self authForEvernote];
    
    // set the callback URL to which the site should redirect, and for which
    // the OAuth controller should look to determine when sign-in has
    // finished or been canceled
    //
    // This URL does not need to be for an actual web page
    [auth setCallback:@"http://www.example.com/OAuthCallback"];
    
    GTMOAuthWindowController *windowController;
    windowController = [[[GTMOAuthWindowController alloc] initWithScope:scope
                                                               language:nil
                                                        requestTokenURL:requestURL
                                                      authorizeTokenURL:authorizeURL
                                                         accessTokenURL:accessURL
                                                         authentication:auth
                                                         appServiceName:kKeychainItemName
                                                         resourceBundle:nil] autorelease];
    [windowController signInSheetModalForWindow:mPrefWindow
                                       delegate:self
                               finishedSelector:@selector(windowController:finishedWithAuth:error:)];
}

- (BOOL)isSignedInEvernote {
    BOOL isSignedIn = [mAuthEvernote canAuthorize];
    return isSignedIn;
}

- (void)signInEvernoteFetchStateChanged:(NSNotification *)note {
    // this just lets the user know something is happening during the
    // sign-in sequence's "invisible" fetches to obtain tokens
    //
    // the type of token obtained is available as
    //   [[note userInfo] objectForKey:kGTMOAuthFetchTypeKey]
    //
    if ([[note name] isEqual:kGTMOAuthFetchStarted]) {
        [mSpinner startAnimation:self];
    } else {
        [mSpinner stopAnimation:self];
    }
}

- (void)signInEvernoteNetworkLost:(NSNotification *)note {
    // the network dropped for 30 seconds
    //
    // we could alert the user and wait for notification that the network has
    // has returned, or just cancel the sign-in sheet, as shown here
    GTMOAuthSignIn *signIn = [note object];
    GTMOAuthWindowController *controller = [signIn delegate];
    [controller cancelSigningIn];
}

- (void)signOutEvernote {
    if ([[mAuthEvernote serviceProvider] isEqual:kGTMOAuthServiceProviderGoogle]) {
        // remove the token from Google's servers
        [GTMOAuthWindowController revokeTokenForGoogleAuthentication:mAuthEvernote];
    }
    
    // remove the stored Evernote authentication from the keychain, if any
    [GTMOAuthWindowController removeParamsFromKeychainForName:kKeychainItemName];
    
    // discard our retains authentication object
    [self setEvernoteAuthentication:nil];
    
    [self updateUI];
}




- (void)setEvernoteAuthentication:(GTMOAuthAuthentication *)auth {
    [mAuthEvernote autorelease];
    mAuthEvernote = [auth retain];
}

+ (NSString *)getEvernoteAuthToken{
    return [mAuthEvernote token];
}

+ (BOOL) evernoteAuthSet{
    return [mAuthEvernote hasAccessToken];
}


// TWITTER //////////////////////////////////

- (IBAction)sendATestTweet:(id)sender{
//    [self doAnAuthenticatedAPIFetch];
    [AppController sendTweet:@"http://app.snppi.com"];
}

+ (void)sendTweet: (NSString *) link{
//    if ([self twitterAuthSet]){
//        NSString *status = [NSString stringWithFormat:@"%@ via @Snappi.", link];
//        NSString *body = [NSString stringWithFormat: @"status=%@", status]; 
//        NSString *urlStr = @"http://api.twitter.com/1/statuses/update.json"; 
//        NSURL *url = [NSURL URLWithString:urlStr]; 
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
//		[request setHTTPMethod:@"POST"]; 
//		[request setHTTPBody: [body dataUsingEncoding:NSUTF8StringEncoding]];
//		[mAuthTwitter authorizeRequest: request];
//		
//		GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];	
//		[myFetcher beginFetchWithCompletionHandler:^(NSData *retrievedData, NSError *error) {             
//            if (error != nil) { 
//                NSLog(@"POST error: %@", error); 
//            } 
//            else 
//            { 
//                NSString *results = [[[NSString alloc] initWithData:retrievedData encoding:NSUTF8StringEncoding] autorelease];
//                //                 NSDictionary *results = [[[[NSString alloc] initWithData: 
//                //                                            retrievedData encoding:NSUTF8StringEncoding] autorelease] JSONValue]; 
//                //                 NSLog(@"POST Successful: #%@ @ %@", [results objectForKey: 
//                //                                                      @"id"], [results objectForKey: @"created_at"]); 
//                NSLog(@"%@",results);
//            } 
//        }];     
//    }
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    NSString *defThumbPath = [[NSBundle mainBundle] pathForResource: @"snappi_icon_g_50" ofType:@"png"];
//    NSData *imgData = [[NSData alloc] initWithContentsOfFile:defThumbPath];
//    
//    // create the auth header for Twitter
//    NSString *twitterVerifyURLStr = @"https://api.twitter.com/1/account/verify_credentials.json";
//    NSURL *twitterURL = [NSURL URLWithString:twitterVerifyURLStr];
//    NSURL *url = [NSURL URLWithString:@"http://api.twitpic.com/1/upload.json"];
//    
//    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
//    
//    [request addPostValue:@"cc3765a58a7a94e65d8e57216acb5056" forKey:@"key"];
//    [request addPostValue:[mAuthTwitter consumerKey] forKey:@"consumer_token"];
//    [request addPostValue:[mAuthTwitter privateKey] forKey:@"consumer_secret"];
//    [request addPostValue:[mAuthTwitter token] forKey:@"oauth_token"];
//    [request addPostValue:[mAuthTwitter tokenSecret] forKey:@"oauth_secret"];
//    [request addPostValue:link forKey:@"message"];
//    [request addData:imgData forKey:@"media"];
//    
//    request.requestMethod = @"POST";
//    
//    [request startAsynchronous];
  
   ////////////////////////////////////////////////////////////////////////////////////////////////////
    if ([self twitterAuthSet]){
        NSString *defThumbPath = [[NSBundle mainBundle] pathForResource: @"snappi_icon_g_50" ofType:@"png"];
        NSData *imgData = [[NSData alloc] initWithContentsOfFile:defThumbPath];
        NSString* data = [[[NSString alloc] initWithData:imgData
                                                encoding:NSUTF8StringEncoding] autorelease];
        
        // create the auth header for Twitter
        NSString *twitterVerifyURLStr = @"http://api.twitter.com/1/account/verify_credentials.json";
        NSURL *twitterURL = [NSURL URLWithString:twitterVerifyURLStr];
        NSMutableURLRequest *tempRequest = [NSMutableURLRequest requestWithURL:twitterURL];
        [mAuthTwitter authorizeRequest:tempRequest];
        [mAuthTwitter addResourceTokenHeaderToRequest:tempRequest];
        // copy the auth header for Twitter into the TwitPic request
        NSString *twitterAuthHeader = [tempRequest valueForHTTPHeaderField:@"Authorization"];
        NSURL *twitPicURL = [NSURL URLWithString:@"http://api.twitpic.com/2/upload.json"];
        
        NSMutableURLRequest *twitPicRequest = [NSMutableURLRequest
                                               requestWithURL:twitPicURL
                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                               timeoutInterval:30.0];
        
        
        [twitPicRequest setValue:twitterAuthHeader forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
        [twitPicRequest setValue:twitterVerifyURLStr forHTTPHeaderField:@"X-Auth-Service-Provider"];
        
        [twitPicRequest addValue:@"cc3765a58a7a94e65d8e57216acb5056" forHTTPHeaderField:@"key"];
        [twitPicRequest addValue:@"test" forHTTPHeaderField:@"message"];
        [twitPicRequest addValue:data forHTTPHeaderField:@"media"];
        
        [twitPicRequest setHTTPMethod:@"POST"];
        [mAuthTwitter authorizeRequest: twitPicRequest];
        
        GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:twitPicRequest];
        [myFetcher beginFetchWithCompletionHandler:^(NSData *retrievedData, NSError *error) {
            if (error != nil) {
                NSLog(@"%@: POST error: %@",tempRequest, error);
            }
            else
            {
                NSDictionary *results = [[[[NSString alloc] initWithData:
                                           retrievedData encoding:NSUTF8StringEncoding] autorelease] JSONValue];
                NSLog(@"POST Successful: #%@ @ %@", [results objectForKey:
                                                     @"id"], [results objectForKey: @"created_at"]);
            }
        }];
    }

    
   ////////////////////////////////////////////////////////////////////////////////////////////////////
//    ASIFormDataRequest *req = [[ASIFormDataRequest alloc] initWithURL:
//                               [NSURL URLWithString:@"http://api.twitpic.com/2/upload.json"]];
//    
//    [req addRequestHeader:@"X-Auth-Service-Provider" value:@"https://api.twitter.com/1/account/verify_credentials.json"];
//    [req addRequestHeader:@"X-Verify-Credentials-Authorization"
//                    value:[oAuth oAuthHeaderForMethod:@"GET"
//                                               andUrl:@"https://api.twitter.com/1/account/verify_credentials.json"
//                                            andParams:nil]];
//     
//     NSString *defThumbPath = [[NSBundle mainBundle] pathForResource: @"snappi_icon_g_50" ofType:@"png"];
//     NSData *imgData = [[NSData alloc] initWithContentsOfFile:defThumbPath];
//     [req setData:imgData forKey:@"media"];
//     
//     // Define this somewhere or replace with your own key inline right here.
//     [req setPostValue:@"cc3765a58a7a94e65d8e57216acb5056" forKey:@"key"];
//     
//     // TwitPic API doc says that message is mandatory, but looks like
//     // it's actually optional in practice as of July 2010. You may or may not send it, both work.
//     [req setPostValue:@"hmm what" forKey:@"message"];
//     
//     [req startSynchronous];
//     
//     
//     
//     NSLog(@"Got HTTP status code from TwitPic: %d", [req
//                                                      responseStatusCode]);
//     NSDictionary *twitpicResponse = [[req responseString] JSONValue];
//     textView.text = [NSString stringWithFormat:@"Posted image URL: 
//                      %@", [twitpicResponse valueForKey:@"url"]]; 
//                      [req release];
    
    
}

- (IBAction)signInOutTwitterClicked:(id)sender {
    if (![self isSignedInTwitter]) {
        // sign in
        [self signInToTwitter];
    } else {
        // sign out
        [self signOutTwitter];
    }
    [self updateUI];
}

- (BOOL)isSignedInTwitter {
    BOOL isSignedIn = [mAuthTwitter canAuthorize];
    return isSignedIn;
}


- (GTMOAuthAuthentication *)authForTwitter {
    // Note: to use this sample, you need to fill in a valid consumer key and
    // consumer secret provided by Twitter for their API
    //
    // http://twitter.com/apps/
    //
    // The controller requires a URL redirect from the server upon completion,
    // so your application should be registered with Twitter as a "web" app,
    // not a "client" app
    NSString *myConsumerKey = @"CPSx8554tIo8VbcQfkEKw";
    NSString *myConsumerSecret = @"JeeYSQ5UwHeRdlMoTqRh8J1WSZFLcDdZysXOFxxU";
    
    if ([myConsumerKey length] == 0 || [myConsumerSecret length] == 0) {
        return nil;
    }
    
    GTMOAuthAuthentication *auth;
    auth = [[[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
                                                        consumerKey:myConsumerKey
                                                         privateKey:myConsumerSecret] autorelease];
    
    // setting the service name lets us inspect the auth object later to know
    // what service it is for
    [auth setServiceProvider:kTwitterServiceName];
    return auth;
}

- (void)signInToTwitter {
    
    [self signOutTwitter];
    
    NSURL *requestURL = [NSURL URLWithString:@"http://twitter.com/oauth/request_token"];
    NSURL *accessURL = [NSURL URLWithString:@"http://twitter.com/oauth/access_token"];
    NSURL *authorizeURL = [NSURL URLWithString:@"http://twitter.com/oauth/authorize"];
    NSString *scope = @"http://api.twitter.com/";
    
    mAuthTwitter = [self authForTwitter];
    if (!mAuthTwitter) {
    }
    
    // set the callback URL to which the site should redirect, and for which
    // the OAuth controller should look to determine when sign-in has
    // finished or been canceled
    //
    // This URL does not need to be for an actual web page
    [mAuthTwitter setCallback:@"http://www.example.com/OAuthCallback"];
    
    GTMOAuthWindowController *windowController;
    windowController = [[[GTMOAuthWindowController alloc] initWithScope:scope
                                                               language:nil
                                                        requestTokenURL:requestURL
                                                      authorizeTokenURL:authorizeURL
                                                         accessTokenURL:accessURL
                                                         authentication:mAuthTwitter
                                                         appServiceName:kTwitterKeychainItemName
                                                         resourceBundle:nil] autorelease];
    [windowController signInSheetModalForWindow:mPrefWindow
                                       delegate:self
                               finishedSelector:@selector(windowController:finishedWithAuth:error:)];
}
- (void)signInTwitterFetchStateChanged:(NSNotification *)note {
    // this just lets the user know something is happening during the
    // sign-in sequence's "invisible" fetches to obtain tokens
    //
    // the type of token obtained is available as
    //   [[note userInfo] objectForKey:kGTMOAuthFetchTypeKey]
    //
    if ([[note name] isEqual:kGTMOAuthFetchStarted]) {
        [mSpinner startAnimation:self];
    } else {
        [mSpinner stopAnimation:self];
    }
}


- (void)signOutTwitter {
    if ([[mAuthTwitter serviceProvider] isEqual:kGTMOAuthServiceProviderGoogle]) {
        // remove the token from Google's servers
        [GTMOAuthWindowController revokeTokenForGoogleAuthentication:mAuthTwitter];
    }
    
    // remove the stored Evernote authentication from the keychain, if any
    [GTMOAuthWindowController removeParamsFromKeychainForName:kTwitterKeychainItemName];
    
    // discard our retains authentication object
    [self setTwitterAuthentication:nil];
    
    [self updateUI];
}

- (void)setTwitterAuthentication:(GTMOAuthAuthentication *)auth {
//    [mAuthTwitter autorelease];
    mAuthTwitter = [auth retain];
}

+ (NSString *)getTwitterAuthToken{
    return [mAuthTwitter token];
}

+ (BOOL) twitterAuthSet{
    return [mAuthTwitter hasAccessToken];
}

/////////// SHORTCUT //////////////////////////////



- (IBAction)toggleScreenshotGlobalHotKey:(id)sender
{
	[screenshotShortcutRecorder setCanCaptureGlobalHotKeys:true];
	if (screenshotGlobalHotKey != nil)
	{
		[[PTHotKeyCenter sharedCenter] unregisterHotKey: screenshotGlobalHotKey];
		[screenshotGlobalHotKey release];
		screenshotGlobalHotKey = nil;
	}
    
	screenshotGlobalHotKey = [[PTHotKey alloc] initWithIdentifier:@"SRTest"
											   keyCombo:[PTKeyCombo keyComboWithKeyCode:[screenshotShortcutRecorder keyCombo].code
																			  modifiers:[screenshotShortcutRecorder cocoaToCarbonFlags: [screenshotShortcutRecorder keyCombo].flags]]];
	
	[screenshotGlobalHotKey setTarget: self];
	[screenshotGlobalHotKey setAction: @selector(hitHotKey:)];
	
	[[PTHotKeyCenter sharedCenter] registerHotKey: screenshotGlobalHotKey];
}

#pragma mark -

- (BOOL)screenshotShortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
	if (aRecorder == screenshotShortcutRecorder)
	{
		BOOL isTaken = NO;
		
		KeyCombo kc = [screenshotDelegateDisallowRecorder keyCombo];
		
		if (kc.code == keyCode && kc.flags == flags) isTaken = YES;
		
		*aReason = [screenshotDelegateDisallowReasonField stringValue];
		
		return isTaken;
	}
	
	return NO;
}

- (void)screenshotShortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	if (aRecorder == screenshotShortcutRecorder)
	{
		[self toggleScreenshotGlobalHotKey: aRecorder];
	}
}

- (IBAction)uploadTest:(id)sender{
    if ([self isSignedInEvernote]){
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        NSURL *directoryURL = [[[NSURL alloc] initWithString:@"/Users/mmoutenot/projects"] autorelease]; 
        NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
        
        NSDirectoryEnumerator *enumerator = [fileManager
                                             enumeratorAtURL:directoryURL
                                             includingPropertiesForKeys:keys
                                             options:0
                                             errorHandler:^(NSURL *url, NSError *error) {
                                                 // Handle the error.
                                                 // Return YES if the enumeration should continue after the error.
                                                 return YES;
                                             }];
        
        for (NSURL *url in enumerator) { 
            NSError *error;
            NSNumber *isDirectory = nil;
            if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                // handle error
            }
            else if (! [isDirectory boolValue]) {
                NSMutableArray *itemPaths = [[[NSMutableArray alloc] init] autorelease];
                NSMutableArray *itemExts  = [[[NSMutableArray alloc] init] autorelease];
                
                NSString *path = [url path]; 
                [itemPaths addObject: path];
                [itemExts  addObject: [path pathExtension]];
                NSLog(@"%@",itemPaths);
                NSArray *args = [NSArray arrayWithObjects:itemPaths, itemExts, [NSNumber numberWithBool:true], nil];
                //            NSLog(@"About to take the screenshot");
                if (args && [args count] > 0)
                    [AppController takeScreenshotWrapper: args];
            }
        }
    }
}

@end
