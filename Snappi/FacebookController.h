//
//  FacebookAppDelegate.h
//  Snappi
//
//  Created by Marshall Moutenot on 8/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PhFacebook/PhFacebook.h>

@interface FacebookController: NSObject <PhFacebookDelegate>
{
  id delegate;
  PhFacebook *fb;
  
  NSArray* friends;
  NSString* selectedFriend;
  NSString* shareLink;
}

- (void) getAccessToken;
- (void) postImage: (NSString *) imgPath: (NSString *)statusText;
- (void) postStatus: (NSString *) status;
- (void) populateFriends;
- (NSArray *) getFriends;
- (void) setSelectedFriend:(NSString *)taggedUser;
- (void) setShareLink:(NSString *)link;
- (BOOL) isSignedIn;
- (void)setDelegate:(id)delegate;
- (void) purge;

@end
