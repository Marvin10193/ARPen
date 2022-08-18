//
//  NSString+LogFile.h
//  CSVLogger
//
//  Created by Sebastian Hueber on 14.01.19.
//

#include <TargetConditionals.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NSString (LogFile)

/**
 Converts a point into a "x,y" string
 */
+ (NSString *)logRepresentationOfPoint:(CGPoint)point;

/**
 Converts a size into a "width,height" string
 */
+ (NSString *)logRepresentationOfSize:(CGSize)size;

/**
 Converts a rect into a "x,y,width,height" string
 */
+ (NSString *)logRepresentationOfRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
