#!/bin/bash
set -euo pipefail

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <service|all> <build|deploy|all>"
    exit 1
fi

# Set environment variables
REGISTRY=localhost:5123
NAMESPACE=apps-template
VERSION=latest
eval $(minikube -p minikube docker-env)

# Set up Kubernetes context
kubectl config use-context minikube

# Build image
build_image() {
    local service="$1"
    echo "👷 Building $service image..."
    (
        cd "$service" || exit
        ./rebuildAndPush.sh -r "$REGISTRY" -n "$NAMESPACE" -v "$VERSION"
    )
}

# Deploy Helm chart with custom options
deploy_helm_chart() {
    local service="$1"
    shift 1
    local chart_options=("$@")

    echo "📦 Deploying $service Helm chart..."
    (
        cd "$service" || exit
        helm upgrade --install --create-namespace "$service" infrastructure/helm \
            -f "infrastructure/helm/values.yaml" \
            "${chart_options[@]}" \
            --set image.repository="$REGISTRY/$NAMESPACE-$service" \
            --set image.tag="$VERSION" \
            --set 'imagePullSecrets=' \
            --namespace "$NAMESPACE"

    )
}

service="$1"
operation="$2"

# Determine which services to operate on
case "$service" in
    "all")
        services=("custom-jres/custom-jre-20" "cms" "user" "api")
        ;;
    "custom-jres/custom-jre-20" | "cms" | "user" | "api"  )
        services=("$service")
        ;;
    *)
        echo "Unsupported service: $service"
        exit 1
        ;;
esac

# Build images if needed
if [[ "$operation" == "build" || "$operation" == "all" ]]; then
    for service in "${services[@]}"; do
        case "$service" in
            "cms")
                ;;
              *)
                build_image "$service"
        esac
    done
fi

# Deploy Helm charts if needed
if [[ "$operation" == "deploy" || "$operation" == "all" ]]; then
    for service in "${services[@]}"; do
        case "$service" in
            "cms")
            echo "📦 Deploying $service"
              helm upgrade --install --create-namespace cms oci://registry-1.docker.io/bitnamicharts/wordpress \
                  -n "$NAMESPACE"
                ;;
            "user")
                deploy_helm_chart "$service" \
                    --set autoscaling.enabled="true" \
                    --set app.db.local="true" \
                    --set app.db.host="user-db" \
                    --set app.db.password="password"
                ;;
            "api")
                deploy_helm_chart "$service" \
                    --set autoscaling.enabled="true" \
                    --set ingress.enabled="false" \
                    --set 'ingress.certificateARN=' \
                    --set 'ingress.host='
                ;;
        esac
    done
fi

echo "Script completed successfully."
