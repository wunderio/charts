# Upgrading silta-cluster chart to 1.16.0

This update adds Traefik 3 as an option for ingress controller. Traefik 1 is still the default load balancer, ingress-nginx is [no longer supported](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/) and it's suggested to migrate to Traefik 3.

**Traefik 3 middleware resources:**

Traefik 3 does not support [ingress-nginx annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#mirror), so if you are using them, you need to migrate to Traefik 3 annotations or use middleware resources (f.ex. basic authentication, ip whitelisting). There are some ingress-nginx annotations that are supported in [traefik compatability mode](https://doc.traefik.io/traefik/master/reference/routing-configuration/kubernetes/ingress-nginx/), but there is not enough coverage for our standard use cases. 
  
Drupal, Frontend and Simple charts will create Traefik 3 middleware resources for rate limiting and basic authentication if Traefik 3 crds are installed. You can preinstall Traefik 3 CRDs by setting `traefik3crds.enabled: true` and running `helm upgrade` for silta-cluster chart. This will not affect traffic in any way, unless you enable Traefik 3. The moment you switch over ingress class, Traefik 3 will start using the middleware resources.

**Traefik 3 migration:**

1. Assign or reuse old external ip address (if using static address) by setting `traefik3.service.spec.loadBalancerIP: "1.2.3.4"`
2. Reuse or redefine ingress class at `traefik3.providers.kubernetesIngressingressClass` and `traefik3.ingressClass.name`
3. Enable Traefik 3 by setting `traefik3.providers.kubernetesIngress.enabled: true`
4a. Traefik 1: Disable Traefik 1 by setting `traefik.enabled: false`
4b. ingress-nginx: Disable ingress-nginx: `ingress-nginx.enabled: false`
5. Delete ingressclass, because `spec.controller` is immutable.
6. Deploy silta-cluster chart

** Troubleshooting **

Traefik 3 replacement can yield error:

> Error: UPGRADE FAILED: cannot patch "traefik" with kind IngressClass: IngressClass.networking.k8s.io "traefik" is invalid: spec.controller: Invalid value: "traefik.io/ingress-controller": field is immutable

If this happens, you need to delete the IngressClass resource and deploy silta-cluster chart again.
```bash
kubectl delete ingressclass traefik
```