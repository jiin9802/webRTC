//
//  MyRemoteRenderer.h
//  janus-gateway-ios
//
//  Created by 김기철 on 2021/08/13.
//  Copyright © 2021 MineWave. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebRTC/WebRTC.h"

NS_ASSUME_NONNULL_BEGIN

@class MyRemoteRenderer;

@protocol MyRemoteRendererDelegate

- (void)myRemoteRenderer:(MyRemoteRenderer *)renderer renderFrame:(RTCVideoFrame*)frame;

@end


@interface MyRemoteRenderer : NSObject<RTCVideoRenderer>

@property(nonatomic, weak, readonly) id<MyRemoteRendererDelegate> delegate;
- (instancetype)initWithDelegate:(id<MyRemoteRendererDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
