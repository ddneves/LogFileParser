#requires -Version 5

<#	
        .NOTES
        ===========================================================================
        Created on:   	02.08.2016
        Created by:   	David das Neves
        Version:        0.1
        Project:        SCCM_LogAnalyzer
        Filename:       LogFileParser.ps1
        ===========================================================================
        .DESCRIPTION
        Parses Logfiles into the class ParsedLogFile, which is integrated in the class LogFileParser
#> 

class LogFileParser
{
    # private 
    [System.Collections.Generic.List``1[ParsedLogFile]] $ParsedLogFiles

    # FilePath
    [String] $LogFilePath
   
    # Constructor
    LogFileParser($LogFilePath)
    {            
        # Constructor Code
        if (Test-Path $LogFilePath)
        {       
            $allLogFiles = (Get-ChildItem $LogFilePath -Filter *.log -Recurse).FullName
            $this.ParsedLogFiles = New-Object -TypeName System.Collections.Generic.List``1[ParsedLogFile]
            $this.LogFilePath = $LogFilePath
            foreach ($file in $allLogFiles)
            {
                $this.ParsedLogFiles.Add([ParsedLogFile]::new($file))   
            }            
        }
        else
        {
            Write-Error 'Path was not reachable. Please verify your Path.'
        }    
    }
}

class ParsedLogFile
{
    # private 
    hidden [int]$IncrementFactor

    # FilePath of the parsed log.
    [string] $LogFilePath
   
    #The parsed logging data.
    $ParsedLogData

    #Hidden variable for the keys in the logfile.
    hidden [string[]] $ColumnNames


    ParsedLogFile($LogFilePath)
    {
        if (Test-Path $LogFilePath)
        {            
            # Constructor Code
            $this.LogFilePath = $LogFilePath
            $actualParsedLog = Get-RegExParsedLogfile -Path $LogFilePath -LogFileType SCCM
            $this.ParsedLogData = $actualParsedLog.Log
            $This.ColumnNames = $actualParsedLog.Keys
        }
        else
        {
            Write-Error 'Path was not reachable. Please verify your Path.'
        }   
    }

    # Returns the column Keys
    [string[]] GetColumnNames()
    {
        return $this.ColumnNames         
    }
}


<#
.Synopsis
   Get-RowNumbersInRange
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-RowNumbersInRange
{
    [CmdletBinding()]    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $RowNumbers,

        [Parameter(Mandatory=$false,                   
                   Position=1)]
        [int]$Range = 20
    )

    Begin
    {        

    }
    Process
    {
        $allShowingRowNumbers = New-Object System.Collections.Generic.List``1[Int]
        foreach ($rowNum in $RowNumbers)
        {
            $min = $rowNum - $Range
            $max = $rowNum + $Range

            for ($x = $min; $x -lt $max; $x += 1) 
            {
              $allShowingRowNumbers.Add($x)
            }
        }        
        $allShowingRowNumbers
    }
    End
    {
    }
}


function Get-RegExParsedLogfile
{
    <#
            .SYNOPSIS
            Returns a ordered hashtable list for a log by using Regex.
            .DESCRIPTION
            The Regular Expression splits a single line of the log file into named keys.
            This is used for a whole log file and a ordered hashtable list is returned.
            .EXAMPLE
            $parsedLogFile = Get-RegExParsedLogfile -Path 'c:\windows\CCM\ccmexec.log' -LogFileType SCCM | Out-GridView
            .EXAMPLE
            Get-RegExParsedLogfile -Path 'c:\windows\logs\cbs\cbs.log' -LogFileType CBS | Out-GridView
            .EXAMPLE
            cls 
            $parsedLogFile = Get-RegExParsedLogfile -Path 'c:\windows\logs\cbs\cbs.log' 
            $parsedLogFile.Log.Line | Where-Object { $_ -like '*error*' }
            The Logfile is written into the hastable with the integrated key "Line".
            You can filter these with where.
            .EXAMPLE
            $rx = '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>(\d{2}:)+\d{2}),\s+(?<Type>\w+)\s+(?<Component>\w+)\s+(?<Message>.*)$'
            $parsedLogFile = Get-RegExParsedLogfile -Path 'c:\windows\logs\cbs\cbs.log' -RegexString $rx
            $parsedLogFile.Keys    
            .EXAMPLE
            $rx='<!\[LOG\[(?<Entry>.*)]LOG]!><time="(?<Time>.*)\.\d{3}-\d{3}"\s+date="(?<Date>.*)"\s+component="(?<Component>.*)"\s+context="(?<Context>.*)"\s+type="(?<Type>.*)"\s+thread="(?<Thread>.*)"\s+file="(?<File>.*):(?<CodeLine>\d*)">' 
            $parsedLogFile = Get-RegExParsedLogfile -Path 'c:\windows\CCM\ccmexec.log' -RegexString $rx
    #>
    [CmdletBinding()]
    param
    (
        #Contains the log file destination.
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Path = 'c:\windows\logs\cbs\cbs.log',
        
        #Contains the RegEx with named keys
        [Parameter(Mandatory = $false, Position = 1)]
        [System.String]
        $RegexString = '(?<Line>.*)$',
        
        #ValidateSet of the differenct preconfigured LogFileTypes               
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet('SCCM', 'CBS')]
        $LogFileType = 'SCCM',

        #Filter
        [Parameter(Mandatory = $false, Position = 3)]
        [System.String]
        $GatherOnlyLinesWhichContain = '' 
    )
    
    $t = Get-Content $Path
    if ($GatherOnlyLineWhichContain)
    {
        $t = $t| Select-String $GatherOnlyLinesWhichContain
    }
    

    [regex]$rx = $RegexString

    if ($LogFileType)   
    {
        switch ($LogFileType)
        {
            'SCCM'       
            { 
                $rx = '<!\[LOG\[(?<Entry>.*)]LOG]!><time="(?<Time>.*)\.\d{3}-\d{3}"\s+date="(?<Date>.*)"\s+component="(?<Component>.*)"\s+context="(?<Context>.*)"\s+type="(?<Type>.*)"\s+thread="(?<Thread>.*)"\s+file="(?<File>.*):(?<CodeLine>\d*)">' 
                break
            }
            'CBS'        
            { 
                $rx = '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>(\d{2}:)+\d{2}),\s+(?<Type>\w+)\s+(?<Component>\w+)\s+(?<Message>.*)$'
                break
            }
        
            default      
            {

            }
        }        
    }
     
  
    [string[]]$names = 'RowNum'  
    $names += $rx.GetGroupNames() | Where-Object -FilterScript {
        $_ -match '\w{2}' 
    } 
    
    [long]$rowNum = 0   
    $data = $t | ForEach-Object -Process {
        $rx.Matches($_) | ForEach-Object -Process {
            $match = $_
            $names | ForEach-Object -Begin {
                $hash = [Ordered]@{}
            } -Process {
                if ($_ -eq 'RowNum')
                {
                    $rowNum += 1
                    $hash.Add($_, $rowNum) 
                }
                else
                {
                    $hash.Add($_, $match.groups["$_"].Value)    
                }                
            } -End {
                [PSCustomObject]$hash
            }
        }
    }    
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty -Name Keys -Value $names
    $object | Add-Member -MemberType NoteProperty -Name Log -Value $data 
    $object    
}


Set-Location $PSScriptRoot
Set-Location -Path 'C:\OneDrive\## Sources\Git\SCCM_LogAnalyzer\'
'#############################'




#$smsts = Get-RegExParsedLogfile -Path ..\DemoLogs\CCMExec.log  -LogFileType SCCM
# instantiate class
$ThisParsedLogFile = [ParsedLogFile]::new($smsts)


#$newLogParser = [LogFileParser]::new('..\DemoLogs\CCMExec.log')
#($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{ $_.RowNum -gt 500 -and $_.RowNum -lt 510  }
$LinesWithErrors = (($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{$_.Entry -like '*error*'}).RowNum



#$newLogParser = [LogFileParser]::new('..\DemoLogs\')
#$newLogParser.ParsedLogFiles[0].ParsedLogData.Log | Out-GridView
#$newLogParser.ParsedLogFiles[1].ParsedLogData | Select-Object -First 10
#$newLogParser.ParsedLogFiles.Where{($_.LogFilePath -like '*ccmexec*')}
#($newLogParser.ParsedLogFiles.Where{$_.LogFilePath -like '*ccmexec*'}).ParsedLogData.Where{$_.Entry -like '*error*'}


$RowList = Get-RowNumbersInRange $LinesWithErrors
$ShowingRows = ($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{ $_.RowNum -in $RowList}


$ShowingRows | Add-Member -MemberType NoteProperty -Name Set -Value 'White' -Force
$ShowingRows.Where{$_.Entry -like '*error*'} | ForEach-Object {$_.Set = 'Red'}
$ShowingRows.Where{$_.Set -eq 'Red'}


#$showingRows | Out-GridView