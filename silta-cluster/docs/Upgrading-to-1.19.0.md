# Upgrading silta-cluster chart to 1.19.0

## Instana-agent upgrade to v2.0.x

This update bumps the `instana-agent` subchart dependency from `1.2.x` to `2.0.x`, only installations with `instana-agent.enabled: true` are affected.

Starting with version 2.0.0, the `instana-agent` chart deploys a Kubernetes Operator that reconciles the agent resources based on an `Agent` CustomResource, instead of managing the agent DaemonSet and related resources directly. This requires a CustomResourceDefinition (CRD) to be present in the cluster.

Helm does not manage CRD updates on `helm upgrade` (only on initial install), so **the CRDs must be applied to the cluster manually before running the silta-cluster chart upgrade**, otherwise the upgrade will fail because the `Agent` custom resource cannot be created.

Apply the CRDs from the instana-agent helm chart repository:

```bash
kubectl apply -f https://raw.githubusercontent.com/instana/helm-charts/main/instana-agent/crds/operator_customresourcedefinition_agents_instana_io.yml
kubectl apply -f https://raw.githubusercontent.com/instana/helm-charts/main/instana-agent/crds/operator_customresourcedefinition_agentsremote_instana_io.yml
```

Or, equivalently, pull the chart and apply the bundled `crds` folder (matches what `helm install` does automatically on a fresh install):

```bash
helm pull --repo https://agents.instana.io/helm --untar --untardir /tmp/instana-agent-chart instana-agent
kubectl apply -f /tmp/instana-agent-chart/instana-agent/crds
```

Once the CRDs are applied, proceed with the regular `silta-cluster` chart upgrade.

Related documentation:
- [instana-agent helm chart README - Upgrade section](https://github.com/instana/helm-charts/blob/main/instana-agent/README.md#upgrade)
- [instana-agent helm chart CRDs folder](https://github.com/instana/helm-charts/tree/main/instana-agent/crds)
- [instana-agent helm chart CHANGELOG](https://github.com/instana/helm-charts/blob/main/instana-agent/CHANGELOG.md)
