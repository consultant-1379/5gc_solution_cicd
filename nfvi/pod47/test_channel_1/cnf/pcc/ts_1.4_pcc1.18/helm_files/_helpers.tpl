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
Expand the name of the Docker images.
*/}}
{{- define "eric-pc-up-data-plane.imagePath" }}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $global := fromJson (include "eric-pc-up-data-plane.global" .) }}
  {{- $registryUrl := default $global.registry.url .Values.imageCredentials.registry.url -}}
  {{- $repoPath := printf "%s/" (default $productInfo.images.dataPlane.repoPath .Values.imageCredentials.repoPath) -}}
  {{- /* If repoPath is an empty string, we don't want to use the default */ -}}
  {{- if (and (typeIs "string" .Values.imageCredentials.repoPath) (not .Values.imageCredentials.repoPath)) -}}
    {{- $repoPath = "" -}}
  {{- end -}}
  {{- $name := default $productInfo.images.dataPlane.name .Values.images.dataPlane.name -}}
  {{- $tag := default $productInfo.images.dataPlane.tag .Values.images.dataPlane.tag -}}
  {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{- define "eric-pc-up-data-plane-at.imageTag" }}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- printf "%s" (default $productInfo.images.dataPlaneAt.tag .Values.images.dataPlaneAt.tag) -}}
{{- end -}}

{{- define "eric-pc-up-data-plane-at.imagePath" }}
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $global := fromJson (include "eric-pc-up-data-plane.global" .) }}
  {{- $registryUrl := default $global.registry.url .Values.imageCredentials.registry.url -}}
  {{- $repoPath := printf "%s/" (default $productInfo.images.dataPlaneAt.repoPath .Values.imageCredentials.repoPath) -}}
  {{- /* If repoPath is an empty string, we don't want to use the default */ -}}
  {{- if (and (typeIs "string" .Values.imageCredentials.repoPath) (not .Values.imageCredentials.repoPath)) -}}
    {{- $repoPath = "" -}}
  {{- end -}}
  {{- $name := default $productInfo.images.dataPlaneAt.name .Values.images.dataPlaneAt.name -}}
  {{- $tag := (include "eric-pc-up-data-plane-at.imageTag" .) -}}
  {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
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
Create image pull policy
*/}}
{{- define "eric-pc-up-data-plane.imagePullPolicy" -}}
  {{- if .Values.imageCredentials.registry.imagePullPolicy -}}
    {{- print .Values.imageCredentials.registry.imagePullPolicy -}}
  {{- else -}}
    {{- $global := fromJson (include "eric-pc-up-data-plane.global" .) }}
    {{- print $global.registry.imagePullPolicy -}}
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
  {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := mustMerge $globalDefaults (dict "security" (dict "policyBinding" (dict "create" false))) -}}
  {{- $globalDefaults := mustMerge $globalDefaults (dict "security" (dict "policyReferenceMap" (dict "default-restricted-security-policy" "default-restricted-security-policy"))) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "timezone" "UTC") -}}
  {{- $globalDefaults := merge $globalDefaults (dict "pullSecret" "") -}}
  {{- $globalDefaults := mustMerge $globalDefaults (dict "registry" (dict "url" $productInfo.images.dataPlane.registry)) -}}
  {{- $globalDefaults := mustMerge $globalDefaults (dict "registry" (dict "imagePullPolicy" "IfNotPresent")) -}}
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
Create annotation for the product information (DR-D1121-064)
*/}}
{{- define "eric-pc-up-data-plane.product-info" -}}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ mustRegexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end }}

{{/*
Default labels attached to all the k8s resources
*/}}
{{ define "eric-pc-up-data-plane.kubernetes-labels" -}}
app.kubernetes.io/name: {{ template "eric-pc-up-data-plane.name" . }}
app.kubernetes.io/version: {{ template "eric-pc-up-data-plane.version" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ template "eric-pc-up-data-plane.chart" . }}
{{ end }}

{{/*
Create a merged set of labels from global and service level.
*/}}
{{ define "eric-pc-up-data-plane.labels" }}
{{- include "eric-pc-up-data-plane.kubernetes-labels" . }}
  {{- $kuberneteslabels := dict "labels" ((include "eric-pc-up-data-plane.kubernetes-labels" . ) | fromYaml) -}}
  {{- $labels := dict "labels" (dict) -}}

  {{- if .Values.global -}}
    {{- if .Values.global.labels -}}
      {{- range $key, $localValue := .Values.global.labels -}}
        {{- if hasKey $kuberneteslabels.labels $key -}}
            {{- $globalValue := index $kuberneteslabels.labels $key -}}
            {{- if ne $globalValue $localValue -}}
              {{- printf "labels \"%s\" specified in global (%s: %s) is same as product info. Its not supported to change the kubernetes related labels." $key $key $localValue | fail -}}
            {{- end -}}
        {{- end -}}
      {{- end -}}

      {{- $global := dict "labels" .Values.global.labels -}}
      {{- $labels := merge $labels $global }}
      {{- $kuberneteslabels := merge $kuberneteslabels $global }}
    {{- end -}}
  {{- end -}}

  {{- if .Values.labels -}}
    {{- range $key, $localValue := .Values.labels -}}
      {{- if hasKey $kuberneteslabels.labels $key -}}
          {{- $globalValue := index $kuberneteslabels.labels $key -}}
          {{- if ne $globalValue $localValue -}}
            {{- printf "labels \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}

    {{- $service := dict "labels" .Values.labels -}}
    {{- $labels := mergeOverwrite $labels $service }}
  {{- end -}}

  {{- if keys $labels.labels -}}
    {{- range $key, $config := $labels.labels }}
      {{- if not (regexMatch "^([A-Za-z0-9][0-9A-Za-z.]{0,252}\\/)?([A-Za-z0-9][_0-9A-Za-z-.]{0,62}$)" $key) }}
        {{- if not (regexMatch "^([A-Za-z0-9][_0-9A-Za-z-.]{0,62}$)" $config) }}
          {{- printf "labels value \"%s\" is wrongly specified. The value of the key cannot exceed 63 characters in [A-Z0-9a-z.-_]" $config | fail -}}
        {{- end }}
        {{- printf "labels key \"%s\" is wrongly specified. key-prefix cannot exceed 253 characters in [A-Z0-9a-z.] and key cannot exceed 63 characters in [A-Z0-9a-z.-_]" $key | fail -}}
      {{- end }}
    {{- end }}
{{ toYaml $labels.labels }}
  {{- end -}}
{{ end }}

{{/*
Create a merged set of annotations from global and service level.
*/}}
{{- define "eric-pc-up-data-plane.helm-annotations" -}}
  {{- $annotations := dict "annotations" ((include "eric-pc-up-data-plane.product-info" . ) | fromYaml) -}}

  {{- if .Values.global -}}
    {{- if .Values.global.annotations -}}
      {{- range $globalKey, $globalValue := .Values.global.annotations -}}
        {{- if not (regexMatch "^([A-Za-z0-9][0-9A-Za-z.]{0,252}\\/)?([A-Za-z0-9][_0-9A-Za-z-.]{0,62}$)" $globalKey) }}
          {{- printf "global annotations key \"%s\" is wrongly specified. key-prefix cannot exceed 253 characters in [A-Z0-9a-z.] and key cannot exceed 63 characters in [A-Z0-9a-z.-_]" $globalKey | fail -}}
        {{- end }}
        {{- if not (regexMatch "^([A-Za-z0-9][_0-9A-Za-z-.]{0,62}$)" $globalValue) }}
          {{- printf "global annotations value \"%s\" is wrongly specified. The value of the key cannot exceed 63 characters in [A-Z0-9a-z.-_]" $globalValue | fail -}}
        {{- end }}
        {{- if hasKey $annotations.annotations $globalKey -}}
            {{- $annotationValue := index $annotations.annotations $globalKey -}}
            {{- if ne $annotationValue $globalValue -}}
              {{- printf "annotations key \"%s\" specified in global (%s: %s) is same as product info. Its not supported to change the product related annotations." $globalKey $globalKey $globalValue | fail -}}
            {{- end -}}
        {{- end -}}
      {{- end -}}

      {{- $global := dict "annotations" .Values.global.annotations -}}
      {{- $annotations := merge $annotations $global }}
    {{- end -}}
  {{- end -}}

  {{- if .Values.annotations -}}
    {{- range $localKey, $localValue := .Values.annotations -}}
      {{- if not (regexMatch "^([A-Za-z0-9][0-9A-Za-z.]{0,252}\\/)?([A-Za-z0-9][_0-9A-Za-z-.]{0,62}$)" $localKey) }}
        {{- printf "local annotations key \"%s\" is wrongly specified. key-prefix cannot exceed 253 characters in [A-Z0-9a-z.] and key cannot exceed 63 characters in [A-Z0-9a-z.-_]" $localKey | fail -}}
      {{- end }}
      {{- if not (regexMatch "^([A-Za-z0-9][_0-9A-Za-z-.]{0,62}$)" $localValue) }}
        {{- printf "local annotations value \"%s\" is wrongly specified. The value of the key cannot exceed 63 characters in [A-Z0-9a-z.-_]" $localValue | fail -}}
      {{- end }}
      {{- if hasKey $annotations.annotations $localKey -}}
          {{- $annotationValue := index $annotations.annotations $localKey -}}
          {{- if ne $annotationValue $localValue -}}
            {{- printf "annotations key \"%s\" is specified in both global or product info (%s: %s) and service level (%s: %s) with differing values which is not allowed." $localKey $localKey $annotationValue $localKey $localValue | fail -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}

    {{- $local := dict "annotations" .Values.annotations -}}
    {{- $annotations := mergeOverwrite $annotations $local }}
  {{- end }}
  {{- toYaml $annotations.annotations }}
{{ end }}

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
