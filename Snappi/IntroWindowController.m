//
//  IntroWindowController.m
//  Snappi
//
//  Created by Marshall Moutenot on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IntroWindowController.h"

@implementation IntroWindowController

- (id)init {
    if (![super initWithWindowNibName:@"Instructions"])
        return nil;
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

@end
