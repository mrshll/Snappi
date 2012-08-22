#import "EvernoteScreenshot.h"
#import "CMDroppableView.h"
#import <QuickLook/QuickLook.h>
#import "MMMarkdown.h"

NSString * const userStoreUri = @"https://www.evernote.com/edam/user";
NSInteger currentFrame;
NSTimer *animTimer;
NSString * const devToken =
  @"S=s29:U=2f04ce:E=13f3513090a:C=137dd61dd0a:P=1cd:A=en-devtoken:H=870c3f166\
    d4ab9d2cc6275d70664f84f";

@implementation EvernoteScreenshot

@synthesize noteStoreUri, noteStore, noteShareUri, currentScreenshotPaths,
  currentScreenshotExts;

/************************************************************
 *
 *  Implementing the singleton pattern
 *
 ************************************************************/

static EvernoteScreenshot *sharedEvernoteManager = nil;

/************************************************************
 *
 *  Accessing the static version of the instance
 *
 ************************************************************/

+ (EvernoteScreenshot *)sharedInstance {

  if (sharedEvernoteManager == nil) {
    sharedEvernoteManager = [[EvernoteScreenshot alloc] init];
  }

  return sharedEvernoteManager;

}

-(id)init{
  self = [super init];
  currentScreenshotExts =  [[NSMutableArray alloc] init];
  currentScreenshotPaths = [[NSMutableArray alloc] init];
  return self;
}

/************************************************************
 *
 *  Connecting to the Evernote server using simple
 *  authentication
 *
 ************************************************************/

- (void) connect {

  if (noteStore == nil)
  {
    // In the case we are not connected we don't have an authToken
    // Instantiate the Thrift objects
    NSURL * NSURLuserStoreUri = [[[NSURL alloc] initWithString:
      userStoreUri] autorelease];

    THTTPClient *userStoreHttpClient = [[[THTTPClient alloc] initWithURL:
                                                NSURLuserStoreUri] autorelease];
    TBinaryProtocol *userStoreProtocol = [[[TBinaryProtocol alloc]
                            initWithTransport:userStoreHttpClient] autorelease];
    EDAMUserStoreClient *userStore = [[[EDAMUserStoreClient alloc]
                              initWithProtocol:userStoreProtocol] autorelease];

    // Check that we can talk to the server
    BOOL versionOk = [userStore checkVersion:@"Cocoa EDAMTest" :
                                   [EDAMUserStoreConstants EDAM_VERSION_MAJOR] :
                                   [EDAMUserStoreConstants EDAM_VERSION_MINOR]];

    if (!versionOk) {
      return;
    }

    noteStoreUri = [[[NSURL alloc] initWithString:[userStore
            getNoteStoreUrl:[AppController getEvernoteAuthToken]]] autorelease];

    [EvernoteScreenshot sharedInstance].noteShareUri =
              [[[NSString alloc] initWithString: [[noteStoreUri absoluteString]
            stringByReplacingOccurrencesOfString:@"notestore" withString:@"sh"]]
                                                                  autorelease];

    // Initializing the NoteStore client
    THTTPClient *noteStoreHttpClient = [[[THTTPClient alloc]
                                         initWithURL:noteStoreUri] autorelease];
    TBinaryProtocol *noteStoreProtocol = [[[TBinaryProtocol alloc]
                            initWithTransport:noteStoreHttpClient] autorelease];
    noteStore = [[[EDAMNoteStoreClient alloc]
                                    initWithProtocol:noteStoreProtocol] retain];
  }
}

/************************************************************
 *
 *  Listing all the user's notebooks
 *
 ************************************************************/

- (NSArray *) listNotebooks {
  // Checking the connection
  [self connect];

  // Calling a function in the API
  NSArray *notebooks =
    [[[NSArray alloc] initWithArray:[[self noteStore]
                      listNotebooks:[AppController getEvernoteAuthToken]]]
                      autorelease];
  return notebooks;
}


/************************************************************
 *
 *  Searching for notes using a EDAM Note Filter
 *
 ************************************************************/

- (EDAMNoteList *) findNotes: (EDAMNoteFilter *) filter {
  // Checking the connection
  [self connect];

  // Calling a function in the API
  return[noteStore findNotes:[AppController getEvernoteAuthToken]:filter:0:100];
}


/************************************************************
 *
 *  Loading a note using the guid
 *
 ************************************************************/

- (EDAMNote *) getNote: (NSString *) guid {
  // Checking the connection
  [self connect];

  // Calling a function in the API
  return [noteStore getNote:
             [AppController getEvernoteAuthToken]:guid :true :true :true :true];
}


/************************************************************
 *
 *  Deleting a note using the guid
 *
 ************************************************************/

- (void) deleteNote: (NSString *) guid {
  // Checking the connection
  [self connect];

  // Calling a function in the API
  [noteStore deleteNote:[AppController getEvernoteAuthToken]:guid];
}


//////////////////////////////////////////////////////////////////////
// the following three functions are used to update/animate the status icon
//////////////////////////////////////////////////////////////////////
/*
- (void)startAnimating
{
  currentFrame = 0;

  animTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0 target:self
                                             selector:@selector(updateImage:)
                                             userInfo:nil repeats:YES];

}

- (void)stopAnimating
{
  [animTimer invalidate];
}

- (void)updateImage:(NSTimer*)timer
{

  float width = 18.0;
  float height = [[NSStatusBar systemStatusBar] thickness];
  NSRect viewFrame = NSMakeRect(0, 0, width, height);
  NSString *imageAName = [[NSBundle mainBundle] pathForResource:
    [NSString stringWithFormat:@"snappi_icon_18",currentFrame] ofType:@"png"];
  NSString *imageBName = [[NSBundle mainBundle] pathForResource:
    [NSString stringWithFormat:@"snappi_icon_g_18",currentFrame] ofType:@"png"];
  NSImage *imageA = [[[NSImage alloc] initWithContentsOfFile:imageAName]
                                                                   autorelease];
  NSImage *imageB = [[[NSImage alloc] initWithContentsOfFile:imageBName]
                                                                   autorelease];

  //get the image for the current frame
  AppDelegate *appDelegate =
                    (AppDelegate *)[[NSApplication sharedApplication] delegate];

  if(currentFrame == 1){
    [[appDelegate getStatusView] setImage:imageA];
  } else {
    [[appDelegate getStatusView] setImage:imageB];
  }
  [[appDelegate getStatusView] drawRect:viewFrame];
  currentFrame = (currentFrame%2) + 1;
}
*/

/************************************************************
 *
 *  Creating a note
 *
 ************************************************************/

- (NSString *) getMimeType:(NSString *)ext{
   if([ext isEqualToString:@"gif"])  return @"image/gif";
   if([ext isEqualToString:@"jpeg"]) return @"image/jpeg";
   if([ext isEqualToString:@"jpg"])  return @"image/jpeg";
   if([ext isEqualToString:@"png"])  return @"image/png";
   if([ext isEqualToString:@"wav"])  return @"audio/wav";
   if([ext isEqualToString:@"mpeg"]) return @"audio/mpeg";
   if([ext isEqualToString:@"mp3"])  return @"audio/mpeg";
   if([ext isEqualToString:@"amr"])  return @"audio/amr";
   if([ext isEqualToString:@"pdf"])  return @"application/pdf";
   return @"application/zip";
}

- (NSString *) generateNoteTitle:(NSString *)title{
  // set note title
  CFGregorianDate currentDate =
                      CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent(),
                                                        CFTimeZoneCopySystem());
  SInt8 hour = currentDate.hour;
  NSString *ampm = @"am";
  if(hour > 12){
    ampm = @"pm";
    hour = hour-12;
  }
  NSString *datestring = [NSString stringWithFormat:@"%02d:%02d %@", hour,
                                                      currentDate.minute, ampm];
  NSString *titleContext = title;
  if([title isEqualToString:@"SnappiScreenshot"]){
    titleContext = @"Screenshot";
  }
  return [NSString stringWithFormat:@"%@ via Snappi @ %@", titleContext,
                                                                    datestring];
}

- (NSArray *) generateNoteWrapper:(NSArray *)args{
  if(args && [args count] == 5){
    NSArray* retVals = [[EvernoteScreenshot sharedInstance]
      generateNoteinNotebook:(NSString *)[args objectAtIndex:0]
                 inClipboard:(NSString *)[args objectAtIndex:1]
                 asShortened:(NSString *)[args objectAtIndex:2]
                   withTitle:(NSString *)[args objectAtIndex:3]
                 withPreview:(NSString *)[args objectAtIndex:4]];
    return retVals;
  }
  return nil;
}

- (NSArray *) generateNoteInNotebook:(NSString *) notebookTitle
                         inClipboard:(NSString *)putLinkInClipboard
                         asShortened:(NSString *)shortenLink
                           withTitle:(NSString *) title
                         withPreview:(NSString *) addPreview {

  BOOL fileUploaded = false;
  BOOL songUploaded = false;
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication]
                                                                      delegate];
  NSString *shareLink;

  EDAMNote *note = [EDAMNote alloc];
  NSString * ENML =
    [[[NSString alloc] initWithString: @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?> <!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"> <en-note> <div style=\"\"> <div style=\"background-attachment:scroll, scroll;background-color:rgb(209, 209, 209);background-image:url('http://app.snppi.com/enml/bg.png'), none;background-position:0% 0%, 0% 0%;background-repeat:repeat, repeat;background-clip:border-box, border-box;background-origin:padding-box, padding-box;background-size:auto auto, auto auto;\"> <div style=\"font-family:'Helvetica Neue Ultralight','Helvetica Neue',Arial,Helvetica,'Liberation Sans',FreeSans,sans-serif;color:rgb(88, 89, 87);font-size:13px;line-height:1.4;\"> <div style=\"height:40px;\"> </div> <div style=\"max-width:950px;padding-left:0px;padding-right:0px;padding-top:25px;padding-bottom:0px;background-attachment:scroll;background-color:rgb(244, 244, 244);background-image:none;background-position:0% 0%;background-repeat:repeat;background-clip:border-box;background-origin:padding-box;background-size:auto auto;margin-left:auto;margin-right:auto;margin-top:0px;margin-bottom:0px;border-radius:15px 15px 15px 15px;box-shadow:0px 1px 30px #000;\"> <div style=\"margin-left:25px;margin-right:25px;margin-top:0px;margin-bottom:0px;clear:left;\"> <div style=\"background-color:#E6E6E6;padding-left:10px;padding-right:10px;padding-top:10px;padding-bottom:10px;border-radius:5px 5px 5px 5px;margin-bottom:10px; box-shadow \"> <h1 style=\"color:#333;font-size:26px;text-shadow:0px 1px 1px #ffffff;filter:dropshadow(color=#ffffff, offx=0, offy=1);margin-top:0px;margin-bottom:0px;padding-bottom:0px;\">"]autorelease];

  note.title = [[EvernoteScreenshot sharedInstance] generateNoteTitle:title];

  ENML = [NSString stringWithFormat:@"%@%@</h1> </div> </div>",ENML,note.title];

  NSUInteger extIndex = 0;
  NSMutableArray *resources = [[NSMutableArray alloc] init];
  NSImage *thumb = nil;
  [thumb autorelease];
  for (NSString* path in currentScreenshotPaths){
    NSLog(@"Uploading file : %@", path);

    NSString *ext = [currentScreenshotExts objectAtIndex:extIndex];


    NSString* title = nil;
    [title autorelease];
    NSString* album = nil;
    [album autorelease];
    NSString* artist = nil;
    [artist autorelease];
    NSArray* artists = nil;
    [artists autorelease];
    NSString* albumArtPath = nil;
    [albumArtPath autorelease];
    if([ext isEqualToString:@"mp3"]){
      MDItemRef metadata = MDItemCreate(NULL, (CFStringRef)path);
      title  = (NSString *)MDItemCopyAttribute(metadata, kMDItemTitle);
      album  = (NSString *)MDItemCopyAttribute(metadata, kMDItemAlbum);
      artists = (NSArray *)MDItemCopyAttribute(metadata, kMDItemAuthors);
      if(artists)
        artist = [artists objectAtIndex:0];
    }

    NSString *markdownXHTML = @"";
    if([ext isEqualToString:@"markdown"] || [ext isEqualToString:@"md"]){
     NSString *rawMarkdown = [NSString stringWithContentsOfFile:path
                                         encoding:NSUTF8StringEncoding
                                            error:NULL];
     rawMarkdown = [NSString stringWithFormat:@"%@\n",rawMarkdown];
     NSError  *error;
     markdownXHTML = [MMMarkdown HTMLStringWithMarkdown:rawMarkdown
                                                                  error:&error];
    }

    NSDictionary *options =
      [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                              forKey:(NSString *)kQLThumbnailOptionIconModeKey];

    CFURLRef sourceUrl = (CFURLRef)[NSURL fileURLWithPath:path];

    CGSize albumArtSize = CGSizeMake(500, 500);

    if ([ext isEqualToString:@"mp3"]){
      albumArtSize = CGSizeMake(150,150);
    }


    CGImageRef ref = QLThumbnailImageCreate(kCFAllocatorDefault, sourceUrl,
                                        albumArtSize, (CFDictionaryRef)options);
    if(ref){
      albumArtPath =
        [[NSString stringWithFormat:@"%@/albumArt_%d.png",[appDelegate
                 getTmpPath],extIndex] stringByReplacingOccurrencesOfString:@" "
                                                                withString:@""];
      CFURLRef destUrl = (CFURLRef)[NSURL fileURLWithPath:albumArtPath];
      CGImageDestinationRef destination =
                  CGImageDestinationCreateWithURL(destUrl, kUTTypePNG, 1, NULL);
      CGImageDestinationAddImage(destination, ref, nil);

      if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
      }

      if(destination)
        CFRelease(destination);
    }

    // Loading the data of the image
    NSData *imageNSData = [[NSData alloc]
      initWithContentsOfFile: path];
    NSString * hash;
    EDAMResource * imageResource = nil;

    if (imageNSData) {
      // The user has selected an image
      NSLog(@"We have an image");

      NSError *error;
      hash =
        [[NSString alloc] initWithContentsOfFile:[NSString
                                stringWithFormat:@"%@/%@.md5", [appDelegate
                                getTmpPath],[[path lastPathComponent]
                                stringByDeletingPathExtension]]
                                encoding:NSUTF8StringEncoding error:&error];

      hash = [hash substringWithRange:NSMakeRange(0, [hash length] - 1)];

      // 1) create the data EDAMData using the hash, the size and the data of
      // the image
      EDAMData * imageData = [[EDAMData alloc] initWithBodyHash:[hash
                                              dataUsingEncoding:
                                     NSUTF8StringEncoding] size:[imageNSData
                                                   length] body:imageNSData];

      // 2) Create an EDAMResourceAttributes object with other important
      // attributes of the file
      EDAMResourceAttributes * imageAttributes =
                            [[[EDAMResourceAttributes alloc] init] autorelease];
      [imageAttributes setFileName: [path lastPathComponent]];

      // 3) create an EDAMResource the hold the mime the data and the attributes
      NSString *mimeType = [[EvernoteScreenshot sharedInstance]getMimeType:ext];
      // if it's an image, let's generate a thumbnail
      if ([currentScreenshotPaths count] == 1 && [mimeType
                                rangeOfString:@"image"].location != NSNotFound){
        thumb = [[NSImage alloc] initWithData:imageNSData];
      }

      imageResource = [[[EDAMResource alloc]init]autorelease];
      [imageResource setMime:mimeType];
      [imageResource setData:imageData];
      [imageResource setAttributes:imageAttributes];

      [resources addObject:imageResource];

      // Constructing the ENML code for the image to the content
      NSString * contextString = @"";
      //make a better context ^^^


      NSString *albumArtHash = nil;
      [albumArtHash autorelease];
      if(albumArtPath && [markdownXHTML isEqualToString:@""]){
        if ([mimeType rangeOfString:@"image"].location == NSNotFound){

          NSLog(@"%@", albumArtPath);
          [[EvernoteScreenshot sharedInstance] createHash:albumArtPath];

          albumArtHash =
            [[NSString alloc] initWithContentsOfFile:[NSString
                                    stringWithFormat:@"%@/albumArt_%d.md5",
            [appDelegate getTmpPath], extIndex] encoding:NSUTF8StringEncoding
                                               error:&error];

          albumArtHash =[albumArtHash substringToIndex:[albumArtHash length]-1];

          NSData *albumArtNSData= [[NSData alloc] initWithContentsOfFile:
                                                                  albumArtPath];

          // 1) create the data EDAMData using the hash, the size and the data
          // of the image
          EDAMData * albumArtData =
            [[EDAMData alloc] initWithBodyHash:[albumArtHash dataUsingEncoding:
                    NSUTF8StringEncoding] size:[albumArtNSData length]
                                          body:albumArtNSData];

          // 2) Create an EDAMResourceAttributes object with other important
          // attributes of the file
          EDAMResourceAttributes * albumArtAttributes =
                            [[[EDAMResourceAttributes alloc] init] autorelease];
          [albumArtAttributes setFileName: [albumArtPath lastPathComponent]];

          // if it's an image, let's generate a thumbnail
          if ([currentScreenshotPaths count] == 1){
            thumb = [[NSImage alloc] initWithData:albumArtNSData];
          }

          EDAMResource* albumArtResource =
                                        [[[EDAMResource alloc]init]autorelease];
          [albumArtResource setMime:@"image/png"];
          [albumArtResource setData:albumArtData];
          [albumArtResource setAttributes:albumArtAttributes];

          [resources addObject:albumArtResource];
        }
      }

      if(! [ext isEqualToString: @"mp3"]){
        NSString *alignStyle = @"text-align:center;";

        if (extIndex == 0)
          ENML = [ENML substringToIndex:[ENML length] - 7];

        if ([mimeType rangeOfString:@"image"].location == NSNotFound &&
          albumArtHash != nil && ![albumArtHash isEqualToString:@""] &&
                [addPreview boolValue] && [markdownXHTML isEqualToString:@""]){

          contextString = [NSString stringWithFormat:@"<en-media alt=\"albumart\" style=\"text-align:center;margin-left:auto;margin-right:auto;padding-left:0px;padding-right:10px;padding-top:8px;padding-bottom:10px;border-style:solid;-moz-border-top-colors:none;-moz-border-right-colors:none;-moz-border-bottom-colors:none;-moz-border-left-colors:none;-moz-border-image:none;border-color:#fff;border-width:1px 2px 2px 1px;border-radius:5px 5px 5px 5px;background-color:white;box-shadow:0px 1px 2px #C4C4C4;\" type=\"image/png\" hash=\"%@\"/>", albumArtHash];

        }

        else if (![markdownXHTML isEqualToString:@""]){

          contextString = markdownXHTML;
          alignStyle = @"";

        }

        ENML = [NSString stringWithFormat:@"%@<div style=\"%@margin-left:auto;margin-right:auto;margin-top:10px;margin-bottom:10px;padding-left:8px;padding-right:8px;padding-top:8px;padding-bottom:8px;max-width:800px;\">%@<br/><br/><en-media alt=\"Snappi Share\" style=\"margin-left:auto;margin-right:auto;margin-top:10px;margin-bottom:10px;padding-left:8px;padding-right:8px;padding-top:8px;padding-bottom:8px;border-style:solid;-moz-border-top-colors:none;-moz-border-right-colors:none;-moz-border-bottom-colors:none;-moz-border-left-colors:none;-moz-border-image:none;border-color:#fff;border-width:1px 2px 2px 1px;border-radius:5px 5px 5px 5px;background-color:white;max-width:800px; height:auto;box-shadow:0px 1px 2px #C4C4C4;\" type=\"%@\" hash=\"%@\"/></div> <br style=\"clear:both\"/>", ENML, alignStyle, contextString, mimeType, hash];

      } else {

        songUploaded = true;


        NSString * metaText = [[[NSString alloc] init] autorelease];

        if(title && ![title isEqualToString:@""]){
          metaText = title;
          if(artist && ![artist isEqualToString:@""]){
          metaText = [NSString stringWithFormat:@"%@ by %@", metaText, artist];
          }
          if(album && ![album isEqualToString:@""]){
            metaText = [NSString stringWithFormat:@"%@ off of %@", metaText,
                                                                        album];
          }
          metaText = [[[[[metaText stringByReplacingOccurrencesOfString: @"&"
                                                       withString: @"&amp;"]
            stringByReplacingOccurrencesOfString: @"\""withString: @"&quot;"]
            stringByReplacingOccurrencesOfString: @"'" withString: @"&apos;"]
            stringByReplacingOccurrencesOfString: @">" withString: @"gt;"]
            stringByReplacingOccurrencesOfString: @"<" withString: @"lt;"];

        }

        if([metaText isEqualToString:@""]){
          metaText = [[path lastPathComponent] stringByDeletingPathExtension];
        }

        // add album art and song
        ENML = [NSString stringWithFormat:@"%@<div style=\"font-size:13px;color:rgb(76, 74, 70);background-color:rgb(237, 246, 247);border-width:5px;border-style:solid;border-color:rgb(255, 255, 255);padding-left:40px;padding-right:40px;padding-top:9px;padding-bottom:9px;clear:both;box-shadow:0px 5px 3px rgba(0, 0, 0, 0.08);overflow:auto;margin-left:25px;margin-right:25px;margin-top:0px;margin-bottom:0px;\"> <h2 style=\"text-shadow:0px 1px 0px rgba(255, 255, 255, 0.5);padding-top:0px;color:rgb(49, 77, 77);font-size:16px;\">%@</h2> <p style=\"padding-left:0px;position:relative;\"><en-media alt=\"Snappi Share\" type=\"%@\" hash=\"%@\"/> <en-media alt=\"albumart\" style=\"float:left;padding-left:0px;padding-right:10px;padding-top:8px;padding-bottom:10px;width:150px;height:150px;\" type=\"image/png\" hash=\"%@\"/></p> </div>", ENML, metaText, mimeType, hash, albumArtHash];

      }
      fileUploaded = true;

    }
    extIndex = extIndex + 1;
  }

  if (fileUploaded){
    //        [appDelegate showLoading];
    // We are transforming the resource into a array to attach it to the note
    if(!songUploaded){
      ENML = [NSString stringWithFormat:@"%@%@", ENML, @"</div><br style=\"clear:both\"/>"];
    }
    ENML = [NSString stringWithFormat:@"%@%@", ENML, @"<div style=\"background-attachment:scroll;background-color:rgba(0, 0, 0, 0.46);background-image:none;background-position:0% 0%;background-repeat:repeat;background-clip:border-box;background-origin:padding-box;background-size:auto auto;height:20px;width:auto;float:right;margin-top:10px;margin-bottom:20px;padding-left:16px;padding-right:16px;padding-top:2px;padding-bottom:2px;border-radius:6px 6px 6px 6px;\"> <div style=\"color:rgb(255, 255, 255);text-decoration:none;font-size:14px;text-align:right;\">Powered By <a href=\"http://snppi.com/app/\" style=\"color:#66e770;text-decoration:none;\">Snappi</a></div> </div> </div> <div style=\"height:80px;\"></div> </div> </div> </div> </en-note> "];

    // Adding the content & resources to the note
    [note setContent:ENML];
    [note setResources:resources];

    note.notebookGuid = [[EvernoteScreenshot sharedInstance]
                                             getOrCreateNotebook:notebookTitle];

    // Create the note!
    EDAMNote *createdNote;
    @try {
      createdNote = [[EvernoteScreenshot sharedInstance] createNote:note];

    }
    @catch (EDAMUserException * e) {
      NSString * errorMessage =
        [NSString stringWithFormat:@"Error saving note: error code %i",
                                                                [e errorCode]];
      NSLog(@"%@",errorMessage);
      return nil;
    }

    // Add to the clipboard
    NSString *noteKey = [[EvernoteScreenshot sharedInstance]
                                                      getShareKey:createdNote];

    shareLink = [NSString stringWithFormat:@"%@/%@",
                [NSString stringWithFormat:@"%@/%@",
                [[EvernoteScreenshot sharedInstance] noteShareUri],
                                                    createdNote.guid], noteKey];

    if ([putLinkInClipboard boolValue]){
      if ([shortenLink boolValue])
        shareLink = [[EvernoteScreenshot sharedInstance] shortenURL:shareLink];

      [[EvernoteScreenshot sharedInstance]addToClipboard :shareLink];
    }

    // Add an item to the status bar menu
    NSMenuItem *mainItem = [[NSMenuItem alloc] init];
    [mainItem setTitle:note.title];
    NSMenu *subMenu = [[NSMenu alloc] init];
    NSMenuItem *item1 =
      [[NSMenuItem alloc] initWithTitle:@"Copy Shortlink"
                                 action:@selector(statusItemClicked:)
                          keyEquivalent:@""];
    [item1 setToolTip: [[[NSString alloc] initWithString: shareLink]
                                                                  autorelease]];
    [item1 setTarget: [EvernoteScreenshot sharedInstance]];
    NSMenuItem *item2 =
      [[NSMenuItem alloc] initWithTitle:@"View Stats"
                                 action:@selector(statsItemClicked:)
                          keyEquivalent:@""];
    [item2 setToolTip: [[[NSString alloc] initWithString: shareLink]
                                                                  autorelease]];
    [item2 setTarget: [EvernoteScreenshot sharedInstance]];
    [subMenu addItem:item1];
    [subMenu addItem:item2];

    [mainItem setSubmenu:subMenu];
    [[appDelegate getStatusMenu] addItem:mainItem];

  }
  [fbc setShareLink:shareLink];
  NSArray *retVals = [NSArray arrayWithObjects:[NSNumber
                                numberWithBool:fileUploaded], thumb, nil];
  return retVals;
}

- (void) addToClipboard:(NSString *)shareLink{
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard clearContents];
  [pasteboard setString:shareLink forType:NSPasteboardTypeString];
}

- (NSString *) getOrCreateNotebook:(NSString *) notebookName{
  EDAMNotebook *notebook = [EDAMNotebook alloc];
  notebook.name = notebookName;
  NSString *nguid = [NSString alloc];
  @try {
    EDAMNotebook *test = [[EvernoteScreenshot sharedInstance]
      createNotebook:notebook];
    nguid = [test guid];
  }
  @catch ( NSException *e ) {
    NSArray *notebooks = [self listNotebooks];
    for (id book in notebooks){
      NSLog(@"%@  =  %@", [book name], notebook.name);
      if ([[book name]isEqualToString: notebook.name]) {
        nguid = [book guid];
      }
    }
    NSLog(@"GUID: %@",nguid);
  }
  return nguid;
}

- (void) statusItemClicked:(NSMenuItem *) menuItem{
  NSLog(@"CLICKED");
  // this opens the url in a browser, but I would prefer to recopy it into the
  // clipboard...
  NSString *shareLink = [menuItem toolTip];
  [[EvernoteScreenshot sharedInstance] addToClipboard: shareLink];
  AppDelegate *appDelegate =
    (AppDelegate *)[[NSApplication sharedApplication] delegate];
  [appDelegate hideLoading];
  [appDelegate showMessage:@"The link has been copied! Ready to paste."];
  [appDelegate performSelector:@selector(hideComplete)
                    withObject:nil afterDelay:4];
}

- (void) statsItemClicked:(NSMenuItem *) menuItem{
  NSString *shareLink = [NSString stringWithFormat:@"%@+", [menuItem toolTip]];
  NSURL *statsUrl = [[[NSURL alloc] initWithString:shareLink] autorelease];
  [[NSWorkspace sharedWorkspace] openURL:statsUrl];
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


- (EDAMNote*) createNote: (EDAMNote *) note {
 [self connect];

 // Calling a function in the API
 return [noteStore createNote:[AppController getEvernoteAuthToken]:note];
}

- (EDAMNotebook*) createNotebook: (EDAMNotebook *) notebook {
 // Checking the connection
 [self connect];

 // Calling a function in the API
 return[noteStore createNotebook:[AppController getEvernoteAuthToken]:notebook];
}

- (NSString*) getShareKey:(EDAMNote *)note{
 [self connect];

 return [noteStore shareNote:[AppController getEvernoteAuthToken]:note.guid];
}

- (void)dealloc {
 [noteStore release];
 [super dealloc];
}

- (void) addScreenshotPath:(NSString *) path{
[currentScreenshotPaths addObject:path];
}

- (void) addScreenshotExt:(NSString *) ext{
[currentScreenshotExts addObject:ext];
}

- (NSTask *) getScreenShot{
 // Checking the connection
 NSString *launchPath = @"/usr/sbin/screencapture";

 // Set up the task
 NSTask *task = [[[NSTask alloc] init] autorelease];
 [task setLaunchPath:launchPath];
 NSLog(@"Capturing file at %@", [currentScreenshotPaths objectAtIndex:0]);
 NSArray	*args = [NSArray arrayWithObjects:@"-s",
          [currentScreenshotPaths objectAtIndex:0],
          nil];
 [task setArguments: args];

 // Set the output pipe.
 NSPipe *outPipe = [[[NSPipe alloc] init] autorelease];
 [task setStandardOutput:outPipe];

 [task launch];
 return task;

}

- (NSTask *) createHash:(NSString *) path {
  AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication]
                                                                      delegate];
  //generate the hash for the image into a file
  NSString *launchPath = @"/bin/sh";
  NSString* escPath = path;
  // Set up the task
  NSTask *task = [[[NSTask alloc] init] autorelease];
  [task setLaunchPath:launchPath];

  NSArray *args = [NSArray arrayWithObjects: @"-c",
                    [NSString stringWithFormat:@"md5 \"%@\" | awk -F'= ' '{ print $2 }' > \"%@/%@.md5\"",
                    escPath,
                    [appDelegate getTmpPath],
                    [[escPath lastPathComponent]stringByDeletingPathExtension]],
                    nil];

  [task setArguments: args];

  // Set the output pipe.
  NSPipe *outPipe = [[[NSPipe alloc] init] autorelease];
  [task setStandardOutput:outPipe];

  [task launch];
  [task waitUntilExit];
  return task;
}


@end








