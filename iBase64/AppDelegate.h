//
//  AppDelegate.h
//  iBase64
//
//  Created by fankun on 12-9-4.
//  Copyright (c) 2012年 zfkun.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Converter.h"
#import "DropView.h"
#import "WaitingView.h"


enum {
    ConvertRunModeAutomatic = 0,
    ConvertRunModeManual = 1
};

typedef NSUInteger ConvertRunMode;


@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, DropViewDelegate, ConverterDelegate>

{
    NSArray *_convertFileList;
    NSMutableArray *_waitFileList;
    NSUInteger _runMode;
}

@property (assign) IBOutlet NSWindow *window;

//@property (weak) IBOutlet NSArrayController *arrayController;
@property (weak) IBOutlet NSSegmentedControl *fixOptionSegmented;
@property (weak) IBOutlet NSSegmentedControl *runModeSegmented;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *progressLogTextField;
@property (weak) IBOutlet NSTextField *waitBadgeValueTextField;
@property (weak) IBOutlet Converter *converter;
@property (weak) IBOutlet DropView *dropView;
@property (weak) IBOutlet WaitingView *waitingView;


@end
