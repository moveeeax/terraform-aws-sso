# terraform-aws-sso

Terraform module that manages an [AWS IAM Identity
Center](https://aws.amazon.com/iam/identity-center/) (SSO) permission set. It
discovers the Identity Center instance, creates a permission set and attaches
managed and inline policies that define its access.

## Usage

```hcl
module "sso" {
  source = "github.com/moveeeax/terraform-aws-sso"

  name             = "readonly"
  session_duration = "PT2H"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]

  tags = {
    ManagedBy = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

The module attaches nothing by default: with no `managed_policy_arns` and no
`inline_policy` the permission set grants no access at all, and sessions default
to the shortest duration AWS accepts (one hour). Broad access such as
`arn:aws:iam::aws:policy/AdministratorAccess` is only ever attached because you
asked for it by name.

Inputs are validated at plan time rather than failing mid-apply:

| Input                 | Constraint                                                                  |
|-----------------------|-----------------------------------------------------------------------------|
| `name`                | 1-32 characters from `A-Za-z0-9+=,.@-_`                                      |
| `description`         | 1-700 characters                                                             |
| `session_duration`    | ISO-8601 duration of hours and/or minutes, between `PT1H` and `PT12H`        |
| `relay_state`         | 1-240 characters from the set AWS allows in a RelayState value, if set       |
| `managed_policy_arns` | each entry must be a full IAM policy ARN                                     |
| `inline_policy`       | valid JSON containing a `Statement` element                                  |

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| aws       | >= 5.0   |

## Inputs

| Name                  | Description                                             | Type           | Default                   | Required |
|-----------------------|---------------------------------------------------------|----------------|---------------------------|:--------:|
| `name`                | Name of the permission set.                             | `string`       | n/a                       |   yes    |
| `description`         | Description of the permission set.                      | `string`       | `"Managed by Terraform"`  |    no    |
| `session_duration`    | Session validity in ISO-8601 duration format (`PT1H`-`PT12H`). | `string` | `"PT1H"`                  |    no    |
| `relay_state`         | Relay state URL used to redirect users.                 | `string`       | `null`                    |    no    |
| `managed_policy_arns` | AWS managed policy ARNs to attach.                      | `list(string)` | `[]`                      |    no    |
| `inline_policy`       | JSON inline policy to attach.                           | `string`       | `null`                    |    no    |
| `tags`                | Tags applied to the permission set.                     | `map(string)`  | `{}`                      |    no    |

## Outputs

| Name           | Description                                        |
|----------------|----------------------------------------------------|
| `arn`          | ARN of the permission set.                         |
| `id`           | Combined permission set and instance ARN.          |
| `instance_arn` | ARN of the Identity Center instance.               |

## Tests

The suite in [`tests/`](tests) runs against a mocked AWS provider, so it needs
no credentials and no network:

```sh
terraform init -backend=false
terraform test
```

`terraform test` with `mock_provider` requires Terraform >= 1.7. That is a
requirement of the test suite only — the module itself still supports >= 1.5.

## License

[MIT](LICENSE)
