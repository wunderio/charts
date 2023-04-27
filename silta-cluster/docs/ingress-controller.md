# Ingress controller

Silta cluster uses traefik (1) ingress controllers by default but it supports running other controllers too. Alternative controllers have been tested and it's highly possible the default controllers will be swapped out in near future. 

Tested controllers:
 
  - Traefik 1 (modified version, https://github.com/wunderio/charts/tree/master/legacy_traefik): works but is obsolete.
    - Official controller image does not support kubernetes 1.22+, we use modified image that supports it. It works, but is unsupported.
    - Has SNI and CN + wildcard issue, hosts field in the TLS configuration is ignored for cerficiate selection.
 
  - Traefik 2 (https://doc.traefik.io/traefik/providers/kubernetes-ingress/): Partially compatible
    - Missing rate limiter
    - Allows using middleware applications for traffic handling
    - Provides WAF options.
    - Has SNI and CN + wildcard issue, hosts field in the TLS configuration is ignored for cerficiate selection.
 
   - ingress-nginx (community version, https://github.com/kubernetes/ingress-nginx): Fully compatible
     - Support custom modules, lua and modsecurity
     - GCP GKE private cluster requires custom firewall rule for validation webhooks.
 
  - nginx-ingress (Nginx Inc. version, https://docs.nginx.com/nginx-ingress-controller/): Partially compatible
    - Requires CRD deployment
    - Rate limiting is not available in annotations nor helm configuration (requires configuration snippets?)
    - Provides WAF options

  - Application Gateway Ingress Controller (https://azure.github.io/application-gateway-kubernetes-ingress/): Partially compatible
    - Available in Azure clusters only
    - Rate limiting is not found (does it exist?)
    - Requires Application Gateway installation, controller setup
    - Provides WAF options.

  - Google GKE Ingress controller (https://cloud.google.com/kubernetes-engine/docs/concepts/ingress): Partially compatible
    - Load balancer rules take a while to sync configuration
    - Rate limiting is not found (does it exist?)
    - WAF functionality available
    - Requires static ip, one IP per ingress

Promising but untested: HAProxy, Kong

## Usage

Current version of `silta-cluster` sets `traefik` as default ingress controller and so do all other charts that depend on `silta-cluster`; this means alternative ingress controller needs to "impersonate" `traefik` ingress class. See `silta-cluster` chart values file for more details and examples. ingress-nginx can be used as a drop in replacement, but does require project deployment configuration changes if rate limiting annotations have been added to it.
