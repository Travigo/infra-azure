resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    name        = "ingress-nginx"
    annotations = {}
    labels      = {}
  }
}

resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  version = "4.10.2"

  namespace = kubernetes_namespace.ingress-nginx.metadata[0].name

  values = [
  <<-EOF
  controller:
    service:
      type: ClusterIP

    admissionWebhooks:
      enabled: false

    resources:
      requests:
        cpu: 10m

  defaultBackend:
    enabled: true
  EOF
  ]
}