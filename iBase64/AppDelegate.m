//
//  AppDelegate.m
//  iBase64
//
//  Created by fankun on 12-9-4.
//  Copyright (c) 2012年 zfkun.com. All rights reserved.
//

#import "AppDelegate.h"

#define FORMAT_WAIT_BADGEVALUE @"(%ld)"

@implementation AppDelegate


//@synthesize arrayController = _arrayController;
@synthesize fixOptionSegmented = _fixOptionSegmented;
@synthesize runModeSegmented = _runModeSegmented;
@synthesize progressIndicator = _progressIndicator;
@synthesize progressLogTextField = _progressLogTextField;
@synthesize waitBadgeValueTextField = _waitBadgeValueTextField;
@synthesize converter = _converter;
@synthesize dropView = _dropView;
@synthesize waitingView = _waitingView;



#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // 待处理队列初始化
    _waitFileList = [[NSMutableArray alloc] init];
    // 处理种队列初始化
    _convertFileList = [[NSArray alloc] init];
    
    // 设置转换模式
    _runMode = ConvertRunModeAutomatic;
    
    // 设置 转换器代理 | 拖放区代理 | 等候区数据源
    self.converter.delegate = self;
    self.dropView.delegate = self;
    self.waitingView.dataSource = self;
//    self.progressIndicator.usesThreadedAnimation = YES;
    
    // 设置 转换器 自动修复配置
    self.converter.fixWhiteSpace = [self.fixOptionSegmented isSelectedForSegment:0];
    self.converter.fixSingleQuotes = [self.fixOptionSegmented isSelectedForSegment:1];
    self.converter.fixDoubleQuotes = [self.fixOptionSegmented isSelectedForSegment:2];
    
    // 等候区 badgeValue
    [self updateWaitBadgeValueTo:0];
    
    // 注册 URL Scheme 处理方法
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}




#pragma mark - Private

- (void)updateWaitBadgeValueTo:(NSInteger)number
{
    [self.waitBadgeValueTextField setStringValue:[NSString stringWithFormat:FORMAT_WAIT_BADGEVALUE, number]];
}

- (void)showProgressLogWithText:(NSString *)text
{
    if (self.progressLogTextField.isHidden) {
        [self.progressLogTextField setHidden:NO];
    }
    
    [self.progressLogTextField setStringValue:text];
}

- (void)doCleanTaskOnConvertFinished
{
    [self.progressIndicator setHidden:YES];
    [self.progressLogTextField setHidden:YES];
//    [_convertFileList removeAllObjects];
    
    // 检查 等候区 是否需要继续处理
    [self checkWaitingList:_waitFileList startIfNotEmpty:_runMode == ConvertRunModeAutomatic];
}

- (void)checkWaitingList:(NSArray *)fileList startIfNotEmpty:(BOOL)autoStart
{
    if ([fileList count] == 0 || !autoStart) {
        return;
    }
    
    _convertFileList = [fileList copy];
    [self.converter startWithFileList:_convertFileList];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    // enum `keyDirectObject` : '----'
    NSString *url = [[event descriptorForKeyword:keyDirectObject] stringValue];

//    NSLog(@"handleURLEvent: %@ , replay: %@", event, replyEvent);
    [[NSAlert alertWithMessageText:@"URL Request"
                    defaultButton:@"OK"
                  alternateButton:nil
                      otherButton:nil
        informativeTextWithFormat:@"%@", url] runModal];
    
    // TODO: 解析url，快速执行任务
    // ...
}




#pragma mark - IBActions

- (IBAction)fixOptionChange:(NSSegmentedControl *)sender
{
    NSInteger clickedSegemnt = sender.selectedSegment;
    NSInteger clickedTag = [[sender cell] tagForSegment:clickedSegemnt];
    BOOL isSeleted = [sender isSelectedForSegment:clickedSegemnt];
    
    //    NSLog(@"clicked segment: %ld, tag: %ld", clickedSegemnt, clickedTag);
    
    if (clickedTag == 0) { // 空白
        self.converter.fixWhiteSpace = isSeleted;
    } else if (clickedTag == 1) { // 单引号
        self.converter.fixSingleQuotes = isSeleted;
    } else if (clickedTag == 2) { // 双引号
        self.converter.fixDoubleQuotes = isSeleted;
    }
}

- (IBAction)runModeChange:(NSSegmentedControl *)sender
{
    NSInteger clickedSegemnt = sender.selectedSegment;
    NSInteger clickedTag = [[sender cell] tagForSegment:clickedSegemnt];
//    BOOL isSeleted = [sender isSelectedForSegment:clickedSegemnt];
  
    if (clickedTag == 0) { // 手动
        _runMode = ConvertRunModeManual;
    } else if (clickedTag == 1) { // 自动
        _runMode = ConvertRunModeAutomatic;
        
        // 若空闲, 则自动启动
        if (!self.converter.isBusy) {
            [self checkWaitingList:_waitFileList startIfNotEmpty:YES];
        }
    }
}





#pragma mark - DropViewDelegate

- (void)dropView:(DropView *)sender dropFiles:(NSArray *)files
{
    // 当前等候队列计数
    NSUInteger waitTotal = [_waitFileList count];
    
    // 过滤出新增数据，加入等候队列 
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", _waitFileList];
    [_waitFileList addObjectsFromArray:[files filteredArrayUsingPredicate:predicate]];
    
    // 没有新数据，直接忽略退出
    if ([_waitFileList count] <= waitTotal) {
        return;
    }
    
    // 加入了新数据, 刷新Talbe
    [self.waitingView reloadData];
    
    // 更新等候区统计数
    [self updateWaitBadgeValueTo:[_waitFileList count]];
    
    if (self.converter.busy) {
        // TODO:
        // ...some tips
    } else {
        // 检查 等候区 是否需要继续处理
        [self checkWaitingList:_waitFileList startIfNotEmpty:_runMode == ConvertRunModeAutomatic];
    }
}




#pragma mark - ConverterDelegate

- (void)converterDidStart:(Converter *)sender
{
    [self.progressIndicator setHidden:NO];
    [self showProgressLogWithText:@"转换开始..."];
}

- (void)converterDidFinished:(Converter *)sender
{
    [self showProgressLogWithText:@"转换完毕!"];

    // 这里不能直接设置 hidden 会看不到过渡动画，加个延迟规避
    [self performSelector:@selector(doCleanTaskOnConvertFinished) withObject:nil afterDelay:1];
}

- (void)converter:(Converter *)sender willConvertFileAtIndex:(NSInteger)index totalOfFiles:(NSInteger)total
{
    [self.waitingView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:YES];
}

- (void)converter:(Converter *)sender didConvertFileAtIndex:(NSInteger)index totalOfFiles:(NSInteger)total success:(BOOL)success
{
    [self showProgressLogWithText:[NSString stringWithFormat:@"%@ (%ld/%ld): %@", success ? @"完成" : @"失败", index + 1, total, [_convertFileList objectAtIndex:index]]];
    
//    NSLog(@"%@ (%ld/%ld): %@", success ? @"完成" : @"失败", index + 1, total, [_convertFileList objectAtIndex:index]);
    
    // 注意: 这里的 index 一定要转换成 double , 否则 除法运算后会自动省略小数部分损失精度，总是0
    self.progressIndicator.doubleValue = (((double)index + 1) / total) * 100;
    
    if (success) {
        [_waitFileList removeObject:[_convertFileList objectAtIndex:index]];
        [self.waitingView reloadData];
        [self updateWaitBadgeValueTo:[_waitFileList count]];
    }
}





#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
//    NSLog(@"number rows = %ld", [_waitFileList count]);
    return [_waitFileList count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{

    NSString *fileFullPath = [_waitFileList objectAtIndex:row];
    
    if ([[tableColumn identifier] isEqualToString:@"fileFullPath"]) {
        // do nonthing
    } else if ([[tableColumn identifier] isEqualToString:@"fileName"]) {
        // get file extension
        fileFullPath = [fileFullPath lastPathComponent];
    }
    
//    NSLog(@"column = %@, row = %@", [tableColumn identifier], fileFullPath);
    
    return fileFullPath;
}





@end
