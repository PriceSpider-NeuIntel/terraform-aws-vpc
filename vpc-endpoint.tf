resource "aws_vpc_endpoint" "this" {
  for_each = { for endpoint in var.vpc_endpoints : endpoint.service_name => endpoint }

  auto_accept         = each.value.auto_accept
  policy              = each.value.policy
  private_dns_enabled = each.value.private_dns_enabled
  security_group_ids  = each.value.vpc_endpoint_type == "Interface" ? [aws_security_group.vpc_endpoint.id] : null
  service_name        = each.value.service_name
  tags                = each.value.tags

  route_table_ids = each.value.vpc_endpoint_type == "Gateway" ? flatten([
    for table in each.value.route_tables : try(
      [aws_route_table.this[table.subnet_group].id],
      [for az in try(each.value.azs, var.availability_zones) : aws_route_table.this["${table.subnet_group}-${az}"].id]
    )
  ]) : null

  subnet_ids = each.value.vpc_endpoint_type == "Interface" || each.value.vpc_endpoint_type == "GatewayLoadBalancer" ? (
    [for net in aws_subnet.vpc_endpoint : net.id]
  ) : null

  vpc_endpoint_type = each.value.vpc_endpoint_type
  vpc_id            = aws_vpc.this.id
}

resource "aws_subnet" "vpc_endpoint" {
  for_each = {
    for az in toset(var.availability_zones) : az => {
      az   = az
      name = "${var.name}-vpc-endpoint-${az}"
      cidr_block = cidrsubnet(
        var.cidr_block,
        coalesce(var.vpc_endpoint_subnets.newbits, 27 - parseint(split("/", var.cidr_block)[1], 10)),
        coalesce(var.vpc_endpoint_subnets.first_netnum, length(var.availability_zones)) + index(sort(var.availability_zones), az)
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

resource "aws_route_table" "vpc_endpoint" {
  vpc_id = aws_vpc.this.id

  tags = {
    "Availability Zones" = join(",", var.availability_zones)
    "Name"               = "${var.name}-vpc-endpoint"
    "Type"               = "airgapped"
  }
}

resource "aws_route_table_association" "vpc_endpoint" {
  for_each = toset(var.availability_zones)

  route_table_id = aws_route_table.vpc_endpoint.id
  subnet_id      = aws_subnet.vpc_endpoint[each.key].id
}

resource "aws_network_acl" "vpc_endpoint" {
  subnet_ids = [for az in var.availability_zones : aws_subnet.vpc_endpoint[az].id]
  vpc_id     = aws_vpc.this.id

  ingress {
    from_port  = 0
    to_port    = 65535
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.cidr_block
    rule_no    = 1
  }

  ingress {
    from_port  = 1024
    to_port    = 65535
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    rule_no    = 2
  }

  egress {
    from_port  = 0
    to_port    = 65535
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    rule_no    = 1
  }

  tags = {
    "Availability Zones" = join(",", sort(var.availability_zones))
    "Name"               = "${var.name}-vpc-endpoint"
    "Type"               = "airgapped"
  }
}

resource "aws_security_group" "vpc_endpoint" {
  description = "Manages ingress and egress for VPC endpoints in VPC ${var.name}"
  name        = "${var.name}-vpc-endpoint"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.cidr_block]
  security_group_id = aws_security_group.vpc_endpoint.id
  type              = "ingress"
}

resource "aws_security_group_rule" "vpc_endpoint_egress" {
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc_endpoint.id
  type              = "egress"
}
