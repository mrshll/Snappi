//
//  MainWindowControllerWindowController.m
//  Snapped
//
//  Created by Marshall Moutenot on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainWindowController.h"

@implementation MainWindowController
@synthesize introView;
@synthesize mainWindow;

-(id)init{
    if (![super initWithWindowNibName:@"mainWindow"])
        return nil;
    
    return self;
}

- (void) showIntro {
    //window.contentView = aView; // AND
     [mainWindow setContentView:introView];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

@end
