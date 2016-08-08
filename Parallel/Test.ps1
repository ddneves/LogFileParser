
# dot sourcing
. 'C:\OneDrive\## Sources\Git\LogFileParser\LogFileParser.ps1'




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