//
//  PreferenceController.h
//  Snappi
//
//  Created by Marshall Moutenot on 5/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController
@property (assign) IBOutlet NSComboBox *notebookPicker;

-(void)populateNotebooks: (NSArray*) notebooks;

@end
