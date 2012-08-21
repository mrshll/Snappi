//
//  CustomView.h
//  NSStatusItemTest
//
//  Created by Matt Gemmell on 04/03/2008.
//  Copyright 2008 Magic Aubergine. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AppController;
@interface CustomView : NSView {
    __weak AppController *controller;
    BOOL clicked;
}

- (id)initWithFrame:(NSRect)frame controller:(AppController *)ctrlr;

@end
