# Configure Rancher provider
terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = ">=1.21.0"
    }
  }
}

provider "rancher2" {
  api_url = "https://sanes-rancher.westeurope.cloudapp.azure.com"
  access_key = var.access_key
  secret_key = var.secret_key
  insecure = true
}

module "rke_cluster" {
  source = "app.terraform.io/georgevazj-lab/rke_cluster/rancher2"
  version = "0.0.4"

  api_url = "https://sanes-rancher.westeurope.cloudapp.azure.com"
  access_key = var.access_key
  secret_key = var.secret_key
  description = var.description
  name = var.name
  kubernetes_network_plugin = var.kubernetes_network_plugin
}

module "controlplane" {
  source  = "app.terraform.io/georgevazj-lab/node_pool/rancher2"
  version = "0.0.3"

  name = "${var.node_pool_name}-control"
  hostname_prefix = "${var.node_pool_name}-control"
  access_key = var.access_key
  secret_key = var.secret_key
  description = "Control plane pool"
  cluster_id = module.rke_cluster.cluster_id
  api_url = "https://sanes-rancher.westeurope.cloudapp.azure.com"
  node_template = "rke-playground-controlplane"
  is_control_plane = true
  is_worker = false
  is_etcd = false
  quantity = 2
}

module "etcd" {
  source  = "app.terraform.io/georgevazj-lab/node_pool/rancher2"
  version = "0.0.3"

  name = "${var.node_pool_name}-etcd"
  hostname_prefix = "${var.node_pool_name}-etcd"
  access_key = var.access_key
  secret_key = var.secret_key
  description = "etcd pool"
  cluster_id = module.rke_cluster.cluster_id
  api_url = "https://sanes-rancher.westeurope.cloudapp.azure.com"
  node_template = "rke-playground-etcd"
  is_control_plane = false
  is_worker = false
  is_etcd = true
  quantity = 3
}

module "node_pool" {
  source  = "app.terraform.io/georgevazj-lab/node_pool/rancher2"
  version = "0.0.3"

  api_url = "https://sanes-rancher.westeurope.cloudapp.azure.com"
  name = var.node_pool_name
  access_key = var.access_key
  secret_key = var.secret_key
  cluster_id = module.rke_cluster.cluster_id
  description = var.description
  node_template = var.node_template_name
  hostname_prefix = var.hostname_prefix
  is_control_plane = false
  is_worker = true
  is_etcd = false
  quantity = var.quantity
}

resource "rancher2_cluster_sync" "sync" {
  cluster_id = module.rke_cluster.cluster_id
  node_pool_ids = [module.controlplane.node_pool_id,module.etcd.node_pool_id,module.node_pool.node_pool_id]
}
