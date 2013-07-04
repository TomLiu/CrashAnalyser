//
//  AppDelegate.h
//  CrashAnalyser
//
//  Created by 61 on 13-7-3.
//  Copyright (c) 2013年 61. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *dysmBtn;
@property (weak) IBOutlet NSButton *crashReportBtn;
@property (weak) IBOutlet NSButton *analyseBtn;

@property (weak) IBOutlet NSTextField *dysmPathField;
@property (weak) IBOutlet NSTextField *crPathField;
@property (weak) IBOutlet NSTextField *remoteCrPathField;

@property (strong) IBOutlet NSTextView *resultView;
@property (strong) IBOutlet NSTextView *reportView;

- (IBAction)dysmBtnClicked:(id)sender;
- (IBAction)crBtnClicked:(id)sender;
- (IBAction)analyseBtnClicked:(id)sender;
- (IBAction)clearBtnClicked:(id)sender;
- (IBAction)remoteBtnClicked:(id)sender;
@end
