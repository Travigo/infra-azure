locals {
  nodes = {
    "db" = {
      name            = "db"
      vm_size         = "Standard_E8s_v6"
      node_count      = 1
      priority        = "Spot"
      eviction_policy = "Delete"
      os_disk_size_gb = 48
      vnet_subnet_id  = azurerm_subnet.kube.id
      node_labels = {
        "kube.travigo.app/role" = "datastore"
        "kubernetes.azure.com/scalesetpriority" = "spot"
      },
      node_taints = [
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule",
        "kube.travigo.app/role=datastore:NoSchedule",
      ]

      enable_auto_scaling = true
      min_count = 1
      max_count = 1

      vnet_subnet = {id = azurerm_subnet.kube.id}
    },
    "workers" = {
      name            = "workers"
      vm_size         = "Standard_D4s_v6"
      node_count      = 1
      priority        = "Spot"
      eviction_policy = "Delete"
      os_disk_size_gb = 48
      vnet_subnet_id  = azurerm_subnet.kube.id
      node_labels = {
        "kubernetes.azure.com/scalesetpriority" = "spot"
      }
      node_taints = [
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
      ]

      enable_auto_scaling = true
      min_count = 1
      max_count = 1

      vnet_subnet = {id = azurerm_subnet.kube.id}
    },
    "medium-batch" = {
      name            = "mbatch"
      vm_size         = "Standard_D4s_v6"
      node_count      = 0
      priority        = "Spot"
      eviction_policy = "Delete"
      os_disk_size_gb = 32
      vnet_subnet_id  = azurerm_subnet.kube.id
      node_labels = {
        "kube.travigo.app/batch-burst-size" = "medium"
        "kubernetes.azure.com/scalesetpriority" = "spot"
      },
      node_taints = [
        "kube.travigo.app/batch-burst=true:NoSchedule",
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
      ]

      enable_auto_scaling = true
      min_count = 0
      max_count = 1

      vnet_subnet = {id = azurerm_subnet.kube.id}
    },
    "large-batch" = {
      name            = "lbatch"
      vm_size         = "Standard_D16s_v6"
      node_count      = 0
      priority        = "Spot"
      eviction_policy = "Delete"
      os_disk_size_gb = 48
      vnet_subnet_id  = azurerm_subnet.kube.id
      node_labels = {
        "kube.travigo.app/batch-burst-size" = "large"
        "kubernetes.azure.com/scalesetpriority" = "spot"
      },
      node_taints = [
        "kube.travigo.app/batch-burst=true:NoSchedule",
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
      ]

      enable_auto_scaling = true
      min_count = 0
      max_count = 1

      vnet_subnet = {id = azurerm_subnet.kube.id}
    }
  }
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "10.2.0"

  prefix              = "travigo"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_location
  sku_tier            = "Free"
  vnet_subnet = {
    id      = azurerm_subnet.kube.id
  }
  node_pools          = local.nodes

  log_analytics_workspace_enabled   = true
  rbac_aad_azure_rbac_enabled       = true
  rbac_aad                          = true
  role_based_access_control_enabled = true

  // System pool
  agents_pool_name    = "system"
  agents_count        = 1
  enable_auto_scaling = false
  agents_size         = "Standard_B2pls_v2"
  os_disk_size_gb     = 32
  only_critical_addons_enabled = true
  temporary_name_for_rotation  = "systemrotate"

  // Scale
  auto_scaler_profile_enabled = true
  auto_scaler_profile_skip_nodes_with_system_pods = false
  auto_scaler_profile_skip_nodes_with_local_storage = false
}