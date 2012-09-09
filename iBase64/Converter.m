//
//  Converter.m
//  iBase64
//
//  Created by fankun on 12-9-5.
//  Copyright (c) 2012年 zfkun.com. All rights reserved.
//

#import "Converter.h"
#import "NSData+Base64.h"
#import "RegexKitLite.h"

#define REGEX_NEW_LINE @"\\r\\n"
#define REGEX_BG_IMG @"url\\([\\s\\'\\\"]*([^\\s\\\"\\')]*)[\\s\\'\\\"]*\\)"
#define REGEX_BG_IMG_CAPTURE 1
#define REGEX_WHITESPACE_IN_URL @"(?:url\\()\\s*(\\S*)\\s*(?:\\))"
#define REGEX_SINGLEQUOTE_IN_URL @"(?:url\\()(\\s*)(?:\\'*)([^\\)\\'\\\"]*)(?:\\'*)(\\s*)(?:\\))"
#define REGEX_DOBULEQUOTE_IN_URL @"(?:url\\()(\\s*)(?:\\\"*)([^\\)\\'\\\"]*)(?:\\\"*)(\\s*)(?:\\))"

#define TEMPLATE_REGEX_WHITESPACE @"url(%@)"
#define TEMPLATE_REGEX_SINGLEQUOTE @"url(%@%@%@%@%@)"
#define TEMPLATE_REGEX_DOBULEQUOTE @"url(%@%@%@%@%@)"
#define TEMPLATE_DATA_URI_SCHEME @"data:%@;base64,%@"


@implementation Converter

@synthesize delegate = _delegate;
@synthesize busy = _busy;
@synthesize fixWhiteSpace = _fixWhiteSpace;
@synthesize fixSingleQuotes = _fixSingleQuotes;
@synthesize fixDoubleQuotes = _fixDoubleQuotes;
@synthesize fixWhiteSpaceByReplaceWith = _fixWhiteSpaceByReplaceWith;
@synthesize fixQuotesByReplaceWith = _fixQuotesByReplaceWith;



#pragma mark - NSView Ciycle

- (id)init
{
    self = [super init];
    
    if (self) {
        _fileList = [[NSArray alloc] init];
        [self setupDefaultOptions];
    }

    return self;
}

- (id)initWithFileList:(NSArray *)fileList
{
    self = [super init];

    if (self) {
        _fileList = [[NSArray alloc] initWithArray:fileList];
        [self setupDefaultOptions];
    }

    return self;
}

- (BOOL)isBusy
{
    return _isBusy;
}



#pragma mark - Public API Implements

- (void)setupDefaultOptions
{
    self.fixWhiteSpace = YES;
    self.fixSingleQuotes = NO;
    self.fixDoubleQuotes = NO;
    self.fixWhiteSpaceByReplaceWith = @"";
    self.fixQuotesByReplaceWith = @"\"";
}

//- (BOOL)appendFile:(NSString *)file
//{
//    if (self.isBusy) {
//        return NO;
//    }
//    
//    [_fileList addObject:file];
//    
//    return YES;
//}

- (void)start
{
    if (!self.isBusy) {
        _isBusy = YES;
        
        if ([self.delegate respondsToSelector:@selector(converterDidStart:)]) {
            [self.delegate converterDidStart:self];
        }
        
        // 开新线程
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self performConvert];
            
            if ([self.delegate respondsToSelector:@selector(converterDidFinished:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate converterDidFinished:self];
                });
            }
        });
    }
}

- (void)startWithFileList:(NSArray *)fileList
{
    if (!self.isBusy) {
//        [_fileList removeAllObjects];
//        [_fileList addObjectsFromArray:fileList];
        _fileList = fileList;

        [self start];
    }
}

- (void)stop
{
    // TODO:
    if (self.busy) {
        // TODO:
        //....
        _isBusy = NO;
    }
}



#pragma mark - Private Methods Implements

- (void)performConvert
{
    NSString *filePath = nil;
    BOOL result = false;
    for (NSInteger index = 0, total = [_fileList count]; index < total; index++) {
        if (!_isBusy) {
            if ([self.delegate respondsToSelector:@selector(converterDidStoped:)]) {
                [self.delegate converterDidStoped:self];
            }
            break;
        }
        
        filePath = [_fileList objectAtIndex:index];
        
        if ([self.delegate respondsToSelector:@selector(converter:willConvertFileAtIndex:totalOfFiles:)]) {
            [self.delegate converter:self willConvertFileAtIndex:index totalOfFiles:total];
        }
        
        result = [self doConvert:filePath];
        
        if ([self.delegate respondsToSelector:@selector(converter:didConvertFileAtIndex:totalOfFiles:success:)]) {
            [self.delegate converter:self
               didConvertFileAtIndex:index
                        totalOfFiles:total
                             success:result];
        }
    }
    
    // 重置标志
    _isBusy = false;
}

- (BOOL)doConvert:(NSString *)filePath
{
//    // 当前 CSS 文件路径 (用作后面图片的路径计算 参考基准)
//    NSString *filePath = [self.fileList objectAtIndex:0];
    
    // 读取 CSS 文件内容
    NSString *textDataFile = [NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    
    // 多余 空白 / 单引号 / 双引号 去冗
    textDataFile = [self fixByOptionsWithData:textDataFile];

    
    // 执行正则查询
    NSArray *matched = [textDataFile componentsMatchedByRegex:REGEX_BG_IMG
                                                      capture:REGEX_BG_IMG_CAPTURE];
    
//    NSLog(@"regex: %@, capture: %d", REGEX_BG_IMG, REGEX_BG_IMG_CAPTURE);
//    NSLog(@"result: %@", [textDataFile arrayOfCaptureComponentsMatchedByRegex:REGEX_BG_IMG]);

    
    // 无结果直接退出
    if ([matched count] < 1) {
        NSLog(@"no match result, exit...");
        return YES;
    }
    
    
//    NSLog(@"=-=-=-=-=-=-=-%@", [textDataFile arrayOfCaptureComponentsMatchedByRegex:matchRegex]);
    
    // 待转换图片列表字典 ( path => path )
    NSDictionary *imageDic = [NSDictionary dictionaryWithObjects:matched forKeys:matched];
    // 转换后图片列表字典 ( path => base64 data)
    NSMutableDictionary *imageEncodedDic = [NSMutableDictionary dictionaryWithCapacity:[imageDic count]];
    // 默认文件管理器实例
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 遍历 已找出的图片路径 字典，Base64 编码后存储至 imageEncodeDic
    [imageDic enumerateKeysAndObjectsUsingBlock:^(id imgPath, id imgData, BOOL *stop) {
        // 计算出当前图片的绝对物理地址
        NSString *imgFullPath = [Converter fileFullPathByCSSFile:imgPath withComponent:filePath];
        
        if (![fileManager fileExistsAtPath:imgFullPath]) {
            NSLog(@"error: file not exists at %@", imgPath);
        } else {
            // Base64 转换
            NSString *data = [[NSData dataWithContentsOfFile:imgFullPath] base64EncodedString];
            
            // 过滤多余的空行字符 (Base64 转换后存在大量的空白换行符号，郁闷...)
            data = [data stringByReplacingOccurrencesOfRegex:REGEX_NEW_LINE withString:@""];
            
            // 填充结果字典
            [imageEncodedDic setObject:data forKey:imgPath];
        }
    }];
    
    
    // 生成 Base64 后的新内容
    __block NSString *textDataEncoded = [NSString stringWithString:textDataFile];
    [imageEncodedDic enumerateKeysAndObjectsUsingBlock:^(id imgPath, id imgData, BOOL *stop) {
        // 生成 Data URI scheme
        NSString *dataWithURIWrapper = [Converter dataURIByFileExtension:[imgPath pathExtension]
                                                                withData:imgData];
        // 过滤更新
        textDataEncoded = [textDataEncoded stringByReplacingOccurrencesOfString:imgPath
                                                                     withString:dataWithURIWrapper];
    }];
    
    
    // 新内容写入文件
    NSError *error = NULL;
    NSString *fileEncodedName = [[filePath lastPathComponent] stringByReplacingOccurrencesOfRegex:@"\\."
                                                                                       withString:@"-b."];
    NSString *fileEncodedPath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileEncodedName];
    
    [textDataEncoded writeToFile:fileEncodedPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    return error ? NO : YES;
}

- (NSString *)fixByOptionsWithData:(NSString *)data
{
    // 多余空白修正
    if (self.fixWhiteSpace) {
        data = [data stringByReplacingOccurrencesOfRegex:REGEX_WHITESPACE_IN_URL
              usingBlock:^NSString *(NSInteger captureCount,
                                     NSString *const __unsafe_unretained *capturedStrings,
                                     const NSRange *capturedRanges,
                                     volatile BOOL *const stop) {
                  // 替换掉多余空白
                  return [NSString stringWithFormat:TEMPLATE_REGEX_WHITESPACE, capturedStrings[1]];
              }];
    }
    
    // 单引号替换修正
    if (self.fixSingleQuotes) {
        data = [data stringByReplacingOccurrencesOfRegex:REGEX_SINGLEQUOTE_IN_URL
              usingBlock:^NSString *(NSInteger captureCount,
                                     NSString *const __unsafe_unretained *capturedStrings,
                                     const NSRange *capturedRanges,
                                     volatile BOOL *const stop) {
                  // 替换单引号
                  return [NSString stringWithFormat:TEMPLATE_REGEX_SINGLEQUOTE,
                          capturedStrings[1],
                          self.fixQuotesByReplaceWith,
                          capturedStrings[2],
                          self.fixQuotesByReplaceWith,
                          capturedStrings[3]];
              }];
    }
    
    // 双引号替换修正
    if (self.fixDoubleQuotes) {
        data = [data stringByReplacingOccurrencesOfRegex:REGEX_DOBULEQUOTE_IN_URL
              usingBlock:^NSString *(NSInteger captureCount,
                                     NSString *const __unsafe_unretained *capturedStrings,
                                     const NSRange *capturedRanges,
                                     volatile BOOL *const stop) {
                  // 替换双引号
                  return [NSString stringWithFormat:TEMPLATE_REGEX_DOBULEQUOTE,
                          capturedStrings[1],
                          self.fixQuotesByReplaceWith,
                          capturedStrings[2],
                          self.fixQuotesByReplaceWith,
                          capturedStrings[3]];
              }];
    }
    
    return data;
}




#pragma mark - Class Static API

+ (NSString *)fileFullPathByCSSFile:(NSString *)filePath withComponent:(NSString *)cssFilePath
{
    return [[cssFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:filePath];
}

+ (NSString *)mimeTypeByFileExtension:(NSString *)fileExtension
{
    NSDictionary *mimeTypes = [NSDictionary dictionaryWithObjectsAndKeys:@"image/png", @"png",
                               @"image/jpeg", @"jpg",
                               @"image/gif", @"gif",
                               @"svg+xml", @"svg",
                               @"image/tiff", @"tiff",
                               @"image/vnd.microsoft.icon", @"ico",
                               nil];
    
    return [mimeTypes objectForKey:[fileExtension lowercaseString]];
}

+ (NSString *)dataURIByFileExtension:(NSString *)fileExtension withData:(NSString *)data
{
    return [NSString stringWithFormat:TEMPLATE_DATA_URI_SCHEME, [Converter mimeTypeByFileExtension:fileExtension], data];
}



@end
