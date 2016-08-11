# Dot Sourcing
. 'C:\OneDrive\## Sources\Git\LogFileParser\LogFileParserExt.ps1'

# loading complete directory recursive
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\')  
 
# loading a specific file
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\CBS\cbs.log')  
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\Upgrade\setupact.log')  
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\Upgrade\setuperr.log')  
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\SCCM\ccmexec.log')  

#Loading a specific file with own classes
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\DISM\dism.log','C:\OneDrive\## Sources\Git\LogFileParser\Classes.xml')  


# information of actual data
$newLogParser
$newLogParser.ParsedLogFiles
$newLogParser.ParsedLogFiles | Select-Object LogFilePath, LogFileType

# show data
$newLogParser.ParsedLogFiles[0].ParsedLogData

# columns of data, which can be used for conditions
$newLogParser.ParsedLogFiles[0].GetColumnNames()

# gather only rows, which contain errors and show them
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{$_.Entry -like '*error*'} | Out-GridView

#Row conditions
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{ $_.RowNum -gt 500 -and $_.RowNum -lt 510  } | Out-GridView

#Time conditions
($newLogParser.ParsedLogFiles[0].ParsedLogData)[0].Time

#last 2 days
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{ $_.DateTime -gt ([DateTime]::Now).AddDays(-2)  }

# gather only rows, which contain errors and show also all 20 lines before and after the error-lines
$newLogParser.ParsedLogFiles[0].GetLinesWithErrorsWithRange(20) | Out-GridView

#Example add additional LogFileClass
$exampleClass =  [LogFileTypeClass]::new()
$exampleClass.LogFileType = 'Example'
$exampleClass.Description = 'Example description'
$exampleClass.RegExString = '(?<All>.*)'
$exampleClass.LogFiles = ('example.log','example*.log')
$exampleClass.LocationsLogFiles = ('c:\Temp\example.log','C:\example.log')
#UNCOMMENT#($this.LoadedClasses).Add($exampleClass)

return


#Creates the classes for the logfiles and exports them
$newLogFileTypeClasses = [LogFileTypeClasses]::new()
Export-Clixml -InputObject $newLogFileTypeClasses -Path 'C:\OneDrive\## Sources\Git\LogFileParser\Classes.xml'

#Import to prove classes
$classes = Import-Clixml -Path 'C:\OneDrive\## Sources\Git\LogFileParser\Classes.xml'



#$newLogFileTypeClasses.LoadedClasses.LogFileType




#$classes

$LinesWithErrors = (($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{$_.Entry -like '*error*'}).RowNum
$RowList = Get-RowNumbersInRange -RowNumbers $LinesWithErrors -Range 20
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{$_.RowNum -in $RowList} | Out-GridView