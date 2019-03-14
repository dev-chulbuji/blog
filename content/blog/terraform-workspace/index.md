---
title: terraform-workspace
date: 2019-03-13
description: terraform concept for managing multiple environments(test, dev, prod) with the same setup 
---

terraform에서 다른 infrastructure 환경을 코드로 관리할 때 보통 다음과 같이 환경별 folder를 구분해서 관리한다. 
```
└── terraform
    └── ec2
        ├── dev
        └── prod
```
이럴 수밖에 없는 이유는 terraform은 apply된 실제 인프라에 적용하면서 나온 결과인 tfstate를 환경별로 구분해야 하기 때문인데 실제로 코드는 region 정보, backend 설정, 몇몇 변수들이 다르고 나머지 .tf 코드들은 대부분 동일하다.

terraform에서는 0.10 버전부터 0.9에서 *environment*로 사용되던 [workspace](https://www.terraform.io/docs/state/workspaces.html)라는 개념으로 
이런 상황에서 하나의 terraform 코드로 여러 환경을 다룰 수 있다.
```bash
$ terraform workspace list  // get all workspaces
$ terraform workspace new dev // create new workspace
$ terraform workspace select dev // switch workspace
$ terraform workspace delete prod // delete workspace
```
```terraform workspace``` 명령을 통해 workspace 생성, 선택, 삭제를 할 수 있다. 
```terraform workspace list```를 하면 기본적으로 default workspace를 사용하고 있고 default workspace는 삭제할 수 없다.
```terraform apply```를 통해 나온 artifact(tfstate)를 workspace라는 개념과 연결해 각 workspace별 tfstate를 관리할 수 있으므로 다양한 환경에서 하나의 terraform 코드로 관리할 수 있게 해준다.

실제로 현업에선 협업을 위해 tfstate를 remote backend로 관리를 하는데 예를 들어 ec2 resource를 생성한다고 해보자.
```hcl
terraform {
  required_version = ">= 0.11.11"
  backend "s3" {
    bucket  = "dj-terraform-backend-dev"
    key     = "ec2/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "dj-TerraformStateLock-dev"
    acl = "bucket-owner-full-control"
  }
}

locals {
  tier = "dev"
  region = "ap-northeast-1"
  key = "aws_key_pair_tokyo"
}

provider "aws" {
  version = "~> 2.1"
  region = "${local.region}"
}

data "aws_availability_zones" "available" {}

module "ec2" {
  source = "../modules/ec2"
  name = "server-${local.tier}"
  region = "${local.region}"

  vpc_id = "xxxxx"
  subnet_id = "xxxxx"

  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  instance_type = "t2.micro"
  keypair_name = "${local.key}"
  ami = "${data.aws_ami.ubuntu-18_04.id}"

  allow_ssh_ips = ["0.0.0.0/0"]

  tags = {
    "TerraformManaged" = "true"
  }
}
```
backend 설정을 해주고 필요한 값들은 local로 선언해서 사용했다. 이 dev 환경의 ec2 terraform code를 production에 적용할 때 workspace 개념을 사용하지 않으면 
backend 설정과 local 변수를 변경하여 별도로 tf code를 생성해줘야 한다.

```hcl
terraform {
  required_version = ">= 0.11.11"
  backend "s3" {
    bucket  = "dj-terraform-backend-prod"
    key     = "ec2/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "dj-TerraformStateLock-prod"
    acl = "bucket-owner-full-control"
  }
}

locals {
  tier = "prod"
  region = "ap-northeast-2"
  key = "aws_key_pair_seoul"
}

provider "aws" {
  version = "~> 2.1"
  region = "${local.region}"
}

data "aws_availability_zones" "available" {}

module "ec2" {
  source = "../modules/ec2"
  name = "server-${local.tier}"
  region = "${local.region}"

  vpc_id = "xxxxx"
  subnet_id = "xxxxx"

  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  instance_type = "t2.micro"
  keypair_name = "${local.key}"
  ami = "${data.aws_ami.ubuntu-18_04.id}"

  allow_ssh_ips = ["0.0.0.0/0"]

  tags = {
    "TerraformManaged" = "true"
  }
}
```

```
└── terraform
    └── ec2
        ├── dev
        │   ├── ec2.tf
        └── prod
            └── ec2.tf
```

### managing multi env by workspace
terraform workspace을 활용하면 단일 terraform code로 여러 환경을 관리를 할 수 있다.
```bash
$ terraform workspace new dev
$ terraform workspace select dev
```
```hcl
terraform {
  required_version = ">= 0.11.11"
  backend "s3" {
    bucket  = "dj-terraform-backend"
    key     = "ec2/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "dj-TerraformStateLock"
    acl = "bucket-owner-full-control"
  }
}

locals {
  tier = "${terraform.workspace}"
  region = "${terraform.workspace == "dev" ? "ap-northeast-1" : "ap-northeast-2"}"
  key = "${terraform.workspace == "dev" ? "aws_key_pair_tokyo" : "aws_key_pair_seoul"}"
}

provider "aws" {
  version = "~> 2.1"
  region = "${local.region}"
}

module "ec2" {
  source = "../modules/ec2"
  name = "server-${local.tier}"
  region = "${local.region}"

  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  subnet_id = "${data.terraform_remote_state.vpc.public_subnets_ids[0]}"

  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  instance_type = "t2.micro"
  keypair_name = "${local.key}"
  ami = "${data.aws_ami.ubuntu-18_04.id}"

  allow_ssh_ip = ["0.0.0.0/0"]

  tags = {
    "TerraformManaged" = "true"
  }
}
```
```${terraform.workspace}```로 현재 workspace를 가져와 local값을 환경에 맞게 주입 시켜 환경 별다른 region, 다른 설정으로 관리할 수 있다.
위 예제는 dev, prod 환경을 단일 remote backend로 관리하는 예제로 실제 s3 버킷을 보면 workspace별로 tfstate를 관리할 수 있다. 
```
└── env:
    ├── dev
    │   └── ec2
    │       └── terraform.tfstate
    └── prod
        └── ec2
            └── terraform.tfstate
```
그렇다면 remote state에서 data로 ouput값을 가져올 때는 어떻게 가져올 수 있을까?
```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  workspace = "${terraform.workspace}"
  config {
    bucket  = "dj-terraform-backend-dev"
    key     = "ec2/terraform.tfstate"
    region  = "${local.region}"
    encrypt = true
  }
}
```
```terraform_remote_state```를 가져올 때 workspace를 명시해주면 각 workspace별 tfstate를 져올 수 있다.


> 팀별로 다르겠지만 같은 계정에서 환경을 나눠서 작업하는 경우는 괜찮겠지만 만약 test 계정이 따로 있다면 해당 계정 접근 권한을 열어주어야만 하고, backend 자체가 환경마다 다른 종류를 가진다면 위와 같은 방법으로 tfstate를 관리할 수 없다.

### Partial Configuration (dynamic backend)
각 환경마다 따로 backend를 가지고 workspace마다 환경에 맞는```terraform init```을 통해 state를 가져오고 싶을 땐 다음과 같이 3가지 방법이 있다.
- Interactively
- File
- Command-line key/value pairs

Interactively는 backend 설정이 없을 시 command창에서 설정을 그때그때 입력할 수 있는 interface가 제공된다. 
file의 경우는 환경별 backend 설정(dev.tfbackend, prod.tfbackend)을 따로 두어 ```-backend-config``` option으로 파일을 지정해 준다.
```
## dev.tfbackend
bucket  = "dj-terraform-backend-dev"
key     = "ec2/terraform.tfstate"
region  = "ap-northeast-1"
encrypt = true
dynamodb_table = "dj-TerraformStateLock-dev"
acl = "bucket-owner-full-control"
```

```
## prod.tfbackend
bucket  = "dj-terraform-backend-prod"
key     = "ec2/terraform.tfstate"
region  = "ap-northeast-2"
encrypt = true
dynamodb_table = "dj-TerraformStateLock-prod"
acl = "bucket-owner-full-control"
```

```hcl
## ec2.tf
terraform {
  required_version = ">= 0.11.11"
  backend "s3" {
  }
}

locals {
  tier = "${terraform.workspace}"
  region = "${terraform.workspace == "dev" ? "ap-northeast-1" : "ap-northeast-2"}"
  key = "${terraform.workspace == "dev" ? "aws_key_pair_tokyo" : "aws_key_pair_seoul"}"
}

provider "aws" {
  version = "~> 2.1"
  region = "${local.region}"
}

module "ec2" {
  source = "../modules/ec2"
  name = "server-${local.tier}"
  region = "${local.region}"

  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  subnet_id = "${data.terraform_remote_state.vpc.public_subnets_ids[0]}"

  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  instance_type = "t2.micro"
  keypair_name = "${local.key}"
  ami = "${data.aws_ami.ubuntu-18_04.id}"

  allow_ssh_ip = ["0.0.0.0/0"]

  tags = {
    "TerraformManaged" = "true"
  }
}
```
```bash
$ terraform init -reconfigure -backend-config=dev.tfbackend
$ terraform init -reconfigure -backend-config=prod.tfbackend
```

### co-working with Atlantis
workspace 개념을 도입하면 하나의 파일로 여러 환경을 관리할 수 있다는 장점이 있지만 
기존의 dev, prod 폴더를 나눠 관리했을 때와는 다르게 그때그때 ```terraform workspace list``` 
명령으로 현재 workspace를 확인해야 하고 잘못된 workspac로 plan, apply하는 실수를 범할 수 있고, init 명령도 option을 지정해줘야 하는 불편함이 있다.
이 부분을 Atlantis([Atlantis post](https://chulbuji.gq/terraform-atlantis/))를 활용해 자동화함으로써 좀 더 쉽게 관리할 수 있다.

```yaml
version: 2
automerge: true # Automatically merge pull request when all plans are applied
projects:
- name: ec2-dev
  dir: terraform/ec2
  workspace: dev
  terraform_version: v0.11.11
  autoplan:
    when_modified: ["*.tf", "../modules/ec2/**.tf"]
    enabled: true
  apply_requirements: [mergeable, approved]
  workflow: dev
  
- name: ec2-prod
  dir: terraform/ec2
  workspace: prod
  terraform_version: v0.11.11
  autoplan:
    when_modified: ["*.tf", "../modules/ec2/**.tf"]
    enabled: true
  apply_requirements: [mergeable, approved]
  workflow: prod

workflows:
  prod:
    plan:
      steps:
      - init: 
          extra_args: [-backend-config=prod.tfbackend]
      - plan
  dev:
    plan:
      steps:
      - init: 
          extra_args: [-backend-config=dev.tfbackend]
      - plan
```
각 팀마다 terraform 운영 방식에 따라 다르겠지만 test, dev, prod 환경으로 구분된다면 구성한 terraform을 test에 적용하면서 통과가 되면 
pr을 통해 atlantis로 dev, prod 환경에서 plan결과 확인 및 코드 리뷰 후 ```atlantis apply``` 명령을 통해 자동으로 infra에 적용하고 pr도 자동으로 close 할 수 있다.

workspace개념을 쓰면서 하나의 파일로 여러 환경을 관리할 수 있는 건 좋지만 
매번 workspace 변경 및 확인하는 절차가 귀찮고 실수를 유발하기 쉽다.
이 부분을 atlantis를 활용해 자동화를 하고 리뷰를 좀 더 편하게 할 수 있어 좋은 것 같다.
하지만 v1에선 프로젝트 단위로 atlantis 설정을 하던 게 
v2가 되면서 하나의 atlantis설정으로 전체를 관리하는데 매번 pr마다 전체 project plan 결과를 출력하는 이슈가 있다. 덩치가 커지면 느려질 것 같고 원하지 않는 project의 plan 결과를 보는 게 불편한데 이 부분은 docs를 좀 더 찾아보고 튜닝을 해야 할 것 같다. 

