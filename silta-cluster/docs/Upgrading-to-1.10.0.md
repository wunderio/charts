# Upgrading silta-cluster chart to 1.10.0

This applies to silta-cluster installations using[ Nginx Inc. ingress](https://github.com/nginxinc/kubernetes-ingress/), only installations with `nginx-ingress.enabled: true` are affected. Installations with `ingress-nginx.enabled: true` are not affected by this removal, you don't have to do anything.

## Nginx-ingress setup

Nginx Inc. [kubernete-ingress](https://github.com/nginxinc/kubernetes-ingress/) load balancer is removed from silta-cluster subchart list, but it is still compatible with ingresses and resources. If you want to keep using using it, you have to install the nginx-ingress manually.

Follow installation instructions here: https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm/

Values file example (for chart version 0.17, more recent version might have value schema change):
```
controller:
  replicaCount: 1
  service:
    # loadBalancerIP: 1.2.3.4
    externalTrafficPolicy: Local
  ingressClass: nginx
  setAsDefaultIngress: false
  appprotect:
    enable: false
    # Sets log level for App Protect WAF. Allowed values: fatal, error, warn, info, debug, trace
    logLevel: info
  appprotectdos:
    enable: false
    debug: false
  config:
    entries:
      # Optional CDN configuration
      real-ip-header: "X-Forwarded-For"
      real-ip-recursive: "True"
      #set-real-ip-from: "1.1.1.1/32, 2.2.2.2/32"
      # Logging configuration
      access-log-off: "False"
      server-tokens: "False"
  autoscaling:
    enabled: false
    minReplicas: 1
    maxReplicas: 3
    targetCPUUtilizationPercentage: 80
    targetMemoryUtilizationPercentage: 80
  priorityClassName: "high-priority"
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "200m"
      memory: "512Mi"
```