
# High Level Architecture

![Screenshot 2023-08-01 at 17 29 19](https://github.com/template-apps/.github/assets/12097639/98e531f1-f14a-4583-87a2-fdeb755fc1f1)

# Local Development

## Installations
* Docker: https://docs.docker.com/docker-for-mac/install/
* [For Intel Chipset Only] Virtual Box: `brew install --cask virtualbox`
* [For Intel Chipset Only] Kubernetes cli tools: `brew install kubernetes-cli`
* Minikube: `brew install minikube`
* Helm: `brew install helm`
* Java 20
* TODO: AWS cli, Creating ECR repository, AWS Access Key

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
    --set app.db.local="true" \
    --set app.db.host="user-db" \
    --set app.db.password="password" \
    --namespace "$NAMESPACE")
```

# Production Deployment
## TODO
* GitHub Actions (TBA)
* EKS, ECR Repositories (TBA)

## Building
```
#!/bin/bash

# Set environment variables
export REGISTRY=881387567440.dkr.ecr.us-east-1.amazonaws.com
export NAMESPACE=apps-template
export VERSION=latest
export REGION=us-east-1

# Log in to Docker registry
echo "Logging in to Docker registry..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

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

echo "Script completed successfully."
```

## Deployment
```
#!/bin/bash

# Set environment variables
export REGISTRY=881387567440.dkr.ecr.us-east-1.amazonaws.com
export NAMESPACE=apps-template
export VERSION=latest
export REGION=us-east-1

# Delete and recreate Kubernetes secret for ECR image pull
kubectl delete secret regcred --namespace="$NAMESPACE"
kubectl create secret docker-registry regcred \
    --docker-server="$REGISTRY" \
    --docker-username=AWS \
    --docker-password="$(aws ecr get-login-password --region "$REGION")" \
    --docker-email=sachin@joincypher.com \
    --namespace="$NAMESPACE"

# Upgrade and install Helm charts
helm upgrade --install --create-namespace cms oci://registry-1.docker.io/bitnamicharts/wordpress \
    -n "$NAMESPACE"

(cd user && \
    helm upgrade --install --create-namespace user infrastructure/helm \
    -f infrastructure/helm/values.yaml \
    --set image.repository="$REGISTRY/$NAMESPACE-user" \
    --set image.tag="$VERSION" \
    --set 'imagePullSecrets[0].name=regcred' \
    --set app.db.local="false" \
    --set app.db.host="RDS Host TBA" \
    --set app.db.password="RDS DB Password TBA" \
    --namespace "$NAMESPACE")
```
