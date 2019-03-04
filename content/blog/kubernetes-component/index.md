---
title: kubernetes component
date: "2018-12-22"
description: k8s component master & worker node
---

## kubernetes #1 component

kuberernetes는 linux container cluster를 하나의 단일 시스템으로 관리하여 운영 관리 이슈를 줄여 개발에 더욱 집중할 수 있는 docker orchestration의 하나로 구글의 수많은 머신 클러스터를 관리하는 borg라는 프로젝트에서 파생된 오픈소스 프로젝트이다.

docker swarm , rancher, mesos뿐 아니라 다양한 container orchestration이 있지만 kubernetesr가 표준 아닌 표준으로 자리 잡은 상황이다.

개인적으로 공부하면서 느낀 건 kubernetes는 일종의 기술이면서 spec이다.

container cluster를 운영하면서 필요한 여러 기술들을 추상화된 개념으로 소개하고 몇몇 개념들에서는 spec 개념으로 구현체를 따로 구현해야 하는 경우가 있다.

실제 서비스에선 다양한 서버 환경들이 있고 cloud service를 사용하는 환경뿐 아니라 온프레미스 그리고 멀티 cloud service, cloud service + on-premise로 구축된 다양한 서버 환경들이 있다.

특히 cloud service 같은 경우 각 벤더마다 접근하는 방식과 구현 방식이 다르기 때문에 모든 케이스를 아우르는 container cluster 기술을 구축하기란 현실적으로 한계가 있다

이런 부분에서 kubernetes에선 적절한 spec 을 제시하면서 구글에서의 노하우를 바탕으로 실제 서비스를 운영하는데 필요한 다양한 케이스들을 커버한다.

앞으로의 글에서는 그간 삽질하면서 열심히 공부해왔던 kubernetes의 개념적인 부분을 최대한 상세히 알아보려고 한다.

### # kubernetes architecture

![kubernetes architecture](https://cdn-images-1.medium.com/max/800/0*parN9vK2eBPFlgUy)*kubernetes architecture*

### # kubernetes component

kubernetes는 크게 master node와 nod( worker node, minion ) 2개로 나뉜다.

### ## k8s master node

master node는 cluster control tower로 cluster를 관리하고 설정 환경을 저장하는 역할을 한다.

![kubernetes master node component](https://cdn-images-1.medium.com/max/800/1*oQkc9gI69u4TNZqyekCwiw.png)*kubernetes master node component*

사진 설명을 입력하세요.

master node는 api server, scheduler, etcd, controller manager 총 4개의 요소들로 구성된다.

### ### kubernetes master node — api server

![kubernetes master node api server](https://cdn-images-1.medium.com/max/800/1*E7a2ZT3UlURRVfVpd_PVZA.png)*kubernetes master node api server*

master node의 api sever는 kubernetes rest api 제공하는 역할을 하며 kubernetes cli 도구인 kubectl로 들어오는 명령과 rest api call에 의한 request를 받아서 worker node(kublet)들에게 req를 전달하는 역할을 한다.

### ### kubernetes master node — scheduler

![kubernetes master node scheduler](https://cdn-images-1.medium.com/max/800/1*krZiYgzISJqLNWSVTWpRVw.png)*kubernetes master node scheduler*

scheduler는 말 그대로 kubernetes의 가장 최소 배포 단위인 pod들을 어떤 worker node에 배치할지를 책임지는 역할을 한다.

그림에서 보면 기본적으로 resource가 pod가 배치되기 적당한 node를 선정하며 다양한 scheduling 전략을 구성할 수 있도록 kubernetes에는 다양한 개념들이 있다 (ex: label selector, taint, toleration, affinity,..)

### ### kubernetes master node — etcd

![kubernetes master node etcd](https://cdn-images-1.medium.com/max/800/1*ANx979KuseQsivNZv-FcwQ.png)*kubernetes master node etcd*

kubernetes는 cluster의 모든 정보를 고가용성의 분산 key-value store인 etcd에 저장을 한다.

### ### kubernetes master node — controller manager

![kubernetes master node controller manager](https://cdn-images-1.medium.com/max/800/1*WrNYta1830DfkJ5JFYmVUQ.png)*kubernetes master node controller manager*

controller manager는 control loop를 도는 controller들을 구동하는 관리자 역할을 담당하며 ontrol loop란 system의 상태와 상관없이 무한히 loop를 돌며 api server를 통해 etcd에 저장되어 있는 cluster 상태(desired 한 상태)를 유지하는 역활을 한다

Node controller: node가 죽었을 때를 인식하고 알리는 역할을 한다

Replication controller: Replication controller의 현재 pod 개수를 유지하는 역할을 한다

Endpoint controller: Service와 pod를 연결하는 것과 같은 Endpoint 객체를 유지한다

Service Account & Token controller: kubernetes의 논리적 단위인 namespace가 생성됐을 때 default account와 api token을 생성한다.

### ### kubernetes master node — cloud controller manager

![kubernetes master node cloud controller manager](https://cdn-images-1.medium.com/max/800/0*3txDsz6iFjaguSzt)*kubernetes master node cloud controller manager*

cloud controller manager이란 기존에 controller manager에 있던 cloud 벤더사에 디펜던시가 있던 부분이 버전 1.6부터 빠져나온 개념이다.

이전의 Kubernetes core code에 cloud service를 지원하는 부분에서 cloud service 벤더사의 cloud provider에 의존성이 있을 수밖에 없었다. 버전 1.6이후 kubernetes의 core 코드와 각 벤더사의 provider 사이에 의존성을 없애려 기존의 controller manager에서 빠져나온 개념으로 k8s core code 독릭접으로 발전 할 수 있는 역할을 한다.

### ## k8s node ( worker node, minion )

![kubernetes node component](https://cdn-images-1.medium.com/max/800/1*bR7T6SUfzdJOoOxvke8y9A.png)*kubernetes node component*

node는 실제 work load가 올라가는 부분으로 pod들을 관리하고 kubernetes 실행 환경을 제공한다.

### ### kubernetes node — kublet

![kubernetes node kublet](https://cdn-images-1.medium.com/max/800/1*JJj_wfZ6tdlsi_icVxl7EA.png)*kubernetes node kublet*

kublet은 agent로 master node의 api server와 통신하며 전달받은 명령을 처리하고 node의 상태를 master node에 전달하는 역할로 node 내의 pod들, pod 내의 여러 container들을 관리한다

### ### kubernetes node — kube proxy

![kubernetes node kube proxy](https://cdn-images-1.medium.com/max/800/1*Pn2LqZ-Svtbmxpey2HA0hA.png)*kubernetes node kube proxy*

일종의 proxy 역할로 사용자의 요청이 왔을 때 그에 맞는 pod들을 service discovery pattern으로 찾아 proxy 해준다. kube proxy를 통해 host의 네트웍 rule을 추상화해 kubernetes의 service란 개념으로 loadbalancing이 가능하다.

### ### kubernetes node — container runtime

![kubernetes node container runtime](https://cdn-images-1.medium.com/max/800/1*fR9ajqa2u-2caObU1T1YVQ.png)*kubernetes node container runtime*

docker가 아닌 다른 선택지들도 있지만 쉽게 docker(linux container 환경)를 구동할 수 있는 환경을 제공한다고 생각하면 쉽게 이해할 수 있다.
