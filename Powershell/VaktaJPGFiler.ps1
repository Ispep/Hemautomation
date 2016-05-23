    Skriven av Ispep
    www.automatiserar.se



    Krav
        * Powershell 4.0 eller senare
    

        https://gallery.technet.microsoft.com/scriptcenter/Powershell-FileSystemWatche-dfd7084b
                      

#>
$VerbosePreference = "silentlycontinue"




# VERA
[bool]$script:SendVeraNotifiering    = $false 
[string]$veraIP       = 'VeraIP'                      # Ange namn eller IP till vera om du har en.

# Telldus Live  
[bool]$script:SendTelldusNotifiering = $false 
[int] $script:TelldusBell = '1234567'

# Loggservern



$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 




function Send-MJ-Notifiering{
    param(
    $info 
    )
    Write-Verbose "Tid som diffas: $(Get-Date) -ge $($lasttripped.AddMinutes($Triggtid))"

    if ((Get-Date) -ge ($lasttripped.AddMinutes($Triggtid)))
    {
        $script:lasttripped = Get-Date
        
        return $true
    } 
    else 
    {
        Write-Verbose "Har redan triggat de senaste $triggtid minuterna"
        return $false
    } 

}
 
Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action { 
$name = $Event.SourceEventArgs.Name 
$changeType = $Event.SourceEventArgs.ChangeType 
$timeStamp = $Event.TimeGenerated 

    Write-Host "Filen '$name' skapades klockan $timeStamp - nr $FileCreated" -fore green 
    $tmp = $name.Split("\")
    $FileCreated++

    if (!(((Get-Date).ToShortDateString()) -le $StartDate))
    {
        $StartDate   = (Get-Date).ToShortDateString() 
        $FileCreated = 0
    } 
    else
    {
        Write-Verbose "Samma dag - $StartDate"
    }
    
    if ($SendHTTPNotifiering){
        Invoke-WebRequest "http://$($IpTillLoggserver)/?Kamera/$($tmp[0])/$($tmp[1])/AllToday/$($FileCreated)"
    }
    
    if (Send-MJ-Notifiering -info $tmp[0])
    {
        if ($SendHTTPNotifiering)
        {
            Invoke-WebRequest "http://$($IpTillLoggserver)/?Telldus/bell/$($tmp[0])/$($FileCreated)"
           
        } 
        if ($SendVeraNotifiering){

              Invoke-WebRequest "http://$($veraIP):3480/data_request?id=variableset&DeviceNum=$($veraDevideID)&serviceId=urn:micasaverde-com:serviceId:LightSensor1&Variable=CurrentLevel&Value=$($FileCreated)"
        }

        if ($SendTelldusNotifiering){

            Connect-TelldusLive -Credential (Get-TDCredential)         # Detta fungerar bra om du har Telldus live och hemautomations modulen: https://github.com/Ispep/Hemautomation/blob/master/Powershell/Automatiserar.psm1
            Set-TDDevice -DeviceID $TelldusBell -Action bell           # Detta fungerar bra om du har Telldus live och hemautomations modulen: https://github.com/Ispep/Hemautomation/blob/master/Powershell/Automatiserar.psm1
        }

    }
} 
Clear-Host
write-host "Scriptet startade: $lasttripped"

#Unregister-Event FileCreated  # detta avregistrerar lyssnaren 
