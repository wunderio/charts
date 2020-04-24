# How it works

- CronJob runs the following
    - Get Ingresses with a `auto-downscale/last-update` annotation, this is used to check which should be downscaled.
    - The `auto-downscale/services` annotation on the ingress indicates which service should be redirected to the placeholder page.
    - The `auto-downscale/label-selector` indicates which deployments, statefulsets and cronjobs should be downscaled. This is typically set to `release=<release-name>`.
    
- When someone hits the placeholder
    - Get Ingress matching current hostname
    - Show message to user with option to re-enable
    - When upscale is ready, redirect user