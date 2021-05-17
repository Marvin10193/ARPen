//
//  OpenCVWrapper.mm
//  OpenCV
//
//  Created by Felix Wehnert on 28.09.17.
//  Copyright © 2017 Felix Wehnert. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <aruco/aruco.h>
#endif

#import "OpenCVWrapper.h"
#import <GLKit/GLKit.h>
//#import "calibrator.h"

using namespace std;

aruco::MarkerDetector mDetector;
/// markerSize is the size of the marker in real world in meters.
float markerSizeOriginal = 0.0258; // Lieber Felix. Komm bitte nicht nochmal auf die Idee diesen Wert anzupassen, außer du druckst neue Marker! gez. Felix
float markerSizeRedesigned = 0.0240;
float markerSizeSmall = 0.0144;

// Used to hold the indices for special ARPens
// Original model
const int ORIGINAL_MODEL = 0;
// BackFrontSmall model
const int SMALL_MODEL = 7;

@interface OpenCVWrapper()
@property NSOperationQueue* queue;
@property BOOL isSearching;
@property BOOL isVisible;

@end

@implementation OpenCVWrapper

@synthesize delegate, queue;

-(instancetype)init {
    self = [super init];
    if (self) {
        self.queue = [NSOperationQueue new];

        self.isSearching = false;
        mDetector.setDictionary("ARUCO_MIP_36h12");
    }
    return self;
}

/**
 Finds a marker in a given CVPixelBufferRef
 */
-(void)findMarker:(CVPixelBufferRef)pixelBuffer withCameraIntrinsics:(matrix_float3x3)intrinsics cameraSize:(CGSize)cameraSize currentModel:(int)currentModel {
    
    //Convert intrinsics into cv::Mat
    //Took that from https://github.com/pukeanddie/aruco-arkit-localizer
    cv::Mat cameraMatrix(3,3,CV_64F);
    
    cameraMatrix.at<Float64>(0,0) = intrinsics.columns[0][0];
    cameraMatrix.at<Float64>(0,1) = intrinsics.columns[1][0];
    cameraMatrix.at<Float64>(0,2) = intrinsics.columns[2][0];
    cameraMatrix.at<Float64>(1,0) = intrinsics.columns[0][1];
    cameraMatrix.at<Float64>(1,1) = intrinsics.columns[1][1];
    cameraMatrix.at<Float64>(1,2) = intrinsics.columns[2][1];
    cameraMatrix.at<Float64>(2,0) = intrinsics.columns[0][2];
    cameraMatrix.at<Float64>(2,1) = intrinsics.columns[1][2];
    cameraMatrix.at<Float64>(2,2) = intrinsics.columns[2][2];
    
    //Assuming zero distortions as in aruco-arkit-localizer seem to work pretty good
    cv::Mat distCoeffs = cv::Mat::zeros(5, 1, CV_64F);
    aruco::CameraParameters camParams = aruco::CameraParameters(cameraMatrix, distCoeffs, cv::Size(cameraSize.width, cameraSize.height));
    
    // Check if we are alone in the queue
    if(self.queue.operationCount != 0) {
        return;
    }
    
    // Create a cv:Mat object
    cv::Mat image;
    image = [OpenCVWrapper convertPixelBufferToOpenCV:pixelBuffer];
    if(image.empty()) {
        [self.delegate noMarkerFound];
        return;
    }
    
    [self.queue addOperationWithBlock:^{
        
        //std::vector<SCNVector3> translations;
        NSMutableArray<NSValue*>* rotations = [NSMutableArray array];
        NSMutableArray<NSValue*>* translations = [NSMutableArray array];
        NSMutableArray<NSNumber*>* usedIds = [NSMutableArray array];
        
        std::vector<aruco::Marker> allMarkersOriginal;
        std::vector<aruco::Marker> allMarkersRedesigned;
        std::vector<aruco::Marker> markers;

        std::vector<aruco::Marker> allMarkersSmall;
        std::vector<aruco::Marker> markersSmall;
        
        // Detect the markers in the image -> indices must match ARPenModelKeys indices
        // 0 = original model
        if(currentModel == ORIGINAL_MODEL){
            mDetector.detect(image, allMarkersOriginal, camParams, markerSizeOriginal);
        } else {
            // redesigned model
            mDetector.detect(image, allMarkersRedesigned, camParams, markerSizeRedesigned);
        }
        //additionally check for small markers if needed (7 = backFrontSmall)
        if(currentModel == SMALL_MODEL){
            mDetector.detect(image, allMarkersSmall, camParams, markerSizeSmall);
        }

        std::vector<aruco::Marker>::iterator it;
        int i = 0;
        
        //0: original
        //1: rTop
        //2: rBack
        //3: rFront
        //4: rBackTop
        //5: rBackFront
        //6: rTopFront
        //7:rBackFrontSmall
        if(currentModel == ORIGINAL_MODEL){
            for(it = allMarkersOriginal.begin(); it != allMarkersOriginal.end(); it++) {
                if (it->id < 1 || it->id > 8) {
                    continue;
                }
                markers.push_back(*it);
            }
        } else {
            // Redesigned models
            for(it = allMarkersRedesigned.begin(); it != allMarkersRedesigned.end(); it++) {
                if (it->id < 1 || it->id > 20) {
                    continue;
                }
                switch (it->id){
                    //Back cube
                    case 1 ... 6:
                        if(not(currentModel == 2 || currentModel == 4 || currentModel == 5 || currentModel == 7)) {continue;}
                        break;
                    //CHIARPen(7) and laserMesseARPen(8) are always added
                    case 7 ... 8:
                        break;
                    //Front cube
                    case 9 ... 14:
                        if(not(currentModel == 3 || currentModel == 5 || currentModel == 6)) {continue;}
                        break;
                    //Top cube
                    case 15 ... 20:
                        if(not(currentModel == 1 || currentModel == 4 || currentModel == 6)) {continue;}
                        break;
                }
                markers.push_back(*it);
            }
        }
        
        //additionally check for small markers if needed (7 = backFrontSmall)
        if(currentModel == SMALL_MODEL){
            for(it = allMarkersSmall.begin(); it != allMarkersSmall.end(); it++) {
                if (it->id < 21 || it->id > 26) {
                    continue;
                }
                markersSmall.push_back(*it);
            }
        }
        
        if(markers.size() == 0 && markersSmall.size() == 0) {
            [delegate noMarkerFound];
            return;
        }

        for(i = 0, it = markers.begin(); it != markers.end(); it++,i++) {
            //std::cout << "M = "<< std::endl << " "  << &rvecs << std::endl << std::endl;
            
            //SCNVector4 rotation = SCNVector4Make(r[0], r[1], r[2], r[3]);
            
            //Set the correct marker size for the current model
            vector<cv::Point3f> objpoints = currentModel == ORIGINAL_MODEL ? it->get3DPoints(markerSizeOriginal) : it->get3DPoints(markerSizeRedesigned);
            
            cv::Mat raux, taux;
            cv::solvePnP(objpoints, *it, cameraMatrix, distCoeffs, raux, taux);
            
            cv::Mat rotationMatrix;
            cv::Rodrigues(raux, rotationMatrix);
            cv::Vec3f eulerAngles = [OpenCVWrapper rotationMatrixToEulerAngles:rotationMatrix];
            SCNVector3 rotation = SCNVector3Make(eulerAngles[0], eulerAngles[1], eulerAngles[2]);
            rotation.y *= -1;
            rotation.z *= -1;
            
            taux.convertTo(it->Tvec, CV_32F);
            
            SCNVector3 translation = SCNVector3Make(it->Tvec.at<float>(0,0), it->Tvec.at<float>(0,1), it->Tvec.at<float>(0,2));
            // Convert OpenGL to SceneKit
            translation.y *= -1;
            translation.z *= -1;
            
            [translations addObject:[NSValue valueWithSCNVector3:translation]];
            [rotations addObject:[NSValue valueWithSCNVector3:rotation]];
            [usedIds addObject:[NSNumber numberWithInt:it->id]];
            
        }
        
        if(currentModel == SMALL_MODEL){
            for(i = 0, it = markersSmall.begin(); it != markersSmall.end(); it++,i++) {
                //std::cout << "M = "<< std::endl << " "  << &rvecs << std::endl << std::endl;
                
                //SCNVector4 rotation = SCNVector4Make(r[0], r[1], r[2], r[3]);
                
                vector<cv::Point3f> objpoints = it->get3DPoints(markerSizeSmall);
                
                cv::Mat raux, taux;
                cv::solvePnP(objpoints, *it, cameraMatrix, distCoeffs, raux, taux);
                
                cv::Mat rotationMatrix;
                cv::Rodrigues(raux, rotationMatrix);
                cv::Vec3f eulerAngles = [OpenCVWrapper rotationMatrixToEulerAngles:rotationMatrix];
                SCNVector3 rotation = SCNVector3Make(eulerAngles[0], eulerAngles[1], eulerAngles[2]);
                rotation.y *= -1;
                rotation.z *= -1;
                
                taux.convertTo(it->Tvec, CV_32F);
                
                SCNVector3 translation = SCNVector3Make(it->Tvec.at<float>(0,0), it->Tvec.at<float>(0,1), it->Tvec.at<float>(0,2));
                // Convert OpenGL to SceneKit
                translation.y *= -1;
                translation.z *= -1;
                
                [translations addObject:[NSValue valueWithSCNVector3:translation]];
                [rotations addObject:[NSValue valueWithSCNVector3:rotation]];
                [usedIds addObject:[NSNumber numberWithInt:it->id]];
            }
        }
        
        if(translations.count > 0) {
            // inform the delegate about the new data
            [delegate markerTranslation:translations rotation:rotations ids:usedIds];
        } else {
            [delegate noMarkerFound];
        }
    }];
}

/*
-(CVPixelBufferRef)copy:(CVPixelBufferRef)pixelBuffer {
    // Get pixel buffer info
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    uint8_t* baseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // Copy the pixel buffer
    CVPixelBufferRef pixelBufferCopy = NULL;
    CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, kCVPixelFormatType_32BGRA, NULL, &pixelBufferCopy);
    CVPixelBufferLockBaseAddress(pixelBufferCopy, 0);
    uint8_t* copyBaseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(pixelBufferCopy);
    memcpy(copyBaseAddress, baseAddress, bufferHeight * bytesPerRow);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return pixelBufferCopy;
}
*/

/**
 Helper function to convert a cvPixelBufferRef to an UIImage
 */
+(UIImage*)cvPixelBufferToUIImage:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer),
                                                       CVPixelBufferGetHeight(pixelBuffer))];
    
    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return uiImage;
}

/**
 Helper function
 */
+(cv::Mat)convertPixelBufferToOpenCV:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    
    cv::Mat mat(height, width, CV_8UC1, baseaddress, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return mat;
}

/**
 Helper function to convert a rotationMatrix to an eulerAngle
 */
+(cv::Vec3f)rotationMatrixToEulerAngles:(cv::Mat &)R {
    float sy = sqrt(R.at<double>(0,0) * R.at<double>(0,0) +  R.at<double>(1,0) * R.at<double>(1,0) );
    
    bool singular = sy < 1e-6; // If
    
    float x, y, z;
    if (!singular) {
        x = atan2(R.at<double>(2,1) , R.at<double>(2,2));
        y = atan2(-R.at<double>(2,0), sy);
        z = atan2(R.at<double>(1,0), R.at<double>(0,0));
    } else {
        x = atan2(-R.at<double>(1,2), R.at<double>(1,1));
        y = atan2(-R.at<double>(2,0), sy);
        z = 0;
    }
    return cv::Vec3f(x, y, z);
}

@end
