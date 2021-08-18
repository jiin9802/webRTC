
#import "ViewController.h"
#import "WebSocketChannel.h"
#import <WebRTC/WebRTC.h>
#import "RTCSessionDescription+JSON.h"
#import "JanusConnection.h"
#import <Vision/Vision.h>
#import <CoreML/CoreML.h>
#import "DeepLabV3.h"
#import "DeepLabV3FP16.h"
#import "DeepLabV3Int8LUT.h"


static NSString * const kARDMediaStreamId = @"ARDAMS";
static NSString * const kARDAudioTrackId = @"ARDAMSa0";
static NSString * const kARDVideoTrackId = @"ARDAMSv0";

@interface ViewController () <RTCVideoCapturerDelegate>
//@property (strong, nonatomic) RTCCameraPreviewView *localView;
//rtccamerapreviewview->uiview
@property (weak, nonatomic) IBOutlet RTCMTLVideoView *local_view;
@property (weak, nonatomic) IBOutlet UIView *remoteView1;
@property (weak, nonatomic) IBOutlet UIView *remoteView2;
@property (weak, nonatomic) IBOutlet UIView *remoteView3;

@end

@implementation ViewController

RTCEAGLVideoView *image_view;
RTCCameraVideoCapturer * videoCapturer;
WebSocketChannel *websocket;
NSMutableDictionary *peerConnectionDict;
NSMutableArray *peerConnectionArray;
NSArray *resultArray;
NSMutableArray *view_arr;
VNCoreMLModel *coremodel;
DeepLabV3FP16 *model;
VNCoreMLRequest *coreMLRequest;
VNImageRequestHandler *img_handler;
RTCVideoFrame *newFrame;
MLMultiArray *inferenceResult;

RTCPeerConnection *publisherPeerConnection;
RTCVideoTrack *localTrack;
RTCAudioTrack *localAudioTrack;

int height = 0;
//NSMutableArray *arr;
@synthesize factory = _factory;
//@synthesize localView = _localView;

- (void)viewDidLoad {
    [super viewDidLoad];
    image_view=[[RTCEAGLVideoView alloc]init];

    peerConnectionArray=[[NSMutableArray alloc] init];

    view_arr=[NSMutableArray arrayWithCapacity:3];
    [view_arr insertObject:self.remoteView1 atIndex:0];
    [view_arr insertObject:self.remoteView2 atIndex:1];
    [view_arr insertObject:self.remoteView3 atIndex:2];

    //setupmodel
    model = [[DeepLabV3FP16 alloc]init];
    coremodel = [VNCoreMLModel modelForMLModel:model.model error:nil];
    if (coremodel) {
        coreMLRequest = [[VNCoreMLRequest alloc] initWithModel:coremodel
                                             completionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            [self visionRequestDidComplete:coreMLRequest error:error];
            coreMLRequest.imageCropAndScaleOption=VNImageCropAndScaleOptionScaleFill;
        }];
    }

    videoCapturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:self];
    NSArray *device = [RTCCameraVideoCapturer captureDevices];

    NSArray<AVCaptureDeviceFormat *> *formatList = [RTCCameraVideoCapturer supportedFormatsForDevice:device[1]];
    for (AVCaptureDeviceFormat *format in formatList) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        if (dimension.width >= 360 || dimension.height >= 360) {
            [videoCapturer startCaptureWithDevice:device[1]
                                           format:format
                                              fps:10];
            break;
        }
    }

    NSURL *url = [[NSURL alloc] initWithString:@"wss://18.223.76.233/websocket"];
    websocket = [[WebSocketChannel alloc] initWithURL: url]; //url설정, timer설정 등등 socket open
    websocket.delegate = self;

    peerConnectionDict = [NSMutableDictionary dictionary];
    _factory = [[RTCPeerConnectionFactory alloc] init];
    localTrack = [self createLocalVideoTrack];
    localAudioTrack = [self createLocalAudioTrack];
}
-(void)arrangeRemoteView{
    NSInteger i=0;
    
    for(JanusConnection *peerConnection in peerConnectionArray)
    {
        if(i>=[view_arr count]) //3개의 뷰만 constraint로 표현될 수 있게 peerconnectionarray에 있는 다른 것들은 표시 안되게, for(view_arr수만큼)대신한 문장
        {
            break;
        }
        
        
        RTCEAGLVideoView *remote_View =peerConnection.videoView;
        [view_arr[i] addSubview:remote_View];
       // [view_arr[i] subviews]
        remote_View.translatesAutoresizingMaskIntoConstraints=NO;
        
        NSLayoutConstraint *constraint1=[NSLayoutConstraint constraintWithItem:remote_View attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view_arr[i] attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f];
        NSLayoutConstraint *constraint2=[NSLayoutConstraint constraintWithItem:remote_View attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view_arr[i] attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f];
        NSLayoutConstraint *constraint3=[NSLayoutConstraint constraintWithItem:remote_View attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view_arr[i] attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f];
        NSLayoutConstraint *constraint4=[NSLayoutConstraint constraintWithItem:remote_View attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:view_arr[i] attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f];
       
        [view_arr[i] addConstraints:@[constraint1,constraint2,constraint3,constraint4]];
        i++;
        
    }
}
- (RTCEAGLVideoView *)createRemoteView {
    NSInteger index;
    RTCEAGLVideoView *remoteView = [[RTCEAGLVideoView alloc] init];
    //remoteView.contentMode=UIViewContentModeScaleAspectFill;
    //[remoteView renderFrame:nil];
    remoteView.delegate = self;

    return remoteView;
}
- (void)createPublisherPeerConnection {
    publisherPeerConnection = [self createPeerConnection];
    [self createAudioSender:publisherPeerConnection];
    [self createVideoSender:publisherPeerConnection];
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    NSDictionary *optionalConstraints = @{ @"DtlsSrtpKeyAgreement" : @"true" };
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil  optionalConstraints:optionalConstraints];
    return constraints;
}

- (RTCIceServer *)defaultSTUNServer {
    NSArray *array = [NSArray arrayWithObject:@"turn:101.101.208.163:3478"];
    return [[RTCIceServer alloc] initWithURLStrings:array
                                           username:@"myuser"
                                         credential:@"1234"];
}

- (RTCPeerConnection *)createPeerConnection {
    RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    NSMutableArray *iceServers = [NSMutableArray arrayWithObject:[self defaultSTUNServer]];
    config.iceServers = iceServers;
    config.iceTransportPolicy = RTCIceTransportPolicyRelay;
    RTCPeerConnection *peerConnection = [_factory peerConnectionWithConfiguration:config
                                         constraints:constraints
                                            delegate:self];
    return peerConnection;
}

- (void)offerPeerConnection: (NSNumber*) handleId {
    [self createPublisherPeerConnection];
    JanusConnection *jc = [[JanusConnection alloc] init];
    jc.connection = publisherPeerConnection;
    jc.handleId = handleId;
    peerConnectionDict[handleId] = jc;

    [publisherPeerConnection offerForConstraints:[self defaultOfferConstraints]
                       completionHandler:^(RTCSessionDescription *sdp,
                                           NSError *error) {
                           [publisherPeerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                               [websocket publisherCreateOffer: handleId sdp:sdp];
                           }];
                       }];
}

- (RTCMediaConstraints *)defaultMediaAudioConstraints {
//    NSDictionary *mandatoryConstraints = @{ kRTCMediaConstraintsLevelControl : kRTCMediaConstraintsValueFalse };
    RTCMediaConstraints *constraints =
    [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil/*mandatoryConstraints*/
                                          optionalConstraints:nil];
    return constraints;
}


- (RTCMediaConstraints *)defaultOfferConstraints {
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio" : @"false",
                                           @"OfferToReceiveVideo" : @"false"
                                           };
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
    return constraints;
}

- (RTCAudioTrack *)createLocalAudioTrack {
    
    RTCMediaConstraints *constraints = [self defaultMediaAudioConstraints];
    RTCAudioSource *source = [_factory audioSourceWithConstraints:constraints];
    RTCAudioTrack *track = [_factory audioTrackWithSource:source trackId:kARDAudioTrackId];

    return track;
}
//RTCCameraVideoCapturer

- (RTCRtpSender *)createAudioSender:(RTCPeerConnection *)peerConnection {
    RTCRtpSender *sender = [peerConnection senderWithKind:kRTCMediaStreamTrackKindAudio streamId:kARDMediaStreamId];
    if (localAudioTrack) {
        sender.track = localAudioTrack;
    }
    return sender;
}

- (RTCVideoTrack *)createLocalVideoTrack {

    RTCVideoTrack *localVideoTrack = [_factory videoTrackWithSource:[_factory videoSource] trackId:kARDVideoTrackId];

    return localVideoTrack;
}

- (RTCRtpSender *)createVideoSender:(RTCPeerConnection *)peerConnection {
    RTCRtpSender *sender = [peerConnection senderWithKind:kRTCMediaStreamTrackKindVideo
                                                 streamId:kARDMediaStreamId];
    if (localTrack) {
        sender.track = localTrack;
    }

    return sender;
}

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    CGRect rect = videoView.frame;
    rect.size = size;
    NSLog(@"========didChangeVideiSize %fx%f", size.width, size.height);
    //videoView.frame = rect;
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream {
    NSLog(@"=========didAddStream");
    NSInteger index=0;
    JanusConnection *janusConnection;
    for (NSNumber *key in peerConnectionDict) {
        JanusConnection *jc = peerConnectionDict[key];
        if (peerConnection == jc.connection) {
            janusConnection = jc;
            break;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (stream.videoTracks.count) {
            RTCVideoTrack *remoteVideoTrack = stream.videoTracks[0];
            RTCEAGLVideoView *remoteView=[self createRemoteView];
//            [remoteVideoTrack addRenderer:remoteView];
            MyRemoteRenderer *remoteRenderer = [[MyRemoteRenderer alloc] initWithDelegate:self];
            [remoteVideoTrack addRenderer:remoteRenderer];
            janusConnection.videoTrack = remoteVideoTrack;
            janusConnection.videoView=remoteView;
            [peerConnectionArray addObject:janusConnection];
            [self arrangeRemoteView];
            //janusConnection.videoView.contentMode=UIViewContentModeScaleAspectFit;
        }
    });
//    for(NSInteger i=0; i<[view count];i++){
//        NSLog(@"===========objectatIndex view[%ld]=[%ld]",(long)i,(long)[view[i] integerValue]);
//        //NSLog(@"type:",[view[i] class]);
//    }
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream {
    NSLog(@"=========didRemoveStream");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel {

}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {

}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    NSLog(@"=========didGenerateIceCandidate==%@", candidate.sdp);

    NSNumber *handleId;
    for (NSNumber *key in peerConnectionDict) {
        JanusConnection *jc = peerConnectionDict[key];
        if (peerConnection == jc.connection) {
            handleId = jc.handleId;
            break;
        }
    }
    if (candidate != nil) {
        [websocket trickleCandidate:handleId candidate:candidate];
    } else {
        [websocket trickleCandidateComplete: handleId];
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    
}

- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {

}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"=========didRemoveIceCandidates");
}


// mark: delegate

- (void)onPublisherJoined: (NSNumber*) handleId {
    [self offerPeerConnection:handleId];
}

- (void)onPublisherRemoteJsep:(NSNumber *)handleId dict:(NSDictionary *)jsep {
    JanusConnection *jc = peerConnectionDict[handleId];
    RTCSessionDescription *answerDescription = [RTCSessionDescription descriptionFromJSONDictionary:jsep];
    [jc.connection setRemoteDescription:answerDescription completionHandler:^(NSError * _Nullable error) {
    }];
}

- (void)subscriberHandleRemoteJsep: (NSNumber *)handleId dict:(NSDictionary *)jsep {
    RTCPeerConnection *peerConnection = [self createPeerConnection];

    JanusConnection *jc = [[JanusConnection alloc] init];
    jc.connection = peerConnection;
    jc.handleId = handleId;
    peerConnectionDict[handleId] = jc;

    RTCSessionDescription *answerDescription = [RTCSessionDescription descriptionFromJSONDictionary:jsep];
    [peerConnection setRemoteDescription:answerDescription completionHandler:^(NSError * _Nullable error) {
    }];
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio" : @"true",
                                           @"OfferToReceiveVideo" : @"true",
                                           };
    RTCMediaConstraints* constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];

    [peerConnection answerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        [peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
        }];
        [websocket subscriberCreateAnswer:handleId sdp:sdp];
    }];

}

- (void)onLeaving:(NSNumber *)handleId {
    JanusConnection *jc = peerConnectionDict[handleId];
    NSInteger p;
    NSPredicate *predicate=[NSPredicate predicateWithFormat:@"handleId == %@",jc.handleId];
    resultArray=[peerConnectionArray filteredArrayUsingPredicate:predicate];
    for(JanusConnection *peerConnection in peerConnectionArray)
    {
        if(peerConnection==resultArray[0])
        {
            p=[peerConnectionArray indexOfObject:peerConnection];
        }
    }
    [peerConnectionArray removeObjectsInArray:resultArray];
    [jc.connection close];
    jc.connection = nil;
    RTCVideoTrack *videoTrack = jc.videoTrack;
    [videoTrack removeRenderer: jc.videoView];
    videoTrack = nil;
    [jc.videoView renderFrame:nil];
    [jc.videoView removeFromSuperview];
    
    [peerConnectionDict removeObjectForKey:handleId];
    if(p<[view_arr count]) //4번째 입장하는 사람들이 왔다갔다 해도 arrangeview안되게
    {
        for(NSInteger i=0; i<[view_arr count];i++){
            for(UIView *v in [view_arr[i] subviews])
            {
                [v removeFromSuperview];
            }
        }
        [self arrangeRemoteView];
    }
}

#pragma mark - RTCVideoCaptureDelegate
//capture될때마다 delegate호출되어서 밑에 함수 실행:view에 rendering
-(void)capturer:(RTCVideoCapturer *)capturer didCaptureVideoFrame:(RTCVideoFrame *)frame
{
    //frame의 pixelbuffer를 rendering해서 uiview에 그리기
   // [frame initWithBuffer:<#(nonnull id<RTCVideoFrameBuffer>)#> rotation:<#(RTCVideoRotation)#> timeStampNs:<#(int64_t)#>]
    [localTrack.source capturer:capturer didCaptureVideoFrame:frame]; //remote에 쏴주기
    
    RTCCVPixelBuffer* remotepixel=(RTCCVPixelBuffer*)frame.buffer;
    CVPixelBufferRef pixelBuffer=remotepixel.pixelBuffer;
    if (coreMLRequest) {
        img_handler=[[VNImageRequestHandler alloc]initWithCVPixelBuffer:pixelBuffer options:@{}];
        [img_handler performRequests:@[coreMLRequest] error:nil];

    }
//    [self.local_view renderFrame:frame];
    [self renderLocalViewWithNewVideoFrame:frame
                           inferenceResult:inferenceResult];
    NSLog(@"========didcapturevideoframe 호출됨");
}

#pragma mark - MyRemoteRendererDelegate
- (void)myRemoteRenderer:(MyRemoteRenderer *)renderer renderFrame:(RTCVideoFrame*)frame {
    //myRenderer가 토스해주는 frame을 받음.
    dispatch_async(dispatch_get_main_queue(), ^{//작업이 오래 걸리는 걸 백그라운드에서 실행시키기 위해
        for (int i=0;i<[view_arr count];i++){
            for (RTCEAGLVideoView *view in [view_arr[i] subviews]) {
                [view renderFrame:frame];
            }
        }
    });
}

#pragma mark - Handler
- (void)visionRequestDidComplete:(VNRequest *)request error:(NSError *)error {
    NSLog(@"========visionRequestDidComplete 호출됨");

    dispatch_async(dispatch_get_main_queue(), ^{//작업이 오래 걸리는 걸 백그라운드에서 실행시키기 위해
        inferenceResult = [[request.results[0] featureValue] multiArrayValue];
        
        // 513 x 513 pixelBuffer를 생성
        // pixelBuffer에 mlMultiArray의 값으로 흰색 / 검은색을 구분하여 채웁니다.
        // pixelBuffer를 RTCVideoFrame으로 만듭니다.
        // local_view에 renderFrame으로 rendering해줍니다.
    });
}

- (void)renderLocalViewWithNewVideoFrame:(RTCVideoFrame *)videoFrame
                         inferenceResult:(MLMultiArray *)inferenceResult {
    if (videoFrame == nil || inferenceResult == nil) {
        return;
    }
    
    int segmentationWidth = [inferenceResult.shape[0] intValue];
    int segmentationHeight = [inferenceResult.shape[1] intValue];
    
//    CVPixelBufferRef pixelBuffer = ((RTCCVPixelBuffer*)newFrame.buffer).pixelBuffer;
//    size_t pixelBufferWidth = CVPixelBufferGetWidth(pixelBuffer);
//    size_t pixelBufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    // TODO::videoFrame -> pixelbuffer format을 32bgra로 전환시키거나, 새로운 pixel buffer로 만들어서
    // inferenceResult를 기반으로 배경을 지워서 보여주자!(inferece result 값이 0 인 경우 검정색으로 색칠..)
    
    CVPixelBufferRef pixelBuffer = [self createPixelBufferWithSize:CGSizeMake(segmentationWidth, segmentationHeight)];
    
    const int kBytesPerPixel = 4;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);

    for (int row=0; row<segmentationHeight; row++) {
        uint8_t *pixel = baseAddress + row * bytesPerRow;
        for (int column=0; column<segmentationWidth; column++) {
            int index = column * segmentationHeight + row;
            if (inferenceResult[index].shortValue > 0) {
                pixel[0] = 255; // BGRA, Blue value
                pixel[1] = 255; // Green value
                pixel[2] = 255; // Red value
            } else {
                pixel[0] = 0; // BGRA, Blue value
                pixel[1] = 0; // Green value
                pixel[2] = 0; // Red value
            }
            pixel += kBytesPerPixel;
        }
    }
//    for (int row=0; row<pixelBufferHeight; row++) {
//        uint8_t *pixel = baseAddress + row * bytesPerRow;
//        for (int column=0; column<pixelBufferWidth; column++) {
//            int index = column * segmentationHeight * (segmentationHeight / pixelBufferHeight)
//                        + row * (segmentationWidth / pixelBufferWidth);
//            if (inferenceResult[index].shortValue == 0) {
//                pixel[0] = 0; // BGRA, Blue value
//                pixel[1] = 0; // Green value
//                pixel[2] = 0; // Red value
//            }
//            pixel += kBytesPerPixel;
//        }
//    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    RTCCVPixelBuffer *rtcPixelBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:pixelBuffer];
    RTCVideoFrame *newVideoFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcPixelBuffer
                                                                rotation:RTCVideoRotation_0
                                                             timeStampNs:[NSDate date].timeIntervalSince1970];
    [self.local_view renderFrame:newVideoFrame];
}

- (nonnull CVImageBufferRef)createPixelBufferWithSize:(CGSize)size {
    CVPixelBufferRef pixelBuffer = NULL;
    static size_t const attributes_size = 3;
    CFTypeRef attributesKeys[attributes_size] = {
        kCVPixelBufferMetalCompatibilityKey,
        kCVPixelBufferIOSurfacePropertiesKey,
        kCVPixelBufferPixelFormatTypeKey
    };
    
    CFDictionaryRef io_surface_value = CFDictionaryCreate(NULL,
                                                          NULL, NULL, 0,
                                                          &kCFTypeDictionaryKeyCallBacks,
                                                          &kCFTypeDictionaryValueCallBacks);
    
    int64_t nv12type = kCVPixelFormatType_32BGRA;
    CFNumberRef pixel_format = CFNumberCreate(NULL, kCFNumberLongType, &nv12type);
    CFTypeRef values[attributes_size] = {kCFBooleanTrue, io_surface_value, pixel_format};
    CFDictionaryRef attributes = CFDictionaryCreate(NULL,
                                                    attributesKeys, values, attributes_size,
                                                    &kCFTypeDictionaryKeyCallBacks,
                                                    &kCFTypeDictionaryValueCallBacks);
    if (io_surface_value) {
        CFRelease(io_surface_value);
        io_surface_value = NULL;
    }
    if (pixel_format) {
        CFRelease(pixel_format);
        pixel_format = NULL;
    }
    
    CVReturn returnValue = CVPixelBufferCreate(kCFAllocatorDefault,
                                               (size_t)(size.width),
                                               (size_t)(size.height),
                                               kCVPixelFormatType_32BGRA,
                                               attributes,
                                               &pixelBuffer);
    CFRelease(attributes);
    if(returnValue != kCVReturnSuccess) {
        return nil;
    }
    
    CVPixelBufferLockFlags unlockFlags = kNilOptions;
    CVPixelBufferLockBaseAddress(pixelBuffer, unlockFlags);
    uint8_t *baseAddress = (unsigned char *)(CVPixelBufferGetBaseAddress(pixelBuffer));
    memset(baseAddress, 0xFF, size.width * size.height * 4);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return pixelBuffer;
}

@end
