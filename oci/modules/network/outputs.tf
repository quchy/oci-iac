output "vcn" {
  value = oci_core_vcn.this
}

output "subnet" {
  value = oci_core_subnet.regional_sn
}