//
//  DragDropView.m
//  iBase64
//
//  Created by fankun on 12-9-4.
//  Copyright (c) 2012年 zfkun.com. All rights reserved.
//

#import "DropView.h"


@implementation DropView

@synthesize highlight = _highlight;
@synthesize delegate = _delegate;


#pragma mark - NSView

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

//- (id)initWithFrame:(NSRect)frameRect
//{
//    NSLog(@"init with frame");
//    self = [super initWithFrame:frameRect];
//    
//    if (self) {
//        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
//    }
//    
//    return self;
//}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    if (self.highlight) {
        [[NSColor grayColor] set];
        [NSBezierPath setDefaultLineWidth: 5];
        [NSBezierPath strokeRect: [self bounds]];
    }
}



#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    self.highlight = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationGeneric;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    self.highlight = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    self.highlight = NO;
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];

    if ([[[draggedFilenames objectAtIndex:0] pathExtension] isEqual:@"css"]){
        return YES;
    } else {
        return NO;
    }
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
//    NSLog(@"delegate notify : %@, %@", self.delegate, draggedFilenames);
    
    // delegate notify
    [self.delegate dropView:self dropFiles:draggedFilenames];
}


@end
