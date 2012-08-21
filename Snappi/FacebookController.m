#import "FacebookController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"


@implementation FacebookController

- (FacebookController *) init
{
    FacebookController *fbc = [FacebookController alloc]; 
    fbc->fb = [[PhFacebook alloc] initWithApplicationID:@"340986745985159" delegate: self];
    
    return fbc;
}

- (void) getFriendsFinished:(ASIHTTPRequest *)request{
    // Use when fetching text data
    NSString *responseString = [request responseString];
    NSLog(@"Got Facebook Profile: %@", responseString);
    
    NSMutableDictionary *responseJSON = [responseString JSONValue];   
    NSMutableArray * feed = (NSMutableArray *) [responseJSON objectForKey:@"data"];
    NSMutableArray *friendsList = [[NSMutableArray alloc] init];
    
    //adding values to array
    for (NSDictionary *d in feed) {
        [friendsList addObject:d];
    }
    friends = [[NSArray alloc] initWithArray:friendsList];
}

- (void) populateFriends{
    NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/me/friends?access_token=%@", [fb.accessToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDidFinishSelector:@selector(getFriendsFinished:)];
    
    [request setDelegate:self];
    [request startAsynchronous];
}

- (NSArray *) getFriends {
    return friends;
}

- (void) getAccessToken
{
    // Always get a new token, don't get a cached one
    [fb getAccessTokenForPermissions: [NSArray arrayWithObjects: @"publish_stream", @"publish_actions", nil] cached: YES]; 
}

- (void) postImage: (NSString *) imgPath :(NSString *)statusText//:(NSString *)taggedUser
{
    NSString *fb_id = @"me";
    // get ID of tagged user, if any
    if(selectedFriend && ![selectedFriend isEqualToString:@""]){
        for (int i = 0; i < [friends count]; i++){
            if(selectedFriend == [[friends objectAtIndex:i] objectForKey:@"name"]){
                fb_id = [[friends objectAtIndex:i] objectForKey:@"id"];
            }
        }
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/photos?access_token=%@", fb_id, fb.accessToken]];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
    [request addFile:imgPath forKey:@"file"];
    
    [request setPostValue:statusText forKey:@"message"];
    
    
    [request startAsynchronous];
}

- (void) postStatus:(NSString *)status {
    if (!shareLink || [shareLink isEqualToString:@""]){
        NSLog(@"Link nil. Not going to share");
    }
    NSString *fb_id = @"me";
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/feed?access_token=%@", fb_id, fb.accessToken]];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
    [request setPostValue:[NSString stringWithFormat:@"%@ %@", shareLink, status] forKey:@"message"];
    [request setPostValue:shareLink forKey:@"link"];
    
    [request startAsynchronous];
    shareLink = @"";
}

- (void) setSelectedFriend:(NSString *)friendName{
    selectedFriend = friendName;
}

- (void) setShareLink:(NSString *)link{
    shareLink = link;
}

- (BOOL) isSignedIn{
    NSString *aT = [fb accessToken];
    return aT != nil;
}

- (void) purge {
    [fb invalidateCachedToken];
}

#pragma mark PhFacebookDelegate methods

- (void) tokenResult: (NSDictionary*) result
{
    if ([[result valueForKey: @"valid"] boolValue])
    {
        [fb sendRequest: @"me/picture"];
    }
    else
    {
        NSLog(@"Error Connecting to Facebook");
    }
}


- (void) willShowUINotification: (PhFacebook*) sender
{
    [NSApp requestUserAttention: NSInformationalRequest];
}

@end