resource "kubernetes_namespace" "redis" {
  metadata {
    name        = "redis"
    annotations = {}
    labels      = {}
  }
}

resource "random_password" "redis-password" {
  length           = 64
  special          = false
}

resource "kubernetes_secret" "redis-password" {
  metadata {
    name      = "redis-password"
  }

  data = {
    "password" = random_password.redis-password.result
  }

  type = "kubernetes.io/secret"
}

resource "helm_release" "redis" {
  name       = "redis"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"

  version = "18.12.0"

  namespace = kubernetes_namespace.redis.metadata[0].name

  values = [
  <<-EOF
  global:
    redis:
      password: ${random_password.redis-password.result}

  master:
    persistence:
      enabled: false

  replica:
    persistence:
      enabled: false
    replicaCount: 0
  EOF
  ]
}