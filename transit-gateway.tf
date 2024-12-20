resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = { for attachment in var.transit_gateway_attachments : attachment.transit_gateway_id => attachment }

  appliance_mode_support                          = each.value.appliance_mode_support
  dns_support                                     = each.value.dns_support
  ipv6_support                                    = each.value.ipv6_support
  subnet_ids                                      = [for subnet in aws_subnet.peering : subnet.id]
  tags                                            = each.value.tags
  transit_gateway_id                              = each.value.transit_gateway_id
  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = each.value.transit_gateway_default_route_table_propagation
  vpc_id                                          = aws_vpc.this.id
}

resource "aws_route" "transit_gateway" {
  for_each = {
    for route in distinct(flatten([
      for group in var.subnet_groups : [
        for route in coalesce(group.routes, []) : merge(route, {
          destination = coalesce(
            route.cidr_block,
            route.ipv6_cidr_block,
            route.prefix_list_id
          )
        }) if route.transit_gateway_id != null
      ]
    ])) : route.destination => route
  }

  destination_cidr_block      = each.value.cidr_block
  destination_ipv6_cidr_block = each.value.ipv6_cidr_block
  destination_prefix_list_id  = each.value.prefix_list_id
  route_table_id              = aws_route_table.peering.id
  transit_gateway_id          = each.value.transit_gateway_id
}
