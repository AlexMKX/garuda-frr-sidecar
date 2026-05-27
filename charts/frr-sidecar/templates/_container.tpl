{{/*
Render the FRR/OSPF sidecar container as a single list element.

Usage (inside spec.template.spec.containers, with 8-space indent):
    {{- include "frr-sidecar.container" (dict
          "image" .Values.images.frr
          "ospf" .Values.ospf
          "transit" .Values.transit
        ) | nindent 8 }}

The template is a no-op when `.ospf` is nil. Callers MUST include
unconditionally (no caller-side {{- if .Values.ospf }} wrapper).

Required dict keys:
    image:   container image reference (string)
    ospf:    dict consumed by frr-sidecar.frrConf
    transit: dict with `interfaces: [string]` (optional)

PBR_TRANSIT_TAG="201" mirrors
  roles/backbone_network/files/ospf_injector/frr_injector/config.py:TRANSIT_TAG
which is the OSPF External LSA tag the transit_watcher.py (in the
sidecar image) keys off to install `ip rule iif <iface> lookup 201`.

Capability set NET_ADMIN/NET_RAW/SYS_ADMIN matches the historical
ospf_injector consumer.py contract; without SYS_ADMIN the FRR daemons
fail `cap_set_proc` on startup.
*/}}
{{- define "frr-sidecar.container" -}}
{{- if and (and .ospf .ospf.transit_provider) (and .transit (gt (len (default (list) .transit.interfaces)) 0)) -}}
{{- fail (printf "frr-sidecar: workload cannot be both transit provider (ospf.transit_provider=true) and transit consumer (transit.interfaces=%v) at the same time. See roles/backbone_network/files/ospf_injector/frr_injector/transit_config.py:34-36." .transit.interfaces) -}}
{{- end -}}
{{- if .ospf -}}
- name: frr-sidecar
  image: {{ .image | quote }}
  imagePullPolicy: IfNotPresent
  {{- with .transit }}
  {{- if .interfaces }}
  env:
    - name: PBR_TRANSIT_TAG
      value: "201"
    - name: PBR_TRANSIT_INTERFACES
      value: {{ join "," .interfaces | quote }}
  {{- end }}
  {{- end }}
  volumeMounts:
    - name: frr-source
      mountPath: /etc/frr-source
      readOnly: true
  securityContext:
    capabilities:
      add: ["NET_ADMIN", "NET_RAW", "SYS_ADMIN"]
{{- end -}}
{{- end }}
