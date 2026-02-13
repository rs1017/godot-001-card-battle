param(
	[string]$CodexDir = ".codex",
	[string]$BackupDir = ".tmp/acl_backups"
)

$ErrorActionPreference = "Stop"

function Resolve-AbsolutePath {
	param([string]$PathValue)
	if ([System.IO.Path]::IsPathRooted($PathValue)) {
		return $PathValue
	}
	return Join-Path (Get-Location) $PathValue
}

$targetPath = Resolve-AbsolutePath -PathValue $CodexDir
if (-not (Test-Path -LiteralPath $targetPath)) {
	throw "Target path not found: $targetPath"
}

$backupRoot = Resolve-AbsolutePath -PathValue $BackupDir
if (-not (Test-Path -LiteralPath $backupRoot)) {
	New-Item -ItemType Directory -Path $backupRoot | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $backupRoot ("codex_acl_backup_{0}.txt" -f $timestamp)

$acl = Get-Acl -LiteralPath $targetPath
$backupContent = @(
	("# Path: {0}" -f $targetPath),
	("# Timestamp: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")),
	("# Owner: {0}" -f $acl.Owner),
	("# SDDL"),
	$acl.Sddl
)
Set-Content -Path $backupFile -Value $backupContent -Encoding UTF8

$denyRules = @($acl.Access | Where-Object { $_.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny })
if ($denyRules.Count -eq 0) {
	Write-Output "No explicit Deny rules found on: $targetPath"
	Write-Output "ACL backup saved: $backupFile"
	exit 0
}

foreach ($rule in $denyRules) {
	[void]$acl.RemoveAccessRuleSpecific($rule)
	Write-Output ("Removed Deny: {0} | Rights={1} | Inherited={2}" -f $rule.IdentityReference, $rule.FileSystemRights, $rule.IsInherited)
}

Set-Acl -LiteralPath $targetPath -AclObject $acl

Write-Output "Updated ACL: $targetPath"
Write-Output "ACL backup saved: $backupFile"
