locals {
  compartment_id                  = var.target_compartment_id
  vcn_id                          = var.vcn_id
  all_cidr                        = "0.0.0.0/0"
  current_time                    = formatdate("YYYYMMDDhhmmss", timestamp())
  app_name                        = "oci-dev-kit"
  display_name                    = join("-", [local.app_name, local.current_time])
  compartment_name                = data.oci_identity_compartment.this.name
  dynamic_group_tenancy_level     = "Allow dynamic-group ${oci_identity_dynamic_group.for_instance.name} to manage all-resources in tenancy"
  dynamic_group_compartment_level = "Allow dynamic-group ${oci_identity_dynamic_group.for_instance.name} to manage all-resources in compartment ${local.compartment_name}"
  num_of_ads                      = length(data.oci_identity_availability_domains.ads.availability_domains)
  ads                             = local.num_of_ads > 1 ? flatten([
                                        for ad_shapes in data.oci_core_shapes.this : [
                                            for shape in ad_shapes.shapes : ad_shapes.availability_domain if shape.name == var.instance_shape
                                        ]
                                    ]) : [for ad in data.oci_identity_availability_domains.ads.availability_domains : ad.name]
}

resource "oci_core_network_security_group" "nsg" {
  compartment_id = local.compartment_id                   # Required
  vcn_id         = local.vcn_id                           # Required
  display_name   = "${local.display_name}-security-group" # Optional
  freeform_tags  = var.common_tags
}

resource "oci_core_network_security_group_security_rule" "ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "6"                                    # Required
  source                    = local.all_cidr                         # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  tcp_options {                                                      # Optional
    destination_port_range {                                         # Optional         
      max = "22"                                                     # Required
      min = "22"                                                     # Required
    }
  }
  description = "ssh only allowed" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_icmp_3_4" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "1"                                    # Required
  source                    = local.all_cidr                         # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  icmp_options {                                                     # Optional
    type = "3"                                                       # Required
    code = "4"                                                       # Required
  }
  description = "icmp option 1" # Optional
}

resource "oci_core_network_security_group_security_rule" "ingress_icmp_3" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "INGRESS"                              # Required
  protocol                  = "1"                                    # Required
  source                    = "10.0.0.0/16"                          # Required
  source_type               = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  icmp_options {                                                     # Optional
    type = "3"                                                       # Required
  }
  description = "icmp option 2" # Optional
}

resource "oci_core_network_security_group_security_rule" "egress" {
  network_security_group_id = oci_core_network_security_group.nsg.id # Required
  direction                 = "EGRESS"                               # Required
  protocol                  = "6"                                    # Required
  destination               = local.all_cidr                         # Required
  destination_type          = "CIDR_BLOCK"                           # Required
  stateless                 = false                                  # Optional
  description               = "connect to any network"
}

# Get a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "this" {
  compartment_id           = local.compartment_id # Required
  operating_system         = var.image_os         # Optional
  operating_system_version = var.image_os_version # Optional
  shape                    = var.instance_shape   # Optional
  sort_by                  = "TIMECREATED"        # Optional
  sort_order               = "DESC"               # Optional
}

data "oci_core_shapes" "this" {
  count               = local.num_of_ads > 1 ? local.num_of_ads : 0 
  #Required
  compartment_id      = local.compartment_id

  #Optional
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index].name
  image_id            = data.oci_core_images.this.images[0].id
}

data "oci_identity_compartment" "this" {
  id = local.compartment_id
}

# Generate the private and public key pair
resource "tls_private_key" "ssh_keypair" {
  algorithm = "RSA" # Required
  rsa_bits  = 2048  # Optional
}

resource "oci_identity_dynamic_group" "for_instance" {
  compartment_id = var.tenancy_ocid
  description    = "To Access OCI CLI"
  name           = "${local.display_name}-dynamic-group"
  matching_rule  = "ANY {instance.id = '${oci_core_instance.dev_tools.id}'}"
  freeform_tags  = var.common_tags
}

resource "oci_identity_policy" "dg_manage_all" {
  compartment_id = var.use_tenancy_level_policy ? var.tenancy_ocid : local.compartment_id
  description    = "To Access OCI CLI"
  name           = "${local.display_name}-instance-policy"
  statements     = var.use_tenancy_level_policy ? [local.dynamic_group_tenancy_level] : [local.dynamic_group_compartment_level]
  freeform_tags  = var.common_tags
}

resource "oci_core_instance" "dev_tools" {
  availability_domain  = local.ads[0]
  compartment_id       = local.compartment_id
  shape                = var.instance_shape
  preserve_boot_volume = false
  freeform_tags        = var.common_tags

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.nsg.id]
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.this.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.generate_ssh_key_pair ? tls_private_key.ssh_keypair.public_key_openssh : var.ssh_public_key
    user_data           = base64encode(file("./modules/compute/scripts/bootstrap.sh"))
    tenancy_id          = var.tenancy_ocid
  }
}
