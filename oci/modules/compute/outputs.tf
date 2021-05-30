output "instance" {
  value = oci_core_instance.dev_tools
}

output "instance_keys" {
  value = tls_private_key.ssh_keypair
}
