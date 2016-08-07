Set-Location $PSScriptRoot
Set-Location 'C:\OneDrive\## Sources\Git\SCCM_LogAnalyzer\'
'#############################'
$smsts = Get-Content ..\DemoLogs\SMSTS*.log 
'#############################'
$template = Get-Content .\Templates\SMSTS1.log
'#############################'

$LogData= $smsts | ConvertFrom-String -TemplateFile .\Templates\SMSTS1.log
$LogData | Out-GridView