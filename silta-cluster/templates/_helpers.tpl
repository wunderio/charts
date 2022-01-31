{{- define "silta-cluster.cert-manager-api-version" }}
{{- if ( .Capabilities.APIVersions.Has "cert-manager.io/v1" ) }}
apiVersion: cert-manager.io/v1
{{- else -}}
apiVersion: certmanager.k8s.io/v1alpha1
{{- end -}}
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
