<#
.SYNOPSIS
    Checks msdb for databases whose backups are older than the allowed age.

.DESCRIPTION
    Writes backup-check-report.md and sets a late_count output so the workflow
    can decide whether to open an issue. Run it by hand before you schedule it.

.EXAMPLE
    ./Invoke-BackupCheck.ps1 -SqlInstance SQL01 -FullBackupHours 26 -LogBackupMinutes 60
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $SqlInstance,

    [int] $FullBackupHours = 26,

    [int] $LogBackupMinutes = 60,

    [string] $ReportPath = 'backup-check-report.md',

    [string] $GitHubOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module SqlServer -ErrorAction Stop

$query = @"
SELECT
    DatabaseName        = d.name,
    RecoveryModel       = d.recovery_model_desc,
    LastFullBackup      = MAX(CASE WHEN b.type = 'D' THEN b.backup_finish_date END),
    LastLogBackup       = MAX(CASE WHEN b.type = 'L' THEN b.backup_finish_date END)
FROM sys.databases AS d
LEFT JOIN msdb.dbo.backupset AS b
    ON b.database_name = d.name
WHERE d.database_id <> 2          -- skip tempdb
  AND d.state_desc = 'ONLINE'
  AND d.source_database_id IS NULL -- skip snapshots
GROUP BY d.name, d.recovery_model_desc
ORDER BY d.name;
"@

Write-Host "Checking backups on $SqlInstance ..."
$rows = Invoke-Sqlcmd -ServerInstance $SqlInstance -Query $query -TrustServerCertificate

$now      = Get-Date
$fullCut  = $now.AddHours(-$FullBackupHours)
$logCut   = $now.AddMinutes(-$LogBackupMinutes)
$problems = [System.Collections.Generic.List[object]]::new()

foreach ($row in $rows) {
    $lastFull = $row.LastFullBackup -as [datetime]
    $lastLog  = $row.LastLogBackup  -as [datetime]

    if (-not $lastFull -or $lastFull -lt $fullCut) {
        $problems.Add([pscustomobject]@{
            Database = $row.DatabaseName
            Problem  = 'Full backup late or missing'
            LastSeen = if ($lastFull) { $lastFull.ToString('u') } else { 'never' }
        })
    }

    # Log backups only matter when the database is not in SIMPLE recovery.
    if ($row.RecoveryModel -ne 'SIMPLE' -and (-not $lastLog -or $lastLog -lt $logCut)) {
        $problems.Add([pscustomobject]@{
            Database = $row.DatabaseName
            Problem  = 'Log backup late or missing'
            LastSeen = if ($lastLog) { $lastLog.ToString('u') } else { 'never' }
        })
    }
}

$report = [System.Collections.Generic.List[string]]::new()
$report.Add("# Backup check - $($now.ToString('yyyy-MM-dd HH:mm'))")
$report.Add('')
$report.Add("Instance: ``$SqlInstance``")
$report.Add("Full backups must be newer than **$FullBackupHours hours**.")
$report.Add("Log backups must be newer than **$LogBackupMinutes minutes**.")
$report.Add('')

if ($problems.Count -eq 0) {
    $report.Add('All databases are within their backup windows.')
}
else {
    $report.Add('| Database | Problem | Last seen |')
    $report.Add('|---|---|---|')
    foreach ($p in $problems) {
        $report.Add("| $($p.Database) | $($p.Problem) | $($p.LastSeen) |")
    }
}

$report -join "`n" | Set-Content -Path $ReportPath -Encoding utf8
Write-Host "Report written to $ReportPath"

if ($GitHubOutput) {
    "late_count=$($problems.Count)" | Add-Content -Path $GitHubOutput
}

if ($problems.Count -gt 0) {
    Write-Warning "$($problems.Count) backup problem(s) found."
}
else {
    Write-Host 'No backup problems found.'
}
