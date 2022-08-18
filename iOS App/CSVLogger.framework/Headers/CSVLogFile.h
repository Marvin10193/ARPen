//
//  CSVLogFile.h
//  CSV Logger
//
//  Created by Sebastian Hueber on 15.09.18.
//  Copyright © 2018 Sebastian Hueber. All rights reserved.
//

#include <TargetConditionals.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif


NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, LogFileOption) {
    LogFileOptionNone               = 0,
    LogFileOptionLineNumbering      = 1 << 0,
    LogFileOptionNoAutomaticWrite   = 1 << 1
};





@interface CSVLogFile : NSObject

/**
 The name of your CSV file without the ".csv" ending.
 */
@property (readonly, atomic, copy) NSString *name;


/**
 A comma-separated string without linebreak that defines the header of your CSV file on first write.
 */
@property (nonatomic, nullable) NSString *header;


/**
 The directory URL defines in which directory your logs should be saved.
 Not specifying a URL will default to your app's caches directory.
 */
@property (nullable, atomic) NSURL *directoryURL;


- (NSURL *)fileURL;


/**
 The method creates and returns a new LogFile object that can be used to perform save operations on the specified CSV file.
 
 @param name The name of the CSV file without the file extension.
 @param directoryURL If you want to save your file in a different directory than Caches, provide a URL to that location.
 @param options A bitmask of LogFileOptions that customize the way the CSV is processed.
 @return A properly initialized LogFile object.
 
 No file will be saved to the disk until the first save operation.
 If you want to provide a header row that should be written in front of your data you should use the header property.
 */
+ (instancetype)logFileWithName:(NSString *)name inDirectory:(nullable NSURL *)directoryURL options:(LogFileOption)options;


/**
 Use this method to write to the CSV file. Pass in the values you want to log __in the correct order__. NSArrays will be processed like a list of data spanning multiple columns.
 As default, i.e. without setting the option flag, this row of data will be immediately written to the disk.
 
 @param ... A __nil-terminated__ comma-separated list of columns
 */
- (void)logObjects:(nonnull id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;


/**
 Use this method to write to the CSV file. Pass in the values you want to log __in the correct order__. NSArrays will be processed like a list of data spanning multiple columns.
 As default, i.e. without setting the option flag, this row of data will be immediately written to the disk.
 
 @param array A list of elements that should be logged
 */
- (void)logObjectsInArray:(NSArray *)array;


/**
 You can use this method to manually add rows to your logfile.
 
 @param row A complete row of the file without a line break at the end.
 @return Returns YES if the write operation was successful.
 */
- (BOOL)writeRow:(NSString *)row;


/**
 If you disabled automatic writing for your log, call this method to write these rows to your file that were logged but not saved to disk yet.
 */
- (void)writeOut;


/**
 Use this method to delete the last row from the CSV file.
 If you use automatic row numbering, the line number will not be decreased by this operation.
 */
- (void)removeLastRow;


/**
 Enables your log file to save every few seconds automatically.
 
 @param interval The interval in seconds in which the file should be saved. Minimum is 2 seconds.
 */
- (void)beginSavingPeriodicallyWithInterval:(NSTimeInterval )interval;


- (void)stopSavingAutomatically;

 
/**
 This method deletes the CSV from the disk and also clears the buffer.
 You can continue to use this object for a new log after calling this method.
 
 @return Returns YES if the operation was successful.
 */
- (BOOL)deleteLog;


/**
 Use this method to obtain a list of all logs in a given directory.
 */
+ (NSArray<NSString *> *)allLogsInDirectory:(nullable NSURL *)directoryURL;




#pragma mark - macOS only
#if !TARGET_OS_IPHONE

/**
 The method creates and returns a LogFile object for an existing PDF that the user selects in an OpenPanel. This object can be used to perform save operations on the specified CSV file.
 
 @param options A bitmask of LogFileOptions that customize the way the CSV is processed.
 @return A properly initialized LogFile object if a valid CSV file was selected in the OpenPanel.
 */
+ (nullable instancetype)logFileFromOpenPanelWithOptions:(LogFileOption)options;


/// This method allows you to create a log file from a native save dialog. Hence, you can specify its directory and name in the GUI.
/// @param logFile A pointer to a log file object. If the user completes the file dialog using the save option, it will be set to an actual log file object initialized accordingly.
/// @param options A bitmask of LogFileOptions that customize the way the CSV is processed.
+ (void)createLogFile:(CSVLogFile *__strong _Nonnull *_Nullable)logFile fromFileDialogWithOptions:(LogFileOption)options inWindow:(nullable NSWindow *)window;


/**
 Opens the logged CSV file in the default application associated with this filetype, e.g. Numbers.
 */
- (void)openFile;


/**
 Opens the directory that contains the logged CSV file.
 */
- (void)openDirectory;


/**
 After saving, the file will be moved from its original directory to the new location.
 */
- (void)showSavePanelWithCustomName:(nullable NSString *)customName inWindow:(nullable NSWindow *)window;

#endif

@end

NS_ASSUME_NONNULL_END
