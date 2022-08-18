//
//  CSVLogFileListViewController.h
//  CSV Logger
//
//  Created by Sebastian Hueber on 19.10.18.
//  Copyright © 2018 Sebastian Hueber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSVLogFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSVLogFileListViewController : UINavigationController

/**
 The URL of the directory whose CSV files should be listed.
 Pass nil if you want to use the default directory of the CSVLogFile.
 */
@property (nonatomic, nullable) NSURL *directoryURL;


/**
 Returns a view controller that lists all CSV logs in a given directory. Users can delete and share the logs from here.

 @param directoryURL If you want to list the contents of a directory other than the default location provide it here.
 @return A view controller that can be presented.
 */
+ (instancetype)viewControllerForManagingLogsInDirectory:(nullable NSURL *)directoryURL;


/**
 Returns a view controller that lists all CSV logs in a given directory. Upon tapping on either the cancel button or a log, this view controller is dismissed. You can use the completion handler to obtain the selected log file.

 @param directoryURL If you want to list the contents of a directory other than the default location provide it here.
 @param completion The completion handler in which you can handle the user's selection. If the process was cancelled, the log object will be nil.
 @return A view controller that can be presented.
 */
+ (instancetype)viewControllerForOpeningLogInDirectory:(nullable NSURL *)directoryURL completionHandler:(void (^) (CSVLogFile * _Nullable log))completion;

@end

NS_ASSUME_NONNULL_END
