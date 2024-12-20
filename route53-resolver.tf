resource "aws_route53_resolver_rule_association" "rule" {
  for_each = toset(var.route53_resolver_rule_associations)

  resolver_rule_id = each.key
  vpc_id           = aws_vpc.this.id
}
