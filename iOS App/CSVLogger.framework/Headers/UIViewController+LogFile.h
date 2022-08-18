//
//  UIViewController+LogFile.h
//  CSV Logger
//
//  Created by Sebastian Hueber on 19.10.18.
//  Copyright © 2018 Sebastian Hueber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSVLogFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (LogFile)

/**
 Presents a UIActivityViewController to share CSV files.

 @param logFiles The logs you want to share
 @param sender The UIControl object, e.g. the button, that is used to trigger the event.
 */
- (void)shareLogFiles:(NSArray<CSVLogFile *> *)logFiles originatingAt:(nullable UIControl *)sender;


/**
 Presents the view controller for managing log files modally as a form sheet.

 @param directoryURL The URL to the directory of the logs. Pass nil if you use the default directory.
 */
- (void)showPopupForManagingLogsInDirectory:(nullable NSURL *)directoryURL;


/**
 Presents the view controller for opening a log file modally as a form sheet.
 
 @param directoryURL The URL to the directory of the logs. Pass nil if you use the default directory.
 @param completion Once the user selected a log file, this block will be invoked. If the user cancelled opening a file, the parameter will be nil.
 */
- (void)showPopupForOpeningLogInDirectory:(nullable NSURL *)directoryURL completionHandler:(void (^) (CSVLogFile * _Nullable log))completion;

@end

NS_ASSUME_NONNULL_END
