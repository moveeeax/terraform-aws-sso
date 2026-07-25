# Covers Identity Center instance discovery, which is the one piece of implicit
# behaviour in this module: the instance ARN is never supplied by the caller.
#
# Test-only requirement: `mock_provider` needs Terraform >= 1.7.

variables {
  name = "example"
}

run "picks_a_stable_instance_when_several_are_returned" {
  command = plan

  providers = {
    aws = aws.multiple_instances
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this.instance_arn == "arn:aws:sso:::instance/ssoins-1111111111111111"
    error_message = "With more than one instance ARN the module must sort them and pick deterministically, otherwise plans churn between runs."
  }
}

run "fails_clearly_when_no_instance_exists" {
  command = plan

  providers = {
    aws = aws.no_instances
  }

  expect_failures = [aws_ssoadmin_permission_set.this]
}

mock_provider "aws" {
  alias = "multiple_instances"

  mock_data "aws_ssoadmin_instances" {
    defaults = {
      arns = [
        "arn:aws:sso:::instance/ssoins-2222222222222222",
        "arn:aws:sso:::instance/ssoins-1111111111111111",
      ]
      identity_store_ids = ["d-2222222222", "d-1111111111"]
    }
  }
}

mock_provider "aws" {
  alias = "no_instances"

  mock_data "aws_ssoadmin_instances" {
    defaults = {
      arns               = []
      identity_store_ids = []
    }
  }
}
