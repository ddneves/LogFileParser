
# dot sourcing
. 'C:\OneDrive\## Sources\Git\LogFileParser\LogFileParser.ps1'

# loading complete directory recursive
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\')  
 
# loading a specific file
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\DISM\dism.log')  
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\CBS\cbs.log')  
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\Upgrade\setupact.log')  
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\Upgrade\setuperr.log')  
$newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\SCCM\ccmexec.log')  

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
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{ $_.RowNum -gt 500 -and $_.RowNum -lt 510  }

#Time conditions
($newLogParser.ParsedLogFiles[0].ParsedLogData)[0].Time

#last 2 days
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{ $_.DateTime -gt ([DateTime]::Now).AddDays(-2)  }

# gather only rows, which contain errors and show also all 20 lines bnefore and after the error-lines
$LinesWithErrors = (($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{$_.Entry -like '*error*'}).RowNum
$RowList = Get-RowNumbersInRange -RowNumbers $LinesWithErrors -Range 20
($newLogParser.ParsedLogFiles[0].ParsedLogData).Where{$_.RowNum -in $RowList} | Out-GridView






return


                elseif ($_ -eq 'Time')
                {                    
                    $hash.Add($_, ([datetime]($match.groups["$_"].Value)).ToFileTime()) 
                }                
                elseif ($_ -eq 'Date')
                {                    
                    $hash.Add($_, ([datetime]($match.groups["$_"].Value)).Date) 
                }


$Path ='C:\OneDrive\## Sources\Git\DemoLogs\'


Write-Host 'Standard'
. 'C:\OneDrive\## Sources\Git\LogFileParser\LogFileParser.ps1'

Measure-Command -Expression {  
        $newLogParser = [LogFileParser]::new($Path)  
} 



$newLogParser = $null
[GC]::Collect()
Start-Sleep -Seconds 5
[GC]::Collect()
Start-Sleep -Seconds 5
[GC]::Collect()
Start-Sleep -Seconds 5
[GC]::Collect()
Start-Sleep -Seconds 5
[GC]::Collect()
Start-Sleep -Seconds 5

Write-Host 'Parallel'
. 'C:\OneDrive\## Sources\Git\LogFileParser\LogFileParser_parallel.ps1'
Measure-Command -Expression {  
        $newLogParser = [LogFileParser]::new($Path)  
} 













return

. 'C:\OneDrive\## Sources\Git\LogFileParser\LogFileParser.ps1'
Write-Host 'Standard'
Measure-Command -Expression {  
    for ($x = 1; $x -lt 10; $x += 1) 
    {
        Write-Host "Run started: $x"
        $newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\CBS\cbsbig.log')  
        Write-Host "Run ended: $x"
    }
} 
$newLogParser = $null


Write-Host 'Parallel'
. 'C:\OneDrive\## Sources\Git\LogFileParser\LogFileParser_parallel.ps1'
Measure-Command -Expression {  
    for ($x = 1; $x -lt 10; $x += 1) 
    {
        Write-Host "Run started: $x"
        $newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\CBS\cbsbig.log')  
        Write-Host "Run ended: $x"
    }
} 


Measure-Command -Expression {       
for ($x = 0; $x -lt 3; $x += 1) 
    {
        Write-Host "Run started: $x"
        $newLogParser = [LogFileParser]::new('C:\OneDrive\## Sources\Git\DemoLogs\CBS\cbs.log')  
        Write-Host "Run ended: $x"
    } 
} | Select-Object *