//
//  MyRemoteRenderer.m
//  janus-gateway-ios
//
//  Created by 김기철 on 2021/08/13.
//  Copyright © 2021 MineWave. All rights reserved.
//

#import "MyRemoteRenderer.h"

@implementation MyRemoteRenderer

- (instancetype)initWithDelegate:(id<MyRemoteRendererDelegate>)delegate { //인자로 request추가?
    if (self = [super init]) {
        _delegate = delegate;
    }
    return self;
}

- (void)renderFrame:(nullable RTCVideoFrame *)frame {
    //video track에서 호출해줄거임..
    [_delegate myRemoteRenderer:self
                    renderFrame:frame];
}
//-(void)coreMLRequest:(

- (void)setSize:(CGSize)size {
    
}

@end
