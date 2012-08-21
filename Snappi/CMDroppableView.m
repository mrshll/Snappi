//
//  CMDroppableView.m
//  Snappi
//
//  Created by Marshall Moutenot on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CMDroppableView.h"
#import "AppController.h"

@implementation CMDroppableView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    return self;
}

- (void)setMenu:(NSMenu *)menu {
    [menu setDelegate:self];
    [super setMenu:menu];
}

- (void)setImage:(NSImage *) img{
    image=img; 
    [image retain];
}

- (void)setStatusItem:(NSStatusItem *) statusIt{
    statusItem = statusIt; 
}

- (void)setAltImage:(NSImage *) img{
    alternateImage=img; 
    [alternateImage retain];
}

- (void)mouseDown:(NSEvent *)event {
    [statusItem popUpStatusItemMenu:[self menu]]; // or another method that returns a menu
}

- (void)menuWillOpen:(NSMenu *)menu {
    highlight = YES;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    highlight = NO;
    [self setNeedsDisplay:YES];
}

- (void)swapImages{
    NSImage *temp = image;
    image = alternateImage;
    alternateImage = temp;
    float width = 18.0;
    float height = [[NSStatusBar systemStatusBar] thickness];
    NSRect viewFrame = NSMakeRect(0, 0, width, height);
    [self drawRect: viewFrame];
}

- (void)drawRect:(NSRect)rect {
    
    if (highlight) {
        [[NSColor selectedMenuItemColor] set];
        NSRectFill(rect);
    } 
    
//    NSString *inFilePath = [[NSBundle mainBundle] pathForResource: @"snappi_icon_18" ofType:@"png"];
    
//    NSImage *img = [[[NSImage alloc] initWithContentsOfFile:inFilePath] autorelease];
    if(image)
        [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

    // rest of drawing code goes here, including drawing img where appropriate
}

-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender{
    NSLog(@"Drag Enter");
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate showMessage:@"Drop your file(s) here and\n let Snappi do the rest!"]; 
    return NSDragOperationCopy;
}

-(NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender{
    return NSDragOperationCopy;
}

-(void)draggingExited:(id <NSDraggingInfo>)sender{
    NSLog(@"Drag Exit");
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate hideMessage]; 
}

-(BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender{
     return YES;
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender{
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    if ([[pasteboard types] containsObject:NSFilenamesPboardType])
    {
        NSData* data = [pasteboard dataForType:NSFilenamesPboardType];
        if (data)
        {
            NSString* errorDescription;
            NSArray* filenames = [NSPropertyListSerialization
                                  propertyListFromData:data
                                  mutabilityOption:kCFPropertyListImmutable
                                  format:nil
                                  errorDescription:&errorDescription];
            
            NSMutableArray *itemPaths = [[[NSMutableArray alloc] init] autorelease];
            NSMutableArray *itemExts  = [[[NSMutableArray alloc] init] autorelease];
            
            for (NSString* filename in filenames)
            {   
//                NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"file://localhost%@", filename]];
//                NSString *path = [url path]; 
                [itemPaths addObject: filename];
                [itemExts  addObject:[filename pathExtension]];
            }
            NSLog(@"%@",itemPaths);
            NSArray *args = [NSArray arrayWithObjects:itemPaths, itemExts, [NSNumber numberWithBool:true], nil];
//            NSLog(@"About to take the screenshot");
            if (args && [args count] > 0)
                [AppController performSelector:@selector(takeScreenshotWrapper:)
                                    withObject:args afterDelay:1];
            
//            [AppController takeScreenshot:itemPaths :itemExts :true];
            return YES;
        }
    }

    return NO;
}


@end
