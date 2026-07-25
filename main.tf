data "aws_ssoadmin_instances" "this" {}

locals {
  # aws_ssoadmin_instances returns a set; sort it so the chosen instance stays
  # stable across plans instead of depending on set iteration order.
  instance_arns = sort(tolist(data.aws_ssoadmin_instances.this.arns))
  instance_arn  = try(local.instance_arns[0], null)
}

resource "aws_ssoadmin_permission_set" "this" {
  name             = var.name
  description      = var.description
  instance_arn     = local.instance_arn
  session_duration = var.session_duration
  relay_state      = var.relay_state

  tags = var.tags

  lifecycle {
    precondition {
      condition     = local.instance_arn != null
      error_message = "No AWS IAM Identity Center instance was found. Enable Identity Center in this account and region, or run Terraform against the account and region that owns the instance."
    }
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = toset(var.managed_policy_arns)

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  managed_policy_arn = each.value
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  count = var.inline_policy != null ? 1 : 0

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  inline_policy      = var.inline_policy
}
