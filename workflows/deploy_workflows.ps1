<#
.SYNOPSIS
    Deploy Logic App Standard workflow JSON files via Kudu VFS REST API.
.DESCRIPTION
    Called by Terraform null_resource (workflows.tf) after Logic App is provisioned.
    Can also be run manually for troubleshooting or re-deployment.

    Substitutes __PLACEHOLDER__ tokens in workflow templates before uploading,
    so the same JSON files work across dev / uat / prod without changes.

    Placeholders replaced:
      __SUBSCRIPTION_ID__    Azure subscription ID
      __RESOURCE_GROUP__     Resource group of the Logic App
      __LOCATION__           Azure region (e.g. eastus)
      __VM_NAME__            Automation VM name (from app setting VM_NAME)
      __UAMI_RESOURCE_ID__   Full ARM resource ID of the UAMI
      __KEY_VAULT_NAME__     Key Vault name for Myworkflow connection
      __NOTIFICATION_EMAIL__ Email address for secret expiry alerts

.EXAMPLE
    # Called by Terraform automatically — but can also run manually:
    .\deploy_workflows.ps1 `
        -SubscriptionId    "7a6d2623-..." `
        -ResourceGroupName "rg-winvm-dev-01" `
        -LogicAppName      "laeus-winvm-dev-01" `
        -VmSubscriptionId  "7a6d2623-..." `
        -VmResourceGroup   "rg-winvm-dev-01" `
        -VmName            "vmeus-winvm-dev-01" `
        -UamiResourceId    "/subscriptions/.../userAssignedIdentities/uami-logicapp-storage-dev" `
        -KeyVaultName      "kv-winvm-dev-01" `
        -NotificationEmail "kishore.avula@kaseya.com" `
        -WorkflowsDir      "."
#>

param (
    [Parameter(Mandatory=$true)]  [string]$SubscriptionId,
    [Parameter(Mandatory=$true)]  [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]  [string]$LogicAppName,
    [Parameter(Mandatory=$true)]  [string]$VmSubscriptionId,
    [Parameter(Mandatory=$true)]  [string]$VmResourceGroup,
    [Parameter(Mandatory=$true)]  [string]$VmName,
    [Parameter(Mandatory=$true)]  [string]$UamiResourceId,
    [Parameter(Mandatory=$false)] [string]$KeyVaultName      = "",
    [Parameter(Mandatory=$false)] [string]$NotificationEmail = "kishore.avula@kaseya.com",
    [Parameter(Mandatory=$false)] [string]$WorkflowsDir      = $PSScriptRoot,
    [Parameter(Mandatory=$false)] [string]$Location          = "eastus"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Logic App Workflow Deployment" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Logic App     : $LogicAppName"
Write-Host " Resource Group: $ResourceGroupName"
Write-Host " Subscription  : $SubscriptionId"
Write-Host " VM Name       : $VmName"
Write-Host " UAMI          : $($UamiResourceId.Split('/')[-1])"
Write-Host ""

# Acquire ARM token from current az login session
Write-Host "Acquiring ARM token..." -ForegroundColor Yellow
$token = az account get-access-token --resource "https://management.azure.com/" --query accessToken -o tsv
if (-not $token) {
    throw "Failed to acquire ARM token. Run 'az login' and retry."
}
Write-Host "Token acquired." -ForegroundColor Green

$baseUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$LogicAppName/hostruntime/admin/vfs/site/wwwroot"
$apiVer  = "api-version=2022-03-01"

# ── Substitution map ──────────────────────────────────────────────────────────
$subs = @{
    "__SUBSCRIPTION_ID__"    = $VmSubscriptionId
    "__RESOURCE_GROUP__"     = $VmResourceGroup
    "__LOCATION__"           = $Location
    "__VM_NAME__"            = $VmName
    "__UAMI_RESOURCE_ID__"   = $UamiResourceId
    "__KEY_VAULT_NAME__"     = $KeyVaultName
    "__NOTIFICATION_EMAIL__" = $NotificationEmail
}

function Apply-Substitutions([string]$content) {
    foreach ($k in $subs.Keys) {
        $content = $content.Replace($k, $subs[$k])
    }
    return $content
}

# ── Upload a single file ──────────────────────────────────────────────────────
function Upload-File([string]$remotePath, [string]$content) {
    $url   = "$baseUrl/$remotePath`?$apiVer"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)

    # GET current ETag (optimistic concurrency — prevents overwriting concurrent changes)
    $getReq = [System.Net.HttpWebRequest]::Create($url)
    $getReq.Method = "GET"
    $getReq.Headers.Add("Authorization", "Bearer $token")
    try {
        $getResp = $getReq.GetResponse()
        $etag    = $getResp.Headers["ETag"]
        $getResp.Close()
    } catch {
        $etag = "*"   # File doesn't exist yet — use wildcard
    }

    # PUT with ETag
    $putReq = [System.Net.HttpWebRequest]::Create($url)
    $putReq.Method      = "PUT"
    $putReq.Headers.Add("Authorization", "Bearer $token")
    $putReq.Headers.Add("If-Match", $etag)
    $putReq.ContentType   = "application/json"
    $putReq.ContentLength = $bytes.Length
    $stream = $putReq.GetRequestStream()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()

    try {
        $putResp   = $putReq.GetResponse()
        $statusCode = [int]$putResp.StatusCode
        $putResp.Close()
        Write-Host "  [OK $statusCode] $remotePath" -ForegroundColor Green
    } catch [System.Net.WebException] {
        $errResp   = $_.Exception.Response
        $errReader = New-Object System.IO.StreamReader($errResp.GetResponseStream())
        $errBody   = $errReader.ReadToEnd()
        Write-Host "  [ERR $([int]$errResp.StatusCode)] $remotePath" -ForegroundColor Red
        Write-Host "  $errBody" -ForegroundColor Red
        throw "Failed to upload $remotePath"
    }
}

# ── Deploy connections.json ───────────────────────────────────────────────────
Write-Host "Deploying connections.json ..." -ForegroundColor Yellow
$connectionsFile = Join-Path $WorkflowsDir "connections.json"
if (-not (Test-Path $connectionsFile)) { throw "connections.json not found at: $connectionsFile" }
$connectionsContent = Apply-Substitutions (Get-Content $connectionsFile -Raw -Encoding UTF8)
Upload-File "connections.json" $connectionsContent

# ── Deploy workflow files ─────────────────────────────────────────────────────
$workflows = @(
    @{ Name = "Myworkflow";            File = "Myworkflow\workflow.json" },
    @{ Name = "vm-startup-workflow";   File = "vm-startup-workflow\workflow.json" },
    @{ Name = "vm-shutdown-workflow";  File = "vm-shutdown-workflow\workflow.json" }
)

foreach ($wf in $workflows) {
    $localFile = Join-Path $WorkflowsDir $wf.File
    if (Test-Path $localFile) {
        Write-Host "Deploying $($wf.Name)/workflow.json ..." -ForegroundColor Yellow
        $wfContent = Apply-Substitutions (Get-Content $localFile -Raw -Encoding UTF8)
        Upload-File "$($wf.Name)/workflow.json" $wfContent
    } else {
        Write-Warning "  Skipped: $localFile not found"
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Deployment Complete" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Portal: https://portal.azure.com/#resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$LogicAppName/workflows"
Write-Host ""
Write-Host " Next steps:" -ForegroundColor Yellow
Write-Host "   1. Authorize the Office 365 connection (Myworkflow email sending)"
Write-Host "      Portal -> Logic App -> Connections -> office365 -> Authorize"
Write-Host "   2. Create Event Grid subscription pointing to Myworkflow webhook URL"
Write-Host "   3. Test vm-startup-workflow manually: Logic App -> Workflows -> vm-startup-workflow -> Run Trigger"
