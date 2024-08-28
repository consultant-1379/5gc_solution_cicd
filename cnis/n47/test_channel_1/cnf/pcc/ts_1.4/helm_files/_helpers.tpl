{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-pc-up-data-plane.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create version
*/}}
{{- define "eric-pc-up-data-plane.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "eric-pc-up-data-plane.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the Docker image.
*/}}
{{- define "eric-pc-up-data-plane.image" -}}
{{- $global := fromJson (include "eric-pc-up-data-plane.global" .) }}
{{- $dpImage := index .Values "images" "eric-pc-up-data-plane" }}
{{- if .Values.imageCredentials.registry.url -}}
{{- printf "%s/%s/%s:%s" .Values.imageCredentials.registry.url .Values.imageCredentials.repoPath $dpImage.name $dpImage.tag -}}
{{- else -}}
{{- printf "%s/%s/%s:%s" $global.registry.url .Values.imageCredentials.repoPath $dpImage.name $dpImage.tag -}}
{{- end -}}
{{- end -}}

{{- define "eric-pc-up-data-plane-at.image" -}}
{{- $global := fromJson (include "eric-pc-up-data-plane.global" .) }}
{{- $atImage := index .Values "images" "eric-pc-up-data-plane-at" }}
{{- if .Values.imageCredentials.registry.url -}}
{{- printf "%s/%s/%s:%s" .Values.imageCredentials.registry.url "proj-pc-fw-drop" $atImage.name $atImage.tag -}}
{{- else -}}
{{- printf "%s/%s/%s:%s" $global.registry.url "proj-pc-fw-drop" $atImage.name $atImage.tag -}}
{{- end -}}
{{- end -}}

{{/*
Create image pull secrets.
*/}}
{{- define "eric-pc-up-data-plane.pullSecrets" -}}
  {{- $global := fromJson (include "eric-pc-up-data-plane.global" .) }}
  {{- if .Values.imageCredentials.pullSecret -}}
    {{- print .Values.imageCredentials.pullSecret -}}
  {{- else if $global.pullSecret -}}
    {{- print $global.pullSecret -}}
  {{- end -}}
{{- end -}}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-pc-up-data-plane.nodeSelector" }}
  {{- $global := fromJson (include "eric-pc-up-data-plane.global" .) }}
  {{- if .Values.nodeSelector -}}
    {{- range $key, $localValue := .Values.nodeSelector -}}
      {{- if hasKey $global.nodeSelector $key -}}
          {{- $globalValue := index $global.nodeSelector $key -}}
          {{- if ne $globalValue $localValue -}}
            {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values, which is not allowed." $key $key $globalValue $key $localValue | fail -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- toYaml (merge $global.nodeSelector .Values.nodeSelector) | trim -}}
  {{- else -}}
    {{- toYaml $global.nodeSelector | trim -}}
  {{- end -}}
{{ end }}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-pc-up-data-plane.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := mustMerge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := mustMerge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret" "") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "url" "selndocker.mo.sw.ericsson.se")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "interfacePrefixes" (list (dict "name" "up:" "owner" "up"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "ericsson" (dict "licensing" (dict "licenseDomains" (list (dict "productType" "" "swltId" "" "customerId" ""))))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pcfw" (dict "enabled" false)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "log" (dict "outputs" (list "k8sLevel"))) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-pc-up-data-plane.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Default labels attached to all the k8s resources
*/}}
{{ define "eric-pc-up-data-plane.labels" -}}
app.kubernetes.io/name: {{ template "eric-pc-up-data-plane.name" . }}
app.kubernetes.io/version: {{ template "eric-pc-up-data-plane.version" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ template "eric-pc-up-data-plane.chart" . }}
{{- if .Values.labels }}
{{ toYaml .Values.labels }}
{{- end }}
{{- end -}}

{{/*
Anti-affinity definitions.
*/}}
{{- define "eric-pc-up-data-plane.pod-anti-affinity" }}
podAntiAffinity:
  {{- if kindIs "string" .Values.affinity.podAntiAffinity -}}
  {{- if eq .Values.affinity.podAntiAffinity "hard" }}
  requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
          - key: "app.kubernetes.io/name"
            operator: "In"
            values:
              - {{ template "eric-pc-up-data-plane.fullname" . }}
      topologyKey: "kubernetes.io/hostname"
  {{- else if eq .Values.affinity.podAntiAffinity "soft" }}
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
            - key: "app.kubernetes.io/name"
              operator: "In"
              values:
                - {{ template "eric-pc-up-data-plane.fullname" . }}
        topologyKey: "kubernetes.io/hostname"
  {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Definition for the securityContext fsGroup on pod level.
*/}}
{{- define "eric-pc-up-data-plane.fsGroup.coordinated" -}}
  {{- if .Values.global -}}
    {{- if .Values.global.fsGroup -}}
      {{- if .Values.global.fsGroup.manual -}}
        {{ .Values.global.fsGroup.manual }}
      {{- else -}}
        {{- if eq .Values.global.fsGroup.namespace true -}}
           # The 'default' defined in the Security Policy will be used.
        {{- else -}}
          10000
        {{- end -}}
      {{- end -}}
    {{- else -}}
      10000
    {{- end -}}
  {{- else -}}
    10000
  {{- end -}}
{{- end -}}

{{/*
Methods for defining security policies
*/}}
{{- define "eric-pc-up-data-plane.securityPolicy.reference" -}}
{{- $global := fromJson (include "eric-pc-up-data-plane.global" .) }}
{{- $policyName := "" -}}
    {{- if $global.security -}}
        {{- if $global.security.policyReferenceMap -}}
            {{- if index $global "security" "policyReferenceMap" "default-restricted-security-policy" -}}
                {{ $policyName = index $global "security" "policyReferenceMap" "default-restricted-security-policy" }}
            {{- end -}}
        {{- end -}}
    {{- end -}}
{{- $policyName := default "default-restricted-security-policy" $policyName -}}
{{- $policyName -}}
{{- end -}}

{{/*
Definition for the accelerated I/O driver.
*/}}
{{- define "eric-pc-up-data-plane.acceleratedIo.driver" -}}
  {{- if .Values.acceleratedIo.bifurcatedDriver }}
    {{- /* Migration rule from the legacy parameter. */ -}}
    bifurcated
  {{- else -}}
    {{- if .Values.acceleratedIo.driver -}}
      {{- $valid_drivers := list "vfio" "bifurcated" "uio" -}}
      {{- if has .Values.acceleratedIo.driver $valid_drivers -}}
        {{ .Values.acceleratedIo.driver }}
      {{- else -}}
        {{- fail (printf "Accelerated I/O driver has to be one of %s!" $valid_drivers) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Annotations for multus network interfaces.
*/}}
{{- define "eric-pc-up-data-plane.network-annotations" }}
{{- $_ := . }}
{{- $interfaces := dict "interfaces" (list) -}}
{{- range index .Values.interfaces -}}
  {{- if or (eq .type "macvlan") (eq .type "host-device") (eq .type "ovs") }}
    {{- $noop := printf "%s-%s@%s" $_.Chart.Name .name .name | append $interfaces.interfaces | set $interfaces "interfaces" -}}
  {{- end -}}
{{- end -}}
{{- if $interfaces.interfaces }}
k8s.v1.cni.cncf.io/networks: {{ join "," $interfaces.interfaces -}}
{{- end -}}
{{- end -}}

{{/*-----------------------------------------------------------------------*/}}
{{/* Constants */}}

{{/* File names of trust and keystore files.. */}}
{{- define "eric-pc-up-data-plane.security.tls.caName" }}
  {{- "cacertbundle.pem" -}}
{{- end }}
{{- define "eric-pc-up-data-plane.security.tls.certName" }}
  {{- "cert.pem" -}}
{{- end }}
{{- define "eric-pc-up-data-plane.security.tls.keyName" }}
  {{- "key.pem" -}}
{{- end }}

{{/* Path where server CA bundle for pod-to-pod communcation is mounted. */}}
{{- define "eric-pc-up-data-plane.security.tls.serverTruststore.mountPoint" }}
  {{- printf "%s" "/etc/tls/ca/server" -}}
{{- end }}
{{- define "eric-pc-up-data-plane.security.tls.serverTruststore.bundle" }}
  {{- printf "%s/%s" (include "eric-pc-up-data-plane.security.tls.serverTruststore.mountPoint" .) (include "eric-pc-up-data-plane.security.tls.caName" .) -}}
{{- end }}

{{/* Path where server certificates for pod-to-pod communcation is mounted. */}}
{{- define "eric-pc-up-data-plane.security.tls.serverKeystore.mountPoint" }}
  {{- printf "%s" "/etc/tls/cert/server" -}}
{{- end }}
{{- define "eric-pc-up-data-plane.security.tls.serverKeystore.cert" }}
  {{- printf "%s/%s" (include "eric-pc-up-data-plane.security.tls.serverKeystore.mountPoint" .) (include "eric-pc-up-data-plane.security.tls.certName" .) -}}
{{- end }}
{{- define "eric-pc-up-data-plane.security.tls.serverKeystore.key" }}
  {{- printf "%s/%s" (include "eric-pc-up-data-plane.security.tls.serverKeystore.mountPoint" .) (include "eric-pc-up-data-plane.security.tls.keyName" .) -}}
{{- end }}

{{/* Path where client CA bundles for pod-to-pod communcation is mounted. */}}
{{- define "eric-pc-up-data-plane.security.tls.clientTruststore.mountPoint" }}
  {{- printf "%s" "/etc/tls/ca/client" -}}
{{- end }}
{{- define "eric-pc-up-data-plane.security.tls.clientTruststore.bundle" }}
  {{- $client := index . 0 -}}
  {{- printf "%s/%s/%s" (include "eric-pc-up-data-plane.security.tls.clientTruststore.mountPoint" .) $client (include "eric-pc-up-data-plane.security.tls.caName" .) -}}
{{- end }}

{{/* Path where client certificates for pod-to-pod communcation is mounted. */}}
{{- define "eric-pc-up-data-plane.security.tls.clientKeystore.mountPoint" }}
  {{- printf "%s" "/etc/tls/cert/client" -}}
{{- end }}
{{- define "eric-pc-up-data-plane.security.tls.clientKeystore.cert" }}
  {{- $client := index . 0 -}}
  {{- printf "%s/%s/%s" (include "eric-pc-up-data-plane.security.tls.clientKeystore.mountPoint" .) $client (include "eric-pc-up-data-plane.security.tls.certName" .) -}}
{{- end }}
{{- define "eric-pc-up-data-plane.security.tls.clientKeystore.key" }}
  {{- $client := index . 0 -}}
  {{- printf "%s/%s/%s" (include "eric-pc-up-data-plane.security.tls.clientKeystore.mountPoint" .) $client (include "eric-pc-up-data-plane.security.tls.keyName" .) -}}
{{- end }}

{{/* Path where LI CA bundle is mounted. */}}
{{- define "eric-pc-up-data-plane.li.path.ca" }}
  {{- printf "%s" "/etc/tls/ca/li" -}}
{{- end }}

{{/* Path where LI certificates are mounted. */}}
{{- define "eric-pc-up-data-plane.li.path.certs" }}
  {{- printf "%s" "/etc/tls/cert/li" -}}
{{- end }}
