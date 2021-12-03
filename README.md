# Video teleconferencing service

## Project Description
The COVID-19 pandemic has been pushing more and more people in meeting online and the digital fatigue increases rapidly. This led to the increasing use of this application, a free service to online-meeting that can decrease health problems because of using digital devices. You can connect and collaborate with each other in a cohesive virtual meeting space and eventually increase your concentration during online meeting. 

## Technologies
- WebRTC framwork
- Janus-gateway server
  - AWS
  - Nginx
  - DNS mapping
- iOS
  - DeepLabV3 model

## Architecture

# [ViewController](https://github.com/jiin9802/webRTC/blob/master/janus-gateway-ios%20/janus-gateway-ios/Janus/ViewController.m)
ViewController is related to rendering views and control users' enter&exit.
Also, image processing function.

# [MyRemoteRenderer](https://github.com/jiin9802/webRTC/blob/master/janus-gateway-ios%20/janus-gateway-ios/Janus/MyRemoteRenderer.m)
MyRemoteRenderer is a function to receive images, process them, and render them directly to the view. 

## Improving performance
1. Asynchronous processing of image processing, which takes a long time in a background thread
  -> improve performance up to 30%
  
2. Setting the condition of the function that arrange the view
 
## DEMO
![Hnet-image (3)](https://user-images.githubusercontent.com/51341750/139804342-bc7510ea-aa4b-47d4-94bc-c189e2af6e34.gif)

## Next Steps for the Project
1. Improving performance of ML model
2. Converting cpu-based pixel work to GPU
