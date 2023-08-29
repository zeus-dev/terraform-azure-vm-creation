output "vm_ips" {
  value = [for vm_key, vm in azurerm_linux_virtual_machine.personal : azurerm_public_ip.personal[vm_key].ip_address]
}
