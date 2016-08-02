function Get-ParsedSCCMLogfile
{
    <#
    .SYNOPSYS
    Retrieves timestamped SCCM log entries

    .DESCRIPTION
    Reads SCCM Logs and creates custom object for the individual entries.  Entries have three properties, message, date, and computername.  The date is a datetime object and can be sorted and filtered.

    .EXAMPLE
    Get-SCCMLog -path C:\Windows\ccm\Logs\WUAHandler.log

    message                                 date                                    Computer
    -------                                 ----                                    --------
    Search Criteria is (DeploymentAction... 5/16/2013 10:08:00 PM                   TestVM
    Async searching of updates using WUA... 5/16/2013 10:08:00 PM                   TestVM
    Async searching completed.              5/16/2013 10:08:13 PM                   TestVM
    Successfully completed scan.            5/16/2013 10:08:14 PM                   TestVM
    Its a WSUS Update Source type ({BFEB... 5/17/2013 10:37:00 PM                   TestVM
    ...

    Pulls the entries from the WUAHanlder log file on the local computer TestVM

    .NOTES
    Written by Jason Morgan
    Last Modified 7/15/2013

    #>
    [CmdletBinding()]
    param
    (
        #Contains the log file destination.
        [Parameter(Mandatory=$true, Position=0)]
        [System.String]
        $Path = 'c:\windows\logs\cbs\cbs.log',

        #Filter
        [Parameter(Mandatory=$false, Position=2)]
        [System.String]
        $GatherOnlyLinesWhichContain = ''
    )
    
    $t =  Get-Content $Path
    if ($GatherOnlyLineWhichContain)
    {
      $t = $t| Select-String $GatherOnlyLinesWhichContain
    }
    
    [regex]$rx = $RegexString
    $names = $rx.GetGroupNames() | Where-Object {$_ -match '\w{2}'}
    $data = $t | foreach {
        $rx.Matches($_) | foreach {
            $match = $_
            $names | foreach -begin {$hash=[ordered]@{}} -process {
                $hash.Add($_,$match.groups["$_"].value)
            } -end { [pscustomobject]$hash}
        }
    }    
    $object = New-Object –TypeName PSObject
    $object | Add-Member –MemberType NoteProperty –Name Keys –Value $names
    $object | Add-Member –MemberType NoteProperty –Name Log –Value $data 
    $object    
}


Set-Location $PSScriptRoot
Set-Location 'C:\OneDrive\## Sources\Git\SCCM_LogAnalyzer\'
'#############################'


$smsts = Get-ParsedSCCMLogfile -Path ..\DemoLogs\SMSTS*.log 


$smsts


 

$parsedLogFile.Log 
 
$parsedLogFile.Log | Where-Object State -eq 'Up' | Format-Table -AutoSize -Wrap
 
$parsedLogFile.Log | Where-Object State -eq 'Down' | Format-Table -AutoSize -Wrap
 

