//
//  CustomView.m
//  NSStatusItemTest
//
//  Created by Matt Gemmell on 04/03/2008.
//  Copyright 2008 Magic Aubergine. All rights reserved.
//

#import "CustomView.h"
#import "AppController.h"


@implementation CustomView


- (id)initWithFrame:(NSRect)frame controller:(AppController *)ctrlr
{
    if (self = [super initWithFrame:frame]) {
        controller = ctrlr; // deliberately weak reference.
    }
    
    return self;
}


- (void)dealloc
{
    controller = nil;
    [super dealloc];
}

@end
