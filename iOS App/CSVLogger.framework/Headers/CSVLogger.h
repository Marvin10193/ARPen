//
//  CSVLogger.h
//  CSV Logger
//
//  Created by Sebastian Hueber on 22.11.18.
//  Copyright © 2018 Sebastian Hueber. All rights reserved.
//

/*
 
           __  _
       .-.'  `; `-._  __  _
      (_,         .-:'  `; `-._
    ,'o"(        (_,           )
   (__,-'      ,'o"(            )>
      (       (__,-'            )
       `-'._.--._(             )
          |||  |||`-'._.--._.-'
                     |||  |||

 */

/*
 The CSV Logger
 
 
 How to use this thing:
 
 SETUP:
 Drag the Framework into your Xcode project
 (And remember to make sure, that your frameworks have to be part of your Copy Files phase)
 
 CREATING A LOG FILE:
 Create a CSV file by using [CSVLogFile logFileWithName:inDirectory:options:].
 Provide nil as directory if you have no special folder you wish your logs to be saved in.
 
 AUTOMATIC WRITING:
 By default, the log saves changes to the disk every time you log something.
 Sometimes, this behavior is undesired, e.g. if you log something 60 times per second.
 For these circumstances, consider using the LogFileOptionNoAutomaticWrite option
 or make the log store changes periodically by using beginSavingPeriodicallyWithInterval: method.
 Also have a look at the LogFileOptionLineNumbering option.
 
 LOGGING:
 Log any object you want with the logObjects:... method.
 Some things you might want to log, e.g. a CGPoint are no objects.
 For these values, have a look at the NSString category provided in the framework.
 
 EXPORTING:
 Once your log is complete, you can export it.
 On the Mac, use showSavePanelWithCustomName:inWindow:
 or simply open the Finder at the location of the file (openDirectory:)
 On iOS have a look at the showPopupForManagingLogsInDirectory: method of UIViewController.
 
 */




#import <Foundation/Foundation.h>

#import <CSVLogger/CSVLogFile.h>

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <CSVLogger/CSVLogFileListViewController.h>
#import <CSVLogger/UIViewController+LogFile.h>
#endif
#import <CSVLogger/NSString+LogFile.h>
