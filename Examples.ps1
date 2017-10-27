#TimeBomb
Write-Host "You have 20 seconds left" -ForegroundColor Yellow
Start-Sleep -Seconds 20

$filepath = 'C:\OneDrive\Weiteres\PSConfAsia - 2017\PowerShell Classes\'
Set-Location -Path $filepath 

#break

# Dot Sourcing
#. '.\LogFileParser\LogFileParser.ps1'
#. '.\LogFileParser\LogFileParser - Add Robo1.ps1'
. '.\LogFileParser\LogFileParser - Add Robo2.ps1'

# loading complete directory recursive
$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\Mix\")  
 
# loading a specific file
$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\CBS\cbs.log") 
$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\DISM\dism.log")   
$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\WindowsUpdateLog\WindowsUpdate.log")  
$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\Upgrade\setupact.log")  
$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\Upgrade\setuperr.log")  
$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\SCCM\ccmexec.log")  
$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\Robocopy\Robocopy.log") 


####################################################################################################

#region data

# information of current data
$newLogParser
$newLogParser.ParsedLogFiles
$newLogParser.LogFileTypeClasses | select * -ExpandProperty LoadedClasses
$newLogParser.ParsedLogFiles | Select-Object -Property LogFilePath, LogFileType

# show data
$newLogParser.ParsedLogFiles[0].ParsedLogData | Out-GridView
$newLogParser.ParsedLogFiles[1].ParsedLogData | Out-GridView
$newLogParser.ParsedLogFiles[2].ParsedLogData | Out-GridView
$newLogParser.ParsedLogFiles[3].ParsedLogData | Out-GridView
$newLogParser.ParsedLogFiles[4].ParsedLogData | Out-GridView
$newLogParser.ParsedLogFiles[5].ParsedLogData | Out-GridView
$newLogParser.ParsedLogFiles[6].ParsedLogData | Out-GridView
($newLogParser.ParsedLogFiles[0].ParsedLogData.RowNum | Measure -Maximum).Maximum

# columns of data, which can be used for conditions
$newLogParser.ParsedLogFiles[0].GetColumnNames()

# Gets lines with errors
$newLogParser.ParsedLogFiles[0].GetLinesWithErrors() | Out-GridView

# Gets lines with warnings
$newLogParser.ParsedLogFiles[1].GetLinesWithWarnings() | Out-GridView

# gather only rows, which contain errors and show also all 8 lines before and after the error-lines
$newLogParser.ParsedLogFiles[0].GetLinesWithErrorsWithRange(8) | Out-GridView

# gather only rows, which contain warnings and show also all 8 lines before and after the warning-lines
$newLogParser.ParsedLogFiles[1].GetLinesWithWarningsWithRange(8) | Out-GridView

# columns of data, which can be used for conditions
$newLogParser.ParsedLogFiles[0].GetColumnNames()

# gather only rows, which contain errors and show them
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{
  $_.($newLogParser.ParsedLogFiles[0].DataField) -like '*0x8*'
} | Out-GridView

#Row conditions
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{
  $_.RowNum -gt 10 -and $_.RowNum -lt 50  
} | Out-GridView

#Time conditions
($newLogParser.ParsedLogFiles[0].ParsedLogData).DateTime

#last 500 days
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{
  $_.DateTime -gt ([DateTime]::Now).AddDays(-500)  
}

#endregion

####################################################################################################

#Special functions

($newLogParser.ParsedLogFiles[6]).GetInstalledUpdates() | Out-GridView


####################################################################################################

# Dot Sourcing
. '.\LogFileParser\LogFileParser.ps1'
. '.\LogFileParser\LogFileParser - Add Robo1.ps1'
. '.\LogFileParser\LogFileParser - Add Robo2.ps1'

$newLogParser = [LogFileParser]::new("$filepath\DemoLogs\Robocopy\robocopy.log") 

####################################################################################################


#Class information
[LogFileTypeClass].GetMethods().Name

[ParsedLogFile].GetMethods().Name

####################################################################################################

#region Measures

#Measure LogFileParser

Measure-Command -Expression {
  $filepath = 'C:\OneDrive\Weiteres\PSConfAsia - 2017\PowerShell Classes - Onhands with the example LogFileParser\'
  Set-Location -Path 'C:\OneDrive\Weiteres\PSConfAsia - 2017\PowerShell Classes - Onhands with the example LogFileParser\'

  # Dot Sourcing
  . '.\LogFileParser\LogFileParser.ps1'

  # loading complete directory recursive
  $newLogParser = [LogFileParser]::new("$filepath\DemoLogs\CBS\cbs.log")  
}



#OLD
Measure-Command -Expression {
  $filepath = 'C:\OneDrive\Weiteres\PSConfAsia - 2017\PowerShell Classes - Onhands with the example LogFileParser\'
  Set-Location -Path 'C:\OneDrive\Weiteres\PSConfAsia - 2017\PowerShell Classes - Onhands with the example LogFileParser\'

  # Dot Sourcing
  . '.\LogFileParser_OLD\LogFileParser.ps1'

  # loading complete directory recursive
  $newLogParser = [LogFileParser]::new("$filepath\DemoLogs\CBS\cbs.log")  
}




Measure-Command -Expression {
  # loading complete directory recursive    
  $t = (Get-Content -Path "$filepath\DemoLogs\CBS\cbs.log" -ReadCount 1000).Split([Environment]::NewLine)
}

Measure-Command -Expression {
  # loading complete directory recursive    
  $t = (Get-Content -Path "$filepath\DemoLogs\CBS\cbs.log")
}





Measure-Command -Expression {
  $filepath = 'C:\OneDrive\Weiteres\PSConfAsia - 2017\PowerShell Classes - Onhands with the example LogFileParser'
  Set-Location -Path 'C:\OneDrive\Weiteres\PSConfAsia - 2017\PowerShell Classes - Onhands with the example LogFileParser'

  # Dot Sourcing
  . '.\LogFileParser\Read-WindowsUpdateLog.ps1'

  # loading complete directory recursive
  $newLogParser = Read-WindowsUpdateLog -Path "$filepath\DemoLogs\WindowsUpdateLog\WindowsUpdate.log"
}


#endregion


#region LogFileTypeClasses

#Example add additional LogFileClass
$exampleClass = [LogFileTypeClass]::new()
$exampleClass.LogFileType = 'Example'
$exampleClass.Description = 'Example description'
$exampleClass.RegExString = '(?<All>.*)'
$exampleClass.LogFiles = ('example.log', 'example*.log')
$exampleClass.LocationsLogFiles = ('c:\Temp\example.log', 'C:\example.log')
#UNCOMMENT#    ($this.LoadedClasses).Add($exampleClass)

return

####################################################################################################


#Creates the classes for the logfiles and exports them
$newLogFileTypeClasses = [LogFileTypeClasses]::new()
$newLogFileTypeClasses | Select-Object -ExpandProperty LoadedClasses
Export-Clixml -InputObject $newLogFileTypeClasses -Path "$filepath\LogFileParser\Classes.xml" 

#Import to prove classes
$classes = Import-Clixml -Path "$filepath\LogFileParser\Classes.xml" 

$classes | Select-Object -ExpandProperty LoadedClasses
$newLogFileTypeClasses.LoadedClasses.LogFileType


#Loading a specific file with own classes
#$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\DISM\dism.log','C:\OneDrive\## Sources\Git\LogFileParser\Classes.xml')  

#endregion

####################################################################################################