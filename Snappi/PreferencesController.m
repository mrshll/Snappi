//
//  PreferenceController.m
//  Snappi
//
//  Created by Marshall Moutenot on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"
#import "AppController.h"

@implementation PreferencesController
@synthesize notebookPicker;

-(id)init{
    if (![super initWithWindowNibName:@"Preferences"])
        return nil;
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

- (void)populateNotebooks: (NSArray *) notebooks{
    if ([AppController evernoteAuthSet]){
        NSArray *notebookNames = [notebooks valueForKey:@"name"];
        for (int i = 0; i < [notebookNames count]; i++){
            [notebookPicker addItemWithObjectValue:[NSString stringWithString:[notebookNames objectAtIndex:i]]];
        }
        NSString *notebookPreference = [[NSUserDefaults standardUserDefaults] valueForKey:@"notebookTitle"];
        if (!notebookPreference || [notebookPreference isEqualToString:@""]){
            notebookPreference = @"Snappi";
        }
        NSUInteger selectedIndex = [notebookPicker indexOfItemWithObjectValue:notebookPreference];

        [notebookPicker selectItemAtIndex:selectedIndex];
        
    }
}

@end

