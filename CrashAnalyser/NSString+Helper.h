//
//  NSString+Helper.h
//  CrashAnalyser
//
//  Created by 61 on 13-7-4.
//  Copyright (c) 2013年 61. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Helper)
- (NSString *)stringByTrimmingWhitespaceAndNewLine;
- (NSString *)stringByConvertHTMLBrToNewLine;
@end
