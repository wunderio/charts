{{- define "silta-cluster.cert-manager-api-version" }}
{{- if ( .Capabilities.APIVersions.Has "cert-manager.io/v1" ) }}
cert-manager.io/v1
{{- else }}
certmanager.k8s.io/v1alpha1
{{- end }}
{{- end }}

{{- define "silta-cluster.cert-manager-solver-http01" }}
{{- if ( .Capabilities.APIVersions.Has "cert-manager.io/v1" ) }}
solvers:
- http01:
    ingress: {}
{{- else -}}
http01: {}
{{- end -}}
{{- end }}

{{- define "silta-cluster.ingress-api-version" }}
{{- if semverCompare ">=1.18" .Capabilities.KubeVersion.Version }}
networking.k8s.io/v1
{{- else }}
networking.k8s.io/v1beta1
{{- end }}
{{- end }}

{{- define "silta-cluster.priorityclass-api-version" }}
{{- if semverCompare ">=1.21" .Capabilities.KubeVersion.Version }}
scheduling.k8s.io/v1
{{- else }}
scheduling.k8s.io/v1beta1
{{- end }}
{{- end }}

{{- define "silta-cluster.cron-api-version" }}
{{- if semverCompare ">=1.21" .Capabilities.KubeVersion.Version }}
batch/v1
{{- else }}
batch/v1beta1
{{- end }}
{{- end }}