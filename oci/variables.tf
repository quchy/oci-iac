variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}

variable "instance_shape" {
  description = "Shape of the instance"
  type        = string
}

variable "generate_ssh_key_pair" {
  description = "Auto-generate SSH key pair"
  type        = string
}

variable "ssh_public_key" {
  description = "ssh public key used to connect to the compute instance"
  default     = "" # This value has to be defaulted to blank, otherwise terraform apply would request for one.
  type        = string
}

variable "use_tenancy_level_policy" {
  description = "Compute instance to access all resources at tenancy level"
  type        = bool
}