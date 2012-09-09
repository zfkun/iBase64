//
//  WaitingView.m
//  iBase64
//
//  Created by fankun on 12-9-8.
//  Copyright (c) 2012年 zfkun.com. All rights reserved.
//

#import "WaitingView.h"

@implementation WaitingView

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}





@end
