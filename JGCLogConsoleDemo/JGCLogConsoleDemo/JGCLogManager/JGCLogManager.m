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

#import <sys/utsname.h>

#import "Reachability.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/CaptiveNetwork.h>

#import <CoreBluetooth/CoreBluetooth.h>

#define MB (1024*1024)
#define GB (MB*1024)

@interface JGCLogManager()<MFMailComposeViewControllerDelegate, CBCentralManagerDelegate>
@property (strong, nonatomic) UIViewController *logVC;
@property (strong, nonatomic) NSMutableDictionary *infoDic;
@property (nonatomic, strong) CBCentralManager *bluetoothManager;
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
        NSLog(@"Log redirection enabled.");

        [self removeLogFile];
        [self redirectLogToDocument];
        [self prepareDeviceInfo];
        
        self.bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        NSLog(@"BLE start monitoring...");
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
    [mailComposerVC setToRecipients:@[]];//add default recipients
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    [mailComposerVC setSubject:[NSString stringWithFormat:@"%@ Log",bundleName]];
    
    NSString *message = [self composeMail:bundleName];
    
    [mailComposerVC setMessageBody:message isHTML:false];
    
    //Attach
    NSData *data = [[NSData alloc] initWithContentsOfFile: [[JGCLogManager sharedInstance] getLogFilePath]];
    
    if (data != nil)
    {
        [mailComposerVC addAttachmentData:data mimeType:@"application/txt" fileName:[[JGCLogManager sharedInstance] getLogFileName]];
    }
    
    return mailComposerVC;
}

- (NSString *)composeMail:(NSString *)bundleName
{
    NSString *deviceInfo = [NSString stringWithFormat:@"\n\n\n-----------------------------------------------\nDevice Info:\n\n"];
    deviceInfo = [NSString stringWithFormat:@"%@Model: %@\nSO: %@\nJailbroken: %@\nNetwork: %@\nBluetooth enabled: %@", deviceInfo, self.infoDic[@"model"], self.infoDic[@"so"], self.infoDic[@"isJailbroken"], self.infoDic[@"network"], self.infoDic[@"isBluetoothON"]];

    NSString *diskInfo = [NSString stringWithFormat:@"\n----------------------------------------------\nDisk Info:\n\n"];
    diskInfo = [NSString stringWithFormat:@"%@Total (formatted) space: %@\nFree space: %@\nUsed space: %@",diskInfo, self.infoDic[@"totalSpace"], self.infoDic[@"freeSpace"], self.infoDic[@"usedSpace"]];
    diskInfo = [NSString stringWithFormat:@"%@\n-----------------------------------------------\n\n",diskInfo];
    
    NSString *footer = [[NSString alloc] init];
    if (bundleName != nil)
    {
        footer = [NSString stringWithFormat:@"The log of %@ has been attached successfully.", bundleName];
    } else
    {
        footer = [NSString stringWithFormat:@"Has not been possible to attach the log."];
    }
    
    return [NSString stringWithFormat:@"%@%@%@",deviceInfo, diskInfo, footer];
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
    [tvConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-60-[tv]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(tv)]];
    
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
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *pathForLog = [NSString stringWithFormat:@"%@/%@_LOG.txt",documentsDirectory, bundleName];

    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stdin);
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stdout);
    
    NSLog(@"Redirect debug log to file OK.");
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
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *pathForLog = [NSString stringWithFormat:@"%@/%@_LOG.txt",documentsDirectory, bundleName];
    
    return pathForLog;
}

- (NSString *)getLogFileName
{
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    return [NSString stringWithFormat:@"%@_LOG.txt", bundleName];
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
    if ([fileManager fileExistsAtPath: pathForLog] == YES) {
        [fileManager removeItemAtPath:pathForLog error:&error];
        NSLog(@"Previous log file deleted OK.");
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

#pragma mark - Prepare Device info

- (void)prepareDeviceInfo
{
    self.infoDic = [[NSMutableDictionary alloc] init];
    self.infoDic[@"model"] = [JGCLogManager deviceName];
    self.infoDic[@"so"] = [JGCLogManager iosVersion];
    self.infoDic[@"isJailbroken"] = ([JGCLogManager isJailbroken]) ? @"YES" : @"NO";
    self.infoDic[@"totalSpace"] = [JGCLogManager totalDiskSpace];
    self.infoDic[@"freeSpace"] = [JGCLogManager freeDiskSpace];
    self.infoDic[@"usedSpace"] = [JGCLogManager usedDiskSpace];
    self.infoDic[@"network"] = [JGCLogManager getNetworkType];
    
    NSLog(@"Obtaining device info OK.");
}

#pragma mark - Device Model

+ (NSString *)deviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *code = [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];

    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{@"i386"      : @"Simulator",
                              @"x86_64"    : @"Simulator",
                              @"iPod1,1"   : @"iPod Touch",        // (Original)
                              @"iPod2,1"   : @"iPod Touch",        // (Second Generation)
                              @"iPod3,1"   : @"iPod Touch",        // (Third Generation)
                              @"iPod4,1"   : @"iPod Touch",        // (Fourth Generation)
                              @"iPod7,1"   : @"iPod Touch",        // (6th Generation)
                              @"iPhone1,1" : @"iPhone",            // (Original)
                              @"iPhone1,2" : @"iPhone",            // (3G)
                              @"iPhone2,1" : @"iPhone",            // (3GS)
                              @"iPad1,1"   : @"iPad",              // (Original)
                              @"iPad2,1"   : @"iPad 2",            //
                              @"iPad3,1"   : @"iPad",              // (3rd Generation)
                              @"iPhone3,1" : @"iPhone 4",          // (GSM)
                              @"iPhone3,3" : @"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" : @"iPhone 4S",         //
                              @"iPhone5,1" : @"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" : @"iPhone 5",          // (model A1429, everything else)
                              @"iPad3,4"   : @"iPad",              // (4th Generation)
                              @"iPad2,5"   : @"iPad Mini",         // (Original)
                              @"iPhone5,3" : @"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" : @"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" : @"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" : @"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" : @"iPhone 6 Plus",     //
                              @"iPhone7,2" : @"iPhone 6",          //
                              @"iPhone8,1" : @"iPhone 6S",         //
                              @"iPhone8,2" : @"iPhone 6S Plus",    //
                              @"iPhone8,4" : @"iPhone SE",         //
                              @"iPhone9,1" : @"iPhone 7",          //
                              @"iPhone9,3" : @"iPhone 7",          //
                              @"iPhone9,2" : @"iPhone 7 Plus",     //
                              @"iPhone9,4" : @"iPhone 7 Plus",     //
                              @"iPhone10,1": @"iPhone 8",          // CDMA
                              @"iPhone10,4": @"iPhone 8",          // GSM
                              @"iPhone10,2": @"iPhone 8 Plus",     // CDMA
                              @"iPhone10,5": @"iPhone 8 Plus",     // GSM
                              @"iPhone10,3": @"iPhone X",          // CDMA
                              @"iPhone10,6": @"iPhone X",          // GSM
                              @"iPhone11,2": @"iPhone XS",         //
                              @"iPhone11,4": @"iPhone XS Max",     //
                              @"iPhone11,6": @"iPhone XS Max",     // China
                              @"iPhone11,8": @"iPhone XR",         //
                              
                              @"iPad4,1"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   : @"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   : @"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
                              @"iPad4,7"   : @"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
                              @"iPad6,7"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584)
                              @"iPad6,8"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652)
                              @"iPad6,3"   : @"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                              @"iPad6,4"   : @"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        }
        else {
            deviceName = @"Unknown";
        }
    }
    
    return [NSString stringWithFormat:@"%@ (%@)", deviceName, code];
}

#pragma mark - iOS Version

+ (NSString *)iosVersion
{
    NSString *version = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
    return version;
    
}

#pragma mark - Disk Space Methods

+ (NSString *)memoryFormatter:(long long)diskSpace {
    NSString *formatted;
    double bytes = 1.0 * diskSpace;
    double megabytes = bytes / MB;
    double gigabytes = bytes / GB;
    if (gigabytes >= 1.0)
        formatted = [NSString stringWithFormat:@"%.2f GB", gigabytes];
    else if (megabytes >= 1.0)
        formatted = [NSString stringWithFormat:@"%.2f MB", megabytes];
    else
        formatted = [NSString stringWithFormat:@"%.2f bytes", bytes];
    
    return formatted;
}

+ (NSString *)totalDiskSpace {
    long long space = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemSize] longLongValue];
    return [self memoryFormatter:space];
}

+ (NSString *)freeDiskSpace {
    long long freeSpace = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize] longLongValue];
    return [self memoryFormatter:freeSpace];
}

+ (NSString *)usedDiskSpace {
    return [self memoryFormatter:[self usedDiskSpaceInBytes]];
}

+ (CGFloat)totalDiskSpaceInBytes {
    long long space = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemSize] longLongValue];
    return space;
}

+ (CGFloat)freeDiskSpaceInBytes {
    long long freeSpace = [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize] longLongValue];
    return freeSpace;
}

+ (CGFloat)usedDiskSpaceInBytes {
    long long usedSpace = [self totalDiskSpaceInBytes] - [self freeDiskSpaceInBytes];
    return usedSpace;
}

#pragma mark - Jailbreak Methods

+ (BOOL)isJailbroken
{
#if !(TARGET_IPHONE_SIMULATOR)
    // Check 1 : existence of files that are common for jailbroken devices
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/Cydia.app"] ||
        [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/MobileSubstrate.dylib"] ||
        [[NSFileManager defaultManager] fileExistsAtPath:@"/bin/bash"] ||
        [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/sbin/sshd"] ||
        [[NSFileManager defaultManager] fileExistsAtPath:@"/etc/apt"] ||
        [[NSFileManager defaultManager] fileExistsAtPath:@"/private/var/lib/apt/"] ||
        [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://package/com.example.package"]]) {
                                                       return YES;
                                                       }
                                                       FILE *f = NULL ;
                                                       if ((f = fopen("/bin/bash", "r")) ||
                                                           (f = fopen("/Applications/Cydia.app", "r")) ||
                                                           (f = fopen("/Library/MobileSubstrate/MobileSubstrate.dylib", "r")) ||
                                                           (f = fopen("/usr/sbin/sshd", "r")) ||
                                                           (f = fopen("/etc/apt", "r"))) {
                                                           fclose(f);
                                                           return YES;
                                                       }
                                                       fclose(f);
                                                       // Check 2 : Reading and writing in system directories (sandbox violation)
                                                       NSError *error;
                                                       NSString *stringToBeWritten = @"Jailbreak Test.";
                                                       [stringToBeWritten writeToFile:@"/private/jailbreak.txt" atomically:YES
                                                                             encoding:NSUTF8StringEncoding error:&error];
                                                       if(error==nil){
                                                           //Device is jailbroken
                                                           return YES;
                                                       } else {
                                                           [[NSFileManager defaultManager] removeItemAtPath:@"/private/jailbreak.txt" error:nil];
                                                       }
#endif
                                                       return NO;
}

#pragma mark - Network

+ (NSString *)getNetworkType
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    NSString *networkType = [[NSString alloc] init];
    
    if(status == NotReachable)
    {
        //No internet
        NSLog(@"none");
        networkType = @"None";
    }
    else if (status == ReachableViaWiFi)
    {
        //WiFi
        NSLog(@"Wifi");
        networkType = @"Wifi";
    }
    else if (status == ReachableViaWWAN)
    {
        NSLog(@"WWAN");
        
        //connection type
        CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
        NSString *carrier = [[netinfo subscriberCellularProvider] carrierName];
        
        if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
            networkType = [NSString stringWithFormat:@"%@ - 2G (GPRS)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
            networkType = [NSString stringWithFormat:@"%@ - 2G (EDGE)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
            networkType = [NSString stringWithFormat:@"%@ - 3G (WCDMA)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSDPA]) {
            networkType = [NSString stringWithFormat:@"%@ - 3G (HSDPA)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA]) {
            networkType = [NSString stringWithFormat:@"%@ - 3G (HSUPA)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
            networkType = [NSString stringWithFormat:@"%@ - 2G (CDMA1x)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
            networkType = [NSString stringWithFormat:@"%@ - 3G (CDMAEVDORev0)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
            networkType = [NSString stringWithFormat:@"%@ - 3G (CDMAEVDORevA)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
            networkType = [NSString stringWithFormat:@"%@ - 3G (CDMAEVDORevB)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyeHRPD]) {
            networkType = [NSString stringWithFormat:@"%@ - 3G (HRPD)", carrier];
        } else if ([netinfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
            networkType = [NSString stringWithFormat:@"%@ - 4G (LTE)", carrier];
        }        
    }
    
    return networkType;
}

#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManager.state - %ld",(long)central.state);
    
    switch (central.state) {
        case CBManagerStateUnknown: self.infoDic[@"isBluetoothON"] = @"NO"; NSLog(@"centralManager.state - CBManagerStateUnknown");break;
        case CBManagerStateResetting: self.infoDic[@"isBluetoothON"] = @"NO"; NSLog(@"centralManager.state - CBManagerStateResetting");break;
        case CBManagerStateUnsupported: self.infoDic[@"isBluetoothON"] = @"NO"; NSLog(@"centralManager.state - CBManagerStateUnsupported");break;
        case CBManagerStateUnauthorized: self.infoDic[@"isBluetoothON"] = @"NO"; NSLog(@"centralManager.state - CBManagerStateUnauthorized");break;
        case CBManagerStatePoweredOff: self.infoDic[@"isBluetoothON"] = @"NO"; NSLog(@"centralManager.state - CBManagerStatePoweredOff");break;
        case CBManagerStatePoweredOn: self.infoDic[@"isBluetoothON"] = @"YES"; NSLog(@"centralManager.state - CBManagerStatePoweredOn");break;
    }
}

@end
