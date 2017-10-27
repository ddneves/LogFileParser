#requires -Version 5

<#	
    .NOTES
    ===========================================================================
    Created on:   	27.10.2017
    Created by:   	David das Neves
    Version:        1.0
    Project:        LogFileParser
    Filename:       LogFileParser.ps1
    ===========================================================================
    .DESCRIPTION
    Parses Logfiles into the class ParsedLogFile, which is integrated in the class LogFileParser
#> 

###################################################################################
   
## Class of the LogParser which can open n logfiles. Contains the constructore for files and folders.
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
      #Loads the classes by file
      $this.LogFileTypeClasses = Import-Clixml -Path $LogFileExportedClassFiles
    }
    $this.init($LogFilePath)
  }

  #Initialization and automatically parsing the omitted file(s).
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

      #Parsing each files 1-n
      foreach ($file in $allLogFiles)
      {                
        #Retrieves the filetype - e.g. DISM
        $fileType = $this.GetLogFileType($file.Name) 

        #Loads the LogFileTypeClass to this filetype.
        $regExString = (($this.LogFileTypeClasses.LoadedClasses).Where{
            $_.LogFileType -eq $fileType
        }).RegExString

        #Tries to load the custom class for the loaded fileType for possible overrided or added functions.
        try
        {
            $newParsedLog = New-Object -TypeName $fileType -ArgumentList $file.FullName, $fileType, $regExString
            $this.ParsedLogFiles.Add($newParsedLog)
        }
        catch
        {
          # If it does not find any available class, it will load the default class.
          $this.ParsedLogFiles.Add([ParsedLogFile]::new($file.FullName, $fileType, $regExString))
        }  
      }         
    }
    else
    {
      Write-Error -Message 'Path was not reachable. Please verify your Path.'
    }   
  }    

  #Returns the LogFileType
  hidden [object] GetLogFileType($LogFileName)
  {
    foreach ($class in $this.LogFileTypeClasses.LoadedClasses)
    {
      foreach ($logfile in $class.LogFiles)
      {
        if ($LogFileName -like $logfile)
        {
          return $class.LogFileType
        }                
      }            
    }

    # if no logtype has been found the default value is processed.
    return (( $this.LogFileTypeClasses.LoadedClasses).Where{
        $_.LogFiles -contains 'default'
    }).LogFileType      
  }
  #endregion
}

###################################################################################

#Class for a single LogFileTypeClass, which contains the log information and regEx-string to parse the,.
class LogFileTypeClass
{
  #region properties

  # LogfileType 
  [string]$LogFileType
    
  # Description of the logFile
  [string]$Description

  # RegExString to parse the LogFiles
  hidden [string]$RegExString

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

###################################################################################

# Class for all the different LogFileTypeClasses serialize/deserialize all the types.
class LogFileTypeClasses
{
  #region properties
   
  #Generic List of LogFileTypeClasses
  [System.Collections.Generic.List``1[LogFileTypeClass]] $LoadedClasses

  #endregion

  #Constructor
  LogFileTypeClasses()
  {
    #Load standard classes
    $this.LoadedClasses = New-Object -TypeName System.Collections.Generic.List``1[LogFileTypeClass]

    #SCCM
    $newClass = [LogFileTypeClass]::new()
    $newClass.LogFileType = 'SCCM'
    $newClass.Description = 'All SCCM log-files.'
    $newClass.RegExString = '<!\[LOG\[(?<Entry>.*)]LOG]!><time="(?<Time>.*)\.\d{3}-\d{3}"\s+date="(?<Date>.*)"\s+component="(?<Component>.*)"\s+context="(?<Context>.*)"\s+type="(?<Type>.*)"\s+thread="(?<Thread>.*)"\s+file="(?<File>.*):(?<CodeLine>\d*)">'
    $newClass.LogFiles = 'default'
    $newClass.LocationsLogFiles = ('c:\windows\ccm\logs\*', 'c:\Program Files\System Center Configuration Manager*')
    ($this.LoadedClasses).Add($newClass)

    #CBS
    $newClass = [LogFileTypeClass]::new()
    $newClass.LogFileType = 'CBS'
    $newClass.Description = 'Component log.'
    $newClass.RegExString = '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>(\d{2}:)+\d{2}),\s+(?<Type>\w+)\s+(?<Component>\w+)\s+(?<Message>.*)$'
    $newClass.LogFiles = 'cbs*'
    $newClass.LocationsLogFiles = 'c:\windows\logs\CBS\cbs.log'
    ($this.LoadedClasses).Add($newClass)

    #Upgrade
    $newClass = [LogFileTypeClass]::new()
    $newClass.LogFileType = 'Upgrade'
    $newClass.Description = 'Upgrade log files.'
    $newClass.RegExString = '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>(\d{2}:)+\d{2}),\s+(?<Type>\w+)\s{1,17}(\[(?<ErrorCode>\w*)\])?(?<Component>\s\w+)?\s+(?<Message>.*)'
    $newClass.LogFiles = ('setupact*', 'setuperr*')
    $newClass.LocationsLogFiles = ('C:\windows\panther\setupact.log', 'C:\windows\panther\setuperr.log', 'c:\$WINDOWS.~BT') 
    ($this.LoadedClasses).Add($newClass)

    #DISM
    $newClass = [LogFileTypeClass]::new()
    $newClass.LogFileType = 'DISM'
    $newClass.Description = 'DISM log file.'
    $newClass.RegExString = '(?<Date>\d{4}-\d{2}-\d{2})\s+(?<Time>(\d{2}:)+\d{2}),\s+(?<Type>\w+)\s{1,18}(?<Component>\w+)?\s+(?<Message>.*)'
    $newClass.LogFiles = ('dism.log', 'dism*')
    $newClass.LocationsLogFiles = 'C:\windows\logs\DISM\dism.log'
    ($this.LoadedClasses).Add($newClass)          

    #WindowsUpdateLog
    $newClass = [LogFileTypeClass]::new()
    $newClass.LogFileType = 'WindowsUpdateLog'
    $newClass.Description = 'WindowsUpdate log file.'
    $newClass.RegExString = '(?<Date>\d{4}\.\d{2}\.\d{2})\s(?<Time>\d{2}:\d{2}:\d{2}.\d{7})\s(?<PID>\d{0,})\s{1,}(?<TID>\d{0,})\s{1,}(?<Agent>\w{3,20})\s{1,}(?<Message>.*)'  
    $newClass.LogFiles = ('WindowsUpdate.log')
    $newClass.LocationsLogFiles = 'C:\windows\WindowsUpdate.log'
    ($this.LoadedClasses).Add($newClass)  
    
    #RoboCopy
    $newClass = [LogFileTypeClass]::new()
    $newClass.LogFileType = 'RoboCopy'
    $newClass.Description = 'RoboCopy log file.'
    $newClass.RegExString = ''
    $newClass.LogFiles = ('RoboCopy.log')
    $newClass.LocationsLogFiles = ''
    ($this.LoadedClasses).Add($newClass)   
  } 
    
  #Overriding ToString to show the LogFilenames in the overview
  [string] ToString()
  {
    return ($this.LoadedClasses).LogFileType
  }
}

###################################################################################

#Class for all opened LogFile in the LogFileParser.
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

  #Datafield - columnname, which contains the information data.
  [string] $DataField

  # RegExString
  hidden [string] $RegExString

  #endregion

  #region Funcs

  ## standard constructor

  ## LogFileType SCCM is set
  ParsedLogFile()
  {

  }

  ## LogFileType SCCM is set
  ParsedLogFile($LogFilePath, $regExString)
  {        
    $this.LogFileType = 'SCCM'
    $this.LogFilePath = $LogFilePath
    $this.LogFileType = $this.LogFileType
    $this.RegExString = $regExString
    $this.init()
  }

  ## Constructor with LogFileType
  ParsedLogFile($LogFilePath, $logFileType, $regExString)
  {     
    $this.LogFilePath = $LogFilePath
    $this.LogFileType = $logFileType
    $this.RegExString = $regExString
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
      $plainData = $this.GetLogData()
      $this.GetParsedLogfile($plainData)             
                    
      #Tries to find one of the common data fields
      if ($this.GetColumnNames() -contains 'entry')
      {
        $this.DataField = 'entry'
      }
      else
      {
        #The default data field is message.
        $this.DataField = 'message'
      }   
      Write-Host -Object "Parsing done - the datafield is $($this.dataField)."    
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


  #Returns a generic int list with all values with added ranges.
  hidden [System.Collections.Generic.List``1[Int]] GetRowNumbersInRange($RowNumbers, [int]$Range)
  {
    <#
        .Synopsis
        Get-RowNumbersInRange
        .DESCRIPTION
        Heuristic method, which returns a list of all transmitted rowlines adding a number of lines n ($Range) before and after.
        .EXAMPLE
        $rowsWithErrors = 21,345,456
        $allRowsToSHow = Get-RowNumbersInRange -RowNumbers $rowsWithErrors -Range 10 
    #>
   
    $allShowingRowNumbers = New-Object -TypeName System.Collections.Generic.List``1[Int]

    #Adds the number ranges to the values.
    foreach ($rowNum in $RowNumbers)
    {
      $min = $rowNum - $Range
      if ($min -lt 0)
      {
        $min = 0
      }
      $max = $rowNum + $Range

      for ($x = $min; $x -le $max; $x += 1) 
      {
        if (-not $allShowingRowNumbers.Contains($x))
        {
          $allShowingRowNumbers.Add($x)
        }       
      }
    }        
    return $allShowingRowNumbers
  }
    
  #returns the log data for a log file with a dedicated filter
  hidden [String] GetLogData($GatherOnlyLinesWhichContain)
  {
    #Get-Content with ReadCount, because of perfomance-improvement.
    $data = (Get-Content -Path $this.LogFilePath -ReadCount 1000).Split([Environment]::NewLine)
   
    if ($GatherOnlyLinesWhichContain)
    {
      #Previous filtering to enable faster loading times.
      $data = $data | Select-String -Pattern $GatherOnlyLinesWhichContain
    }          
    
    #Converting the format correctly.
    $data = $data -join [System.Environment]::NewLine

    return $data
  }

  #overloaded call to return the loaded log data without the filter.
  hidden [String] GetLogData()
  {
    return $this.GetLogData('')
  }
    
  # Parses the log files with the RegEx from the LogFileTypeClasses.
  hidden GetParsedLogfile($plainData)
  {
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
        #Adding Rownumber to the output
        if ($_ -eq 'RowNum')
        {
          $global:rowNum += 1
          $hash.Add($_, $rowNum) 
        }
        #make the threads sortable by converting the column from string to int
        elseif ($_ -eq 'Thread')
        {
          $hash.Add($_, [int]($match.groups["$_"].Value))
        }
        #default column
        else
        {
          $hash.Add($_, $match.groups["$_"].Value)
        }
      }
      end
      {
        #add datetime to the columns to make them sortable and filterable with DateTime class.
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
 
    [regex]$rx = $this.RegExString
    if ($plainData.Count -eq 1)
    {
        $plainData = $plainData -split [System.Environment]::NewLine
    }
   
    [string[]]$names = 'RowNum'  
    $names += $rx.GetGroupNames().Where{
      $_ -match '\w{2}'
    } 
    
    #rowNum
    Set-Variable -Name rowNum -Value 0 -Scope Global
   
    # Here is the data parsed. This is done by 3 sub routines which work faster than Foreach/Foreach-Object
    $data = $plainData | Select-Line    
    
    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty -Name Keys -Value $names
    $object | Add-Member -MemberType NoteProperty -Name Log -Value $data 

    #Setting the properties into the class itself
    $this.ParsedLogData = $object.Log
    $this.ColumnNames = $object.Keys
  }      

  #endregion

  ###############################################################

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
      ($_.($this.DataField) -like '*error*') -or 
      ($_.($this.DataField) -like '*failed*') -or 
      ($_.($this.DataField) -like '*0x8*')
    }
    return $LinesWithErrors
  }

  # Returns lines with warnings
  [PSCustomObject]GetLinesWithWarnings()
  {
    $LinesWithErrors = ($this.ParsedLogData).Where{
      ($_.($this.DataField) -like '*resume*') -or 
      ($_.($this.DataField) -like '*warning*') -or
      ($_.($this.DataField) -like '*ttempting*') -or
      ($_.($this.DataField) -like '*Not Applicable*') -or 
      ($_.($this.DataField) -like '*improper*') -or
      ($_.($this.DataField) -like '*can´t*')
    }
    return $LinesWithErrors
  }

  #Returns the lines with errors with a range of rows.
  [PSCustomObject]GetLinesWithErrorsWithRange([int]$Range)
  {
    # gather only rows, which contain errors and show also all x lines before and after the error-lines
    $LinesWithErrors = ($this.GetLinesWithErrors()).RowNum
    if ($LinesWithErrors)
    {        
      $RowList = $this.GetRowNumbersInRange($LinesWithErrors, $Range)
      return ($this.ParsedLogData).Where{
        $_.RowNum -in $RowList
      }
    }
    else
    {
      Write-Host -Object 'No line with errors has been found.'
      return $null
    }
  }

  #Returns the lines with warnings with a range of rows.
  [PSCustomObject]GetLinesWithWarningsWithRange([int]$Range)
  {
    # gather only rows, which contain warnings and show also all x lines before and after the error-lines
    $LinesWithWarnings = ($this.GetLinesWithWarnings()).RowNum
    if ($LinesWithWarnings)
    {        
      $RowList = $this.GetRowNumbersInRange($LinesWithWarnings, $Range)
      return ($this.ParsedLogData).Where{
        $_.RowNum -in $RowList
      }
    }
    else
    {
      Write-Host -Object 'No line with warnings has been found.'
      return $null
    }
  }

  #endregion    
  #endregion
}


###################################################################################
#region extended LogFileTypeClasses

#Inherited class to add functions to the ParsedLogData
class WindowsUpdateLog : ParsedLogFile
{

  ## LogFileType SCCM is set
  WindowsUpdateLog($LogFilePath, $regExString): base($LogFilePath, $regExString)
  {  }

  ## Constructor with LogFileType
  WindowsUpdateLog($LogFilePath, $logFileType, $regExString): base($LogFilePath, $logFileType, $regExString)
  {  }
  
  #region Updates

  #Returns the installed values parsed from the loaded log files.
  [PSCustomObject]GetInstalledUpdates()
  {
    $kbobjects = @()
    foreach ($o in $this.ParsedLogData)
    {
      #Pattern to find the updates
      $Pattern = 'Title\s=\s(?<UpdateName>.{1,})'
      If ($o.Message -match $Pattern)
      {
        $h = [Ordered]@{}
        $h.Date = $o.Date
        $h.Time = $o.Time
        $h.UpdateName = $Matches.UpdateName
      
        $kbobj = New-Object -TypeName PSObject -Property $h
        $kbobjects += $kbobj
      }
    }
    return $kbobjects | Sort-Object -Property Date
  }

  #endregion
}


###################################################################################

#Inherited class to add functions to the ParsedLogData
class RoboCopy : ParsedLogFile
{
  ## standard constructor
  ## LogFileType SCCM is set
  RoboCopy($LogFilePath, $regExString): base($LogFilePath, $regExString)
  {  }

  ## Constructor with LogFileType
  RoboCopy($LogFilePath, $logFileType, $regExString): base($LogFilePath, $logFileType, $regExString)
  {  }
  
  #region Updates

  hidden GetParsedLogfile($plainData)
  {
      $rcLogSummary = [PSCustomObject]@{
         Start       = $null
         End         = $null
         LogFile     = $null
         Source      = $null
         Destination = $null
         TotalDirs   = $null
         CopiedDirs  = $null
         FailedDirs  = $null
         TotalFiles  = $null
         CopiedFiles = $null
         FailedFiles = $null
         TotalBytes  = $null
         CopiedBytes = $null
         FailedBytes = $null
         TotalTimes  = $null
         Speed       = $null
      }
           
      [regex]$regex_Start = 'Started\s:\s+(?<StartTime>.+[^\n\r])'
      if ($plainData -match $regex_Start){
         $rcLogSummary.Start = $Matches['StartTime']
      } 
            
      [regex]$regex_End = 'Ended\s:\s+(?<EndTime>.+[^\n\r])'
      if ($plainData -match $regex_End){
         $rcLogSummary.End = $Matches['EndTime']
      } 
      [regex]$regex_Source = 'Source\s:\s+(?<Source>.+[^\n\r])'
      if($plainData -match $regex_Source){
         $rcLogSummary.Source = $Matches['Source'].Tolower()
      }
      
      [regex]$regex_Target = 'Dest\s:\s+(?<Target>.+[^\n\r])'
      if($plainData -match $regex_Target){
         $rcLogSummary.Destination = $Matches['Target'].ToLower()
      }
      
      [regex]$regex_Dirs = 'Dirs\s:\s+(?<TotalDirs>\d+)\s+(?<CopiedDirs>\d+)(?:\s+\d+){2}\s+(?<FailedDirs>\d+)\s+\d+'
      if ($plainData -match $regex_Dirs){
         $rcLogSummary.TotalDirs  = [int]$Matches['TotalDirs']
         $rcLogSummary.CopiedDirs = [int]$Matches['CopiedDirs']
         $rcLogSummary.FailedDirs = [int]$Matches['FailedDirs']
      }    

      [regex]$regex_Files = 'Files\s:\s+(?<TotalFiles>\d+)\s+(?<CopiedFiles>\d+)(?:\s+\d+){2}\s+(?<FailedFiles>\d+)\s+\d+'
      if ($plainData -match $regex_Files){
         $rcLogSummary.TotalFiles  = [int]$Matches['TotalFiles']
         $rcLogSummary.CopiedFiles = [int]$Matches['CopiedFiles']
         $rcLogSummary.FailedFiles = [int]$Matches['FailedFiles']
      }    

      [regex]$regex_Speed = 'Speed\s:\s+(?<Speed>.+\/min)'
      if ($plainData -match $regex_Speed){
         $rcLogSummary.Speed = $Matches['Speed']
      } 
      
      $arrBytes = @(
         'Bytes\s:\s+(?<TotalBytes>(\d+\.\d+\s)[bmg]|\d+)\s+' #TotalBytes
         '(?<CopiedBytes>\d+.\d+\s[bmg]|\d+)\s+'              #CopiedBytes
         '(?:(\d+.\d+\s[bmg]|\d+)\s+){2}'                     #Skip two
         '(?<FailedBytes>\d+.\d+\s[bmg]|\d+)'                 #FailedBytes
      )
       
      [regex]$regex_Bytes = -join $arrBytes      
      if ($plainData -match $regex_Bytes){
         $rcLogSummary.TotalBytes  = $Matches['TotalBytes']  
         $rcLogSummary.CopiedBytes = $Matches['CopiedBytes'] 
         $rcLogSummary.FailedBytes = $Matches['FailedBytes']
      } 

      [regex]$regex_Times = 'Times\s:\s+(?<TotalTimes>\d+:\d+:\d+)'
      if ($plainData -match $regex_Times){
         $rcLogSummary.TotalTimes  = $Matches['TotalTimes']
      } 

    $this.ParsedLogData = $rcLogSummary
    $this.ColumnNames = $rcLogSummary.Keys
  }
  #endregion
}
#endregion