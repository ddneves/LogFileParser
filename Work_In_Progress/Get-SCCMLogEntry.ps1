
Function Get-SCCMLogEntry
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
Param 
    (
        [Parameter(Mandatory=$True,
         HelpMessage='Enter the path to the target SCCM Log')]
        [String]$path,
        [Parameter(Mandatory=$false,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True) ]
        [string[]]$ComputerName	= $env:COMPUTERNAME
    )
Begin 
    {
        $params = @{
                Argumentlist = $Path
                ScriptBlock = {
                        Param ($Path)
                        get-content -path $Path | ForEach-Object {
                                if (-not($_.endswith('">')))
                                    {
                                        $string += $_
                                        $frag= $true    
                                    }
                                Else 
                                    {
                                        $string += $_
                                        $frag =$false
                                    }
                                if (-not($frag))
                                    {
                                        $hash = @{
                                                Message = ($string -Split 'LOG')[1].trimstart('[').trimend(']')
                                                #message = $string.substring(6,($string.Split('<')[1].length -13))
                                                date = [datetime]"$(($string -Split 'date="')[1].substring(0,10).trimend(' ').trimend('"')) $(($string -csplit 'time="')[1].substring(0,12))" 
                                                Computer = $env:COMPUTERNAME
                                            } # changed the .split() mehtod to -split, used -csplit to keep time= case sensitive, added trimend(' ') and trimend('"') to deal with some logs that switch up the datetime display.
                                        New-Object -TypeName PSObject -Property $hash
                                        Remove-Variable string
                                    }
                        }
                    }
            }
    }
Process
    {
        If ($ComputerName -ne $env:COMPUTERNAME) {$params.Add('ComputerName',$ComputerName)}
        Invoke-Command @params | select Message,Date,Computer
    }
End {}
}