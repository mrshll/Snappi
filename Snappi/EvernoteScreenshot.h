#import <Foundation/Foundation.h>

#import "THTTPClient.h"
#import "TBinaryProtocol.h"
#import "EDAMUserStore.h"
#import "EDAMNoteStore.h"
#import "EDAMErrors.h"

#import "AppController.h"
#import "AppDelegate.h"

extern NSString * const userStoreUri; 
extern NSString * const noteStoreUriBase;

@interface EvernoteScreenshot : NSObject <NSApplicationDelegate>{
    NSURL *noteStoreUri;
    NSString *noteShareUri;
    IBOutlet NSMenu *statusMenu;
    EDAMNoteStoreClient *noteStore;
    EvernoteScreenshot *sharedEvernoteManager;
    NSMutableArray *currentScreenshotPaths;
    NSMutableArray *currentScreenshotExts;
}

@property(retain) NSURL * noteStoreUri;
@property(retain) NSString * noteShareUri;
@property(retain) EDAMNoteStoreClient *noteStore;
@property(retain) NSMutableArray *currentScreenshotPaths;
@property(retain) NSMutableArray *currentScreenshotExts;

+ (EvernoteScreenshot *)sharedInstance;

- (void) addScreenshotPath:(NSString *) path;

- (void) addScreenshotExt:(NSString *) ext;

- (void) connect; 

- (NSArray *) listNotebooks;

- (EDAMNoteList *) findNotes: (EDAMNoteFilter *) filter;

- (EDAMNote *) getNote: (NSString *) guid;

- (void) deleteNote: (NSString *) guid;

- (EDAMNote *) createNote: (EDAMNote *) note;

- (NSString *) generateNoteTitle:(NSString *)title;

- (NSArray *) generateNoteWrapper:(NSArray *)args;

- (NSArray *) generateNote:(NSString *) notebookTitle :(NSString *)putLinkInClipboard :(NSString *)shortenLink :(NSString *) title :(NSString *) addPreview;

- (void) addToClipboard:(NSString *)shareLink;
    
- (NSString *) getOrCreateNotebook:(NSString *) notebookTitle;
    
- (NSTask *) getScreenShot;

- (NSTask *) createHash:(NSString *)path;

- (NSString *) getShareKey: (EDAMNote *) note;

- (NSString *) shortenURL: (NSString*)url;

@end
