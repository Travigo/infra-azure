locals {
  nodes = {
    "workers" = {
      name            = "workers"
      vm_size         = "Standard_D8s_v6"
      node_count      = 1
      priority        = "Spot"
      eviction_policy = "Delete"
      os_disk_size_gb = 48
      vnet_subnet_id  = azurerm_subnet.kube.id
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
      },
      node_taints = [
        "kube.travigo.app/batch-burst=true:NoSchedule"
      ]

      enable_auto_scaling = true
      min_count = 0
      max_count = 1
    },
    "large-batch" = {
      name            = "lbatch"
      vm_size         = "Standard_D8s_v6"
      node_count      = 0
      priority        = "Spot"
      eviction_policy = "Delete"
      os_disk_size_gb = 32
      vnet_subnet_id  = azurerm_subnet.kube.id
      node_labels = {
        "kube.travigo.app/batch-burst-size" = "large"
      },
      node_taints = [
        "kube.travigo.app/batch-burst=true:NoSchedule"
      ]

      enable_auto_scaling = true
      min_count = 0
      max_count = 1
    }
  }
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "9.4.1"

  prefix              = "travigo"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_location
  sku_tier            = "Free"
  vnet_subnet_id      = azurerm_subnet.kube.id
  node_pools          = local.nodes

  log_analytics_workspace_enabled   = true
  rbac_aad_azure_rbac_enabled       = true
  rbac_aad                          = true
  rbac_aad_managed                  = true
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