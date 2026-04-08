# Network Security Perimeter (NSP) does not expose a private endpoint subresource.
# NSP is itself the network isolation boundary for PaaS services and
# does not have a private endpoint resource type of its own.
#
# To associate a PaaS resource that supports Private Link with this NSP,
# use var.resource_associations which creates:
#   Microsoft.Network/networkSecurityPerimeters/resourceAssociations
