# Retrieve the parent resource group to obtain its ID for use as parent_id in azapi resources.
data "azurerm_resource_group" "parent" {
  name = var.resource_group_name
}

# -------------------------------------------------------------------------
# Core resource: Microsoft.Network/networkSecurityPerimeters
# API version: 2025-05-01
# -------------------------------------------------------------------------
resource "azapi_resource" "network_security_perimeter" {
  type      = "Microsoft.Network/networkSecurityPerimeters@2025-05-01"
  name      = var.name
  parent_id = data.azurerm_resource_group.parent.id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {}
  }

  response_export_values = ["*"]
}

# -------------------------------------------------------------------------
# Child resource: NSP Profiles
# Microsoft.Network/networkSecurityPerimeters/profiles@2025-05-01
# -------------------------------------------------------------------------
resource "azapi_resource" "nsp_profile" {
  for_each = var.profiles

  type      = "Microsoft.Network/networkSecurityPerimeters/profiles@2025-05-01"
  name      = each.value.name
  parent_id = azapi_resource.network_security_perimeter.id

  body = {
    properties = {}
  }

  response_export_values = ["*"]
}

# -------------------------------------------------------------------------
# Grandchild resource: NSP Access Rules (per profile)
# Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-05-01
# -------------------------------------------------------------------------
resource "azapi_resource" "nsp_access_rule" {
  for_each = var.access_rules

  type      = "Microsoft.Network/networkSecurityPerimeters/profiles/accessRules@2025-05-01"
  name      = each.value.name
  parent_id = azapi_resource.nsp_profile[each.value.profile_key].id

  body = {
    properties = {
      addressPrefixes           = each.value.address_prefixes
      direction                 = each.value.direction
      emailAddresses            = each.value.email_addresses
      fullyQualifiedDomainNames = each.value.fully_qualified_domain_names
      phoneNumbers              = each.value.phone_numbers
      serviceTags               = each.value.service_tags
      subscriptions             = [for sub in each.value.subscriptions : { id = sub }]
    }
  }

  response_export_values = ["*"]
}

# -------------------------------------------------------------------------
# Child resource: NSP Resource Associations
# Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2025-05-01
# -------------------------------------------------------------------------
resource "azapi_resource" "nsp_resource_association" {
  for_each = var.resource_associations

  type      = "Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2025-05-01"
  name      = each.value.name
  parent_id = azapi_resource.network_security_perimeter.id

  body = {
    properties = {
      accessMode = each.value.access_mode
      privateLinkResource = {
        id = each.value.private_link_resource_id
      }
      profile = {
        id = azapi_resource.nsp_profile[each.value.profile_key].id
      }
    }
  }

  response_export_values = ["*"]
}

# -------------------------------------------------------------------------
# AVM required resource interfaces
# -------------------------------------------------------------------------
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.network_security_perimeter.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.network_security_perimeter.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
