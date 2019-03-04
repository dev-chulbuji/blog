---
title: blog test
date: "2019-03-04"
---

# kubernetes #2 pod, service, namespace

kubernetes의 resource들은 다양한 방법으로 생성 할 수 있다.

* kubectl

* api server

* yaml

* language extension

kubectl은 kubernetes에서 제공하는 command line interface(CLI)로 kubernetes cluster에 명령을 내릴 수 있다. 내부적으론 kubernetes master node의 api server에 명령이 가는 형태이다
> [kubectl 공식 문서 :: kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)

뿐만아니라 인증 절차를 거친다면 명시적으로 api server를 호출하는 형태로 cluster에 명령을 내릴 수 있고 재미있는건 language 마다 다양한 extension들이 있어 application내에서 자유롭게 제어를 할 수 있는 기능도 있다.
> [kubernetes 공식문서 :: client library](https://kubernetes.io/docs/reference/using-api/client-libraries/)

보통 현업에선 대부분 yaml 파일로 resource들을 관리할텐데 형태는 아래와 같다.

![k8s_pod.yaml](https://cdn-images-1.medium.com/max/2000/1*yExyfJcq0VYjnhEXvurizQ.png)*k8s_pod.yaml*

사진은 vscode kubernetes extension을 설치하면 indent warning부터 일부 auto complete 기능도 지원을 한다.

위에서부터 살펴보면 kubernetes의 api version과 이 yaml이 나타내는 kubernetes resource kind, resource meta 정보 그리고 spec이하로 pod내의 container들을 정의한다.

## Pod

그렇다면 kubernetes의 가장 작은 배포 단위인 pod에 대해서 알아보자
> # A Pod encapsulates an application container(s),
> # storage resources, a unique network IP, and options
> # that how the container(s) should run

![kubernetes pod architecture](https://cdn-images-1.medium.com/max/3176/1*Y9Tg7mvjUqmAFopF6wbHnw.png)*kubernetes pod architecture*

pod는 kubernetes의 가장 작은 배포단위로 master node의 scheduling에 의해 실제 workload가 올라가는 node에 배치된다.

pod는 하나 이상의 container들과 생성될 때 node로 부터 할당 받은 storage, network ip를 가진다. 하나 이상의 container이라 하면 실제 application container뿐만 아니라 application의 workload를 돕는 다른 container을 pod라는 개념으로 묶어 배포를 할 수 있다는 의미로 cloud design pattern의 sidecar, ambassador, adapter pattern,..등을 쉽게 구축 할 수 있다.
> [microsoft azure에서 cloud design pattern 자료](https://docs.microsoft.com/ko-kr/azure/architecture/patterns/)

간단한 예로 network proxy하는 container를 붙인다거나 log파일을 퍼나르는 container, platform에 맞게 response type을 지정해주는 container를 붙이는등 여러가지 형태로 pod를 구성 할 수 있다.

pod의 특징에는 pod내의 container들을 storage와 ip를 공유한다는 특징이 있는데

![share each container port](https://cdn-images-1.medium.com/max/3356/1*0dz0sk1Mhb8YviK6fpqOuA.png)*share each container port*

pod내의 container들끼리는 서로 localhost로 요청이 가능하고 storage도 공유 할 수 있다.

## Service

service는 pod라는 개념으로 container를 배포하고 난 후 service라는 resource를 통해 배포된 container들을 cluster 내외부에 노출 시킬 수 있는 pod의 loadbalancer다.

![the set of pod targeted by a service](https://cdn-images-1.medium.com/max/4100/1*QkKZa6xatrexevyfOCh-pA.png)*the set of pod targeted by a service*

kubernetes에서 deployment로 관리된 pod는 ReplicaSet에 의해 언제든 없어지고 다시 살아난다. 만약 frontend container와 backend container가 있을 때 frontend container에서 backend container를 어떻게 찾을 수 있을까? 배포 당시 같은 Node에 배포가 됬고 backend container에서 application의 Port를 안다면 접근 할 수 있겠지만 pod는 master node의 scheduling에 의해 어떤 node에 배포되는지 알 수 없다. 이런 상황에서 service는 label selector를 통해 pod들을 논리적으로 묶어 type에 따라 cluster 내/외부에 노출시킨다.

![join pod to service](https://cdn-images-1.medium.com/max/4792/1*SPt_7cm2Z1odPVdObogaHw.png)*join pod to service*

service에는 크게 4가지 타입이 있다.

1. ClusterIP

1. NodePort

1. LoadBalancer

1. ExternalName

![clusterIP type service](https://cdn-images-1.medium.com/max/2000/0*tZbn3fTdgZyWsgz6)*clusterIP type service*

ClusterIP 는 cluster 내부에 특정 ip로 노출시키는 역활을 하고 NodePort 는 cluster 외부로 특정 ip를 노출 시킨다. NodePort 로 service를 생성하면 ClusterIP 가 자동으로 생성되며 NodeIP:NodePort 로 cluster 외부에서 호출이 가능하다.

![loadbalancer type service](https://cdn-images-1.medium.com/max/2000/0*EEPGK2QM_UMgWYaP)*loadbalancer type service*

LoadBalancer는 cloud provider의 load balancer를 통해 외부로 service를 노출시키며 aws에 cluster를 구성 후 service type을 LoadBalancer타입으로 하면 ELB가 생겨 해당 pod가 있는 node의 instance를 ELB에 묶어준다. 그리고 위와 같이 loadBalancerIP를 지정해주면 Network Load Balancer(NLB)로 특정 ip를 LB에 엮는 형태로 aws에서 쉽게 구축 할 수 있다.

마지막으로 ExternalName 은 cluster내부에서 외부 서비스를 접근하는 방법으로 외부의 database에 접근한다고 할 때 ExternalName 으로 외부 서비스를 연결해 호출 할 수 있다.

![externalName type service](https://cdn-images-1.medium.com/max/2624/1*uzmYeqSy_8Uter224Jd2DA.png)*externalName type service*

![externalName type service yaml](https://cdn-images-1.medium.com/max/2224/1*uUNhkyrXL5C1VOn9aSMKbA.png)*externalName type service yaml*

## Namespace

![kubernetes namespace](https://cdn-images-1.medium.com/max/4880/1*zSTrQt8ePD1K8W1fOa4ySA.png)*kubernetes namespace*

kubernetes에서는 namespace라는 논리적 단위로 가상 cluster 묶음을 구성 할 수 있다.

위와 같이 dev, qa, prod namespace로 cluster를 구분 할 수 있고 각 namespace별로 user access policy, system quota를 따로 줄 수 있다.

주의해야 할 부분은 namespace는 논리적인 분리이지 물리적인 분리가 아니다.

![namespace is not physical isolation](https://cdn-images-1.medium.com/max/4520/1*rsmCPG3lKruqbPtBI9eHzg.png)*namespace is not physical isolation*

다른 namespace간의 pod끼리도 통신이 가능하다.

## ConfigMap & Secret

실제 서비스에서는 환경에 따라 다른 설정값들을 가진다. staging된 환경에서 각 환경에 맞는 db 정보, 디버그 모드, apikey 등이 있는데 이러한 정보를 kubernetes에서는 configMap과 secret resource를 따로 두어 환경에 맞게 container들에게 주입시켜준다. 이를 통해 개발과 실제 서비스 환경에서 설정 값을 따로 주어 동일한 container를 운영 할 수 있다.

configMap과 secret의 경우 2가지 방법으로 container에 주입시켜 줄 수 있는데 환경변수로 값을 주는 경우와 config, secret을 container에 volume mount 시키는 방법이다.

kubernetes에서 configMap과 secret은 master node의 etcd에 저장되는데 secret의 경우 기본적으로 설정이 없다면 암호화 되지 않는 평문으로 저장이 된다. 실제로 kubernetes의 dashboard를 사용하다 api token이 노출되면서 master node의 etcd가 털려 서비스가 전체로 털리는 사례가 있다고 하니 kubernetes cluster 구성할 때 secret에 관한 설정을 해주거나 etcd 접근을 제한하는 것이 중요하다.

![kubernetes configMap&security env variable](https://cdn-images-1.medium.com/max/3428/1*DHlcoyKn-wdRQwMMJHu49w.png)*kubernetes configMap&security env variable*

위와 같이 valueFrom으로 지정해놓은 configMap과 secret을 container내의 RDS라는 환경변수로 주입 시켜 줄 수 있다. 2번째 설정 파일을 volume mount하는 방법은 kubernetes의 volume이란 개념을 알아보면서 같이 소개를 하겠다.