provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = "eu-west-1"
  alias  = "account2"
}

module "zones" {
  source = "../../modules/zones"

  zones = {
    "api.ecr.cn-northwest-1.amazonaws.com.cn" = {
      comment = "ECR endpoint"
      primary_vpc = [
        { vpc_id = "vpc-1" }
      ]
      additional_local_vpcs = [
        { vpc_id = "vpc-2" },
        { vpc_id = "vpc-3" }
      ]
      crossaccount_vpcs = [
        { vpc_id = "vpc-4" }
      ]

    }
    "dkr.ecr.cn-northwest-1.amazonaws.com.cn" = {
      comment = "ECR DKR endpoint"
      primary_vpc = [
        { vpc_id = "vpc-5" }
      ]
      additional_local_vpcs = [
        { vpc_id = "vpc-6" }
      ]
      crossaccount_vpcs = [
        { vpc_id = "vpc-7" }
      ]
    }
    "example.com.cn" = {
      comment = "ECR DKR endpoint"
    }

    tags = {
      ManagedBy = "Terraform"
    }
  }
}

resource "aws_route53_zone_association" "ecr_api" {
  provider = "account2"
  zone_id  = module.zones.id
  vpc_id   = "vpc-4"
}

resource "aws_route53_zone_association" "ecr_dkr" {
  provider = "account2"
  zone_id  = module.zones.id
  vpc_id   = "vpc-7"
}
