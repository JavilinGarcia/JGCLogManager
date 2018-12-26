//
//  JGCLogManager.h
//  JGCLogConsoleDemo
//
//  Created by Javier Garcia Castro on 24/12/17.
//  Copyright © 2017 Javier Garcia Castro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define NSLog(...) NSLog(@"\n--------------------------------------------------------------------------------------------\n%s %@\n--------------------------------------------------------------------------------------------\n", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__]);[JGCLogManager sharedInstance].logConsole = [NSString stringWithFormat:@"%@ %@",[JGCLogManager sharedInstance].logConsole,[NSString stringWithFormat:__VA_ARGS__]];fflush(stdout);setlinebuf(stdout)

@protocol JGCLogConsoleDelegate <NSObject>
@optional
- (void)navigateToLogConsoleViewController:(UIViewController *)logConsoleViewController;
@end

@interface JGCLogManager : NSObject

@property(nonatomic, strong) NSString *logConsole;
@property(nonatomic, strong) NSString *stringFromFile;
@property(nonatomic, strong) id<JGCLogConsoleDelegate> logConsoleDelegate;

- (NSString *)stringForKey:(NSString *)key dictionary:(NSDictionary *)dictionary;

+ (JGCLogManager *)sharedInstance;

- (UIButton *)createConsoleButton;
- (NSString *)displayLog;
- (NSString *)getLogFilePath;
- (NSString *)getLogFileName;

- (void)redirectLogToDocument;
- (BOOL)isRunFromXcode;
- (void)removeLogFile;
- (void)readFromFile;

+ (NSString *)totalDiskSpace;
+ (NSString *)freeDiskSpace;
+ (NSString *)usedDiskSpace;

+ (CGFloat)totalDiskSpaceInBytes;
+ (CGFloat)freeDiskSpaceInBytes;
+ (CGFloat)usedDiskSpaceInBytes;

+ (NSString *)getNetworkType;

@end
