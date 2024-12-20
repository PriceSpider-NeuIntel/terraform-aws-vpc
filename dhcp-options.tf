resource "aws_vpc_dhcp_options" "this" {
  domain_name = coalesce(
    var.dhcp.domain_name,
    data.aws_region.current.name == "us-east-1" ? (
      "ec2.internal"
    ) : "${data.aws_region.current.name}.compute.amazonaws.com"
  )

  domain_name_servers  = var.dhcp.domain_name_servers
  ntp_servers          = var.dhcp.ntp_servers
  netbios_name_servers = var.dhcp.netbios_name_servers
  netbios_node_type    = var.dhcp.netbios_node_type

  tags = merge(var.dhcp.tags, {
    "Name" = var.name
  })
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this.id
}
