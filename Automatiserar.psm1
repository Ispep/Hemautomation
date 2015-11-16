
<#
Skriven av Markus Jakobsson 
2015-11-16 
www.automatiserar.se 

Syftet med Scriptet / modulen är att exponera funktonalitet från Veran i Powershell.

Send-MJ-Speak - Ger möjlighet att skicka meddelanden som ljud. 

[CurrentVersion]1.5
[Nyheter]"* Stöd för Telldus Live finns nu tack vare Anders på http://dollarunderscore.azurewebsites.net"
[OLDVersion]"1.4","* Nu går det att kontrollera vilket mode veran är i, samt snabbt byta till ett nytt mode."
[OLDVersion]"1.3","* Nu går det att exportera ut backuperna från vera till en extern enhet."
[OLDVersion]"1.2","* Set-Mj-VeraDevice tillåter ON / Off på enheter med stöd för detta. Schemat exporteras ut på strömbrytare som SwitchService" 
[OLDVersion]"1.1","* Modulen Get-MJ-Verastatus tar nu med alla Z-wave egenskaper"
[OLDVersion]"1.0","* Modulen Get-MJ-Verastatus fungerar nu med Vera UI5 med."
[OLDVersion]"0.9","* Modulen Get-MJ-Verastatus klarar nu av att logga in med användarnamn och lösenord"
[OLDVersion]"0.8","* Modulen kan nu kontrollera vilken version som är installerad","* Mer funktioner för att se nyheter i modulen på WWW.automatiserar.se"
[OLDVersion]"0.7","* Rss läsare från www.automatiserar.se","* Modul för att kontrollera om nyare version av modulen finns på www.automatiserar.se"
[OLDVersion]"0.6","* Uppläsning av data","* Konvertering av UNIX tidsformat till vanligt tidsformat"
[OLDVersion]"0.5","* Första versionen"

V1.5
    Nya funktioner implementerade 2015-11-14 
    
    Helt nya funktioner för Telldus Live finns nu tack vare Anders på http://dollarunderscore.azurewebsites.net
    All cred för Telldus modulerna ska gå till honom och inte mig! 
    
    Genom att köra följande rader är det möjligt att enkelt styra Telldus Live enheter via Powershell

    börja alltid med Connect-TelldusLive i powershell sessionen du startar! 

        För att koppla upp:        Connect-TelldusLive -Credential (Get-Credential)        
        För att lista enheter:     Get-TDDevice
        För att styra enheter:     Set-TDDevice
        För att lista sensorer:    Get-TDSensor
        För att hämta sensordata:  Get-TDSensorData
        för att dimmra en enhet:   Set-TDDimmer
V1.4
    Ny funktion implementerad 2015-02-22:
	     "Get-Mj-VeraMode"
	     "Set-Mj-Veramode"
    
    Funktionen gör det nu möjligt att byta mode i vera, dvs från home till away eller liknande mycket snabbt!.
	
	Följande rad kommer att byta till Night mode om din vera inte kräver inloggning
    	
	    Set-Mj-Veramode -VeraIP DittVeraIP -newmode Night
	
	Följande rad kommer att byta till Night mode om din vera kräver inloggnign

	    Set-Mj-Veramode -VeraIP DittVeraIP -newmode Night-RequireLogin -UserName "DittAnviD" -Password "DittLösenord"


V1.3 
    Ny funktion implemneterad 2015-02-18:
 	    "Get-MJ-VeraBackup"
    
    Funktionen gör det möjligt att exportera ut backuperna från veran.
    
    Om din vera kräver inloggning testa följande:   
    Get-MJ-VeraBackup -veraIP DittVeraIP -FilDestination C:\temp\ -LoginEnabled -UserName "DittKonto" -Pass "DittLösenord" -FilNamn "NamnPåBackupen"

    Om din vera inte kräver inloggning:
    Get-MJ-VeraBackup -veraIP DittVeraIP -FilDestination C:\temp\ -FilNamn "NamnPåBackupen"
V1.2
    Ny funktion implementerad: 
            
            "Get-Mj-VeraDevice"
    
    Funktionen klarar nu av att enkelt starta / stoppa strömbrytare. 

    För att starta enhet 11 exempelvis skriv följande:

        Set-Mj-Veradevice -VeraIP "DittVeraIP" -deviceId 11 -NewStatus ON

    Stänga alla störmbrytare i Vera genom följande rad: 
    Get-MJ-VeraStatus | Where-Object {$_.SwitchService -eq "urn:upnp-org:serviceId:SwitchPower1"} | ForEach-Object {set-Mj-Veradevice -VeraIP "DittVeraIP" -deviceId $_.Enhetsid -NewStatus OFF}

V1.1
     Exponerar fler komponenter till Powershell    

V1.0
     Har nu gjort stöd för Vera med UI5 med.

V0.9
     Lägger till möjlighet att använda användarnamn och lösenord för att logga in i veran.
     Exempel Get-MJ-Verastatus -username DemoUser -password Demo -RequireLogin
V0.8
     Update-MJ-Module - kollar vilken version du har installerad, samt möjliggör test mot internet.
     Testar att uppdatera data i filen.

V0.7
     Get-MJ-AutomatiserarRSS - lägger till ett enkelt sätt att läsa rss feeden från hemsidan

V0.6 

V0.5 
           Första versionen av scriptet.

#>

###

##### set och get veramodes #### 

function Get-Mj-VeraMode {
<#
    Funktionen returnerar 
    Value [int]    - 1   , 2  , 3    , 4       ,   
    Mode  [string] - Home, Away Night, Vacation, ERROR

#>

    [cmdletbinding()]
    param(
    $VeraIP = "vera",                # IP Adress till din vera. 
    [switch]$RequireLogin,          # Används om din vera behöver en inloggning.
    [string]$Password    = "",      # Om din vera kräver lösenord så spara lösenordet här
    [string]$UserName    = ""       # Användarnamn till din vera
    )

    if (!(Test-Connection $VeraIP -Count 1)){Write-Warning "Kunde inte koppla upp mot IP: $VeraIP"; break}

    # Börjar hämta hem vilket mode verea är i.

    if ($RequireLogin)
    {
            # skapar inloggings objekt.
            $Pass = $Password | ConvertTo-SecureString -AsPlainText -Force # eftersom lösenordet tas emot i klartext så ändras detta till en secure string.
            $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $Pass  

        # Loggar in i vera och kollar vilket läge enheten är i.
        Write-Verbose "$($MyInvocation.InvocationName):: Hämtar data med inloggning (Användare $UserName)"
        $Veramode = Invoke-WebRequest -Uri "http://$($VeraIP):3480/data_request?id=variableget&Variable=Mode" -Credential $Cred

    } 
    
    else 
    
    {
        Write-Verbose "$($MyInvocation.InvocationName):: Hämtar data utan inloggning"
       $Veramode = Invoke-WebRequest -Uri "http://$($VeraIP):3480/data_request?id=variableget&Variable=Mode"


    }


    if ($Veramode.StatusCode -eq 200)
    {
        # Lyckat resultat
        Write-Verbose "$($MyInvocation.InvocationName):: Lyckades koppla upp och få statuscode 200"

        $tmpModeValue = switch (($Veramode.Content.trim()))
                       {
                            '1'     {"Home"    ; break}
                            '2'     {"Away"    ; break}
                            '3'     {"Night"   ; break}
                            '4'     {"Vacation"; break}
                            Default {"ERROR"          }
                       }
    
    $VeraModeResult = New-Object -TypeName psobject 
    $VeraModeResult | Add-Member -MemberType NoteProperty -Name "Value" -Value ($Veramode.Content.trim())
    $VeraModeResult | Add-Member -MemberType NoteProperty -Name "Mode"  -Value $tmpModeValue
    
    return $VeraModeResult
        
    }
    
    else 
    
    {
        Write-Verbose "$($MyInvocation.InvocationName):: Fick inte status code 200, kommer att returnera en varning"
        Write-Warning "Fick fel information från veran. Kontrollera vad http svar: $($Veramode.StatusCode) innebär"
    }

}


function Set-Mj-Veramode {
<#
    Funktionen byter läge på vera till någon av följande.

        Home
        Away
        Night
        Vacation 
        
#>

    [cmdletbinding()]
    param(
    $VeraIP = "vera", # IP Adress till din vera. 
    [validateset('Home','Away','Night','Vacation')]$newmode = "",    # Ange vilket läge du vill sätta.                    
    [switch]$RequireLogin,          # Används om din vera behöver en inloggning.
    [string]$Password    = "",      # Om din vera kräver lösenord så spara lösenordet här
    [string]$UserName    = ""       # Användarnamn till din vera
    )

    if ($RequireLogin)
    {
        # skapar inloggings objekt.
        $Pass = $Password | ConvertTo-SecureString -AsPlainText -Force # eftersom lösenordet tas emot i klartext så ändras detta till en secure string.
        $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $Pass  

        # Kontrollera så att veran inte redan är i läget du försöker sätta. 
        $CurrentVeraMode = Get-Mj-VeraMode -VeraIP $VeraIP -RequireLogin -UserName $UserName -Password $Password

            Write-Verbose "$($MyInvocation.InvocationName):: `$CurrentVeraMode.mode = $($CurrentVeraMode.mode) `$newmode = $newmode"

            if ($CurrentVeraMode.mode -eq $newmode)
            {
                Write-Verbose "$($MyInvocation.InvocationName):: Du är redan är redan i $newmode, kommer inte att sätta det igen"
                Write-Warning "Veran är redan satt i $newmode"
            }
            else 
            {
                # Byter här till rätt mode.

            $VeraModeToSet = switch ($newmode)
            {
                 'Home'     {1  ; break}
                 'Away'     {2  ; break}
                 'Night'    {3  ; break}
                 'Vacation' {4  ; break}
                            Default {"ERROR"          }

            }
            Write-Verbose "$($MyInvocation.InvocationName):: Lommer nu att sätta vera mode $veramodetoset, vilket är $newmode"
            
            $VeraModeResultat = Invoke-WebRequest -Uri "http://$($VeraIP):3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=SetHouseMode&Mode=$VeraModeToSet" -Credential $Cred

                if ($(([xml]$VeraModeResultat.Content).SetHouseModeResponse.ok) -eq "OK")
                {
                    Write-Verbose "$($MyInvocation.InvocationName):: Fick ett lyckat svar när mode byttes."
                    return "SUCCESS" 
                } else 
                {
                    Write-Verbose "$($MyInvocation.InvocationName):: Misslyckades med att sätta nytt mode!, fick svaret:$(([xml]$VeraModeResultat.Content).SetHouseModeResponse.ok) "
                    return "ERROR"
                }

            }

    } 
    
    else       ##### Följande del kräver ej inloggnign
     
    {
            

            $CurrentVeraMode = Get-Mj-VeraMode -VeraIP $VeraIP

            Write-Verbose "$($MyInvocation.InvocationName):: `$CurrentVeraMode.mode = $($CurrentVeraMode.mode) `$newmode = $newmode"

            if ($CurrentVeraMode.mode -eq $newmode)
            {
                Write-Verbose "$($MyInvocation.InvocationName):: Du är redan är redan i $newmode, kommer inte att sätta det igen"
                Write-Warning "Veran är redan satt i $newmode"
            }
            else 
            {
                # Byter här till rätt mode.

            $VeraModeToSet = switch ($newmode)
            {
                 'Home'     {1  ; break}
                 'Away'     {2  ; break}
                 'Night'    {3  ; break}
                 'Vacation' {4  ; break}
                            Default {"ERROR"          }

            }
            Write-Verbose "$($MyInvocation.InvocationName):: Lommer nu att sätta vera mode $veramodetoset, vilket är $newmode"
            
            $VeraModeResultat = Invoke-WebRequest -Uri "http://$($VeraIP):3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=SetHouseMode&Mode=$VeraModeToSet"

                if ($(([xml]$VeraModeResultat.Content).SetHouseModeResponse.ok) -eq "OK")
                {
                    Write-Verbose "$($MyInvocation.InvocationName):: Fick ett lyckat svar när mode byttes."
                    return "SUCCESS" 
                } else 
                {
                    Write-Verbose "$($MyInvocation.InvocationName):: Misslyckades med att sätta nytt mode!, fick svaret:$(([xml]$VeraModeResultat.Content).SetHouseModeResponse.ok) "
                    return "ERROR"
                }

            }



    }

}

#### slut set och get veramodes ###

############# Följande möjliggör en backup av backupen i Vera. 
Function Get-MJ-VeraBackup{
    [cmdletbinding()]
    param(
    $veraIP,                         # Ip adress till vera
    $FilDestination = "C:\temp",     # Sökväg dit filen ska sparas C:\temp är default om inte annat anges.
    $FilNamn        = "VeraBackup",  # Namnet på filen som ska sparas ( datum och .tgz adderas )
    [switch]$LoginEnabled,           # Används om lösenord krävs från veran. 
    $UserName,                       # Användarnamn 
    $Password                        # Lösenord

    )

    Write-Verbose "$($MyInvocation.InvocationName):: Hämtar Backup från $veraIP"
    $veraPath = "http://" + $veraIP + "/cgi-bin/cmh/backup.sh"
    
    Write-Verbose "$($MyInvocation.InvocationName):: Hämtar från: $veraPath"

        if (Test-Connection $veraIP -Count 1 -ErrorAction SilentlyContinue)
        {
            Write-Verbose "$($MyInvocation.InvocationName):: Veran svarar på ping"


            ### Kontrollerar om sökvägen dit filen ska sparas finns

            if (Test-Path $FilDestination)
            {
                Write-Verbose "$($MyInvocation.InvocationName):: Sökvägen $FilDestination finns"
            }
            else 
            {
                Write-Verbose "$($MyInvocation.InvocationName):: Sökvägen saknas, kommer att skapa den."
                New-Item -Path $FilDestination -ItemType directory -ErrorVariable FileError | Out-Null

                if ($FileError)
                {
                        Write-Warning "Kunde inte skapa mappen $FilDestination"
                        return "ERROR - Kunde inte Skapa mapp $FilDestination"
                        break
                       
                }
            
            }

            ### mapp skapad 
                
                ### Laddar hem backupen 

                 Write-Verbose "$($MyInvocation.InvocationName):: Börjar ladda hem data"

                $VeraWebData = New-Object System.Net.WebClient
                
                $Totaldestination = Join-Path -Path $FilDestination -ChildPath "$FilNamn-$(Get-Date -UFormat %Y-%m-%d-%H_%M_%S).tgz"

                    IF ($LoginEnabled)
                    {
                            Write-Verbose "$($MyInvocation.InvocationName):: Testar att logga in med lösenord."

                        
                            $Password = $Password | ConvertTo-SecureString -AsPlainText -Force # eftersom lösenordet tas emot i klartext så ändras detta till en secure string.
                            $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $Password    

                            Write-Verbose "$($MyInvocation.InvocationName):: "


                            $VeraWebData.Credentials = $Cred
                            $VeraWebData.Headers.Add([System.Net.HttpRequestHeader]::AcceptEncoding, "gzip")
                            $VeraWebData.DownloadFile($veraPath, $Totaldestination) 

                            Write-Verbose "$($MyInvocation.InvocationName):: Filen nerladdad till $Totaldestination"

                            return "OK - Backup nerladdad till $Totaldestination"

                    } 
                    ELSE 
                    {                
                        Write-Verbose "$($MyInvocation.InvocationName):: Laddar hem från $veraIP utan lösenord"                

                        $VeraWebData.Headers.Add([System.Net.HttpRequestHeader]::AcceptEncoding, "gzip")
                        $VeraWebData.DownloadFile($veraPath, $Totaldestination)

                        Write-Verbose "$($MyInvocation.InvocationName):: Filen nerladdad till $Totaldestination"
                        return "OK - Backup nerladdad till $Totaldestination"
                    }
        } 
        else 
        {
            Write-Verbose "$($MyInvocation.InvocationName):: Veran svarar inte på ping"
            Write-Warning "Kunde inte koppla upp mot $veraIP"
            return "ERROR - Kunde inte koppla upp till $veraIP"
        }

}
########### Slut Vera backup 


####################################################################  Update-Mj-Module


function Update-MJ-Module {
<#
.Synopsis
Funktionen Update-MJ-Module används för att uppdatera modulen över internet, för att detta ska fungera så måste du ha döpt modulen till Automatiserar.psm1
.DESCRIPTION
Modulen Upddate-MJ-Module underlätta för dom som lägger till och kör mitt script, kör man funktionen och väljer:
Update-MJ-Module ?CheckIfUpToDate, då får man direkt information om modulen som du kör är samma version som den som finns på www.automatiserar.se 
Modulen har även stöd för att direkt uppdatera sig och lägga nuvarande version som en .old.

.EXAMPLE
   Update-MJ-Module -CheckIfUpToDate

   Följande kontrollerar om du har samma version som den på www.automatiserar.se
.EXAMPLE
   Update-MJ-Module -UpdateModule

   Följande hämtar hem scriptet från hemsidan och placerar den på samma ställe som nuvarande modul ligger.
   #>
    [cmdletbinding()]
    param(
    [switch]$CheckIfUpToDate, # Kontrollerar vilken version du använder samt kollar vilken version som finns på internet.
    [switch]$UpdateModule     # används om du vill uppdatera modulen nu.
    )
    begin{
            $ModuleFound = $false # lägger in en säkerhet för att kontrollera om modulen finns.
    }
    process{
        $AutomatiserObjekt = New-Object -TypeName psobject  # skapar ett objekt.

        # Används för att kolla i vilken sökväg du har sparat modulen på, denna ska sedan uppdatera modulen med den nya versionen hit om du väljer det.
        ($env:PSModulePath).Split(";") | ForEach-Object {
            
            $currentModulePath = $_   # Sparar ner sökvägen som ska testas.
            Write-Verbose "Kommer nu att kontrollera sökvägen $currentModulePath"

                # kontrollerar om modulen funns under sökvägen.
                if ($automatiserarPath = Get-ChildItem -Filter Automatiserar.psm1 -Recurse -Path $currentModulePath -ErrorAction SilentlyContinue){
                    
                    $ModuleFound = $true # Modulen hittades, sätter failsafe till True
                     
                    Write-Verbose "Hittade modulen under sökvägen $($automatiserarPath.fullname)"  
                
                    # Letar fram vilken version du kör för tillfället.
                    $InstalleradVersion = $((Get-Content $automatiserarPath.FullName).Split("`n") | Where-Object {$_ -match "\[CurrentVersion\]"}).Split(']')[1]
                    
                    Write-Verbose "Du kör version $InstalleradVersion"
                    $AutomatiserObjekt | Add-Member -MemberType NoteProperty -Name "Path" -Value $automatiserarPath.FullName
                
                    Write-Verbose "Den installerade versionen är $InstalleradVersion"
                    $AutomatiserObjekt | Add-Member -MemberType NoteProperty -Name "Installed Version" -Value $([decimal]$InstalleradVersion)
            
            
               } else {Write-Verbose "hittade inte någon modul under sökvägen $currentModulePath som heter Automatiserar.psm1"}
    
       
        }
    }
    end{
        if ($ModuleFound){
            # Kollar om du har samma version som den som finns på internet
            if ($CheckIfUpToDate){
        
                if ([decimal]$InstalleradVersion -ge ([decimal]$versionenOnInternet = (Get-MJ-AutomatiserarModulen -GetLatestVersionInfo).Version)){
                    $true
                    Write-Host "Du har senaste versionen $InstalleradVersion"
                } else{
                    $false
                    write-host "Du har version $InstalleradVersion, Det finns en nyare på internet med version: $versionenOnInternet"
                
                }
            } else {
            Write-Verbose "Du har valt att inte kontrollera om din version är samma som den som finns på internet med -CheckIfUpToDate"
        
            $AutomatiserObjekt
        
            }

        
            if ($UpdateModule){
                    
                Write-Verbose "Kommer nu att uppdatera modulen eftersom du valt -UpdateModule"
                
                Write-Verbose "Laddar ner modulen med hjälp av följande Rad (Get-MJ-AutomatiserarModulen -DownloadScript).script"            

                $newVersionOfScript = (Get-MJ-AutomatiserarModulen -DownloadScript).script

                if ($newVersionOfScript.length -ge 1){

                    Write-Verbose "Scriptet är nu nerladdat och är $($newVersionOfScript.length) Tecken långt"

                    write-host "kommer nu att döpa om $($AutomatiserObjekt.path) till $(Split-Path $AutomatiserObjekt.path)\$((Split-Path -Leaf $AutomatiserObjekt.path).Split(".")[0]).old"
                
                    if (Test-Path "$(Split-Path $AutomatiserObjekt.path)\$((Split-Path -Leaf $AutomatiserObjekt.path).Split(".")[0]).old"){
                        
                            Write-Host "Du har en äldre backup som ligger, är det ok att ta bort den?"
                            Remove-Item "$(Split-Path $AutomatiserObjekt.path)\$((Split-Path -Leaf $AutomatiserObjekt.path).Split(".")[0]).old" -Confirm
                    }
                
                    Rename-Item -Path $($AutomatiserObjekt.path) -NewName "$(Split-Path $AutomatiserObjekt.path)\$((Split-Path -Leaf $AutomatiserObjekt.path).Split(".")[0]).old" -Confirm

                    write-host "kommer nu att skapa en ny fil med följande namn: $($AutomatiserObjekt.path)"
                    $newVersionOfScript | Out-File -FilePath $($AutomatiserObjekt.path) -Confirm
                }

            } else {
                
                Write-Verbose "Du har inte valt att uppdatera modulen eftersom du inte körde med -UpdateModule"

            }
       } else {
       
        Write-Warning "Hittade inte någon modul på din som heter Automatiserar.psm1"

       }

    }    
}

##################################################################  Get-MJ-AutomatiserarModulen 

Function Get-MJ-AutomatiserarModulen {
<#
.Synopsis
Scriptet hämtar hem information från www.automatiserar.se för att visa om det har kommit någon ny version.    
.DESCRIPTION
Om du vill se vad som är nytt i scriptet så har jag gjort en funktion som hämtar hem och visar vad som är nytt i varje version, utöver det så har jag gjort en funktion som laddar ner hela scriptet till en variabel. 
.EXAMPLE
   Get-MJ-AutomatiserarModulen 
   
   Genom att köra följande så får du information om gällande version samt information om ändringar i varje version.
.EXAMPLE
    Get-MJ-AutomatiserarModulen -DownloadScript
    
    Körs följande så laddas scriptet hem och sparas variabeln Script
.EXAMPLE
    (Get-MJ-AutomatiserarModulen -DownloadScript).script | Out-File C:\temp\script.ps1 

    Genom att köra följande så sparas scriptet under C:\temp\script.ps1
.EXAMPLE
    Get-MJ-AutomatiserarModulen -GetLatestVersionInfo

    Följande används för att få fram den senaste versionen som finns på internet. Följande funktion nyttjar den funktionen "Update-MJ-Module -UpdateModule"
    
#>
    [cmdletbinding()]
    param(
    [switch]$GetLatestVersionInfo,  # används för att få ut versionen som finns på internet
    [switch]$DownloadScript         # används för att ladda ner hela scriptet i sin helhet.
    )
    begin{
    try{
    $version = $(invoke-webrequest -uri "http://www.automatiserar.se/wp-content/uploads/2015/11/Automatiserar.txt").content.split("`n") | Where-Object {$_ -match "\[currentversion\]" -or $_ -match "\[Nyheter\]" -or $_ -match "\[OLDVersion\]"}
    } 
    catch{
    Write-Error "Fel"
    }
    
    }
    process{
                $AutoObjektTOExport = New-Object -TypeName psobject 

                if ($GetLatestVersionInfo){
                Write-Verbose "sparar versionsnummer för senaste versionen"
                $LatestVersion = $($version[0].Split(']')[1])
    
                }
                else {

                if (!($DownloadScript)){
                    Write-host "Version på Internet $($version[0].Split(']')[1])" 
                    write-host ""
        
                    write-host "Nyheter i version $($version[0].Split(']')[1])" 
                    write-host ""
                
                    ($version[1].Split(']')[1]).split(",") -replace '"'
                    write-host ""

                    " -------------- Older versions ----------------- "
                }
            $i = 2 # räknare för versioner
            while ($i -le $version.Count){
                $ii = 1 
                if ($version[$i] -match "\]"){
                $Vdata = @($($version[$i].Split(']')[1] -replace '"').Split(","))
                
                if (!($DownloadScript)){
                write-host ""
                write-host "Version: $($vdata[0])"
                write-host ""
                }    
                    while ($ii -le $Vdata.Count){

                       if (!($DownloadScript)){
                       write-host "$($Vdata[$ii])"
                       }

                    $ii++
                    }
        
                }
                $i++
            } 
            }
    }
    end{
            if ($GetLatestVersionInfo){

                $AutoObjektTOExport |  Add-Member -MemberType NoteProperty -Name Version  -Value $([decimal]$LatestVersion)
                            
            }
            
            if ($DownloadScript){

                $AutoObjektTOExport | Add-Member -MemberType NoteProperty -Name Script  -Value $($(invoke-webrequest -uri "http://www.automatiserar.se/wp-content/uploads/2014/12/Automatiserar.txt").Content)
                

            }

    $AutoObjektTOExport
    }

}

##################################################################  Read-MJ-AutomatiserarRSSFeed
function Read-MJ-AutomatiserarRSSFeed {
<#
.Synopsis
   Funktionen Read-MJ-AutomatiserarRSSFeed läser in och visar alla nyheter på www.automtiserar.se
.DESCRIPTION
   Long description
.EXAMPLE
   Read-MJ-AutomatiserarRSSFeed

   Genom att skriva följande så laddas och skrivs RSS feeden från www.automatiserar.se
#>

([xml]$(Invoke-WebRequest -Uri "http://www.automatiserar.se/feed/").Content).rss.channel.ITEM | Select-Object title, pubdate, link

}


##################################################################   Send-MJ-Speak
function Send-MJ-Speak {
<#
.Synopsis
   Funktionen Send-MJ-Speak läser upp text i högtalaren med den inbyggda speech funktionen i Windows 
.DESCRIPTION
   Genom att skicka in text till funktionen via -Message så får du detta uppläst. Tyvärr så fungerar rösten inte allt för bra på svenska så det bästa är att skicka englesk text.
.EXAMPLE
    Send-MJ-Speak -message "Hello, its 4 degree Celsius outside today" 

    Genom att skriva följande så läses detta upp.. vilket är rätt självklart. 
.EXAMPLE 
    Send-MJ-Speak -message "Hello, its $((get-MJ-VeraStatus -veraIP vera | Where-Object {$_.EnhetsID -eq 67}).CurrentTemperature) degree Celsius outside today"

    Om man nyttjar funktionen jag gjort för att hämta information ur Veran så blir det genast mycket intressantare (-veraIP "Vera" är mitt namn i DNS på enheten, Enhetsid 67 är en tempgivare i min vera)
    Genom att skriva följande så får jag temperatur uppläst i realtid.
#>
[cmdletbinding()]
param(
[string]$message = "No information given!",
[int]$SoundVolume     = 100 # hur högt ska de låta? 0 - 100 
)

Add-Type -AssemblyName System.speech
$prata = New-Object System.Speech.Synthesis.SpeechSynthesizer
$prata.Volume = $SoundVolume
$prata.Speak($message)

}


##################################################################
<#
.Synopsis
   Följande funktion hämtar ut alla enheter ur veran, enheterna som hämtas mappas till ett rum och namn. 
.DESCRIPTION
   Funktionen kommer att ändras allt eftersom, för tillfället så hämtas alla enheter ut oavsett om man valt att söka ett enda device. 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

Function get-MJ-VeraStatus {
[cmdletbinding()]
param(
[string]$veraIP      = "Vera",  # ange din vera controllers ip eller namn
[switch]$RequireLogin,          # Används om din vera behöver en inloggning.
[string]$Password    = "",      # Om din vera kräver lösenord så spara lösenordet här
[string]$UserName    = "",      # Användarnamn till din vera
[int]$FindThisDevice            # ange detta om du vill få fram ett enda device.
)

# Lägger till stöd för inloggning i Veran.
if ($RequireLogin){
    $Pass = $Password | ConvertTo-SecureString -AsPlainText -Force # eftersom lösenordet tas emot i klartext så ändras detta till en secure string.
    $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $Pass    
    }

# Namnsättning på Enheter 
$SensorNameZWaveNetwork1      = "Z-wave Controller"     
$SensorNameSceneController1   = "Scene Controller" 
$SensorNameSwitchPower1       = "PowerPlugg"       
$SensorNameCamera1            = "Kamera"            
$SensorNameWOL1               = "Wake On Lan"              
$SensorNameDataMine1          = "Data Mine"          
$SensorNameLightSensor1       = "Ljus Sensor"
$SensorNameSecuritySensor1    = "Säkerhetsbrytare"
$SensorNameTemperatureSensor1 = "Temperaturgivare"
$SensorNameHumiditySensor1    = "Luftfuktighetsgivare"
$SensorNameHaDevice1          = "HaDevice1"          
$SensorNamePingSensor1        = "Ping Sensor"   
$SensorNameVSwitch1           = "Virtuell Knapp"


# slut på namnsättning: 

function UnixTime-TillNormaltid{
[cmdletbinding()]
param(
$Unuxtid   # ange ditt unix datum 
)

if ($Unuxtid -eq 0)
{
    Write-Verbose "$($MyInvocation.MyCommand):: Datum som mottogs är 0, skickar inte ut nått."
} 
else
{
    Write-Verbose "$($MyInvocation.MyCommand):: Innan översättning: $Unuxtid"
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    Write-Verbose "$($MyInvocation.MyCommand):: Efter översättning: $($origin.AddSeconds($Unuxtid))"
    $origin.AddSeconds($Unuxtid)
}

} # end UnixTime-TillNormalTid

# hämtar ut rum och ID.
Function GetAllVeraNames {

# Hämtar in informationen
if ($RequireLogin){

    $veraJsonData = ConvertFrom-Json (Invoke-WebRequest -Uri "http://$($veraIP):3480/data_request?id=sdata" -Credential $Cred).RawContent.Split("`n")[3]
    $veraJsonData
    
    } else {
    
    $veraJsonData = ConvertFrom-Json (Invoke-WebRequest -Uri "http://$($veraIP):3480/data_request?id=sdata").RawContent.Split("`n")[3] 
    $veraJsonData
    
    }

}


# skapar ett objekt av varje enhet:
function Device-ToObject {
[cmdletbinding()]
param(
[object]$CurrentDevice  # ett objekt som ska översättas till ett Powershell Objekt.
)
begin{}
process {
    Write-Verbose "[Device-ToObject] $Tempdevice"

    $PSVeraDevice = New-Object -TypeName psobject
    
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsID"            -Value $CurrentDevice.ID
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Name"                -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Room"                -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "RoomID"                -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Status"              -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Target"              -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Lastupdated"         -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "CurrentLevel"        -Value ""  
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "KWH"                 -Value ""  # power plugg 
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "KWHReading"          -Value ""  # power plugg 
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Watts"               -Value ""  # power plugg
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "CurrentTemperature"  -Value ""  # power plugg
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Armed"               -Value ""  # Dörr brytare
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Tripped"             -Value ""  # Dörr brytare / ping sensor / rörelse vakt 
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "ArmedTripped"        -Value ""  # Dörr brytare
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "LastTrip"            -Value ""  # Dörr brytare
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "BatteryLevel"        -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "BatteryDate"         -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "IPPeriod"            -Value ""  # ping sensor
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "IPAddress"           -Value ""  # ping sensor
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "IPInvert"            -Value ""  # ping sensor
# Nya i Version 1.1
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Neighbors"           -Value ""  # Alla givare
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "PollTxFail"          -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "PollOk"              -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "PollSettings"        -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "NodeInfo"            -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "VersionInfo"         -value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Capabilities"        -value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "FirstConfigured"     -value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "PollNoReply"         -value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Configured"          -Value ""
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "ModeSetting"         -Value "" 
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "LastUpdate"          -Value "" 
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "AutoConfigure"       -Value "" 
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "CommFailure"         -Value "" 
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "CommFailureTime"     -Value "" 
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "Health"              -Value "" 
# Nya i version 1.2
    $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "SwitchService"       -Value "" # exponerar schemat för knappar. 


    $DeviceType = ($($CurrentDevice.states.state).service | Group-Object | Select-Object -ExpandProperty name)[0].split(':')[3] 

    #$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $DeviceType

    $FixedDevice = $false # Detta kontrollerar om jag har hunnit lägga upp översättningen av objeketet.

  switch ($DeviceType)
  {
      'ZWaveNetwork1'      {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameZWaveNetwork1       ; $FixedDevice = $false;break}
      'SceneController1'   {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameSceneController1    ; $FixedDevice = $false;break}
      'SwitchPower1'       {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameSwitchPower1        ; $FixedDevice = $true;break}
      'Camera1'            {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameCamera1             ; $FixedDevice = $false;break}
      'WOL1'               {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameWOL1                ; $FixedDevice = $false;break}
      'DataMine1'          {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameDataMine1           ; $FixedDevice = $false;break}
      'LightSensor1'       {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameLightSensor1        ; $FixedDevice = $true;break}
      'SecuritySensor1'    {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameSecuritySensor1     ; $FixedDevice = $true;break}
      'TemperatureSensor1' {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameTemperatureSensor1  ; $FixedDevice = $true;break}
      'HumiditySensor1'    {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameHumiditySensor1     ; $FixedDevice = $true;break}
      'HaDevice1'          {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameHaDevice1           ; $FixedDevice = $true;break}
      'PingSensor1'        {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNamePingSensor1         ; $FixedDevice = $true;break}
      'VSwitch1'           {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameVSwitch1            ; $FixedDevice = $true;break}
      'ZWaveDevice1'       {$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $SensorNameZWaveDevice1        ; $FixedDevice = $true;break}
      Default {Write-Warning "[Device-ToObject][Switch] Enheten $DeviceType är inte upplagd!";$PSVeraDevice | Add-Member -MemberType NoteProperty -Name "EnhetsTyp" -Value $DeviceType}
  }

  $PSVeraDevice | Add-Member -MemberType NoteProperty -Name "ObjektiferadEnhet" -Value $FixedDevice


  ### default som ska finnas på alla enheter...

  if ($FixedDevice)
  {
    # följande läggs till på alla enheter
            $PSVeraDevice.Neighbors          = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "Neighbors"}).value 
            $PSVeraDevice.PollTxFail         = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "PollTxFail"}).value 
            $PSVeraDevice.PollOk             = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "PollOk"}).value 
            $PSVeraDevice.PollNoReply        = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "PollNoReply"}).value
            $PSVeraDevice.PollSettings       = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "PollSettings"}).value         
            $PSVeraDevice.NodeInfo           = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "NodeInfo"}).value
            $PSVeraDevice.VersionInfo        = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "VersionInfo"}).value
            $PSVeraDevice.Health             = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "Health"}).value            
            $PSVeraDevice.Capabilities       = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:ZWaveDevice1" -and $_.variable -eq "Capabilities"}).value
            
            
            $PSVeraDevice.FirstConfigured    = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "FirstConfigured"}).value                        
            $PSVeraDevice.Configured         = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "Configured"}).value
            $PSVeraDevice.ModeSetting        = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "ModeSetting"}).value
            $PSVeraDevice.LastUpdate         = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "LastUpdate"}).value
            $PSVeraDevice.AutoConfigure      = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "AutoConfigure"}).value
            $PSVeraDevice.CommFailure        = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "CommFailure"}).value
            $PSVeraDevice.CommFailureTime    = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "CommFailureTime"}).value

  
  }
    
  Write-Verbose "[Device-ToObject] Ã–versätter enheten till ett objekt"

  # följande är av enhetstypen strömbrytare.
  if ($DeviceType -eq "SwitchPower1"){
    
        # ta med 
            #    SwitchPower1
            #    EnergyMetering1   ( detta finns bara om enheten stödjer detta )

            $PSVeraDevice.SwitchService      = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:upnp-org:serviceId:SwitchPower1"}).service
            $PSVeraDevice.Status             = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:upnp-org:serviceId:SwitchPower1" -and $_.variable -eq "Status"}).value
            $PSVeraDevice.Target             = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:upnp-org:serviceId:SwitchPower1" -and $_.variable -eq "Target"}).value
            $PSVeraDevice.KWH                = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:EnergyMetering1" -and $_.variable -eq "KWH"}).value
            $PSVeraDevice.KWHReading         = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:EnergyMetering1" -and $_.variable -eq "KWHReading"}).value
            $PSVeraDevice.Watts              = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:EnergyMetering1" -and $_.variable -eq "Watts"}).value

          
     

  } # slut SwitchPower1

  if ($DeviceType -eq "LightSensor1"){

        $PSVeraDevice.CurrentLevel = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:LightSensor1" -and $_.variable -eq "CurrentLevel"}).value    # man kan ha flera enheter här!
        $PSVeraDevice.Lastupdated = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "LastUpdate"}).value

  } # end LightSensor1


  if ($DeviceType -eq "TemperatureSensor1"){


        $PSVeraDevice.CurrentTemperature = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:upnp-org:serviceId:TemperatureSensor1" -and $_.variable -eq "CurrentTemperature"}).value
        

  } # end TemperatureSensor1


  if ($DeviceType -eq "SecuritySensor1"){


       $PSVeraDevice.Armed           = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:SecuritySensor1" -and $_.variable -eq "Armed"}).value
       $PSVeraDevice.Tripped         = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:SecuritySensor1" -and $_.variable -eq "Tripped"}).value
       $PSVeraDevice.ArmedTripped    = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:SecuritySensor1" -and $_.variable -eq "ArmedTripped"}).value
       $PSVeraDevice.LastTrip        = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:SecuritySensor1" -and $_.variable -eq "LastTrip"}).value
       $PSVeraDevice.BatteryDate     = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "BatteryDate"}).value 
       $PSVeraDevice.BatteryLevel    = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HaDevice1" -and $_.variable -eq "BatteryLevel"}).value 


  } # end SecuritySensor1


  if ($DeviceType -eq "VSwitch1"){

       $PSVeraDevice.Status             = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:upnp-org:serviceId:VSwitch1" -and $_.variable -eq "Status"}).value
    
  } # end VSwitch1


  if ($DeviceType -eq "HumiditySensor1"){

 
  
      $PSVeraDevice.CurrentLevel = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:HumiditySensor1" -and $_.variable -eq "CurrentLevel"}).value    # man kan ha flera enheter här!


  } # end HumiditySensor1


  if ($DeviceType -eq "PingSensor1"){

    #$CurrentDevice.states.state

    $PSVeraDevice.IPPeriod      = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:demo-ted-striker:serviceId:PingSensor1" -and $_.variable -eq "Period"}).value    # man kan ha flera enheter här!
    $PSVeraDevice.IPAddress     = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:demo-ted-striker:serviceId:PingSensor1" -and $_.variable -eq "Address"}).value    # man kan ha flera enheter här!
    $PSVeraDevice.IPInvert      = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:demo-ted-striker:serviceId:PingSensor1" -and $_.variable -eq "Invert"}).value    # man kan ha flera enheter här!
    $PSVeraDevice.Tripped       = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:SecuritySensor1" -and $_.variable -eq "Tripped"}).value    # man kan ha flera enheter här!
    $PSVeraDevice.LastTrip      = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:SecuritySensor1" -and $_.variable -eq "LastTrip"}).value    # man kan ha flera enheter här!
    $PSVeraDevice.Armed         = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:SecuritySensor1" -and $_.variable -eq "Armed"}).value    # man kan ha flera enheter här!
    $PSVeraDevice.ArmedTripped  = (($CurrentDevice.states.state) | Where-Object {$_.service -eq "urn:micasaverde-com:serviceId:SecuritySensor1" -and $_.variable -eq "ArmedTripped"}).value    # man kan ha flera enheter här!


  } # end PingSensor1

 

}
end {

        # översätter så man slipper Unix Time i powershell...
        if ($PSVeraDevice.LastTrip){
        $PSVeraDevice.LastTrip = UnixTime-TillNormaltid -Unuxtid $PSVeraDevice.LastTrip
        }
        if ($PSVeraDevice.Lastupdated){
        $PSVeraDevice.Lastupdated = UnixTime-TillNormaltid -Unuxtid $PSVeraDevice.Lastupdated
        }
        if ($PSVeraDevice.BatteryDate){
        $PSVeraDevice.BatteryDate = UnixTime-TillNormaltid -Unuxtid $PSVeraDevice.BatteryDate
        }
        if ($PSVeraDevice.KWHReading){
        $PSVeraDevice.KWHReading = UnixTime-TillNormaltid -Unuxtid $PSVeraDevice.KWHReading
        }
        if ($PSVeraDevice.CommFailureTime){
        $PSVeraDevice.CommFailureTime = UnixTime-TillNormaltid -Unuxtid $PSVeraDevice.CommFailureTime
        }
        if ($PSVeraDevice.LastUpdate){
        $PSVeraDevice.LastUpdate = UnixTime-TillNormaltid -Unuxtid $PSVeraDevice.LastUpdate
        }
        if ($PSVeraDevice.FirstConfigured){
        $PSVeraDevice.FirstConfigured = UnixTime-TillNormaltid -Unuxtid $PSVeraDevice.FirstConfigured
        }


# ta fram namn och rum till enheten 

        $tmpdevicInfoname = $enhetsInfon.devices | Where-Object {$_.id -eq $PSVeraDevice.EnhetsID} 

        $PSVeraDevice.name = $tmpdevicInfoname.name
        $PSVeraDevice.room = ($enhetsInfon.rooms | Where-Object {$_.id -eq $tmpdevicInfoname.room}).name
        $PSVeraDevice.roomID = $tmpdevicInfoname.room
$PSVeraDevice


}
   


}

# Verifierar så att enheten är aktiv.
if (!(Test-Connection $veraIP -Count 1 -ErrorAction SilentlyContinue)){Write-Error "kunde ej hitta $veraIP"; break} else {Write-Verbose "[Test-Connection]`$VeraIP = svarar på ping"}


$enhetsInfon = GetAllVeraNames
New-Variable VeraData
# Hämtar in informationen 
if ($RequireLogin){
$veraData = Invoke-WebRequest -Uri "http://$($veraIP):3480/data_request?id=status&output_format=xml" -Credential $Cred
} else {
$veraData = Invoke-WebRequest -Uri "http://$($veraIP):3480/data_request?id=status&output_format=xml"
}

# fortsätter bara om man fick korrket web response.
if ($veraData.StatusCode -eq 200){

    if ($veraData.content[0] -eq "<"){
    
    # data som ska processas 
    $WorkData = ([xml]$veraData.Content).root
    } else {
    
    # Nytt för att supportera Vera UI5
    
    $Rcounter = 3; 
    $RUnit    = @($veraData.RawContent.Split("`n"))

        $rawResult = while ($Rcounter -le $RUnit.count){

        $RUnit[$Rcounter]

        $Rcounter++
        }
    
    $WorkData = ([xml]$rawResult).root

    }
    Write-Verbose "[Workdata] Antal Enheter hittade $($WorkData.devices.ChildNodes.count)"

    Write-Verbose "[Workdata] Kontrollerar nu vad som finns i $FindThisDevice"
    # om du söker efter en enda enhet så körs denna rad.
    if ($FindThisDevice -ge 1){

    Write-Verbose "Du har valt att söka efter enbart $FindThisDevice"

    # Skickar bara in en enda enhet som den finns. 
    $WorkData.devices.device | Where-Object {$_.id -eq $FindThisDevice} | ForEach-Object {Device-ToObject -CurrentDevice $_}

    } else {

    # Skickar in alla enheter. 
    $WorkData.devices.device | ForEach-Object {Device-ToObject -CurrentDevice $_}
    
    }

} 
else 
{
    Write-Error "Felande status kod från webresponse!, fick inte status 200"    
}













} # end Get-MJ-VeraStatus

###########


function Set-Mj-VeraDevice {
    [cmdletbinding()]
    param(
    [parameter(Mandatory=$true)][int]$deviceId,
    [parameter(Mandatory=$true)][ValidateSet('ON','OFF',ignorecase=$true)][string]$NewStatus,
    $VeraIP = "vera",                # IP Adress till din vera. 
    [switch]$RequireLogin,          # Används om din vera behöver en inloggning.
    [string]$Password    = "",      # Om din vera kräver lösenord så spara lösenordet här
    [string]$UserName    = ""       # Användarnamn till din vera
    )
    $NewSwitchStatus = 0  # av eller på via HTTP
    $PowerSwitchScheme = "urn:upnp-org:serviceId:SwitchPower1" # Schemat för strömbrytare.
    if ($NewStatus -eq "ON")
    {
        Write-Verbose "$($MyInvocation.InvocationName):: `$NewStatus = 1"
        $NewSwitchStatus = 1
    } 
    else 
    {
        Write-Verbose "$($MyInvocation.InvocationName):: `$NewStatus = 0"
        $NewSwitchStatus = 0
    }

    Write-Verbose "$($MyInvocation.InvocationName):: `$deviceid = $deviceid"
    Write-Verbose "$($MyInvocation.InvocationName):: `$NewStatus = $NewStatus"
    Write-Verbose "$($MyInvocation.InvocationName):: `$RequireLogin = $RequireLogin"
    Write-Verbose "$($MyInvocation.InvocationName):: `$UserName = $UserName"
    Write-Verbose "$($MyInvocation.InvocationName):: `$Password = (Längden på lösenordet): $($Password.Length)"

    
    # här lagras om rätt typ av enhet hittades. 
    $SetResultat = get-MJ-VeraStatus -veraIP $VeraIP -FindThisDevice $deviceId

    if ($SetResultat.EnhetsID -eq $deviceId -and $SetResultat.SwitchService -eq $PowerSwitchScheme)
    {
        Write-Verbose "$($MyInvocation.InvocationName):: Hittade enhet $deviceId med schema $($SetResultat.SwitchService), Fortsätter"
        Write-Verbose "Kommer nu att byta status på $($SetResultat.name) i rummet $($SetResultat.room)"
        
        Invoke-WebRequest -Uri "http://$($veraip):3480/data_request?id=lu_action&output_format=xml&DeviceNum=$($deviceId)&serviceId=$($PowerSwitchScheme)&action=SetTarget&newTargetValue=$($NewSwitchStatus)" | Out-Null
        Write-host "Bytte status på ID $deviceId till $NewStatus (Namn: `"$($SetResultat.name)`" i rummet `"$($SetResultat.room)`")"
    }
    else 
    {
        Write-Verbose "$($MyInvocation.InvocationName):: Felande enhet. $deviceId har schema `"$($SetResultat.SwitchService)`", det skulle ha varit `urn:upnp-org:serviceId:SwitchPower1`""
        Write-Warning "$($MyInvocation.InvocationName):: Felande enhet. $deviceId har schema `"$($SetResultat.SwitchService)`", det skulle ha varit `urn:upnp-org:serviceId:SwitchPower1`""
    }


}

##########################################################################################################################################################################################################################
##########################################################################################################################################################################################################################
############################################################ Externa moduler som vi fått ok att lägga med i modulen ######################################################################################################
##########################################################################################################################################################################################################################
##########################################################################################################################################################################################################################



#===================== Start Telldus Live funktioner======================
# Created By: Anders Wahlqvist
# Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
#========================================================================   

    #========================================================================
    # Created By: Anders Wahlqvist
    # Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
    #========================================================================     
    function Connect-TelldusLive
    {
        [cmdletbinding()]
        param(
              [Parameter(Mandatory=$True)]
              [System.Management.Automation.PSCredential] $Credential)
     
     
        $LoginPostURI="https://login.telldus.com/openid/server?openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.mode=checkid_setup&openid.return_to=http%3A%2F%2Fapi.telldus.com%2Fexplore%2Fclients%2Flist&openid.realm=http%3A%2F%2Fapi.telldus.com&openid.ns.sreg=http%3A%2F%2Fopenid.net%2Fextensions%2Fsreg%2F1.1&openid.sreg.required=email&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select#"
        $turnOffURI="http://api.telldus.com/explore/device/turnOff"
     
        $TelldusWEB = Invoke-WebRequest $turnOffURI -SessionVariable Global:Telldus
     
        $form = $TelldusWEB.Forms[0]
        $form.Fields["email"] = $Credential.UserName
        $form.Fields["password"] = $Credential.GetNetworkCredential().Password
     
        $TelldusWEB = Invoke-WebRequest -Uri $LoginPostURI -WebSession $Global:Telldus -Method POST -Body $form.Fields
     
        $form = $null
     
        [gc]::Collect()
    }
    
    #========================================================================
    # Created By: Anders Wahlqvist
    # Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
    #========================================================================    
    function Get-TDDevice
    {
        <#
        .SYNOPSIS
        Retrieves all devices associated with a Telldus Live! account.
     
        .DESCRIPTION
        This command will list all devices associated with an Telldus Live!-account and their current status and other information.
     
        .EXAMPLE
        Get-TDDevice
     
        .EXAMPLE
        Get-TDDevice | Format-Table
     
        #>
     
        if ($Telldus -eq $null) {
            Write-Error "You must first connect using the Connect-TelldusLive cmdlet"
            return
        }
     
        $PostActionURI="http://api.telldus.com/explore/doCall"
        $Action='list'
        $SupportedMethods=19
     
        $request = @{'group'='devices';'method'= $Action;'param[supportedMethods]'= $SupportedMethods;'responseAsXml'='xml'}
     
        [xml] $ActionResults=Invoke-WebRequest -Uri $PostActionURI -WebSession $Global:Telldus -Method POST -Body $request
     
        $Results=$ActionResults.devices.ChildNodes
     
        foreach ($Result in $Results)
        {
            $PropertiesToOutput = @{
                                 'Name' = $Result.name;
                                 'State' = switch ($Result.state)
                                           {
                                                 1 { "On" }
                                                 2 { "Off" }
                                                16 { "Dimmed" }
                                                default { "Unknown" }
                                           }
                                 'DeviceID' = $Result.id;
                                 
     
                                 'Statevalue' = $Result.statevalue
                                 'Methods' = switch ($Result.methods)
                                             {
                                                 3 { "On/Off" }
                                                19 { "On/Off/Dim" }
                                                default { "Unknown" }
                                             }
                                 'Type' = $Result.type;
                                 'Client' = $Result.client;
                                 'ClientName' = $Result.clientName;
                                 'Online' = switch ($Result.online)
                                            {
                                                0 { $false }
                                                1 { $true }
                                            }
                                 }
     
            $returnObject = New-Object -TypeName PSObject -Property $PropertiesToOutput
     
            Write-Output $returnObject | Select-Object Name, DeviceID, State, Statevalue, Methods, Type, ClientName, Client, Online
        }
    }
    
    #========================================================================
    # Created By: Anders Wahlqvist
    # Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
    #========================================================================    
    function Set-TDDevice
    {
     
        <#
        .SYNOPSIS
        Turns a device on or off.
     
        .DESCRIPTION
        This command can set the state of a device to on or off through the Telldus Live! service.
     
        .EXAMPLE
        Set-TDDevice -DeviceID 123456 -Action turnOff
     
        .EXAMPLE
        Set-TDDevice -DeviceID 123456 -Action turnOn
     
        .PARAMETER DeviceID
        The DeviceID of the device to turn off or on. (Pipelining possible)
     
        .PARAMETER Action
        What to do with that device. Possible values are "turnOff" or "turnOn".
     
        #>
     
        [CmdletBinding()]
        param(
     
          [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
          [Alias('id')]
          [string] $DeviceID,
          [Parameter(Mandatory=$True)]
          [ValidateSet("turnOff","turnOn")]
          [string] $Action)
     
     
        BEGIN {
            if ($Telldus -eq $null) {
                Write-Error "You must first connect using the Connect-TelldusLive cmdlet"
                return
            }
     
            $PostActionURI = "http://api.telldus.com/explore/doCall"
        }
     
        PROCESS {
     
            $request = @{'group'='device';'method'= $Action;'param[id]'= $DeviceID;'responseAsXml'='xml'}
     
            [xml] $ActionResults=Invoke-WebRequest -Uri $PostActionURI -WebSession $Global:Telldus -Method POST -Body $request
     
            $Results=$ActionResults.device.status -replace "\s"
     
            Write-Verbose "Doing action $Action on device $DeviceID. Result: $Results."
        }
    }
    
    #========================================================================
    # Created By: Anders Wahlqvist
    # Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
    #========================================================================    
    function Get-TDSensor
    {
        <#
        .SYNOPSIS
        Retrieves all sensors associated with a Telldus Live! account.
     
        .DESCRIPTION
        This command will list all sensors associated with an Telldus Live!-account and their current status and other information.
     
        .EXAMPLE
        Get-TDSensor
     
        .EXAMPLE
        Get-TDSensor | Format-Table
     
        #>
     
        if ($Telldus -eq $null) {
            Write-Error "You must first connect using the Connect-TelldusLive cmdlet"
            return
        }
     
        $sensorListURI="http://api.telldus.com/explore/sensors/list"
        $PostActionURI="http://api.telldus.com/explore/doCall"
     
     
        $SensorList=Invoke-WebRequest -Uri $sensorListURI -WebSession $Global:Telldus
        $SensorListForm=$SensorList.Forms
     
        $ActionResults=$null
     
        [xml] $ActionResults=Invoke-WebRequest -Uri $PostActionURI -WebSession $Global:Telldus -Method POST -Body $SensorListForm.Fields
        [datetime] $TelldusDate="1970-01-01 00:00:00"
     
        $TheResults=$ActionResults.sensors.ChildNodes
     
        foreach ($Result in $TheResults) {
            $SensorInfo=$Result
     
            $DeviceID=$SensorInfo.id.trim()
            $SensorName=$SensorInfo.name.trim()
            $SensorLastUpdated=$SensorInfo.lastupdated.trim()
            $SensorLastUpdatedDate=$TelldusDate.AddSeconds($SensorLastUpdated)
            $clientid=$SensorInfo.client.trim()
            $clientName=$SensorInfo.clientname.trim()
            $sensoronline=$SensorInfo.online.trim()
     
            $returnObject = New-Object System.Object
            $returnObject | Add-Member -Type NoteProperty -Name DeviceID -Value $DeviceID
            $returnObject | Add-Member -Type NoteProperty -Name Name -Value $SensorName
            $returnObject | Add-Member -Type NoteProperty -Name LocationID -Value $clientid
            $returnObject | Add-Member -Type NoteProperty -Name LocationName -Value $clientName
            $returnObject | Add-Member -Type NoteProperty -Name LastUpdate -Value $SensorLastUpdatedDate
            $returnObject | Add-Member -Type NoteProperty -Name Online -Value $sensoronline
     
            Write-Output $returnObject
        }
    }
    
    
    #========================================================================
    # Created By: Anders Wahlqvist
    # Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
    #========================================================================    
    function Get-TDSensorData
    {
        <#
        .SYNOPSIS
        Retrieves the sensordata of specified sensor.
     
        .DESCRIPTION
        This command will retrieve the sensordata associated with the specified ID.
     
        .EXAMPLE
        Get-TDSensorData -DeviceID 123456
     
        .PARAMETER DeviceID
        The DeviceID of the sensor which data you want to retrieve.
     
        #>
     
        [CmdletBinding()]
        param(
     
          [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] [Alias('id')] [string] $DeviceID)
     
        BEGIN {
            if ($Telldus -eq $null) {
                Write-Error "You must first connect using the Connect-TelldusLive cmdlet"
                return
            }
     
            $sensorDataURI="http://api.telldus.com/explore/sensor/info"
            $PostActionURI="http://api.telldus.com/explore/doCall"
        }
     
        PROCESS {
            $request = @{'group'='sensor';'method'= 'info';'param[id]'= $DeviceID;'responseAsXml'='xml'}
     
            [xml] $ActionResults=Invoke-WebRequest -Uri $PostActionURI -WebSession $Global:Telldus -Method POST -Body $request
            [datetime] $TelldusDate="1970-01-01 00:00:00"
     
            $SensorInfo=$ActionResults.sensor
            $SensorData=$ActionResults.sensor.data
     
            $SensorName=$SensorInfo.name.trim()
            $SensorLastUpdated=$SensorInfo.lastupdated.trim()
            $SensorLastUpdatedDate=$TelldusDate.AddSeconds($SensorLastUpdated)
            $clientName=$SensorInfo.clientname.trim()
            $SensorTemp=($SensorData | ? name -eq "temp").value | select -First 1
            $SensorHumidity=($SensorData | ? name -eq "humidity").value | select -First 1
     
            $returnObject = New-Object System.Object
            $returnObject | Add-Member -Type NoteProperty -Name DeviceID -Value $DeviceID
            $returnObject | Add-Member -Type NoteProperty -Name Name -Value $SensorName
            $returnObject | Add-Member -Type NoteProperty -Name LocationName -Value $clientName
            $returnObject | Add-Member -Type NoteProperty -Name Temperature -Value $SensorTemp
            $returnObject | Add-Member -Type NoteProperty -Name Humidity -Value $SensorHumidity
            $returnObject | Add-Member -Type NoteProperty -Name LastUpdate -Value $SensorLastUpdatedDate
     
            Write-Output $returnObject
        }
    }
    
    
    #========================================================================
    # Created By: Anders Wahlqvist
    # Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
    #========================================================================    
    function Set-TDDimmer
    {
        <#
        .SYNOPSIS
        Dims a device to a certain level.
     
        .DESCRIPTION
        This command can set the dimming level of a device to through the Telldus Live! service.
     
        .EXAMPLE
        Set-TDDimmer -DeviceID 123456 -Level 89
     
        .EXAMPLE
        Set-TDDimmer -Level 180
     
        .PARAMETER DeviceID
        The DeviceID of the device to dim. (Pipelining possible)
     
        .PARAMETER Level
        What level to dim to. Possible values are 0 - 255.
     
        #>
     
        [CmdletBinding()]
        param(
     
          [Parameter(Mandatory=$True,
                     ValueFromPipeline=$true,
                     ValueFromPipelineByPropertyName=$true,
                     HelpMessage="Enter the DeviceID.")] [Alias('id')] [string] $DeviceID,
     
          [Parameter(Mandatory=$True,
                     HelpMessage="Enter the level to dim to between 0 and 255.")]
          [ValidateRange(0,255)]
          [int] $Level)
     
     
        BEGIN {
     
            if ($Telldus -eq $null) {
                Write-Error "You must first connect using the Connect-TelldusLive cmdlet"
                return
            }
     
            $PostActionURI="http://api.telldus.com/explore/doCall"
            $Action='dim'
        }
     
        PROCESS {
     
            $request = @{'group'='device';'method'= $Action;'param[id]'= $DeviceID;'param[level]'= $Level;'responseAsXml'='xml'}
     
            [xml] $ActionResults=Invoke-WebRequest -Uri $PostActionURI -WebSession $Global:Telldus -Method POST -Body $request
     
            $Results=$ActionResults.device.status -replace "\s"
     
            Write-Verbose "Dimming device $DeviceID to level $Level. Result: $Results."
        }
    }

#===================== SLUT Telldus Live funktioner======================
# Created By: Anders Wahlqvist
# Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
#========================================================================
