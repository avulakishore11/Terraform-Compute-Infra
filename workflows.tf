###############################################################################
# Workflow Deployment
#
# Logic App Standard workflow files (workflow.json, connections.json) live on
# the App Service file system and cannot be managed by native azurerm resources.
# They are uploaded via the Azure Management Kudu VFS REST API after the
# Logic App is provisioned.
#
# Placeholder substitution is handled in deploy_workflows.ps1 so the same
# JSON templates work across dev / uat / prod without changes.
#
# Triggers re-run the deployment when:
#   - The Logic App resource changes (redeploy / plan change)
#   - Any workflow JSON template file changes (content hash)
#   - Any value that affects workflow content changes (VM name, UAMI ID, etc.)
###############################################################################
resource "null_resource" "deploy_workflows" {
  triggers = {
    logic_app_id   = module.logic_app.logic_app_id

    # Re-deploy if any workflow file content changes
    connections_hash = filesha256("${path.module}/workflows/connections.json")
    myworkflow_hash  = filesha256("${path.module}/workflows/Myworkflow/workflow.json")
    vm_startup_hash  = filesha256("${path.module}/workflows/vm-startup-workflow/workflow.json")
    vm_shutdown_hash = filesha256("${path.module}/workflows/vm-shutdown-workflow/workflow.json")

    # Re-deploy if any injected values change (e.g. VM renamed, UAMI recreated)
    vm_name          = local.vm_name
    uami_resource_id = module.identity.uami_id
    subscription_id  = var.subscription_id
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      & "${path.module}/workflows/deploy_workflows.ps1" `
        -SubscriptionId       "${var.subscription_id}" `
        -ResourceGroupName    "${module.resource_group.name}" `
        -LogicAppName         "${module.logic_app.logic_app_name}" `
        -VmSubscriptionId     "${var.subscription_id}" `
        -VmResourceGroup      "${module.resource_group.name}" `
        -VmName               "${local.vm_name}" `
        -UamiResourceId       "${module.identity.uami_id}" `
        -KeyVaultName         "${var.key_vault_name}" `
        -NotificationEmail    "${var.notification_email}" `
        -WorkflowsDir         "${path.module}/workflows"
    EOT
  }

  depends_on = [module.logic_app]
}
