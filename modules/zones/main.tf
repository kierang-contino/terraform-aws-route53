resource "aws_route53_zone" "this" {
  for_each = var.create ? tomap(var.zones) : tomap({})

  name          = lookup(each.value, "domain_name", each.key)
  comment       = lookup(each.value, "comment", null)
  force_destroy = lookup(each.value, "force_destroy", false)

  delegation_set_id = lookup(each.value, "delegation_set_id", null)

  dynamic "vpc" {
    for_each = try(tolist(lookup(each.value, "primary_vpc", [])), [lookup(each.value, "vpc", {})])

    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = lookup(vpc.value, "vpc_region", null)
    }
  }

  tags = merge(
    lookup(each.value, "tags", {}),
    var.tags
  )

  # Prevent the deletion of associated VPCs after
  # the initial creation. See documentation on
  # aws_route53_zone_association for details
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association
  lifecycle {
    ignore_changes = [vpc]
  }
}

locals {
  additional_local_vpcs_map_interim = flatten([
    for zone in keys(var.zones) : [
      for vpc in lookup(var.zones[zone], "additional_local_vpcs", []) : {
        "${zone}-${vpc.vpc_id}" = {
          zone    = zone
          zone_id = aws_route53_zone.this[zone].zone_id
          vpc_id  = vpc.vpc_id
        }
      }
    ]
  ])
  additional_local_vpcs_map = {
    for submap in local.additional_local_vpcs_map_interim :
    keys(submap)[0] => values(submap)[0]
  }
  crossaccount_vpcs_map_interim = flatten([
    for zone in keys(var.zones) : [
      for vpc in lookup(var.zones[zone], "crossaccount_vpcs", []) : {
        "${zone}-${vpc.vpc_id}" = {
          zone    = zone
          zone_id = aws_route53_zone.this[zone].zone_id
          vpc_id  = vpc.vpc_id
        }
      }
    ]
  ])
  crossaccount_vpcs_map = {
    for submap in local.crossaccount_vpcs_map_interim :
    keys(submap)[0] => values(submap)[0]
  }
}

resource "aws_route53_zone_association" "local" {
  for_each = local.additional_local_vpcs_map

  vpc_id  = each.value.vpc_id
  zone_id = each.value.zone_id
}

resource "aws_route53_vpc_association_authorization" "cross-account" {
  for_each = local.crossaccount_vpcs_map

  vpc_id  = each.value.vpc_id
  zone_id = each.value.zone_id
}
