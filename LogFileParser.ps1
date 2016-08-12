#requires -Version 5

<#	
        .NOTES
        ===========================================================================
        Created on:   	12.08.2016
        Created by:   	David das Neves
        Version:        0.2
        Project:        LogFileParser
        Filename:       LogFileParser.ps1
        ===========================================================================
        .DESCRIPTION
        Parses Logfiles into the class ParsedLogFile, which is integrated in the class LogFileParser
#> 


class LogFileTypeClasses
{
    #region properties
   
    #Generic List of LogFileTypeClasses
    [System.Collections.Generic.List``1[LogFileTypeClass]] $LoadedClasses

    #endregion

    LogFileTypeClasses()
    {
        #Load standard classes
        $this.LoadedClasses = New-Object -TypeName System.Collections.Generic.List``1[LogFileTypeClass]

        #SCCM
        $newClass =  [LogFileTypeClass]::new()
        $newClass.LogFileType = 'SCCM'
        $newClass.Description = 'All SCCM log-files.'
        $newClass.RegExString = '<!\[LOG\[(?<Entry>.*)]LOG]!><time="(?<Time>.*)\.\d{3}-\d{3}"\s+date="(?<Date>.*)"\s+component="(?<Component>.*)"\s+context="(?<Context>.*)"\s+type="(?<Type>.*)"\s+thread="(?<Thread>.*)"\s+file="(?<File>.*):(?<CodeLine>\d*)">'
        $newClass.LogFiles = 'default'
        $newClass.LocationsLogFiles = ('c:\windows\ccm\logs\*','c:\Program Files\System Center Configuration Manager*')
        ($this.LoadedClasses).Add($newClass)


        #CBS
        $newClass =  [LogFileTypeClass]::new()
        $newClass.LogFileType = 'CBS'
        $newClass.Description = 'Component log.'
        $newClass.RegExString = '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>(\d{2}:)+\d{2}),\s+(?<Type>\w+)\s+(?<Component>\w+)\s+(?<Message>.*)$'
        $newClass.LogFiles = 'cbs*'
        $newClass.LocationsLogFiles = 'c:\windows\logs\CBS\cbs.log'
        ($this.LoadedClasses).Add($newClass)

        #Upgrade
        $newClass =  [LogFileTypeClass]::new()
        $newClass.LogFileType = 'Upgrade'
        $newClass.Description = 'Upgrade log files.'
        $newClass.RegExString = '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>(\d{2}:)+\d{2}),\s+(?<Type>\w+)\s{1,17}(\[(?<ErrorCode>\w*)\])?(?<Component>\s\w+)?\s+(?<Message>.*)'
        $newClass.LogFiles = ('setupact*','setuperr*')
        $newClass.LocationsLogFiles = ('C:\windows\panther\setupact.log', 'C:\windows\panther\setuperr.log', 'c:\$WINDOWS.~BT') 
        ($this.LoadedClasses).Add($newClass)

        #DISM
        $newClass =  [LogFileTypeClass]::new()
        $newClass.LogFileType = 'DISM'
        $newClass.Description = 'DISM log file.'
        $newClass.RegExString = '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>(\d{2}:)+\d{2}),\s+(?<Type>\w+)\s{1,18}(?<Component>\w+)?\s+(?<Message>.*)'
        $newClass.LogFiles = ('dism.log','dism*')
        $newClass.LocationsLogFiles = 'C:\windows\logs\DISM\dism.log'
        ($this.LoadedClasses).Add($newClass)           
    }
    
    #Overriding ToString to show the LogFilenames in the overview
    [string] ToString()
    {
        return ($this.LoadedClasses).LogFileType
    }
}

class LogFileTypeClass
{
    #region properties

    # LogfileType in enum
    [string]$LogFileType
    
    # Description of the logFile
    [string]$Description

    # RegExString to parse the LogFiles
    [string]$RegExString

    # used for condition to apply the correct LogFileType depending of the LogFileName
    [string[]]$LogFiles

    # all the locations where these kind of LogFiles can be found.
    [string[]]$LocationsLogFiles

    #endregion
        
    #Constructor without values
    LogFileTypeClass()
    {

    }

    #Constructor with values
    LogFileTypeClass($logFileType, $description, $regExString, $logFiles, $locationsLogFiles)
    {
        $this.LogFileType = $logFileType 
        $this.Description = $description 
        $this.RegExString = $regExString 
        $this.LogFiles = $logFiles 
        $this.LocationsLogFiles = $locationsLogFiles         
    }

    #Overriding ToString to show the LogFileTypes in the overview
    [string] ToString()
    {
        return ($this.LogFileType).ToString()
    }
}
   
## Class of the LogParser which can open n logfiles
class LogFileParser
{
    #region Props

    # Generic List of all parsed LogFiles of Type "ParsedLogfile" (Class)
    [System.Collections.Generic.List``1[ParsedLogFile]] $ParsedLogFiles

    # FilePath
    [String] $LogFilePath

    #LogFileTypeClasses
    $LogFileTypeClasses
    
    #endregion

    #region Funcs

    # Constructor
    LogFileParser($LogFilePath)
    {            
        $this.init($LogFilePath)
    }

    LogFileParser($LogFilePath, $LogFileExportedClassFiles)
    {            
        if (Test-Path $LogFileExportedClassFiles)
        {
            $this.LogFileTypeClasses = Import-Clixml -Path $LogFileExportedClassFiles
        }
        $this.init($LogFilePath)
    }

    hidden init($LogFilePath)
    {
        # Constructor Code
        if (Test-Path $LogFilePath)
        { 
            if (-not $this.LogFileTypeClasses)
            {
                $this.LogFileTypeClasses = [LogFileTypeClasses]::new()
            }   
      
            $allLogFiles = Get-ChildItem $LogFilePath -Filter *.log -Recurse
            $this.ParsedLogFiles = New-Object -TypeName System.Collections.Generic.List``1[ParsedLogFile]
            $this.LogFilePath = $LogFilePath
            foreach ($file in $allLogFiles)
            {                
                $fileType = Get-LogFileType -LogFileName $file.Name -LogFileTypeClasses $this.LogFileTypeClasses
                $RegExString = (($this.LogFileTypeClasses.LoadedClasses).Where{$_.LogFileType -eq $fileType}).RegExString
                $this.ParsedLogFiles.Add([ParsedLogFile]::new($file.FullName, $fileType, $RegExString))   
            }         
        }
        else
        {
            Write-Error -Message 'Path was not reachable. Please verify your Path.'
        }   
    }
    #endregion
}

class ParsedLogFile
{
    #region Props

    #Hidden variable for the keys in the logfile.
    hidden [string[]] $ColumnNames

    # FilePath of the parsed log.
    [string] $LogFilePath
   
    #The parsed logging data.
    $ParsedLogData

    #LogFileType for this file
    [string] $LogFileType

    # RegExString
    hidden [string] $RegExString

    #endregion

    #region Funcs

    ## standard constructor
    ## LogFileType SCCM is set
    ParsedLogFile($LogFilePath, $RegexString)
    {        
        $this.LogFileType = 'SCCM'
        $this.LogFilePath = $LogFilePath
        $this.LogFileType = $this.LogFileType
        $this.RegExString = $RegexString
        $this.init()
    }

    ## Constructr with LogFileType
    ParsedLogFile($LogFilePath, $LogFileType, $RegexString)
    {     
        $this.LogFilePath = $LogFilePath
        $this.LogFileType = $LogFileType
        $this.RegExString = $RegexString
        $this.init()
    }

    ## Initialization of class and log
    hidden init()
    {        
        if (Test-Path -Path $this.LogFilePath)
        {            
            # Constructor Code
            $this.LogFilePath = $this.LogFilePath
            Write-Host -Object "Parsing LogFile $($this.LogFilePath) with LogfileType $($this.LogFileType)."
            $actualParsedLog = Get-RegExParsedLogfile -Path $this.LogFilePath -LogFileType $this.LogFileType -regExString $this.RegExString
            Write-Host -Object 'Parsing done.'
            $this.ParsedLogData = $actualParsedLog.Log
            $this.ColumnNames = $actualParsedLog.Keys            
        }
        else
        {
            Write-Error -Message "Path was not reachable. Please verify your Path: $($this.LogFilePath)."
        }   
    }

    #Overriding ToString to show the LogFilenames in the overview
    [string] ToString()
    {
        return ($this.LogFilePath).ToString()
    }

    #region private functions

    # Returns lines with errors
    hidden [int[]] GetLinesWithErrorsHeuristic()
    {
        $LinesWithErrors = (($this.ParsedLogData).Where{
                $_.Entry -like '*error*'
        }).RowNum
        $RowList = Get-RowNumbersInRange -RowNumbers $LinesWithErrors
        $null = ($this.ParsedLogData).Where{
            $_.RowNum -in $RowList
        }
        return $LinesWithErrors
    }

    # Returns lines with errors
    # Overload with Range
    hidden [int[]] GetLinesWithErrorsHeuristic([int]$Range)
    {
        $LinesWithErrors = (($this.ParsedLogData).Where{
                $_.Entry -like '*error*'
        }).RowNum
        $RowList = Get-RowNumbersInRange -RowNumbers $LinesWithErrors -Range $Range
        $null = ($this.ParsedLogData).Where{
            $_.RowNum -in $RowList
        }
        return $LinesWithErrors
    }
    
    # Returns lines with errors
    hidden [int[]] GetRowNumbersWithErrors()
    {
        $LinesWithErrors = (($this.ParsedLogData).Where{
                $_.Entry -like '*error*'
        }).RowNum
        return $LinesWithErrors  
    }

    #endregion


    #region public functions
    
    # Returns the column Keys
    [string[]] GetColumnNames()
    {
        return $this.ColumnNames
    }
        
    # Returns lines with errors
    [PSCustomObject]GetLinesWithErrors()
    {
        $LinesWithErrors = ($this.ParsedLogData).Where{
            ($_.Entry -like '*error*') -or 
            ($_.Entry -like '*failed*') -or 
            ($_.Entry -like '*0x8*')
        }
        return $LinesWithErrors
    }

    # Returns lines with warnings
    [PSCustomObject]GetLinesWithWarnings()
    {
        $LinesWithErrors = ($this.ParsedLogData).Where{
            ($_.Entry -like '*resume*') -or 
            ($_.Entry -like '*warning*') -or
            ($_.Entry -like '*ttempting*') -or
            ($_.Entry -like '*Not Applicable*') -or 
            ($_.Entry -like '*improper*') -or
            ($_.Entry -like '*can´t*')
        }
        return $LinesWithErrors
    }

    [PSCustomObject]GetLinesWithErrorsWithRange([int]$Range)
    {
        # gather only rows, which contain errors and show also all x lines before and after the error-lines
        $LinesWithErrors = ($this.GetLinesWithErrors()).RowNum
        if ($LinesWithErrors)
        {        
            $RowList = Get-RowNumbersInRange -RowNumbers $LinesWithErrors -Range $Range
            return ($this.ParsedLogData).Where{
                $_.RowNum -in $RowList
            }
        }
        else
        {
            Write-Host 'No line with errors has been found.'
            return $null
        }
    }

    [PSCustomObject]GetLinesWithWarningsWithRange([int]$Range)
    {
        # gather only rows, which contain warnings and show also all x lines before and after the error-lines
        $LinesWithWarnings = ($this.GetLinesWithErrors()).RowNum
        if ($LinesWithWarnings)
        {        
            $RowList = Get-RowNumbersInRange -RowNumbers $LinesWithWarnings -Range $Range
            return ($this.ParsedLogData).Where{
                $_.RowNum -in $RowList
            }
        }
        else
        {
            Write-Host 'No line with warnings has been found.'
            return $null
        }
    }

    #endregion
    
    #endregion
}



function Get-RowNumbersInRange
{
    <#
            .Synopsis
            Get-RowNumbersInRange
            .DESCRIPTION
            Heuristic method, which returns a list of all transmitted rowlines addiing a number of lines n ($Range) before and after.
            .EXAMPLE
            $rowsWithErrors = 21,345,456
            $allRowsToSHow = Get-RowNumbersInRange -RowNumbers $rowsWithErrors -Range 10 
    #>
    Param
    (
        #Previous calculated set of rowNumbers.
        [Parameter(Mandatory = $true,HelpMessage='List of RowNumbers.',
                ValueFromPipelineByPropertyName = $true,
        Position = 0)]
        $RowNumbers,

        [Parameter(Position = 1)]
        [int]$Range = 20
    )
    Begin
    { }
    Process
    {
        $allShowingRowNumbers = New-Object -TypeName System.Collections.Generic.List``1[Int]
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
    { }
}


function Get-LogFileType
{
    <#
            .Synopsis
            Get-LogFileType
            .DESCRIPTION
            Returns the type of the transmitted LogFile.
            .EXAMPLE       
            $LogFileType = Get-LogFileType -LogFileName 'dism.log'
    #>
    Param
    (
        #Name of the logFile
        [Parameter(Mandatory = $true,HelpMessage='The Name of the logfile.',
                ValueFromPipelineByPropertyName = $true,
        Position = 0)]
        $LogFileName,

        [Parameter(Mandatory = $true,HelpMessage='The LogFileTypeClasses load by LogFileParser.',
        Position = 0)]
        $LogFileTypeClasses
    )
    Begin
    { }
    Process
    {
        foreach ($class in $LogFileTypeClasses.LoadedClasses)
        {
            foreach ($logfile in $class.LogFiles)
            {
                if ($logfileName -like $logfile)
                {
                    return $class.LogFileType
                }                
            }            
        }

        # if no logtype has been found the default value is processed.
        return (($LogFileTypeClasses.LoadedClasses).Where{$_.LogFiles -contains 'default'}).LogFileType       
    }
    End
    { }
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
    param
    (
        #Contains the log file destination.
        [Parameter(Mandatory = $true,HelpMessage='Contains the LogFile destination.', Position = 0)]
        [String]
        $Path,
        
        #Contains the RegEx with named keys
        [Parameter(Mandatory =$true,HelpMessage='The RegEx to parse the LogFile.', Position = 1)]
        [String]
        $RegExString,
        
        #ValidateSet of the differenct preconfigured LogFileTypes               
        [Parameter(Position = 2)]
        [string]$LogFileType = 'SCCM',

        #Filter
        [Parameter(Position = 3)]
        [String]
        $GatherOnlyLinesWhichContain = '' 
    )   
    function Select-Names
    {
        <#
            .SYNOPSIS
            SubFunction
        #>
        begin
        {        
            $hash = [Ordered]@{}        
        }
        process
        {        
            if ($_ -eq 'RowNum')
            {
                $global:rowNum += 1
                $hash.Add($_, $rowNum) 
            }
            elseif ($_ -eq 'Thread')
            {
                $hash.Add($_, [int]($match.groups["$_"].Value))
            }
            else
            {
                $hash.Add($_, $match.groups["$_"].Value)
            }
        }
        end
        {
            $thisDate = [datetime]($hash.Date + ' ' + $hash.Time)
            $hash.Add('DateTime', $thisDate)                
            [PSCustomObject]$hash                    
        }
    }
    function Select-Matches
    {
        <#
            .SYNOPSIS
            SubFunction
        #>
        process
        {        
            $match = $_
            $names | Select-Names                        
        }
    }
    function Select-Line
    {
        <#
            .SYNOPSIS
            SubFunction
        #>
        process
        {      
            $rx.Matches($_) | Select-Matches            
        }
    }

    #Get-Content with ReadCount, because of perfomance-improvement.
    $t = (Get-Content -Path $Path -ReadCount 1000).Split([Environment]::NewLine)

    if ($GatherOnlyLineWhichContain)
    {
        $t = $t | Select-String -Pattern $GatherOnlyLinesWhichContain
    }         
  
    [regex]$rx = $RegexString

    [string[]]$names = 'RowNum'  
    $names += $rx.GetGroupNames().Where{$_ -match '\w{2}'} 
    
    #rowNum
    Set-Variable -Name rowNum -Value 0 -Scope Global

    # Here is the data parsed. This is done by 3 sub routines which work faster than Foreach/Foreach-Object
    $data = $t | Select-Line    
    
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty -Name Keys -Value $names
    $object | Add-Member -MemberType NoteProperty -Name Log -Value $data 
    $object    
}
