//
//  GKLyricParser.m
//  GKAudioPlayerDemo
//
//  Created by QuintGao on 2017/9/7.
//  Copyright © 2017年 高坤. All rights reserved.
//

#import "GKLyricParser.h"
#import "GKTool.h"

@implementation GKLyricParser

/**
 歌词解析
 
 @param url 歌词的url
 @return 包含歌词模型的数组
 */
+ (NSArray *)lyricParserWithUrl:(NSString *)url {
    // 根据歌词文件的url获取歌词内容
    NSString *lyricStr = [NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil];
    return [self lyricParaseWithLyricString:lyricStr];
}

/**
 歌词解析
 
 @param str 所有歌词的字符串
 @return 包含歌词模型的数组
 */
+ (NSArray *)lyricParserWithStr:(NSString *)str {
    return [self lyricParaseWithLyricString:str];
}


/**
 解析歌词方法
 
 @param lyricString 歌词对应的字符串
 @return 歌词解析后的模型数组
 */
+ (NSArray *)lyricParaseWithLyricString:(NSString *)lyricString {
    // 1. 以\n分割歌词
    NSArray *linesArray = [lyricString componentsSeparatedByString:@"\n"];
    
    // 2. 创建模型数组
    NSMutableArray *modelArray = [NSMutableArray new];
    
    // 3. 开始解析
    // 由于有形如
    // [ti:如果没有你]
    // [00:00.64]歌词
    // [00:01.89][03:01.23][05:03.43]歌词
    // 这样的歌词形式，所以最好的方法是用正则表达式匹配 [00:00.00] 来获取时间
    
    for (NSString *line in linesArray) {
        // 正则表达式 [00:01.78], \\ 转义,  @"\\[\\d{2}:\\d{2}.\\d{2}\\]"
        NSString *pattern = @"\\[[0-9][0-9]:[0-9][0-9].[0-9][0-9]\\]";
        
        NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
        // 进行匹配
        NSArray *matchesArray = [regular matchesInString:line options:NSMatchingReportProgress range:NSMakeRange(0, line.length)];
        
        // 获取歌词部分
        // 方法一
        //        NSTextCheckingResult *match = matchesArray.lastObject;
        //
        //        NSString *content = [line substringFromIndex:(match.range.location + match.range.length)];
        
        // 方法二  [00:01.78]歌词
        NSString *content = [line componentsSeparatedByString:@"]"].lastObject;
        
        // 获取时间部分[00:00.00]
        for (NSTextCheckingResult *match in matchesArray) {
            NSString *timeStr = [line substringWithRange:match.range];
            // 去掉开头和结尾的[],得到时间00:00.00
            timeStr = [timeStr substringWithRange:NSMakeRange(1, 8)];
            // 分、秒、毫秒
            NSString *minStr = [timeStr substringWithRange:NSMakeRange(0, 2)];
            NSString *secStr = [timeStr substringWithRange:NSMakeRange(3, 2)];
            NSString *mseStr = [timeStr substringWithRange:NSMakeRange(6, 2)];
            
            // 转换成以毫秒秒为单位的时间 1秒 = 1000毫秒
            NSTimeInterval time = [minStr floatValue] * 60 * 1000 + [secStr floatValue] * 1000 + [mseStr floatValue];
            
            // 创建模型，赋值
            GKLyricModel *lyricModel = [GKLyricModel new];
            lyricModel.content      = content;
            lyricModel.msTime       = time;
            lyricModel.secTime      = time / 1000;
            lyricModel.timeString   = [GKTool timeStrWithMsTime:time];
            [modelArray addObject:lyricModel];
        }
    }
    
    // 数组根据时间进行排序 时间（time）
    // ascending: 是否升序
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"msTime" ascending:YES];
    
    return [modelArray sortedArrayUsingDescriptors:@[descriptor]];
}

@end
