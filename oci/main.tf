locals {
  common_tags = {
    Reference = "oci-dev-tools"
  }
}

module "network" {
  source                = "./modules/network"
  target_compartment_id = var.compartment_ocid
  common_tags           = local.common_tags
}

module "compute" {
  source                   = "./modules/compute"
  region                   = var.region
  tenancy_ocid             = var.tenancy_ocid
  target_compartment_id    = var.compartment_ocid
  vcn_id                   = module.network.vcn.id
  subnet_id                = module.network.subnet.id
  instance_shape           = var.instance_shape
  generate_ssh_key_pair    = var.generate_ssh_key_pair
  ssh_public_key           = var.ssh_public_key
  use_tenancy_level_policy = var.use_tenancy_level_policy
  common_tags              = local.common_tags
}