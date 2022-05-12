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
{{- if and ( ge $.Capabilities.KubeVersion.Major "1") ( ge $.Capabilities.KubeVersion.Minor "18" ) }}
networking.k8s.io/v1
{{- else }}
networking.k8s.io/v1beta1
{{- end }}
{{- end }}

{{- define "silta-cluster.priorityclass-api-version" }}
{{- if and ( ge $.Capabilities.KubeVersion.Major "1") ( ge $.Capabilities.KubeVersion.Minor "21" ) }}
scheduling.k8s.io/v1
{{- else }}
scheduling.k8s.io/v1beta1
{{- end }}
{{- end }}

{{- define "silta-cluster.cron-api-version" }}
{{- if and ( ge $.Capabilities.KubeVersion.Major "1") ( ge $.Capabilities.KubeVersion.Minor "21" ) }}
batch/v1
{{- else }}
batch/v1beta1
{{- end }}
{{- end }}
