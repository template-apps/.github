
# High Level Architecture

![Screenshot 2023-08-01 at 17 29 19](https://github.com/template-apps/.github/assets/12097639/98e531f1-f14a-4583-87a2-fdeb755fc1f1)

# Local Development

## Installations
* Docker: https://docs.docker.com/docker-for-mac/install/
* Virtual Box if you don't already have it: `brew install --cask virtualbox`
* Minikube: `brew install minikube`
* Kubernetes cli tools: `brew install kubernetes-cli`
* Helm: `brew install helm`

## Setup Minikube cluster
```
minikube config set disk-size 20GB
minikube config set memory 6144
minikube delete
minikube start
```

## Setup Local Docker Registry
```
docker run -d -p 5000:5000 --restart always --name registry registry:2

# Edit the /etc/docker/daemon.json to have the following line

{ "insecure-registries": ["localhost:5000"] }
```

## Building
```
# CMS Build 
    # (No need)

# user service
    cd user
    ./gradlew clean build
    docker rmi $(docker images -qa 'localhost:5000/com.cypher-user')
    docker build --no-cache -t localhost:5000/com.cypher-user:latest --build-arg SERVICE=user .
    docker push localhost:5000/com.cypher-user:latest

cd ..

# api service
    cd api
    ./gradlew clean build
    docker rmi $(docker images -qa 'localhost:5000/com.cypher-api')
    docker build --no-cache -t localhost:5000/com.cypher-api:latest --build-arg SERVICE=api .
    docker push localhost:5000/com.cypher-api:latest
    
# web service
    cd web
    #TBA
    docker rmi $(docker images -qa 'localhost:5000/com.cypher-web')
    docker build --no-cache -t localhost:5000/com.cypher-web:latest --build-arg SERVICE=web .
    docker push localhost:5000/com.cypher-web:latest

# native
    #NA
```

## Deployment
```
# Define Namespace
    export NAMESPACE=cypher

# Install/Upgrade CMS (Wordpress)
    helm upgrade cms oci://registry-1.docker.io/bitnamicharts/wordpress -n $NAMESPACE

# Install/Upgrade user service
    cd user
    helm upgrade user -n $NAMESPACE
    
cd ..

# Install/Upgrade api service
    cd api
    helm upgrade api -n $NAMESPACE
    
cd ..

# Install/Upgrade web service
    cd web
    helm upgrade web -n $NAMESPACE

cd ..

# Install/Upgrade native
    #N/A

```

# Production Deployment
* Github Actions (TBA)
