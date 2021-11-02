# 다자간 영상 통화 서비스 개발
### 개발 목표
비대면 화상 서비스의 사용량이 급증하고 있는 시기에 딱딱한 화면 프레임이 아니라 더욱 더 만남에 몰입할 수 있는 기능을 가진 서비스 개발
### 사용 기술
* janus gateway 서버 구축
  * Nginx
  * AWS
* iOS client
  * WebRTC framework
  * DeepLabV3 ML 모델

### 주요 기능
janus server로부터 받아온 사용자들의 영상을 ML모델을 이용하여 배경과 분리하여 회의실 배경에 배치한다.
회의 참여자들이 마치 한 공간에 있는 듯한 느낌을 주고 더욱 몰입할 수 있는 기능을 제공한다.

### DEMO
<img src="![Hnet-image (3)](https://user-images.githubusercontent.com/51341750/139804342-bc7510ea-aa4b-47d4-94bc-c189e2af6e34.gif)
">

### 개선할 점
* 속도 개선
* 참여 인원 수 증가


### 외부 리소스 참조
