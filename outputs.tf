# AVM required outputs
output "resource" {
  description = "The full network security perimeter resource object."
  value       = azapi_resource.network_security_perimeter
}

output "resource_id" {
  description = "The resource ID of the network security perimeter."
  value       = azapi_resource.network_security_perimeter.id
}

output "name" {
  description = "The name of the network security perimeter."
  value       = azapi_resource.network_security_perimeter.name
}

# NSP-specific outputs
output "profiles" {
  description = "A map of the NSP profile resources created. Keyed by the map key used in var.profiles."
  value       = azapi_resource.nsp_profile
}

output "resource_associations" {
  description = "A map of the NSP resource association resources created. Keyed by the map key used in var.resource_associations."
  value       = azapi_resource.nsp_resource_association
}
