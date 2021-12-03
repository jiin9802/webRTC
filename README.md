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
1. Sharing the rough ideas with other students who have technical backgrounds. 
   - This application was originally designed exclusively for users, donors and recipients, but there was a feedback saying that adding another authentication for administrators to manage food banks would be a great idea. 
   - **Solution**: Separate UI and account for users and administrators. The final application has two different landing pages. When logged in as admin, it shows a list of all the foods and members’ profile information while the user account shows a list of foods based on the location and their personal profile
 
 2. Asking potential app users with a wide range of ages about their concerns or suggestions after implementing basic functionalities, such as donating and receiving food items, labelling food banks on Google Maps API and managing users on admin accounts.
    - Users side: How trustful the app would be. They suggested that there should be an action in the case that someone puts bad or expired food. 
    - Admin side: How to increase the management efficiency. It would be hard to place at least one administrator at every single location. So, there should be a system to keep track of food flows.
    - **Solution**: Gave the administrators the rights to give penalties if needed. Anyone who got more than two penalties would not be allowed to use the food bank service anymore. Also, personal QR code per user has been added to help the management. People who want to either donate or take out food must scan their assigned QR code to access the food bank or open the fridge if they have one. It sends the food and user real-time information to the server and notifies the administrator, which doesn’t require in-person management to keep security.


## DEMO
![Hnet-image (3)](https://user-images.githubusercontent.com/51341750/139804342-bc7510ea-aa4b-47d4-94bc-c189e2af6e34.gif)

## Next Steps for the Project
