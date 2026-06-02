# ── Tag Enforcement Policies ─────────────────────────────────────────────────
# Assigns built-in Azure "Require a tag" policies at the subscription scope.
# Effect is Deny — resources and resource groups missing any required tag will
# be blocked by ARM at creation/update time.
#
# Required RBAC: the deployment principal needs Owner or Policy Contributor
# at the subscription scope to create policy assignments.

# To assign permissions to SP RoleUse This When Resource Policy Contributor **Recommended** — pipeline only manages policies
# User Access AdministratorAdd this only if policies have DeployIfNotExists or Modify effectsOwner Avoid — too broad, security team will push back
# Contributor Won't work — explicitly denied for policy operations

data "azurerm_subscription" "current" {}

locals {
  required_tags = toset(["CreatedBy", "Department", "Environment", "Project"])

  # Built-in policy definition IDs (immutable Azure platform GUIDs)
  policy_require_tag_on_resources       = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  policy_require_tag_on_resource_groups = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"

  # "Schedule recurring updates using Azure Update Manager"
  # "Configure periodic checking for missing system updates on azure virtual machines"
  
  policy_schedule_updates = "/providers/Microsoft.Authorization/policyDefinitions/ba0df93e-e4ac-479a-aac2-134bbae39a1a"
  policy_check_missing_updates = "/providers/Microsoft.Authorization/policyDefinitions/59efceea-0c96-497e-a4a1-4eb2290dac15"
}

# Enforce required tags on every resource
resource "azurerm_subscription_policy_assignment" "require_tag_resources" {
  for_each = local.required_tags

  name                 = "require-tag-${lower(each.key)}-res"
  display_name         = "Require ${each.key} tag on resources"
  policy_definition_id = local.policy_require_tag_on_resources
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode({
    tagName = { value = each.key }
  })
}

# Enforce required tags on every resource group
resource "azurerm_subscription_policy_assignment" "require_tag_resource_groups" {
  for_each = local.required_tags

  name                 = "require-tag-${lower(each.key)}-rg"
  display_name         = "Require ${each.key} tag on resource groups"
  policy_definition_id = local.policy_require_tag_on_resource_groups
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode({
    tagName = { value = each.key }
  })
}

# ── Azure Update Manager Policies ─────────────────────────────────────────────
# Both policies assigned at subscription scope.
# Verify policy GUIDs in Azure Portal → Policy → Definitions before applying.
#
# Policy 1: Schedule Windows updates EastUS – RING 1
#   DeployIfNotExists → requires managed identity to auto-remediate VMs.
#   enforce=false → DoNotEnforce (audit-only).
#
# Policy 2: Check for missing system updates
#   DeployIfNotExists → also requires managed identity (installs Azure Monitor
#   Agent via remediation task). enforce=true (active). Reuses same identity.
# ─────────────────────────────────────────────────────────────────────────────

# Grants the managed identity Contributor so DeployIfNotExists remediation tasks
# can modify VMs (e.g. install the update agent extension).
#
# PREREQUISITE: the pipeline service principal needs "User Access Administrator"
# at subscription scope to create this role assignment. Contributor alone is
# insufficient — Azure explicitly denies roleAssignments/write for Contributors.
# Grant it once via:
#   az role assignment create \
#     --assignee <pipeline-sp-object-id> \
#     --role "User Access Administrator" \
#     --scope /subscriptions/<subscription-id>
resource "azurerm_role_assignment" "policy_remediation_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = module.policy_remediation_identity.principal_id 
}

resource "azurerm_subscription_policy_assignment" "schedule_windows_updates_ring1" {
  count                = var.maintenance_configuration_resource_id != null ? 1 : 0

  name                 = "ka-sched-win-upd-eus-r1"
  display_name         = "KA-Schedule Windows updates EastUS - RING 1"
  description          = "Schedule Windows Server recurring updates for EastUS infrastructure."
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_schedule_updates
  enforce              = false
  location             = var.location

  identity {
    type         = "UserAssigned"
    identity_ids = [module.policy_remediation_identity.id]
  }

  parameters = jsonencode({
    maintenanceConfigurationResourceId = {
      value = var.maintenance_configuration_resource_id
    }
    tagValues = {
      value = [{ key = "Update Ring", value = "Ring 1" }]
    }
    locations = {
      value = ["eastus", "eastus2"]
    }
    operatingSystemTypes = {
      value = ["Windows"]
    }
    effect = {
      value = "DeployIfNotExists"
    }
    tagOperator = {
      value = "Any"
    }
    resourceGroups = {
      value = []
    }
  })
}

# Policy 59efceea uses DeployIfNotExists (installs the Azure Monitor Agent)
# so a managed identity is required — Azure uses it to run the remediation task.
# Reuses the same identity as the schedule policy; both need Contributor scope.
resource "azurerm_subscription_policy_assignment" "check_missing_updates_windows" {
  name                 = "ka-win-check-missing-upd"
  display_name         = "KA-Windows Server -Check for missing system updates"
  description          = "Check for missing updates on all KA subscriptions windows servers."
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = local.policy_check_missing_updates
  enforce              = true
  location             = var.location

  identity {
    type         = "UserAssigned"
    identity_ids = [module.policy_remediation_identity.id]
  }

  parameters = jsonencode({
    locations = {
      value = ["eastus", "eastus2"]
    }
    osType = {
      value = "Windows"
    }
    tagOperator = {
      value = "Any"
    }
    # tagValues must be an Object (map of tagName→tagValue), NOT an Array.
    # Policy 59efceea v4.10.0 changed the expected type from Array to Object.
    # Empty object {} means "no tag filter — apply to all VMs".
    tagValues = {
      value = {}
    }
    assessmentMode = {
      value = "AutomaticByPlatform"
    }
  })
}
