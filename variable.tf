variable "public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "/Users/mac/.ssh/id_rsa.pub"
}

variable "vm_count" {
  description = "Number of virtual machines"
  type        = number
  default     = 3
}
