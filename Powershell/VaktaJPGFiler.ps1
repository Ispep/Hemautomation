<#
    Skriven av Ispep
    www.automatiserar.se

    Jag nyttjar scriptet för att läsa av en filstruktur dit webbkameror sparar bilder när rörelse detekteras. 
    När en fil skrivs i mappstrukturen som anges under $folder triggas en händelse.
    Jag nyttjar nu detta för att få en 433MHz ringklocka att blinka när en rörelse på en webbkamera registreras max var 5:e minut. Ändrar jag läge på ringklockan så plingar det med (Vilket inte uppskattades)  

    Om scriptet startas och du behöver göra ändringar glöm då inte att köra raden: Unregister-Event FileCreated 

    Krav
        * Powershell 4.0 eller senare
        * Hemautomations modulen vi har på github ( https://github.com/Ispep/Hemautomation/blob/master/Powershell/Automatiserar.psm1 )
              Behoven mot modulen är följande rader: 
                            Connect-TelldusLive -Credential (Get-TDCredential)    # Detta behövs bara om du har Telldus live!
                            Set-TDDevice -DeviceID 123456 -Action bell            # Detta behövs bara om du har Telldus live!
    

    Funktionen som läser filsystemet bygger på (Register-ObjectEvent) som kommer från :
        https://gallery.technet.microsoft.com/scriptcenter/Powershell-FileSystemWatche-dfd7084b
                      

#>
$VerbosePreference = "silentlycontinue"

# Grundläggande funktion
[string]$folder       = 'D:\LARMMAPP\FTP'           # Mappen som ska övervakas. 
[string]$filter       = '*.jpg'                     # Filtypen som ska övervakas. 

[int]$script:Triggtid = 1                           # Anger hur många minuter det ska vara mellan varje "triggnign (Send-MJ-Notifiering)"


# VERA
[bool]$script:SendVeraNotifiering    = $false 
[string]$veraIP       = 'VeraIP'                      # Ange namn eller IP till vera om du har en.
[int]$veraDevideID    = '220'                         # Ange enhets id i Vera som scriptet ska rapportera antal till ( se luvans Guide på hur du lägger till enheten - http://www.automatiserar.se/hamta-data-fran-webbsidor/)

# Telldus Live  
[bool]$script:SendTelldusNotifiering = $false 
[int] $script:TelldusBell = '1234567'

# Loggservern
[bool]$Script:SendHTTPNotifiering = $false            # Anger om du vill nyttja loggning till http servern som anges ovan, sätts till false annars
[string]$script:IpTillLoggserver = "10.20.30.40:90"  # Anger ip till loggserver dit alla händeler sedan skickas:  (kör det själv till: http://www.automatiserar.se/loggning-med-http/ ) 



 # Ändra ej dessa så vida du inte vet vad du gör! 
[int]$script:FileCreated = 0                       # Används för att se hur många bilder som skapats sedan start.
$script:StartDate = (Get-Date).ToShortDateString() # Hämtar datum för att nolla räknaren varje dag.
$script:lasttripped = get-date                     # Används för att inte utföra nått för ofta.
$fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 




# Funktion för att kunna få in en delay mellan händer och bestämma hur ofta det får ske.
function Send-MJ-Notifiering{
    param(
    $info 
    )
    Write-Verbose "Tid som diffas: $(Get-Date) -ge $($lasttripped.AddMinutes($Triggtid))"

    if ((Get-Date) -ge ($lasttripped.AddMinutes($Triggtid)))
    {
        $script:lasttripped = Get-Date
        Write-host "En händelse registrerades! - från: $info" -ForegroundColor Red
        
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
        Write-Verbose "Satte ny tid $StartDate och nollade räknaren"
    } 
    else
    {
        Write-Verbose "Samma dag - $StartDate"
    }
    
    if ($SendHTTPNotifiering){
        Invoke-WebRequest "http://$($IpTillLoggserver)/?Kamera/$($tmp[0])/$($tmp[1])/AllToday/$($FileCreated)"
    }
    
    # skickar in en fråga för att se om en notifiering skickats inom tidsramen som sattes. Dvs, var det mer än 5 minuter sedan det senast skickades så skickar den igen.
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