//
//  CMDroppableView.h
//  Snappi
//
//  Created by Marshall Moutenot on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CMDroppableView : NSView <NSMenuDelegate> {
    NSStatusItem *statusItem;
    BOOL highlight;
    NSImage *image;
    NSImage *alternateImage;
}

- (id)initWithFrame:(NSRect)frame;

- (void)setMenu:(NSMenu *)menu;

- (void)setImage:(NSImage *) img;

- (void)setAltImage:(NSImage *) img;

- (void)drawRect:(NSRect)rect;
    
- (void)setStatusItem:(NSStatusItem *) statusIt;

- (void)swapImages;
    
@end
