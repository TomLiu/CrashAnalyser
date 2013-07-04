//
//  NSString+Helper.m
//  CrashAnalyser
//
//  Created by 61 on 13-7-4.
//  Copyright (c) 2013年 61. All rights reserved.
//

#import "NSString+Helper.h"

@implementation NSString (Helper)

- (NSString *)stringByTrimmingWhitespaceAndNewLine
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
