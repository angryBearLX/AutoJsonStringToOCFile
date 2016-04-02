//
//  ViewController.m
//  JsonTransitionToFile_Demo
//
//  Created by Liu on 16/3/29.
//  Copyright © 2016年 Liu. All rights reserved.
//

#import "ViewController.h"
#import <OpenDirectory/OpenDirectory.h>

static NSArray *openFiles()
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    NSInteger i = [panel runModal];
    if (i == NSModalResponseOK)
    {
        return [panel URLs];
    }
    
    return nil;
}

@interface ViewController ()
{
    NSString *_headerFileContent;
    NSString *_mFileContent;
    NSString *_className;
    NSString *_projectName;
    NSString *_author;
    NSString *_superClassName;
    NSURL *_pathURL;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    self.transition.action = @selector(transition:);
    self.saveToDiskButton.action = @selector(createFileAndSaveToDisk);
    self.finder.action = @selector(openDeskDirectory);
    
    
}

- (void)transition:(id)sender
{
    NSLog(@"%@", sender);
    NSLog(@"%@", self.textView.string);
    
    NSData *data = [self.textView.string dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    if (![NSJSONSerialization isValidJSONObject:obj]) {
        [self alertWithTitle:@"出错啦" infoText:@"json字符串错误！不是json格式的字符串!"];
        return;
    }
    
    _className = self.classNameTF.stringValue;
    _projectName = self.projectTF.stringValue;
    _author = self.authorTF.stringValue;
    _superClassName = self.superClassTF.stringValue;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YY/MM/dd";
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    formatter.dateFormat = @"YYYY";
    NSString *year = [formatter stringFromDate:[NSDate date]];

    //.h
    _headerFileContent = [NSString stringWithFormat:@"//\n//  %@.h\n//  %@\n//\n//  Created by %@ on %@.\n//  Copyright © %@年 %@. All rights reserved.\n//\n", _className, _projectName, _author, dateString, year,_author];
    _headerFileContent = [_headerFileContent stringByAppendingFormat:@"\n#import <Foundation/Foundation.h>\n"];
    
    //.m
    _mFileContent = [NSString stringWithFormat:@"//\n//  %@.m\n//  %@\n//\n//  Created by %@ on %@.\n//  Copyright © %@年 %@. All rights reserved.\n//\n", _className, _projectName, _author, dateString, year, _author];
    _mFileContent = [_mFileContent stringByAppendingFormat:@"\n#import \"%@.h\"\n", _className];
    
    [self stringFromDictionary:obj className:_className];
    
    
    self.textView.string = _headerFileContent;
}

- (void)stringFromDictionary:(NSDictionary *)dic className:(NSString *)className
{
    if (!dic || !className.length) {
        return;
    }
    
    NSMutableArray *nextDicArray = [NSMutableArray array];
    NSMutableArray *nextClassNameArray = [NSMutableArray array];
    
    if ([dic isKindOfClass:[NSDictionary class]]) {
        
        _headerFileContent = [_headerFileContent stringByAppendingFormat:@"\n@interface %@ : %@\n", className, _superClassName];
        
        NSArray *allKeys = [dic allKeys];
        for (NSString *key in allKeys) {
            id value = [dic objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                _headerFileContent = [_headerFileContent stringByAppendingFormat:@"@property (nonatomic, strong) NSString *%@;\n", key];
            }
            else if ([value isKindOfClass:[NSNumber class]]) {
                _headerFileContent = [_headerFileContent stringByAppendingFormat:@"@property (nonatomic, strong) NSNumber *%@;\n", key];
            }
            else if ([value isKindOfClass:[NSArray class]]) {
                id obj = [value firstObject];
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    NSString *nextClassName = [NSString stringWithFormat:@"%@Model", [key capitalizedStringWithLocale:[NSLocale currentLocale]]];
                    NSDictionary *nextDic = obj;
                    [nextClassNameArray addObject:nextClassName];
                    [nextDicArray addObject:nextDic];
                    _headerFileContent = [_headerFileContent stringByAppendingFormat:@"@property (nonatomic, strong) %@ *%@;\n", nextClassName, key];
                }
                else {
                    _headerFileContent = [_headerFileContent stringByAppendingFormat:@"@property (nonatomic, strong) NSArray *%@;\n", key];
                }
            }
            else if ([value isKindOfClass:[NSDictionary class]]) {
                NSString *nextClassName = [NSString stringWithFormat:@"%@Model", [key capitalizedStringWithLocale:[NSLocale currentLocale]]];
                NSDictionary *nextDic = [dic objectForKey:key];
                [nextClassNameArray addObject:nextClassName];
                [nextDicArray addObject:nextDic];
                _headerFileContent = [_headerFileContent stringByAppendingFormat:@"@property (nonatomic, strong) %@ *%@;\n", nextClassName, key];
            }
            else {
                
            }
        }
        
        _headerFileContent = [_headerFileContent stringByAppendingFormat:@"\n\n@end\n"];
        
        
        //.m
        _mFileContent = [_mFileContent stringByAppendingFormat:@"\n@implementation %@\n", className];
        _mFileContent = [_mFileContent stringByAppendingFormat:@"\n\n@end\n"];
    }

    for (int i = 0; i < nextDicArray.count; i++) {
        NSDictionary *nextDic = [nextDicArray objectAtIndex:i];
        NSString *nextClassName = [nextClassNameArray objectAtIndex:i];
        [self stringFromDictionary:nextDic className:nextClassName];
    }
}

- (void)createFileAndSaveToDisk
{
    NSArray *urls = openFiles();
    if (!urls) {
        return;
    }
    _pathURL = [urls lastObject];
    NSString *path = [_pathURL path];
    
    _headerFileContent = self.textView.string;
    if (_headerFileContent.length && _mFileContent.length) {
        NSFileManager *manager = [NSFileManager defaultManager];
        
        //.h
        
        NSString *filePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h", _className]];
        
        NSLog(@"%@", filePath);
        if (![manager fileExistsAtPath:filePath]) {
            BOOL result = [manager createFileAtPath:filePath contents:nil attributes:nil];
            if (!result) {
                NSLog(@"创建文件失败");
                [self alertWithTitle:@"失败" infoText:@"创建.h文件失败"];
            }
            else {
                NSError *error;
                BOOL flag = [_headerFileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                if (!flag) {
                    NSLog(@"写入文件失败 %@", error);
                    [self alertWithTitle:@"失败" infoText:@"创建.h文件失败"];
                }
            }
        }
        else {
            NSError *error;
            BOOL flag = [_headerFileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (!flag) {
                NSLog(@"写入文件失败 %@", error);
                [self alertWithTitle:@"失败" infoText:@"创建.h文件失败"];
            }
        }
        
        //.m
        NSString *mfilePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m", _className]];
        
        NSLog(@"%@", mfilePath);
        if (![manager fileExistsAtPath:mfilePath]) {
            BOOL result = [manager createFileAtPath:mfilePath contents:nil attributes:nil];
            if (!result) {
                NSLog(@"创建文件失败");
                [self alertWithTitle:@"失败" infoText:@"创建.m文件失败"];
            }
            else {
                NSError *error;
                BOOL flag = [_mFileContent writeToFile:mfilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                if (!flag) {
                    NSLog(@"写入文件失败 %@", error);
                    [self alertWithTitle:@"失败" infoText:@"创建.m文件失败"];
                }
            }
        }
        else {
            NSError *error;
            BOOL flag = [_mFileContent writeToFile:mfilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (!flag) {
                NSLog(@"写入文件失败 %@", error);
                [self alertWithTitle:@"失败" infoText:@"创建.m文件失败"];
            }
        }
    }
}

- (void)openDeskDirectory
{

}

- (void)alertWithTitle:(NSString *)title infoText:(NSString *)info
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = info;
    [alert runModal];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
