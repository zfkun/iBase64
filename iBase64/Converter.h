//
//  Converter.h
//  iBase64
//
//  Created by fankun on 12-9-5.
//  Copyright (c) 2012年 zfkun.com. All rights reserved.
//

#import <Foundation/Foundation.h>


enum {
    ConvertFixOptionWhiteSpace = 0,
    ConvertFixOptionSingleQuotes = 1,
    ConvertFixOptionDoubleQuotes = 2
};

typedef NSUInteger ConvertFixOption;



@class Converter;


@protocol ConverterDelegate <NSObject>

@optional
- (void)converterWillStart:(Converter *)sender;

- (void)converterDidStart:(Converter *)sender;

- (void)converterWillFinish:(Converter *)sender;

- (void)converterDidFinished:(Converter *)sender;

- (void)converterDidStoped:(Converter *)sender;

- (void)converter:(Converter *)sender willConvertFileAtIndex:(NSInteger)index totalOfFiles:(NSInteger)total;

- (void)converter:(Converter *)sender didConvertFileAtIndex:(NSInteger)index totalOfFiles:(NSInteger)total success:(BOOL)success;

@end


@interface Converter : NSObject

{
    /* 运行标志位 */
    BOOL _isBusy;
    /* 待处理文件列表 */
    NSArray *_fileList;
}

/* 代理 */
@property (nonatomic, strong) id<ConverterDelegate> delegate;
/* 处理中标志位 */
@property (nonatomic, readonly, getter = isBusy) BOOL busy;
/* 自动修复空白字符(替换为 fixWhiteSpaceByReplaceWith) */
@property (nonatomic) BOOL fixWhiteSpace;
/* 自动修复单引号(替换为 fixQuotesByReplaceWith) */
@property (nonatomic) BOOL fixSingleQuotes;
/* 自动修复双引号(替换为 fixQuotesByReplaceWith) */
@property (nonatomic) BOOL fixDoubleQuotes;
/* 自动修复空白字符的替换符 */
@property (nonatomic, strong) NSString *fixWhiteSpaceByReplaceWith;
/* 自动修复引号(单/双)的替换符 */
@property (nonatomic, strong) NSString *fixQuotesByReplaceWith;


/* 根据CSS文件的绝对路径，计算指定文件的绝对路径 */
+ (NSString *)fileFullPathByCSSFile:(NSString *)filePath withComponent:(NSString *)cssFilePath;

/* 根据文件后缀获取对应 MIME 值 */
+ (NSString *)mimeTypeByFileExtension:(NSString *)fileExtension;

/* 根据文件后缀及文件内容生成对应 Data URI */
+ (NSString *)dataURIByFileExtension:(NSString *)fileExtension withData:(NSString *)data;


/* 初始化 */
- (id)initWithFileList:(NSArray *)fileList;

///* 动态追加新文件 */
//- (BOOL)appendFile:(NSString *)file;

/* 启动转换 */
- (void)start;
- (void)startWithFileList:(NSArray *)fileList;

/* 停止转换 */
- (void)stop;

/* 转换中标志位 */
- (BOOL)isBusy;

@end
