//
//  DragDropView.h
//  iBase64
//
//  Created by fankun on 12-9-4.
//  Copyright (c) 2012年 zfkun.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DropView;


@protocol DropViewDelegate <NSObject>

- (void)dropView:(DropView *)sender dropFiles:(NSArray *)files;

@end


@interface DropView : NSView <NSDraggingDestination>

@property (nonatomic) BOOL highlight;
@property (nonatomic, strong) id<DropViewDelegate> delegate;

@end
