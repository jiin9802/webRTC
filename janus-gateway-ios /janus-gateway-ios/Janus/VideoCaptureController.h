//
//  VideoCaptureController.h
//  janus-gateway-ios
//
//  Created by 정지인님/Comm Media Cell on 2021/08/11.
//  Copyright © 2021 MineWave. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <WebRTC/RTCCameraVideoCapturer.h>

#import "CaptureController.h"

@interface VideoCaptureController : CaptureController

@property (nonatomic, readonly, copy) AVCaptureDeviceFormat *selectedFormat;
@property (nonatomic, readonly) int frameRate;

-(instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer
                 andConstraints:(NSDictionary *)constraints;
-(void)startCapture;
-(void)stopCapture;
-(void)switchCamera;

@end
