#Requires -RunAsAdministrator

#
# Commands to get info on the Events:
#
# (Get-WinEvent -ListProvider "Microsoft-Windows-Kernel-General").Events|Where-Object {$_.Id -eq 1}
# (Get-WinEvent -ListProvider "Microsoft-Windows-Security-Auditing").Events|Where-Object {$_.Id -eq 4616}
#
# References: 
# https://blogs.technet.microsoft.com/ashleymcglone/2013/08/28/powershell-get-winevent-xml-madness-getting-details-from-event-logs/ 
# https://dfirblog.wordpress.com/2016/03/13/how-to-parse-windows-eventlog/
# https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc733210(v=ws.10)

# Show an Open File Dialog and return the file selected by the user
Function Get-Folder($initialDirectory)

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.SelectedPath = "C:\Windows\System32\WinEvt\logs\"
	$foldername.Description = "Select the location of System.evtx and Security.evtx logs (\System32\WinEvt\logs\)"
	$foldername.ShowNewFolderButton = $false
	
    if($foldername.ShowDialog() -eq "OK")
		{
        $folder += $foldername.SelectedPath
		 }
	        else  
        {
            Write-Host "(TimeEvents.ps1):" -f Yellow -nonewline; Write-Host " User Cancelled" -f White
			exit
        }
    return $Folder

	}

$F = Get-Folder +"\"
$Folder = $F +"\"

$DesktopPath = ($Env:WinDir+"\System32\winevt\Logs\")


$c = 0
$d = 0

$File = $Folder + "Security.evtx"
Try {   
	$log = (Get-WinEvent -FilterHashtable @{path = $File; ID=4616} -ErrorAction Stop)
    Write-Host "(TimeEventsAll.ps1):" -f Yellow -nonewline; write-host " Selected Security Event Log: ($File)" -f White
	}
	catch [Exception] {
        if ($_.Exception -match "No events were found that match the specified selection criteria") 
		{Write-host "No Matching Events Found" -f Red; exit}
		}


$File1 = $Folder + "System.evtx"
Try {  
	$log1 = (Get-WinEvent -FilterHashtable @{path = $File1; ID=1; ProviderName="Microsoft-Windows-Kernel-General"} -ErrorAction Stop)
    Write-Host "(TimeEventsAll.ps1):" -f Yellow -nonewline; write-host " Selected System Event Log: ($File1)" -f White
	}
	catch [Exception] {
        if ($_.Exception -match "No events were found that match the specified selection criteria") 
		{Write-host "No Matching Events Found" -f Red; exit}
		}

[xml[]]$xmllog = $log.toXml()
$count = $xmllog.Count

$Events = foreach ($i in $xmllog) {$c++
			
			$Previous = [DateTime] ($i.Event.EventData.Data[4].'#text')
			$New = [DateTime] ($i.Event.EventData.Data[5].'#text')
            
            $versioni =    if ($i.Event.System.Version -eq 0) {'Windows Server 2008, Windows Vista'}
                        elseif($i.Event.System.Version -eq 1) {'Windows Server 2012, Windows 8'}
                         else {$i.Event.System.Version}
                       
                       
            $Leveli = if ($i.Event.System.Level -eq 0 ){"Undefined"}
                        elseif($i.Event.System.Level -eq 1){"Critical"}
                        elseif($i.Event.System.Level -eq 2){"Error"}
                        elseif($i.Event.System.Level -eq 3){"Warning"}
                        elseif($i.Event.System.Level -eq 4){"Information"}
                        elseif($i.Event.System.Level -eq 5){"Verbose"}
						
			#Progress Bar
			write-progress -id 1 -activity "Collecting Security entries with EventID=4616 - $c of $($count)"  -PercentComplete (($c / $count) * 100)		
			# Format output fields
			
			[PSCustomObject]@{ 
			'EventID' = $i.Event.System.EventID
            'Time Created' = Get-Date ($i.Event.System.TimeCreated.SystemTime) -format o
			'RecordID' = $i.Event.System.EventRecordID
            'Version' = $versioni
            'Level' = $Leveli
            'Task' = $i.Event.System.Task
            'Opcode' = $i.Event.System.Opcode
			'PID' = $i.Event.System.Execution.ProcessID
			'ThreadID' = $i.Event.System.Execution.ThreadID
            'LogonID' = $i.Event.EventData.Data[6].'#text'
			'User Name' = $i.Event.EventData.Data[1].'#text'
			'SID' = $i.Event.EventData.Data[0].'#text'
			'Domain Name' = $i.Event.EventData.Data[2].'#text'
            'Computer' = ""
			'New Time' = Get-Date $i.Event.EventData.Data[5].'#text' -f s
			'Previous Time' = Get-Date $i.Event.EventData.Data[4].'#text' -f s
			'Change' = $New - $Previous
            'ProcessId' = ""
			'Reason' = ""
            'Process Name' = $i.Event.EventData.Data[7].'#text'
            'Channel' = $i.Event.System.Channel
            'Correlation' = $i.Event.System.Correlation
			}

	}

[xml[]]$xmllog1 = $log1.toXml()
$count1 = $xmllog1.Count

$Events1 = foreach ($e in $xmllog1) {$d++
			
			
			$OldTime = [DateTime] $e.Event.EventData.Data[1].'#text'
			$NewTime = [DateTime] $e.Event.EventData.Data[0].'#text'
            $Reason = if($e.Event.EventData.Data[2].'#text' -eq 1){"An application or system component changed the time"} 
                        elseif ($e.Event.EventData.Data[2].'#text' -eq 2){"System time synchronized with the hardware clock"} 
                        elseif ($e.Event.EventData.Data[2].'#text' -eq 3){"System time adjusted to the new time zone"}
                        else {$e.Event.EventData.Data[2].'#text'}
            
            $versione =     if ($i.Event.System.Version -eq 0) {'Windows Server 2008, Windows Vista'}
                        elseif($i.Event.System.Version -eq 1) {'Windows Server 2012, Windows 8'}
                         else {$i.Event.System.Version}
            
                         
            $Levele = if ($e.Event.System.Level -eq 0 ){"Undefined"}
                        elseif($e.Event.System.Level -eq 1){"Critical"}
                        elseif($e.Event.System.Level -eq 2){"Error"}
                        elseif($e.Event.System.Level -eq 3){"Warning"}
                        elseif($e.Event.System.Level -eq 4){"Information"}
                        elseif($e.Event.System.Level -eq 5){"Verbose"}
			

			#Progress Bar
			write-progress -id 2 -activity "Collecting System entries with EventID=1 - $d of $count1)"  -PercentComplete (($d / $count1) * 100)		
			# Format output fields
			
			[PSCustomObject]@{ 
			'EventID' = $e.Event.System.EventID
            'Time Created' = Get-Date ($e.Event.System.TimeCreated.SystemTime) -format o
			'RecordID' = $e.Event.System.EventRecordID
			'Version' = $versione
            'Level' = $Levele
            'Task' = $e.Event.System.Task
            'Opcode' = $e.Event.System.Opcode
            'PID' = [Convert]::ToInt64(($e.Event.System.Execution.ProcessID),16) 
            'ThreadID' = $e.Event.System.Execution.ThreadID
			'SID' = $e.Event.System.Security.UserID
			'Computer' = $e.Event.System.Computer
			'New Time' = Get-Date $e.Event.EventData.Data[0].'#text' -f s
			'Previous Time' = Get-Date $e.Event.EventData.Data[1].'#text' -f s
			'Change' = $NewTime - $OldTime
            'Reason' = $Reason 
			'Channel' = $e.Event.System.Channel
            'Correlation' = $e.Event.System.Correlation
			}

	}


function Result{
$Events 
$Events1 
}
			
#Format of the txt filename and path:
$filenameFormat = $env:userprofile + "\desktop\TimeEventsAll_" + (Get-Date -Format "dd-MM-yyyy_hh-mm") + ".csv"
Write-host "Selected Rows will be saved as: " -f Yellow -nonewline; Write-Host $filenameFormat -f White

#Output results to screen table (and save selected rows to csv) 		
Result |Out-GridView -PassThru -Title "A total of $count EventID=(4616) & $count1 EventID=(1) entries were found (Time Changed) in $File & File1"|Export-Csv -Path $filenameFormat
#notepad $filenameFormat
[gc]::Collect() 
