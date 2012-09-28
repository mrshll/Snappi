//
//  CustomLocationController.m
//  Snappi
//
//  Created by Marshall Moutenot on 8/23/12.
//
//

#import "CustomLocationController.h"
#import "AppDelegate.h"

@implementation CustomLocationController

// need to mimic EvernoteScreenshot.m. We could probably even just use that source directly and upload and embedd the sources manaully instead of using the Evernote api. COOL!
- (void) uploadFileWithPath:(NSArray *) paths andTakeScreenshot:(BOOL)screenshot {
  
  NSString *username =
  [[NSUserDefaults standardUserDefaults] valueForKey:@"customLocationUsername"];
  
  NSString *serverAddress=
  [[NSUserDefaults standardUserDefaults] valueForKey:@"customLocationServerAddress"];
  
  NSString *remotePath =
  [[NSUserDefaults standardUserDefaults] valueForKey:@"customLocationRemoteLocation"];
  
  NSString *serverCompound = [NSString stringWithFormat:@"%@@%@", username, serverAddress];

  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication]
                                             delegate];
  NSString *path = [paths objectAtIndex:0];

  if(screenshot) {
    NSTask *getScreenshot = [self getScreenShot:path];
    [getScreenshot waitUntilExit];
  }

  NSString* site = [NSString stringWithFormat:@"<html><body><div style=\\\"\\\"> <div style=\\\"background-attachment:scroll, scroll;background-color:rgb(209, 209, 209);background-image:url('http://app.snppi.com/enml/bg.png'), none;background-position:0% 0%, 0% 0%;background-repeat:repeat, repeat;background-clip:border-box, border-box;background-origin:padding-box, padding-box;background-size:auto auto, auto auto;\\\"> <div style=\\\"font-family:'Helvetica Neue Ultralight','Helvetica Neue',Arial,Helvetica,'Liberation Sans',FreeSans,sans-serif;color:rgb(88, 89, 87);font-size:13px;line-height:1.4;\\\"> <div style=\\\"height:40px;\\\"> </div> <div style=\\\"max-width:950px;padding-left:0px;padding-right:0px;padding-top:25px;padding-bottom:0px;background-attachment:scroll;background-color:rgb(244, 244, 244);background-image:none;background-position:0% 0%;background-repeat:repeat;background-clip:border-box;background-origin:padding-box;background-size:auto auto;margin-left:auto;margin-right:auto;margin-top:0px;margin-bottom:0px;border-radius:15px 15px 15px 15px;box-shadow:0px 1px 30px #000;\\\"> <div style=\\\"margin-left:25px;margin-right:25px;margin-top:0px;margin-bottom:0px;clear:left;\\\"> <div style=\\\"background-color:#E6E6E6;padding-left:10px;padding-right:10px;padding-top:10px;padding-bottom:10px;border-radius:5px 5px 5px 5px;margin-bottom:10px; box-shadow \\\"> <h1 style=\\\"color:#333;font-size:26px;text-shadow:0px 1px 1px #ffffff;filter:dropshadow(color=#ffffff, offx=0, offy=1);margin-top:0px;margin-bottom:0px;padding-bottom:0px;\\\">Screenshot via Snappi @ 11:54 pm</h1> </div><div style=\\\"text-align:center;margin-left:auto;margin-right:auto;margin-top:10px;margin-bottom:10px;padding-left:8px;padding-right:8px;padding-top:8px;padding-bottom:8px;max-width:800px;\\\"><br/><br/><img alt=\\\"Snappi Share\\\" style=\\\"margin-left:auto;margin-right:auto;margin-top:10px;margin-bottom:10px;padding-left:8px;padding-right:8px;padding-top:8px;padding-bottom:8px;border-style:solid;-moz-border-top-colors:none;-moz-border-right-colors:none;-moz-border-bottom-colors:none;-moz-border-left-colors:none;-moz-border-image:none;border-color:#fff;border-width:1px 2px 2px 1px;border-radius:5px 5px 5px 5px;background-color:white;max-width:800px; height:auto;box-shadow:0px 1px 2px #C4C4C4;\\\" src=\\\"%@\\\"/></div> <br style=\\\"clear:both;\\\"/></div><br style=\\\"clear:both\\\"/><div style=\\\"background-attachment:scroll;background-color:rgba(0, 0, 0, 0.46);background-image:none;background-position:0% 0%;background-repeat:repeat;background-clip:border-box;background-origin:padding-box;background-size:auto auto;height:20px;width:auto;float:right;margin-top:10px;margin-bottom:20px;padding-left:16px;padding-right:16px;padding-top:2px;padding-bottom:2px;border-radius:6px 6px 6px 6px;\\\"> <div style=\\\"color:rgb(255, 255, 255);text-decoration:none;font-size:14px;text-align:right;\\\">Powered By <a href=\\\"http://snppi.com/app/\\\" style=\\\"color:#66e770;text-decoration:none;\\\">Snappi</a></div> </div> </div> <div style=\\\"height:80px;\\\"></div> </div> </div> </div> </body></html>", [path lastPathComponent]];
  
  [appDelegate showLoading:@"Uploading to Custom Location"];
  NSTask* createRemoteFile = [self createRemoteFile:site withName:[[path lastPathComponent] stringByDeletingPathExtension] toDest:remotePath onServer:serverCompound];

  [createRemoteFile waitUntilExit];
  NSTask *upload =
    [self uploadFile:path
       toDestination: [NSString stringWithFormat:@"%@:%@", serverCompound, remotePath]];
  [upload waitUntilExit];
  [appDelegate hideLoading];
  NSString *shortURL = [self shortenURL:[NSString stringWithFormat:@"%@%@.html", remotePath, [[path lastPathComponent] stringByDeletingPathExtension]]];
  [self addToClipboard:shortURL];
  [appDelegate showComplete:nil];
  [appDelegate performSelector:@selector(hideComplete)
                    withObject:nil afterDelay:4];
}

- (NSTask *) createRemoteFile:(NSString *) fileContents withName:(NSString *) name toDest:(NSString *)dest onServer:(NSString *)server{
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication]
                                             delegate];
  //generate the hash for the image into a file
  NSString *launchPath = @"/bin/sh";
  // Set up the task
  NSTask *task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:launchPath];

  NSArray *args = [NSArray arrayWithObjects: @"-c",
                   [NSString stringWithFormat:@"ssh %@ -C 'echo \"%@\" > %@%@.html'",
                    server, fileContents, dest, name], nil];

  NSLog(@"%@",args);
  [task setArguments: args];

  // Set the output pipe.
  NSPipe *outPipe = [[[NSPipe alloc] init] autorelease];
  [task setStandardOutput:outPipe];

  [task launch];
  return task;
}

- (NSTask *) uploadFile:(NSString *) path toDestination:(NSString *) dest {
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication]
                                             delegate];
  //generate the hash for the image into a file
  NSString *launchPath = @"/bin/sh";
  // Set up the task
  NSTask *task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:launchPath];

  NSArray *args = [NSArray arrayWithObjects: @"-c",
                   [NSString stringWithFormat:@"scp %@ %@",
                    path, dest], nil];

  NSLog(@"%@",args);
  [task setArguments: args];

  // Set the output pipe.
  NSPipe *outPipe = [[[NSPipe alloc] init] autorelease];
  [task setStandardOutput:outPipe];

  [task launch];
  return task;
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

- (NSTask *) getScreenShot: (NSString *) path{
  // Checking the connection
  NSString *launchPath = @"/usr/sbin/screencapture";

  // Set up the task
  NSTask *task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:launchPath];
  NSArray	*args = [NSArray arrayWithObjects:@"-s",
                   path,
                   nil];
  [task setArguments: args];

  // Set the output pipe.
  NSPipe *outPipe = [[[NSPipe alloc] init] autorelease];
  [task setStandardOutput:outPipe];

  [task launch];
  return task;

}

@end
