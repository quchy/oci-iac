output "compute_instance_public_ip" {
  value = module.compute.instance.public_ip
}

output "compartment_id" {
  value = var.compartment_ocid
}

output "generated_instance_ssh_private_key" {
  value = var.generate_ssh_key_pair ? module.compute.instance_keys.private_key_pem : ""
}