
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

## Setup Minikube cluster with docker registry
```
minikube config set disk-size 20GB
minikube config set memory 6144
minikube delete
minikube start

eval $(minikube -p minikube docker-env)
docker run -d -p 5123:5000 --name local-registry registry:2
```

## Building
```
#!/bin/bash

# Set environment variables
eval $(minikube -p minikube docker-env)
export REGISTRY=localhost:5123
export NAMESPACE=apps-template
export VERSION=latest

# Build and push custom-jres image
echo "Building and pushing custom-jres image..."
(
    cd custom-jres/custom-jre-20 || exit
    ./rebuildAndPush.sh -r "$REGISTRY" -n "$NAMESPACE" -v "$VERSION"
)

# Build and push user image
echo "Building and pushing user image..."
(
    cd user || exit
    ./rebuildAndPush.sh -r "$REGISTRY" -n "$NAMESPACE" -v "$VERSION"
)

# Build and push api image
echo "Building and pushing api image..."
(
    cd api || exit
    ./rebuildAndPush.sh -r "$REGISTRY" -n "$NAMESPACE" -v "$VERSION"
)

echo "Script completed successfully."
```

## Deployment
```
#!/bin/bash

# Set environment variables
export REGISTRY=localhost:5123
export NAMESPACE=apps-template
export VERSION=latest

# Upgrade and install Helm charts
helm upgrade --install --create-namespace cms oci://registry-1.docker.io/bitnamicharts/wordpress \
    -n "$NAMESPACE"

(cd user && \
    helm upgrade --install --create-namespace user infrastructure/helm \
    -f infrastructure/helm/values.yaml \
    --set image.repository="$REGISTRY/$NAMESPACE-user" \
    --set image.tag="$VERSION" \
    --set 'imagePullSecrets=' \
    --set autoscaling.enabled="true" \
    --set app.db.local="true" \
    --set app.db.host="user-db" \
    --set app.db.password="password" \
    --namespace "$NAMESPACE")

(cd api && \
    helm upgrade --install --create-namespace api infrastructure/helm \
    -f infrastructure/helm/values.yaml \
    --set image.repository="$REGISTRY/$NAMESPACE-api" \
    --set image.tag="$VERSION" \
    --set 'imagePullSecrets=' \
    --set autoscaling.enabled="true" \
    --set ingress.enabled="false" \
    --set 'ingress.certificateARN=' \
    --set 'ingress.host=' \
    --namespace "$NAMESPACE")
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
