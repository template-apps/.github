
# High Level Architecture

![Screenshot 2023-08-01 at 17 29 19](https://github.com/template-apps/.github/assets/12097639/98e531f1-f14a-4583-87a2-fdeb755fc1f1)

# Local Development

## Installations
* Docker: https://docs.docker.com/docker-for-mac/install/
* [For Intel Chipset Only] Virtual Box: `brew install --cask virtualbox`
* [For Intel Chipset Only] Kubernetes cli tools: `brew install kubernetes-cli`
* Minikube: `brew install minikube`
* Helm: `brew install helm`
* Java 20 (Preferably Amazon Corretto)
* Install node (> 10.13) (https://nodejs.org/en)

## Setup Minikube cluster with docker registry
```
minikube config set disk-size 20GB
minikube config set memory 6144
minikube delete
minikube start

kubectl config use-context minikube
eval $(minikube -p minikube docker-env)
docker run -d -p 5123:5000 --name local-registry registry:2
```

## Build and Deployment
`local.sh` takes care of build and deployment on local machine
Examples:
```
# Build and Deploy everything!
./.github/scripts/local.sh all all

# Building user service
./.github/scripts/local.sh user build

# Deploying user service
./.github/scripts/local.sh user deploy

# Building & Deploying user service
./.github/scripts/local.sh user all
```

# Production Deployment
* All the services are deployed using GitHub Actions. `.github` repository is the parent that creates foundational infrastructure.
* Manually create AWS account, create admin group and add user. Generate access key. Add `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` as GitHub Org level secret.
* When RDS is created it will use the Master username/password as set in `MYSQL_MASTER_PASSWORD`, `MYSQL_MASTER_USER` GitHub Org level secrets.   
* When EKS cluster will be created it will use `CLUSTER`, `NAMESPACE` GitHub org level variables.
* Add `REGION` GitHub Org level variable to point to your AWS account region e.g. `us-east-1`.
* Create domain (either in Route53 or external), then create Certificate in ACM to use that domain.   
  Then create GitHub secret `CERTIFICATE_ARN` with the ARN of that certificate. Also add `DOMAIN` variable e.g. `example.com`.  
  CMS and API and APP subdomains will be used when ingress is created. Make sure DNS points to those LBs as cname.
* NOTE: Currently there is single RDS instance that's shared by all the services. Creating the database is still manual.
* NOTE: Don't forget to create ECR repositories for images to be pushed (it's template_name-service_name format so e.g. apps-template-user)
