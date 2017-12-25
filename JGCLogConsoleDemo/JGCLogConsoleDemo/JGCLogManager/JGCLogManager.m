//
//  JGCLogManager.m
//  JGCLogConsoleDemo
//
//  Created by Javier Garcia Castro on 24/12/17.
//  Copyright © 2017 Javier Garcia Castro. All rights reserved.
//

#import "JGCLogManager.h"
#import <Foundation/Foundation.h>
#import <assert.h>
#import <stdbool.h>
#import <sys/types.h>
#import <unistd.h>
#import <sys/sysctl.h>
#import <MessageUI/MessageUI.h>

@interface JGCLogManager()<MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) UIViewController *logVC;
@end

@implementation JGCLogManager

static JGCLogManager *sharedInstance = nil;

#pragma mark - Init Methods

+ (JGCLogManager *)sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:nil] init];
        [sharedInstance initComponents];
    }
    return sharedInstance;
}

- (void)initComponents
{
    if (![self isRunFromXcode]) {
        NSLog(@"Run from Xcode: NO");
        [self removeLogFile];
        [self redirectLogToDocument];
    }
    else {
        NSLog(@"Run from Xcode: YES");
    }
}

#pragma mark - Private Methods

- (UIButton *)createConsoleButton
{
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100.0, 50.0)];
    [button setBackgroundColor:[UIColor redColor]];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:@"LOG" forState:UIControlStateNormal];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button addTarget:self action:@selector(logButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (MFMailComposeViewController *)configuredMailComposeViewController
{
    MFMailComposeViewController *mailComposerVC = [[MFMailComposeViewController alloc ]init];
    mailComposerVC.mailComposeDelegate = self; // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
    [mailComposerVC setToRecipients:@[@"javilin.garcia@gmail.com"]];
    [mailComposerVC setSubject:@"Log"];
    [mailComposerVC setMessageBody:@"\n\n\n-----------------------------------------------\nThe console log has been attached.\n-----------------------------------------------" isHTML:false];
    
    //Attached
    NSData *data = [[NSData alloc] initWithContentsOfFile: [[JGCLogManager sharedInstance] getLogFilePath]];
    
    if (data != nil)
    {
        [mailComposerVC addAttachmentData:data mimeType:@"application/txt" fileName:[[JGCLogManager sharedInstance] getLogFileName]];
    }
    
    return mailComposerVC;
}

#pragma mark - User Actions

- (void)logButtonTapped
{
    NSLog(@"Log button tapped");
    self.logVC = [[UIViewController alloc]init];
    [self.logVC.view setBackgroundColor:[UIColor blackColor]];
    
    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    tv.selectable = YES;
    tv.editable = NO;
    [tv setFont:[UIFont fontWithName:tv.font.fontName size:8.f]];
    [[JGCLogManager sharedInstance] readFromFile];
    tv.text = [JGCLogManager sharedInstance].stringFromFile;
    [tv setTextColor:[UIColor greenColor]];
    [tv setBackgroundColor:[UIColor clearColor]];
    [self.logVC.view addSubview:tv];
    
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    NSMutableArray *tvConstraints = [NSMutableArray array];
    [tvConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[tv]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(tv)]];
    [tvConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[tv]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(tv)]];
    
    [tv.superview addConstraints:tvConstraints];
    [self.logVC.view bringSubviewToFront:tv];
    
    UIButton *logButton = [[UIButton alloc]init];
    [logButton setBackgroundColor:[UIColor redColor]];
    [logButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [logButton setTitle:@"Volver" forState:UIControlStateNormal];
    logButton.translatesAutoresizingMaskIntoConstraints = NO;
    [logButton addTarget:self action:@selector(returnButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.logVC.view addSubview:logButton];
    
    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[logButton]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(logButton)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[logButton]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(logButton)]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:logButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:50.f]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:logButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:60.f]];
    
    [logButton.superview addConstraints:constraints];
    [self.logVC.view bringSubviewToFront:logButton];
    
    UIButton *mailButton = [[UIButton alloc]init];
    [mailButton setBackgroundColor:[UIColor blueColor]];
    [mailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [mailButton setTitle:@"Mail" forState:UIControlStateNormal];
    mailButton.translatesAutoresizingMaskIntoConstraints = NO;
    [mailButton addTarget:self action:@selector(mailButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.logVC.view addSubview:mailButton];
    NSMutableArray *mailConstraints = [NSMutableArray array];
    [mailConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[mailButton]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(mailButton)]];
    [mailConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[mailButton]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(mailButton)]];
    [mailConstraints addObject:[NSLayoutConstraint constraintWithItem:mailButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:50.f]];
    [mailConstraints addObject:[NSLayoutConstraint constraintWithItem:mailButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:50.f]];
    
    [mailButton.superview addConstraints:mailConstraints];
    [self.logVC.view bringSubviewToFront:mailButton];
    
    if ([self.logConsoleDelegate respondsToSelector:@selector(navigateToLogConsoleViewController:)])
    {
        [self.logConsoleDelegate navigateToLogConsoleViewController:self.logVC];        
    }
}

- (void)returnButtonTapped
{
    [self.logVC dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailButtonTapped
{
    NSLog(@"mailButtonTapped");
    
    // Prepare mail
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailComposeViewController = [self configuredMailComposeViewController];
        
        [self returnButtonTapped];
        
        if ([self.logConsoleDelegate respondsToSelector:@selector(navigateToLogConsoleViewController:)])
        {
            [self.logConsoleDelegate navigateToLogConsoleViewController:mailComposeViewController];
        }
//        [self presentViewController:mailComposeViewController animated:YES completion:nil];
    }
    else
    {
        NSLog(@"Sending mail error");
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:true completion:nil];
}

- (NSString *)stringForKey:(NSString *)key dictionary:(NSDictionary *)dictionary
{
    id value = dictionary[key];
    
    if ([value isKindOfClass:[NSString class]])
    {
        value = [self parseHTML:value];
        
        return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    if ([value isKindOfClass:[NSNumber class]])
    {
        return [NSString stringWithFormat:@"%@", value];
    }
    
    return @"";
}

- (NSString *)parseHTML:(NSString *)string
{
    string  = [string stringByReplacingOccurrencesOfString:@"&aacute;" withString:@"á"];
    string  = [string stringByReplacingOccurrencesOfString:@"&Aacute;" withString:@"A"];
    string  = [string stringByReplacingOccurrencesOfString:@"&eacute;" withString:@"é"];
    string  = [string stringByReplacingOccurrencesOfString:@"&Eacute;" withString:@"É"];
    string  = [string stringByReplacingOccurrencesOfString:@"&iacute;" withString:@"í"];
    string  = [string stringByReplacingOccurrencesOfString:@"&Iacute;" withString:@"Í"];
    string  = [string stringByReplacingOccurrencesOfString:@"&oacute;" withString:@"ó"];
    string  = [string stringByReplacingOccurrencesOfString:@"&Oacute;" withString:@"Ó"];
    string  = [string stringByReplacingOccurrencesOfString:@"&uacute;" withString:@"ú"];
    string  = [string stringByReplacingOccurrencesOfString:@"&Uacute;" withString:@"Ú"];
    
    string  = [string stringByReplacingOccurrencesOfString:@"&ntilde;" withString:@"ñ"];
    string  = [string stringByReplacingOccurrencesOfString:@"&Ntilde;" withString:@"Ñ"];
    string  = [string stringByReplacingOccurrencesOfString:@"\\U00bf" withString:@"Ñ"];
    string  = [string stringByReplacingOccurrencesOfString:@"\\u00bf" withString:@"ñ"];
    
    return string;
}

#pragma mark - Redirect log to file

- (void)redirectLogToDocument
{
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSString *pathForLog = [NSString stringWithFormat:@"%@/iOS_LOG.txt",documentsDirectory];

    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stdin);
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stdout);
}

#pragma mark - Display log from file

- (NSString *)displayLog
{
    NSString *pathForLog = [self getLogFilePath];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:pathForLog encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"%@", error);
        return nil;
    }
    else {
        return fileContents;
    }
}

- (NSString *)getLogFilePath
{
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    NSString *pathForLog = [NSString stringWithFormat:@"%@/iOS_LOG.txt",documentsDirectory];

    return pathForLog;
}

- (NSString *)getLogFileName
{
    return [NSString stringWithFormat:@"iOS_LOG.txt"];
}

- (BOOL)isRunFromXcode
// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
{
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}

#pragma mark - Delete log from file

- (void)removeLogFile
{
    NSString *pathForLog = [self getLogFilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    // check if file exists
    if ([fileManager fileExistsAtPath: pathForLog] == YES){
        [fileManager removeItemAtPath:pathForLog error:&error];
    }
    
    if (error) {
        NSLog(@"Error deleting file: %@", error.localizedDescription);
    }
}

#pragma mark - Read from file

- (void)readFromFile
{
    NSString *filepath = [self getLogFilePath];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
    }
    
    self.stringFromFile = fileContents;
}

@end
