terraform {
  required_version = "~> 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# This is the module call
# Example: a Network Security Perimeter with one profile, one inbound access rule,
# and no resource associations (add resource_associations to link PaaS resources).
module "network_security_perimeter" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.unique-seed # use your own valid NSP name
  resource_group_name = azurerm_resource_group.this.name
  # NSP Access Rules - flat map, each rule references a profile via profile_key
  access_rules = {
    allow_inbound_corp = {
      name             = "allow-inbound-corp-subnets"
      profile_key      = "profile1"
      direction        = "Inbound"
      address_prefixes = ["10.0.0.0/8", "172.16.0.0/12"]
    }
    allow_outbound_storage = {
      name                         = "allow-outbound-storage"
      profile_key                  = "profile1"
      direction                    = "Outbound"
      fully_qualified_domain_names = ["*.blob.core.windows.net"]
    }
  }
  enable_telemetry = var.enable_telemetry # see variables.tf
  # NSP Profiles - flat map, one entry per profile
  profiles = {
    profile1 = {
      name = "default-profile"
    }
  }
  tags = {
    environment = "example"
    module      = "avm-res-network-networksecurityperimeter"
  }
}
