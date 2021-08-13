#import <UIKit/UIKit.h>
#import "WebSocketChannel.h"
#import "WebRTC/WebRTC.h"
#import "MyRemoteRenderer.h"


@import Accelerate;

@protocol WebSocketDelegate <NSObject>
- (void)onPublisherJoined:(NSNumber *)handleId;
- (void)onPublisherRemoteJsep:(NSNumber *)handleId dict:(NSDictionary *)jsep;
- (void)subscriberHandleRemoteJsep: (NSNumber *)handleId dict:(NSDictionary *)jsep;
- (void)onLeaving:(NSNumber *)handleId;
@end


@interface ViewController : UIViewController<RTCPeerConnectionDelegate, WebSocketDelegate, RTCEAGLVideoViewDelegate, MyRemoteRendererDelegate>

@property(nonatomic, strong) RTCPeerConnectionFactory *factory;

- (void)renderFrame:(RTCVideoFrame*)frame;

@end


