resource "aws_vpc_peering_connection" "this" {
  for_each = { for peer in var.vpc_peering_connections : peer.peer_vpc_id => peer }

  auto_accept   = each.value.auto_accept
  peer_owner_id = each.value.peer_owner_id
  peer_region   = each.value.peer_region
  peer_vpc_id   = each.value.peer_vpc_id
  tags          = each.value.tags
  vpc_id        = aws_vpc.this.id

  dynamic "accepter" {
    for_each = each.value.accepter != null ? toset([1]) : toset([])

    content {
      allow_remote_vpc_dns_resolution = each.value.accepter.allow_remote_vpc_dns_resolution
    }
  }

  dynamic "requester" {
    for_each = each.value.requester != null ? toset([1]) : toset([])

    content {
      allow_remote_vpc_dns_resolution = each.value.requester.allow_remote_vpc_dns_resolution
    }
  }
}

resource "aws_vpc_peering_connection_accepter" "this" {
  for_each = { for peer in var.vpc_peering_connection_accepters : peer.vpc_peering_connection_id => peer }

  auto_accept               = each.value.auto_accept
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
  tags                      = each.value.tags
}

resource "aws_subnet" "peering" {
  for_each = {
    for az in toset(var.availability_zones) : az => {
      az   = az
      name = "${var.name}-peering-${az}"
      cidr_block = cidrsubnet(
        var.cidr_block,
        coalesce(var.peering_subnets.newbits, 28 - parseint(split("/", var.cidr_block)[1], 10)),
        coalesce(var.peering_subnets.first_netnum, length(var.availability_zones)) + index(sort(var.availability_zones), az)
      )
    }
  }

  availability_zone = each.value.az
  cidr_block        = each.value.cidr_block
  vpc_id            = aws_vpc.this.id

  tags = {
    "Availability Zone" = each.value.az
    "Name"              = each.value.name
    "Type"              = "airgapped"
  }
}

resource "aws_route_table" "peering" {
  vpc_id = aws_vpc.this.id

  tags = {
    "Availability Zones" = join(",", var.availability_zones)
    "Name"               = "${var.name}-peering"
    "Type"               = "airgapped"
  }
}

resource "aws_route_table_association" "peering" {
  for_each = toset(var.availability_zones)

  route_table_id = aws_route_table.peering.id
  subnet_id      = aws_subnet.peering[each.key].id
}

resource "aws_network_acl" "peering" {
  subnet_ids = [for az in var.availability_zones : aws_subnet.peering[az].id]
  vpc_id     = aws_vpc.this.id

  ingress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.cidr_block
    rule_no    = 1
  }

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    rule_no    = 1
  }

  tags = {
    "Availability Zones" = join(",", sort(var.availability_zones))
    "Name"               = "${var.name}-peering"
    "Type"               = "airgapped"
  }
}
