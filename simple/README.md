# Gatsby Helm Chart

This helm chart is derived from https://github.com/wunderio/drupal-project

## Usage

This chart is meant to be used in combination with a continuous integration 
service that will build your codebase, create docker images, push them to a
docker registry and pass them as parameters to this chart. At wunder, we 
currently use CircleCI, you can check out our template repository [here](https://github.com/wunderio/drupal-project)

Here is an example of how we instantiate this helm chart: 

```bash
helm upgrade --install $RELEASE_NAME simple \
            --repo https://wunderio.github.io/charts/ \
            --set environmentName=$CIRCLE_BRANCH \
            --namespace=${CIRCLE_PROJECT_REPONAME,,} \
            --values silta.yml \
            
```

What's happening above:

1. We use `upgrade --install` to upgrade an existing release, or create one if there is no release with that name.
2. `RELEASE_NAME` is based on the name of the repository and the name of the branch. This automatically gives us a dedicated environment for each branch.
3. We set the `environmentName` to match our branch name. This is used to have nicer URLs for branch-specific environments.
4. We deploy each repository into a dedicated namespace to provide some separation.
5. Each project has its own `silta.yml` file where the default configuration can be overridden.

## Configuration

You can see the available options and default values in values.yaml.
To override these options for your project, specify a file when creating/upgrading your helm releases:

```bash
$ helm upgrade --install drupal
  --repo https://wunderio.github.io/charts/ \
  --values silta.yml
    
```

All default values are are optimised for low resource usage on non-production environments.
Production use cases will be supported (they have not been tested yet), but they should
have a dedicated values file adapted to the needs of the project, among others:
- High availability deployment using replicas.
- More dedicated CPU and memory.
- Database and persistent storage delegated to an external hosted service.
- Dedicated ingress resource with a dedicated domain (to be implemented).

## Dependencies
Although this chart is built to work in a variety of different contexts, the default
values assume that certain things will be in place in the cluster. Our setup of the
the cluster itself can be seen here: https://github.com/wunderio/silta-cluster

The relevant dependencies we currently have are:
- [Ambassador](https://getambassador.io) is running on the cluster with a wildcard DNS
entry pointing to its load balancer. This makes it possible to have a dedicated
domain added to each service with a simple annotation.
