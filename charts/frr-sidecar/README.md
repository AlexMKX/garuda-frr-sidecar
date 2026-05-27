# frr-sidecar (Helm library chart)

Shared FRR/OSPF sidecar container template consumed by
`modules/wireguard/kube` and `modules/firezone/kube`. Owns:

- The `frr-sidecar` container name, image binding, capability set
  (`NET_ADMIN`, `NET_RAW`, `SYS_ADMIN`).
- The FRR config renderer (`frr-sidecar.frrConf`).
- The PBR/transit env contract (`PBR_TRANSIT_TAG="201"`,
  `PBR_TRANSIT_INTERFACES`), mirroring `TRANSIT_TAG = 201` in
  `roles/backbone_network/files/ospf_injector/frr_injector/config.py`.

## Consumer integration

In `Chart.yaml`:

```yaml
dependencies:
  - name: frr-sidecar
    version: "0.1.0"
    repository: "file://../../../../frr-sidecar/charts/frr-sidecar"
```

In `templates/deployment.yaml` (inside `spec.template.spec.containers:`):

```yaml
{{- if .Values.ospf }}
{{- include "frr-sidecar.container" (dict
      "image" .Values.images.frr
      "ospf" .Values.ospf
      "transit" .Values.transit
    ) | nindent 8 }}
{{- end }}
```

## Distribution

The library is consumed as an **unpacked subchart**: each consumer
ships a hardlink copy at `charts/frr-sidecar/` so Terraform
`helm_release` works without a `helm dependency build` step. Restore
the hardlinks after a hard `git checkout` with `cp -al`.
