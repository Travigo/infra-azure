resource "kubernetes_namespace" "kyverno" {
  metadata {
    name        = "kyverno"
    annotations = {}
    labels      = {}
  }
}

resource "helm_release" "kyverno" {
  name       = "kyverno"

  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"

  version = "3.3.6"

  namespace = kubernetes_namespace.kyverno.metadata[0].name

  values = [
  <<-EOF
  global:
    tolerations:
    - key: "CriticalAddonsOnly"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
  EOF
  ]
}

resource "kubectl_manifest" "tolerations" {
  yaml_body = <<YAML
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: add-tolerations
    annotations:
      policies.kyverno.io/title: Add Tolerations
      policies.kyverno.io/category: Other
      policies.kyverno.io/severity: medium
      policies.kyverno.io/subject: Pod
      kyverno.io/kyverno-version: 1.7.1
      policies.kyverno.io/minversion: 1.6.0
      kyverno.io/kubernetes-version: "1.23"
      policies.kyverno.io/description: >- 
        Pod tolerations are used to schedule on Nodes which have
        a matching taint. This policy adds the toleration `org.com/role=service:NoSchedule`
        if existing tolerations do not contain the key `org.com/role`.
  spec:
    rules:
    - name: service-toleration
      match:
        any:
        - resources:
            kinds:
            - Pod
      mutate:
        patchesJson6902: |-
          - op: add
            path: "/spec/tolerations/-"
            value:
              key: kubernetes.azure.com/scalesetpriority
              operator: Equal
              value: spot
              effect: NoSchedule 
  YAML
}