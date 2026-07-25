variable "name" {
  description = "Name of the permission set."
  type        = string

  validation {
    condition     = can(regex("^[[:word:]+=,.@-]{1,32}$", var.name))
    error_message = "The name must be 1-32 characters long and may only contain alphanumerics and the characters + = , . @ - _ (the AWS IAM Identity Center permission set name constraint)."
  }
}

variable "description" {
  description = "Description of the permission set."
  type        = string
  default     = "Managed by Terraform"

  validation {
    condition     = length(var.description) >= 1 && length(var.description) <= 700
    error_message = "The description must be between 1 and 700 characters; AWS rejects anything longer."
  }
}

variable "session_duration" {
  description = <<-EOT
    Length of time a session remains valid, as an ISO-8601 duration (for example
    "PT1H", "PT8H" or "PT90M"). AWS only accepts durations between one and twelve
    hours.
  EOT
  type        = string
  default     = "PT1H"

  validation {
    condition     = can(regex("^PT([0-9]+H)?([0-9]+M)?$", var.session_duration)) && var.session_duration != "PT"
    error_message = "The session_duration must be an ISO-8601 duration built from hours and/or minutes, such as \"PT1H\", \"PT8H\" or \"PT90M\". Values like \"1h\" or \"3600\" are rejected by AWS."
  }

  validation {
    # AWS allows a minimum of 1 hour and a maximum of 12 hours (720 minutes).
    condition = alltrue([
      for minutes in [
        try(tonumber(regex("^PT([0-9]+)H", var.session_duration)[0]), 0) * 60
        + try(tonumber(regex("([0-9]+)M$", var.session_duration)[0]), 0)
      ] : minutes >= 60 && minutes <= 720
    ])
    error_message = "The session_duration must be between one hour (\"PT1H\") and twelve hours (\"PT12H\")."
  }
}

variable "relay_state" {
  description = "Relay state URL used to redirect users within the application during sign-in. Null omits it."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the permission set."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.managed_policy_arns :
      can(regex("^arn:aws[[:alpha:]-]*:iam::(aws|[0-9]{12}):policy/", arn))
    ])
    error_message = "Every entry in managed_policy_arns must be a full IAM policy ARN, for example \"arn:aws:iam::aws:policy/ReadOnlyAccess\"."
  }
}

variable "inline_policy" {
  description = "JSON inline policy to attach to the permission set. Null skips the inline policy."
  type        = string
  default     = null

  validation {
    condition     = var.inline_policy == null || can(jsondecode(var.inline_policy))
    error_message = "The inline_policy must be valid JSON. Build it with jsonencode() or the aws_iam_policy_document data source rather than hand-written strings."
  }

  validation {
    condition     = var.inline_policy == null || can(jsondecode(var.inline_policy).Statement)
    error_message = "The inline_policy must be an IAM policy document containing a \"Statement\" element."
  }
}

variable "tags" {
  description = "Tags applied to the permission set."
  type        = map(string)
  default     = {}
}
