//
//  DropboxController.m
//  Snappi
//
//  Created by Marshall Moutenot on 8/23/12.
//
//

#import "DropboxController.h"
#import "AppDelegate.h"

@interface DropboxController () <DBRestClientDelegate>

- (DBRestClient *)restClient;

@end

@implementation DropboxController

- (DBRestClient *)restClient {
  if (!restClient) {
    restClient =
    [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    restClient.delegate = self;
  }
  return restClient;
}

- (void) uploadFileWithPath:(NSString *) path {
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication]
                                             delegate];
  [appDelegate showLoading:@"Uploading to Dropbox"];
  NSString *destDir = @"/Snappi/";
  [[self restClient] uploadFile:[path lastPathComponent] toPath:destDir
                  withParentRev:nil fromPath:path];
  NSLog(@"uploading file to dropbox");
}

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString*)link forFile:(NSString*)path
{
  NSString *shortURL = [self shortenURL:link];
  [self addToClipboard:shortURL];
}

- (NSString *) shortenURL:(NSString *) url
{
  CFStringRef legalStr = CFSTR("!@#$%^&()<>?{},;'[]");
  NSString *escUrl =
  [(NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                      (CFStringRef)url, NULL, legalStr, kCFStringEncodingUTF8) autorelease];
  NSString *apiEndpoint = [NSString stringWithFormat:@"http://snppi.com/yourls-api.php?signature=d5ed24bef1&action=shorturl&url=%@&format=simple",escUrl];
  NSError* error;
  NSString* shortURL =
  [NSString stringWithContentsOfURL:[NSURL URLWithString:apiEndpoint]
                           encoding:NSASCIIStringEncoding error:&error];
  if (shortURL)
    return shortURL;
  else
    return [error localizedDescription];
}

- (void) addToClipboard:(NSString *)shareLink{
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard clearContents];
  [pasteboard setString:shareLink forType:NSPasteboardTypeString];
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication]
                                             delegate];
  [[self restClient] loadSharableLinkForFile:
   [NSString stringWithFormat:@"/Snappi/%@",[destPath lastPathComponent]]];
  [appDelegate hideLoading];
  [appDelegate showComplete:nil];
  [appDelegate performSelector:@selector(hideComplete)
                    withObject:nil afterDelay:4];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication]
                                             delegate];
  [appDelegate showMessage:@"Something went wrong when uploading to Dropbox"];
  NSLog(@"File upload failed with error - %@", error);
}

@end
