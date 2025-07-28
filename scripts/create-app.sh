#!/bin/bash
set -e
APP_NAME=$1
DOMAIN=$2

if [ -z "$APP_NAME" ] || [ -z "$DOMAIN" ]; then
  echo "Usage: ./create-app.sh <app-name> <domain>"
  exit 1
fi

cp -r apps/template-app apps/$APP_NAME
sed -i "s/{{APP_NAME}}/$APP_NAME/g" apps/$APP_NAME/values.yaml
sed -i "s/{{DOMAIN}}/$DOMAIN/g" apps/$APP_NAME/values.yaml

echo "App $APP_NAME created with domain $DOMAIN. Commit and push to Git repo for FluxCD to deploy."

cat <<EOF > clusters/production/$APP_NAME-release.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: $APP_NAME
  namespace: default
spec:
  interval: 1m
  releaseName: $APP_NAME
  chart:
    spec:
      chart: ./helm-charts/flight-hotel-app
      sourceRef:
        kind: GitRepository
        name: flight-hotel-app
        namespace: flux-system
  values:
    appName: "$APP_NAME"
    image:
      repository: "yourrepo/flight-app"
      tag: "latest"
    domain: "$DOMAIN"
    tlsIssuer: "letsencrypt-prod"
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 10
      cpuUtilization: 60
EOF
