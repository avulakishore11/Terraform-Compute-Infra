# ── Automation-only deployment ────────────────────────────────────────────────
# Use this tfvars with azure-pipeline-automation.yml.
# Only the resources needed for VM automation via Logic App are deployed.
# Targeted resources: resource_group, networking, identity, monitoring,
#                     logic_app, logicapp-state container, RBAC assignments.
# ─────────────────────────────────────────────────────────────────────────────

# subscription_id is passed via TF_VAR_subscription_id pipeline secret — do not hardcode here.

location    = "eastus"
environment = "dev"
project     = "winvm"
sequence    = "01"

tags = {
  Department  = "CorpIT"
  CreatedBy   = "Kishore Avula"
  Project     = "Infra-automation"
  Environment = "dev"
}

# ── Networking ────────────────────────────────────────────────────────────────
vnet_address_space     = ["10.1.0.0/16"]
subnet_logicapp_prefix = "10.1.1.0/24"   # Logic App VNet integration subnet (delegation required)
subnet_vm_prefix       = "10.1.3.0/29"   # VM subnet — /29 = 3 usable IPs

# ── Logic App ─────────────────────────────────────────────────────────────────
logic_app_sku = "WS1"
