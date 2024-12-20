variable "assign_generated_ipv6_cidr_block" {
  description = "Whether to request a /56 IPv6 CIDR block for the VPC"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "Availability zones to distribute resources within"
  type        = list(string)
}

variable "bastion" {
  description = "Configurations for bastion hosts in this VPC"
  type = object({
    ami        = optional(string)
    public_key = optional(string)
    subnets = list(object({
      subnet_group = string
      azs          = optional(list(string))
    }))
    ingress = optional(object({
      cidr_blocks     = optional(list(string), [])
      security_groups = optional(list(string), [])
    }))
  })
  default = {
    subnets = []
  }
}

variable "cidr_block" {
  description = "A CIDR block to assign to the VPC"
  type        = string
}

variable "dhcp" {
  description = "Configurations for DHCP options for this VPC"
  type = object({
    domain_name          = optional(string)
    domain_name_servers  = optional(list(string), ["AmazonProvidedDNS"])
    ntp_servers          = optional(list(string))
    netbios_name_servers = optional(list(string))
    netbios_node_type    = optional(number)
    tags                 = optional(map(string))
  })
  default = {}
}

variable "enable_dns_hostnames" {
  description = "Whether or not to enable internal DNS hostnames within the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether or not to enable internal DNS support within the VPC"
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "default, dedicated, or host. Determines tenancy of instances launched within the VPC"
  type        = string
  default     = "default"
}

variable "internet_gateway" {
  description = "Configurations for the internet gateway used by this VPC"
  type = object({
    tags = optional(map(string))
  })
  default = {}
}

variable "name" {
  description = "The name of the VPC, and the prefix for resources created within the VPC"
  type        = string
}

variable "nat_gateway_subnets" {
  description = "Configuration options for the subnets created to house Nat Gateway attachment network interfaces"
  type = object({
    newbits      = optional(number)
    first_netnum = optional(number)
  })
  default = {
    newbits      = null
    first_netnum = null
  }
}

variable "route53_resolver_rule_associations" {
  description = "Route 53 Resolver rules to associate with this VPC"
  type        = list(string)
  default     = []
}

variable "secondary_ipv4_cidr_blocks" {
  description = "Additional IPv4 CIDR blocks to assign to the VPC"
  type = list(object({
    cidr_block          = optional(string)
    ipv4_ipam_pool_id   = optional(string)
    ipv4_netmask_length = optional(number)
  }))
  default = []
}

variable "subnet_groups" {
  description = <<-EOF
    Configurations for groups of subnets. For each group, one subnet will be created in each availability zone.
    Each subnet in a group will share a common network ACL. If the subnet group type is 'private', routes to a 
    nat gateway will be created. If the subnet group type is 'public', routes to an internet gateway will be created.
    If the subnet group type is 'airgapped', neither will be created.
  EOF
  type = list(object({
    assign_ipv6_address_on_creation = optional(bool)
    customer_owned_ipv4_pool        = optional(string)
    first_netnum                    = number
    ipv6_first_netnum               = optional(number)
    ipv6_newbits                    = optional(number)
    ipv6_prefix                     = optional(string)
    map_customer_owned_ip_on_launch = optional(bool)
    map_public_ip_on_launch         = optional(bool)
    nacl = optional(list(object({
      cidr_block      = optional(string)
      from_port       = number
      egress          = optional(bool, false)
      ipv6_cidr_block = optional(string)
      protocol        = string
      action          = string
      rule_no         = number
      subnet_group    = optional(string)
      to_port         = number
      tags            = optional(map(string))
    })), [])
    name             = string
    newbits          = number
    outpost_arn      = optional(string)
    route_table_tags = optional(map(string))
    routes = optional(list(object({
      carrier_gateway_id        = optional(string)
      cidr_block                = optional(string)
      ipv6_cidr_block           = optional(string)
      prefix_list_id            = optional(string)
      egress_only_gateway_id    = optional(string)
      gateway_id                = optional(string)
      local_gateway_id          = optional(string)
      nat_gateway_id            = optional(string)
      network_interface_id      = optional(string)
      transit_gateway_id        = optional(string)
      vpc_endpoint_id           = optional(string)
      vpc_peering_connection_id = optional(string)
    })))
    tags = optional(map(string))
    type = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to assign to the VPC"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_attachments" {
  description = "Attachments to transit gateways from this VPC"
  type = list(object({
    appliance_mode_support                          = optional(string)
    dns_support                                     = optional(string)
    ipv6_support                                    = optional(string)
    tags                                            = optional(map(string))
    transit_gateway_id                              = string
    transit_gateway_default_route_table_association = optional(bool)
    transit_gateway_default_route_table_propagation = optional(bool)
  }))
  default = []
}

variable "peering_subnets" {
  description = "Configuration options for the subnets created to house vpc peering/ tgw network interfaces"
  type = object({
    newbits      = optional(number)
    first_netnum = optional(number)
  })
  default = {}
}

variable "vpc_endpoint_subnets" {
  description = "Configuration options for the subnets created to house VPC endpoints"
  type = object({
    newbits      = optional(number)
    first_netnum = optional(number)
  })
  default = {}
}

variable "vpc_endpoints" {
  description = "VPC endpoints to create within this VPC"
  type = list(object({
    auto_accept         = optional(bool)
    policy              = optional(string)
    private_dns_enabled = optional(bool)
    route_tables = optional(list(object({
      subnet_group = string
      azs          = optional(list(string))
    })))
    service_name      = string
    tags              = optional(map(string))
    vpc_endpoint_type = optional(string)
  }))
  default = []
}

variable "vpc_peering_connection_accepters" {
  description = "Accepters for vpc peering connections that originate elsewhere"
  type = list(object({
    auto_accept               = optional(bool)
    tags                      = optional(map(string))
    vpc_peering_connection_id = string
  }))
  default = []
}

variable "vpc_peering_connections" {
  description = "Peering connections to make to VPCs elsewhere from this VPC"
  type = list(object({
    accepter = optional(object({
      allow_remote_vpc_dns_resolution  = optional(bool)
    }))
    auto_accept   = optional(bool)
    peer_owner_id = optional(string)
    peer_region   = optional(string)
    peer_vpc_id   = string
    requester = optional(object({
      allow_remote_vpc_dns_resolution  = optional(bool)
    }))
    tags = optional(map(string))
  }))
  default = []
}
