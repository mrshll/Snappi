//
//  DropboxController.h
//  Snappi
//
//  Created by Marshall Moutenot on 8/23/12.
//
//

#import <Foundation/Foundation.h>
#import <DropboxOSX/DropboxOSX.h>
#import <WebKit/WebKit.h>

@interface DropboxController : NSObject <NSApplicationDelegate> {
  @public
  DBRestClient *restClient;
}

- (void) uploadFileWithPath:(NSString *) path;
  
@end
