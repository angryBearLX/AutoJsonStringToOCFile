//
//  ViewController.h
//  JsonTransitionToFile_Demo
//
//  Created by Liu on 16/3/29.
//  Copyright © 2016年 Liu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController


@property (strong) IBOutlet NSButton *transition;
@property (strong) IBOutlet NSButton *finder;
@property (strong) IBOutlet NSTextView *textView;

@property (strong) IBOutlet NSButton *saveToDiskButton;
@property (strong) IBOutlet NSTextField *classNameTF;
@property (strong) IBOutlet NSTextField *authorTF;
@property (strong) IBOutlet NSTextField *superClassTF;
@property (strong) IBOutlet NSTextField *projectTF;

@end

