//
//  AppDelegate.m
//  CrashAnalyser
//
//  Created by 61 on 13-7-3.
//  Copyright (c) 2013年 61. All rights reserved.
//

#import "AppDelegate.h"
#import "NSString+Helper.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self prepare];
}

- (void)prepare
{
    NSString *recentDYSMPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"CARecentDYSMPath"];
    if (recentDYSMPath && recentDYSMPath.length > 0) {
        self.dysmPathField.stringValue = recentDYSMPath;
    }
}

- (IBAction)dysmBtnClicked:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    
	[oPanel setCanChooseDirectories:NO];
    [oPanel setCanChooseFiles:YES];
	[oPanel setDirectoryURL:[NSURL fileURLWithPath:@"~"]];
    
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        if (NSFileHandlingPanelOKButton == result) {
            NSString *filePath = [[[oPanel URLs] objectAtIndex:0] path];
            [self.dysmPathField setStringValue:filePath];
            
            [self saveRecentDYSMPathToDefaults:filePath];
        }
    }];
}

- (IBAction)crBtnClicked:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    
	[oPanel setCanChooseDirectories:NO];
    [oPanel setCanChooseFiles:YES];
	[oPanel setDirectoryURL:[NSURL fileURLWithPath:@"~"]];
    
    [oPanel beginWithCompletionHandler:^(NSInteger result) {
        if (NSFileHandlingPanelOKButton == result) {
            NSString *filePath = [[[oPanel URLs] objectAtIndex:0] path];
            [self.crPathField setStringValue:filePath];
            
            NSError *error;
            NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
            self.reportView.string = content;
        }
    }];
}

- (void)saveRecentDYSMPathToDefaults:(NSString *)path
{
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"CARecentDYSMPath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)clearBtnClicked:(id)sender
{
    [self.crPathField setStringValue:@""];
    [self.reportView setString:@""];
    [self.resultView setString:@""];
}

- (IBAction)analyseBtnClicked:(id)sender
{
    [self.resultView setString:@""];
    [self analyseCrashReport];
    return;
}

- (void)printStackInfoFromMemoryAddress:(NSArray *)memoryAddress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSString *address in memoryAddress) {
            NSString *result = [self getStackInfoFromMemoryAddress:address];
            [self.resultView setString:[NSString stringWithFormat:@"%@\n%@",[self.resultView string], result]];
        }
    });
}

- (NSString *)getStackInfoFromMemoryAddress:(NSString *)memoryAddress
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/atos"];
    
    NSString *executablePath = [self executableFilePathFromDYSMPath:self.dysmPathField.stringValue];
    
    NSMutableArray *arguments = [NSMutableArray array];
    [arguments addObject:@"-o"];
    [arguments addObject:executablePath];
    [arguments addObject:@"-arch"];
    [arguments addObject:@"x86_64"];
    [arguments addObject:memoryAddress];
    
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    return result;
}

- (NSString *)executableFilePathFromDYSMPath:(NSString *)dysmPath
{
    NSString *dysmName = [[NSURL URLWithString:dysmPath] lastPathComponent];
    NSString *executableName = [dysmName substringWithRange:NSMakeRange(0, dysmName.length - 9)];
    
    return [NSString stringWithFormat:@"%@/Contents/Resources/DWARF/%@", dysmPath, executableName];
}

- (void)analyseCrashReport
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *content = self.reportView.string;
        
        if ([content stringByTrimmingWhitespaceAndNewLine].length == 0) {
            return;
        }
        
        NSInteger thread = [self getCrashThreadFromContent:content];
        NSString *threadInfo = [self getThreadInfoFromContent:content thread:thread];
        NSString *bundleIdentifier = [self getBundleIdentifierFromContent:content];
        
        NSArray *memoryAddress = [self getMemoryAddressFromThreadInfo:threadInfo bundleIdentifier:bundleIdentifier];
        [self printStackInfoFromMemoryAddress:memoryAddress];
    });
}

- (NSInteger)getCrashThreadFromContent:(NSString *)content
{
    NSString *leftSymbol = @"Crashed Thread: ";
    NSString *rightSymbol = @"Dispatch queue";
    NSRange leftRange = [content rangeOfString:leftSymbol];
    NSRange rightRange = [content rangeOfString:rightSymbol];
    
    if ((leftRange.location != NSNotFound) && (rightRange.location != NSNotFound)) {
        NSInteger location = leftRange.location + leftRange.length;
        NSInteger length = rightRange.location - leftRange.location - leftRange.length - 1;
        NSRange thradStringRange = NSMakeRange(location, length);
        NSString *thread = [content substringWithRange:thradStringRange];
        
        return [thread integerValue];
    } else {
        return NSNotFound;
    }
}

- (NSString *)getThreadInfoFromContent:(NSString *)content thread:(NSInteger)thread
{
    NSString *startSymbol = [NSString stringWithFormat:@"Thread %ld Crashed", thread];
    NSString *endSymbol = @"\n\n";
    
    NSRange startRange = [content rangeOfString:startSymbol];
    NSRange endRange = [content rangeOfString:endSymbol options:0 range:NSMakeRange(startRange.location, content.length - startRange.location)];
    
    if (startRange.location != NSNotFound && endRange.location != NSNotFound) {
        NSInteger location = startRange.location;
        NSInteger length = endRange.location - startRange.location;
        NSRange range = NSMakeRange(location, length);
        
        NSString *threadInfo = [content substringWithRange:range];
        return threadInfo;
    } else {
        return nil;
    }
}

- (NSArray *)getMemoryAddressFromThreadInfo:(NSString *)threadInfo bundleIdentifier:(NSString *)bundleIdentifier
{
    NSMutableArray *memoryAddress = [NSMutableArray array];
    NSArray *stackInfos = [threadInfo componentsSeparatedByString:@"\n"];
    
    for (NSString *stackInfo in stackInfos) {
        NSRange range = [stackInfo rangeOfString:bundleIdentifier];
        if (range.location == NSNotFound) {
            continue;
        }
        
        NSArray *originParts = [stackInfo componentsSeparatedByString:@" "];
        NSMutableArray *fiteredParts = [NSMutableArray array];
        
        for (NSString *part in originParts) {
            if (part.length > 0) {
                [fiteredParts addObject:[part stringByTrimmingWhitespaceAndNewLine]];
            }
        }
        
        if (fiteredParts.count > 3) {
            [memoryAddress addObject:[fiteredParts objectAtIndex:2]];
        }
    }
    
    return memoryAddress;
}

- (NSString *)getBundleIdentifierFromContent:(NSString *)content
{
    NSString *startSymbol = @"Identifier:";
    NSString *endSymbol = @"\n";
    
    NSRange startRange = [content rangeOfString:startSymbol];
    NSRange endRange = [content rangeOfString:endSymbol options:0 range:NSMakeRange(startRange.location, content.length - startRange.location)];
    
    if (startRange.location != NSNotFound && endRange.location != NSNotFound) {
        NSInteger location = startRange.location + startRange.length;
        NSInteger length = endRange.location - startRange.location - startRange.length;
        NSRange range = NSMakeRange(location, length);
        
        NSString *bundleIdentifier = [content substringWithRange:range];
        return [bundleIdentifier stringByTrimmingWhitespaceAndNewLine];;
    } else {
        return nil;
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    [self.window orderFront:nil];
    return YES;
}
@end

