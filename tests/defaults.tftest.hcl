# Verifies the module's defaults and the guard rails on its inputs.
#
# Test-only requirement: `mock_provider` needs Terraform >= 1.7. The module
# itself still supports Terraform >= 1.5 (see versions.tf) — only running this
# test suite needs the newer CLI.

mock_provider "aws" {
  mock_data "aws_ssoadmin_instances" {
    defaults = {
      arns               = ["arn:aws:sso:::instance/ssoins-1111111111111111"]
      identity_store_ids = ["d-1111111111"]
    }
  }
}

variables {
  name = "example"
}

run "defaults_are_least_privilege" {
  command = plan

  assert {
    condition     = aws_ssoadmin_permission_set.this.session_duration == "PT1H"
    error_message = "Sessions must default to one hour, the shortest duration AWS accepts."
  }

  assert {
    condition     = length(aws_ssoadmin_managed_policy_attachment.this) == 0
    error_message = "No managed policy — least of all AdministratorAccess — may be attached unless the caller asks for one."
  }

  assert {
    condition     = length(aws_ssoadmin_permission_set_inline_policy.this) == 0
    error_message = "No inline policy may be created when var.inline_policy is null."
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this.instance_arn == "arn:aws:sso:::instance/ssoins-1111111111111111"
    error_message = "The permission set must be created against the discovered Identity Center instance."
  }
}

run "requested_policies_are_attached" {
  command = plan

  variables {
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess",
      "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess",
    ]
    inline_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets"]
        Resource = "*"
      }]
    })
    session_duration = "PT8H"
  }

  assert {
    condition     = length(aws_ssoadmin_managed_policy_attachment.this) == 2
    error_message = "Both requested managed policies must be attached."
  }

  assert {
    condition     = length(aws_ssoadmin_permission_set_inline_policy.this) == 1
    error_message = "An inline policy must be created when var.inline_policy is set."
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this.session_duration == "PT8H"
    error_message = "An explicit session_duration must be passed through unchanged."
  }
}

run "accepts_minutes_only_duration" {
  command = plan

  variables {
    session_duration = "PT90M"
  }

  assert {
    condition     = aws_ssoadmin_permission_set.this.session_duration == "PT90M"
    error_message = "A duration expressed only in minutes is valid ISO-8601 and must be accepted."
  }
}

run "rejects_non_iso8601_duration" {
  command = plan

  variables {
    session_duration = "1h"
  }

  expect_failures = [var.session_duration]
}

run "rejects_bare_seconds_duration" {
  command = plan

  variables {
    session_duration = "3600"
  }

  expect_failures = [var.session_duration]
}

run "rejects_duration_over_twelve_hours" {
  command = plan

  variables {
    session_duration = "PT24H"
  }

  expect_failures = [var.session_duration]
}

run "rejects_duration_under_one_hour" {
  command = plan

  variables {
    session_duration = "PT30M"
  }

  expect_failures = [var.session_duration]
}

run "rejects_invalid_permission_set_name" {
  command = plan

  variables {
    name = "an invalid name that is also far longer than thirty two characters"
  }

  expect_failures = [var.name]
}

run "rejects_managed_policy_name_instead_of_arn" {
  command = plan

  variables {
    managed_policy_arns = ["ReadOnlyAccess"]
  }

  expect_failures = [var.managed_policy_arns]
}

run "rejects_malformed_inline_policy" {
  command = plan

  variables {
    inline_policy = "{not json"
  }

  expect_failures = [var.inline_policy]
}

run "rejects_inline_policy_without_statement" {
  command = plan

  variables {
    inline_policy = jsonencode({ Version = "2012-10-17" })
  }

  expect_failures = [var.inline_policy]
}
