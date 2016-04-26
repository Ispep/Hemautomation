<#
Skriven av Ispep
2015-11-16 
www.automatiserar.se 

All Dokumentation är flyttat till Github 

Version 1.9 - 
                 Read-MJ-ImageRGBPixel -imageURL C:\Temp\demoBild.jpg -PixelX 33 -pixelY 33 -PixelArea 2

Version 1.8 - 
    2015-12-26 - Set-mj-ArduinohttpServo
	* gör det möjligt att koppla upp med http till en Arduino och styra ett servo. 

Version 1.7 - 
    2015-12-25 - Send-MJ-ArduinoData
        * gör det möjligt att koppla upp till arudino via en COM port, just nu stödjer funktionen att skicka data.

Version 1.6 - 
    2015-12-24 - Get-MJ-SolUppNer 
        * hämtar hem solens upp och nedgång från internet

    2015-12-23 - Get-MJ-WebCamImage   
        * Laddar hem bilder från webbkameror
        * Stödjer både Dlink och Hikvision native idag
        * Stödjer Inloggning 
#>

###

##### set och get veramodes #### 











function Read-MJ-ImageRGBPixel {
<#
.Synopsis
   Skapat av Ispep 
   2016-04-20 
   Version 2
   www.automatiserar.se
   Funktion för att läsa fram färgen på en viss pixel i en bild.
.DESCRIPTION
   Genom att skicka in en url till en bild och X och Y värdet på en bild returneras ett objekt om bilden.
.EXAMPLE
   raden hämtar ut information om pixlarna X22 och Y33
   Read-MJ-ImageRGBPixel -imageURL C:\temp\DemoBild.jpg -PixelX 22 -pixelY 33

    ImageURL      : C:\Temp\DemoBild.jpg
    PixelX        : 22
    PixelY        : 33
    PixelArea     : 2
    Success       : True
    ImageWith     : 640
    ImageHeight   : 480
    Red           : 11
    Red_Max       : 13
    Red_Avg       : 10
    Red_Min       : 5
    Green         : 11
    Green_Max     : 13
    Green_Avg     : 10
    Green_Min     : 5
    Blue          : 11
    Blue_Max      : 13
    Blue_Avg      : 9
    Blue_Min      : 5
    ScriptVersion : 2

.EXAMPLE
   
#>
    [cmdletbinding()]
    param(
    [Parameter(Mandatory=$true)][string]$imageURL,
    [int]$PixelX,
    [int]$pixelY,
    [int]$PixelArea = 5 # Ange hur stor area runt som ska tas med.
    
    )


    begin
    {
        # Börjar skapa objektet som kommer att returneras
        $scriptversion = 2

        $PixelObjekt=[ordered]@{

        ImageURL      = $([string]$imageURL)
        PixelX        = $([int]$PixelX)
        PixelY        = $([int]$pixelY)
        PixelArea     = $([int]$PixelArea)
        Success       = $([bool]$true)
        ImageWith     = $([int])
        ImageHeight   = $([int])
        Red           = $([int])
        Red_Max       = $([int])
        Red_Avg       = $([int])
        Red_Min       = $([int])
        Green         = $([int])
        Green_Max     = $([int])
        Green_Avg     = $([int])
        Green_Min     = $([int])
        Blue          = $([int])       
        Blue_Max      = $([int])              
        Blue_Avg      = $([int])                 
        Blue_Min      = $([int])
        ScriptVersion = $([int]$scriptversion)
        
        }
        $ImageInfo = New-Object -TypeName psobject -Property $PixelObjekt

        if(!(Test-Path $($ImageInfo.imageURL))){Write-Warning "Kunde ej hitta bilden $($ImageInfo.ImageInfo)"; $ImageInfo.Success = $false;}
    }

    PROCESS{

        if ($ImageInfo.Success){
            Write-Verbose "$($MyInvocation.InvocationName):: Påbörjar inläsning av bild"
                
                Add-Type -AssemblyName System.Drawing
                $MyBitmapImage = [System.Drawing.Bitmap]::FromFile($ImageInfo.imageURL)

                $ImageInfo.ImageHeight = $MyBitmapImage.Height
                $ImageInfo.ImageWith   = $MyBitmapImage.Width

                # definierar max / min värdert som ska gås igenom
                $MinX = $PixelX - $PixelArea
                $MaxX = $pixelX + $PixelArea
                $Miny = $pixelY - $PixelArea
                $MaXy = $pixelY + $PixelArea
            
                Write-Verbose "$($MyInvocation.InvocationName):: MinX = $MinX, MaxX = $MaxX, MinY = $minY, MaxY = $MaXy"
            
                # Läser in bilden.

                if ($MaxX -le $MyBitmapImage.Width -and $MaXy -le $MyBitmapImage.Height -and $MinX -ge 0 -and $minY -ge 0)
                {
                    Write-Verbose "$($MyInvocation.InvocationName):: Pixlarna är inom bildens upplösning" 
                    
                        # om man är inom bilden körs detta.
                    $xValue = $MinX
                    $yValue = $Miny
                        $summa = while ($xValue -le $MaxX -and $yValue -le $MaXy){
        
                                        while ($xValue -le $MaxX)                                        
                                        {
        
                                            $MyBitmapImage.GetPixel($xValue,$yValue)
        
                                            $xValue++
                                        }
                                $xValue = $MinX
                                $yValue++
                                
                                }
                      
                      $tmpImage = $MyBitmapImage.GetPixel($PixelX, $PixelY)
                      $ImageInfo.Red     = [int]$tmpImage.r
                      $ImageInfo.Green   = [int]$tmpImage.g
                      $ImageInfo.Blue    = [int]$tmpImage.b
                        
                      $ImageInfo.Red_Avg   = [int]($summa.r | Measure-Object -Average | Select-Object -ExpandProperty Average)
                      $ImageInfo.Green_Avg = [int]($summa.g | Measure-Object -Average | Select-Object -ExpandProperty Average)
                      $ImageInfo.Blue_Avg  = [int]($summa.b | Measure-Object -Average | Select-Object -ExpandProperty Average)                      
                      $ImageInfo.Red_Max   = [int]($summa.r | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
                      $ImageInfo.Green_Max = [int]($summa.g | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
                      $ImageInfo.Blue_Max  = [int]($summa.b | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
                      $ImageInfo.Red_Min   = [int]($summa.r | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)
                      $ImageInfo.Green_Min = [int]($summa.g | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)
                      $ImageInfo.Blue_Min  = [int]($summa.b | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)


                      $MyBitmapImage.Dispose()
                } 
                
                else  # Området du valt är utanför bilden

                {
                Write-Warning "Du har valt ett x / y värde som är utanför bilden"
                $ImageInfo.Success = $false

                }

        
        }
        else
        {
            Write-Verbose "$($MyInvocation.InvocationName):: Kunde inte hitta filen $($ImageInfo.imageinfo)"
            
        }
        
    }

    END
    {
            return $ImageInfo
               
    }


}




function Get-Mj-VeraMode {
<#
    Funktionen returnerar 
    Value [int]    - 1   , 2  , 3    , 4       ,   
    Mode  [string] - Home, Away Night, Vacation, ERROR

#>

    [cmdletbinding()]
    param(
    $VeraIP = "vera",               # IP Adress till din vera. 
    [switch]$RequireLogin,          # Används om din vera behöver en inloggning.
    [string]$Password    = "",      # Om din vera kräver lösenord så spara lösenordet här
    [string]$UserName    = ""       # Användarnamn till din vera
    )

    if (!(Test-Connection $VeraIP -Count 1)){Write-Warning "Kunde inte koppla upp mot IP: $VeraIP"; break}

    # Börjar hämta hem vilket mode vera är i.

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


<#
.Synopsis
   Laddar och spara telldus behörigheter på ett säkert sätt.
.DESCRIPTION
   Skapat av Ispep 2015-11-21
   Genom att nyttja följande funktion är det möjligt att automatiskt ladda och spara behörigheter på ett säkert sätt för telldus Live. 
.EXAMPLE
   $myCred = Get-TDCredential 
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-TDCredential

{
    Begin
    {
        $PassFile = "$($env:APPDATA)\Telldus.log" # Definerar vart behörigheten ska sparas och laddas från.
    }
    Process
    {
        try 
        {
                
            if (Test-Path $PassFile)
            {    
                Write-Verbose "Behörigheter laddas nu in från $PassFile"
                $Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $((Get-Content $PassFile).Split(";")[0]), $(ConvertTo-SecureString -String ((Get-Content $PassFile).Split(";")[1]) -Force)
                Write-Verbose "Konto: $($Credential.UserName) och lösenord laddades"
            } 
            else 
            {
                $newCred = Get-Credential -Message "Ange epost och lösenord till Telldus Live"
                $Secretkey = convertfrom-securestring -securestring $($newCred.Password)
                Out-File -InputObject "$($newCred.UserName);$($Secretkey)" -FilePath $PassFile 
            }
        }
        catch 
        {
            Write-Error "Kunde inte ladda in sparat användarnamn och lösenord!" 
        }
    }
    End
    {
        $Credential
    }
}

####### Funktion för att ladda bilder från web kameror.


function Get-MJ-WebCamImage
<#
.Synopsis
   Funktionen laddar ner bilder från webbkameror både med och utan lösenord. 
   genom att ange ip eller dns namn till kameran så laddas en bild hem till vald mapp.

   Skapad av: Ispep 
   www.automatiserar.se
   Version 1 
   Skapad: 2015-12-23
.DESCRIPTION
   
   Funktionen laddar hem en bild från webbkameror genom att gå in via web url:er 
   Det finns stöd för att ta emot från pipeline eller direkt. 
   
   
   * kräver kameran https så går det just nu inte att använda funktionen -KameraModell, utan då läggs hela sökvägen i -Webcam
   * blir bilden svart? kontrollera då att du endera har en valt en dlink eller hikvison kamera. Om du har en annan modell så måste du ange sökvägen till kamerans bild url.
   * saknas destinations mappen så visas en varning om att den kommer att skapas.

.EXAMPLE
   Exempel laddar hem en bild från en dlink kamera med hjälp av ip adressen. 
   Get-Automatiserar-WebCamImage -WebCam "10.20.30.39" -Destination D:\temp -KameraModell Dlink
.EXAMPLE
   Exempel laddar hem en bild från en hikvision kamera som kräver inloggning. genom att välja "hikvision" så behöver du själv inte veta sökvägen dit bilden finns på kameran. 

   Get-Automatiserar-WebCamImage -WebCam minkamera -Destination D:\temp -KameraModell Hikvision -username kamerakontot -password kamerapass
.EXAMPLE
   Exempel kommer att ladda hem en bild var 5 sekund tills scriptet stängs eller man trycker CTRL+C 
   while ($true){ (Get-MJ-WebCamImage -KameraModell Dlink -Destination D:\temp -WebCam EnDlinkKamera); Start-Sleep -Seconds 5}

.EXAMPLE 
   Exempel hämtar en bild från en Hikvision kamera med inloggning.
   Get-MJ-WebCamImage -Destination D:\temp -WebCam EnHikvision -username administrator -password hemligtLösen -KameraModell Hikvision

.EXAMPLE
   Exemplet hämtar en bild med hjälp av en direkt url till kameran

   Get-MJ-WebCamImage -WebCam http://10.20.30.39/image/jpeg.cgi -Destination D:\temp
#>
{
    [CmdletBinding()]
    Param
    (
        # Välj vart bilden ska sparas. 
        [Parameter(Mandatory=$true,
                   #ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Ange sökvägen dit bilden ska sparas.")]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()][string]$Destination, 

        # Destination till kameran
        
        [Parameter(Mandatory=$true,
                   #ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Ange IP eller dns namn till kameran")]        
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
                   [string]$WebCam,

        [Parameter(Mandatory=$false,
                   #ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Användarnamn till kameran")]
                   [string]$username,

        [Parameter(Mandatory=$false,
                   #ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Lösenord till kameran")]
                   [string]$password,
        
        [Parameter(Mandatory=$false,
                   #ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Ange ett eget filnamn, avsluta med .jpg")][string]$Filename = '{0}-bild.jpg' -f (get-date -UFormat "%Y-%m-%d_%H-%M-%S"),       
        
        [Parameter(Mandatory=$false, 
                   #ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Ange någon av dom förkonfiguerade kamerorna",
                   ParameterSetName='KameraModeller')]
        [ValidateSet("Dlink", "Foscam", "Hikvision")]
        [Alias("Modeller")] 
        $KameraModell


    )

    Begin
    {
        $scriptversion = 1 #initial version av funktionen. 

    }
    Process
    {

     Write-Verbose "Destination = $Destination"
        Write-Verbose "WebCam = $WebCam"
        Write-Verbose "username = $username"
        Write-Verbose "password = $($password.Length) (längden på lösenordet anges)"
        Write-Verbose "Filename = $Filename"
        Write-Verbose "KameraModell = $KameraModell" 

        # följande objekt returneras alltid efter funktionen kört klart.
        $ReturnResult = New-Object psobject -Property @{

            Status       = [bool]$false
            errors       = $()
            Destination  = [string]""
            Version      = [int]$scriptversion
        }


        $SavePath = (Join-Path -ChildPath $Filename  -Path $Destination) 
        $WC = New-Object System.Net.WebClient
    
        if ($username -ne $null)
        {       
            Write-Verbose "Laddar in behörigheter till webbsidan"
            $requirePassword = $true            
            $WC.Credentials = new-object System.Net.NetworkCredential($username,$password ,$null)
        } 


        if ($WebCam -match "^http"){} else {Write-Verbose "lägger till http:// före `"$WebCam`""; $WebCam = "http://$webcam"}




        # Kontrollerar om det finns en mapp dit bilden ska sparas. 
        if (!(Test-Path $Destination))
        {
            Write-Warning "Mappen $Destination finns inte!"
            New-Item -Path $Destination -ItemType directory -Confirm | Out-Null
            if ($?){Write-Verbose "Mappen $Destination skapades korrekt"}
        }

        Write-Verbose "Kontrollerar om kamera modell är vald" 
      
          switch ($KameraModell){

            'Dlink' {$WebCam = $WebCam + "/image/jpeg.cgi"; Write-Verbose "Switch, dlink vald"; break} # dlink kamera 
            'Foscam' {Write-Verbose "Switch, foscam vald"; break} # Foscam
            'Hikvision' {$webcam = $WebCam + "/Streaming/channels/1/picture"; Write-Verbose "Switch, Hikvision vald"; break} # Hikvision 
            default {Write-Verbose "Ingen kamera modell vald"}  # ingen korrigering
         }

        
        try 
        {
                # kontrollerar om kameran går att pinga
                
                    
                  $wc.DownloadFile($WebCam, $SavePath)   ###
                  if ($?)
                  {
                    
                    $resultstatus = $true
                    $ReturnResult.Destination = $SavePath
                    $ReturnResult.Status = $true
                  
                  }
        }
        catch
        {
                Write-Warning "Kunde inte ladda ner bilden $Filename från $WebCam"
                Write-Warning $($Error[0]).Exception
                $ReturnResult.errors = $($Error[0]).Exception
                $ReturnResult.Status = $false
                
        }


    }
    End
    {
      $ReturnResult  # returnerar ett objekt med hur det har gått.
    }
}

############################################### 

function Get-MJ-SolUppNer {
<#
.Synopsis
   Funktionen går ut på en hemsida och hämtar sol upp / ner för alla kommuner i sverige. 

   Skriven av: Ispep
   2015-12-23 
   Version 1 - första version
.DESCRIPTION
   Scriptet hämtar hem sol upp och sol ner från "http://www.dinstartsida.se/solen-alla-kommuner.asp", så länge dom inte ändrar nått så kommer det att gå att hämta sol upp / ner och få tillbaka dessa som objekt med följande värden:
   * Stad   (string)
   * SolUpp (date time)
   * SolNed (date time)
   * Error  (felinformation)
   * scriptversion (script versionen som körs)
   

.EXAMPLE
   Hämtar hem alla solupp / solned i Sverige 
   Get-MJ-SolUppNer 
.EXAMPLE
   hämtar information om just Härnösand genom att välja -stad och sedan skriva härnösand.

   Get-MJ-SolUppNer -Stad härnösand
.EXAMPLE
    hämtar och sorterar alla städer som en formaterad lista
    

#>
[cmdletbinding()]
param(
        [Parameter(Mandatory=$false,
                   #ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   HelpMessage="Ange den stad du vill se tiden för")]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()][string]$Stad 

)

begin
{
    
}
process
{
    $Webconnected = $false 
    $scriptversion = "1" 

    try
    {
    $regexpfilter = "<tr style=`"background-color:#\w*;;`"><td class=`"small`" align=`"left`"><a href=`"solen-ort\.asp\?id=\d*`">(?<Stad>\D*)</a><\/td><td class=`"small`" align=`"center`">(?<SolUpp>\d*:\d*)<\/td><td class=`"small`" align=`"center`">(?<SolNer>\d*:\d*)"
    $web = ((Invoke-WebRequest -Uri http://www.dinstartsida.se/solen-alla-kommuner.asp).RawContent)
    $Webconnected = $true
    }
    catch
    {
        $myresult = [ordered]@{
    
              Stad = "-"
              SolUpp = [datetime](get-date)
              Solned = [datetime](get-date)
              Error  = [bool]$true
              Scriptversion = [int]$scriptversion
        }
        
    }
    
    if ($Webconnected){
        $allObjects = [regex]::Matches($web,$regexpfilter) | Select -ExpandProperty value | ForEach-Object {

            $_ -match $regexpfilter | Out-Null

            $myresult = [ordered]@{
    
                  Stad = $Matches.stad.Trim() 
                  SolUpp = [datetime](get-date $($Matches.SolUpp.trim()))
                  Solned = [datetime](get-date $($Matches.SolNer.Trim()))
                  Error  = [bool]$false
                  Scriptversion = [int]$scriptversion 
            }
        New-Object psobject -Property $myresult    

        }
    } 
    else 
    {

    $allObjects = New-Object psobject -Property $myresult
    
    }
}
end
{
     if ($Stad -ne $null)
     {
        $Solstatus = $allObjects | Where-Object {$_ -match $Stad} 
        if ($Solstatus.count -eq 0)
        {
            Write-Warning "Ingen stad hittad med namnet $Stad"
        }
        else
        {
            $Solstatus
        }
     }
     else 
     {
        $allObjects
     }
}

}

########################## slut get-mj-soluppner

########################## Send-MJ-Arduinodata 

function Send-MJ-ArduinoData
<#
.Synopsis
   För att enkelt prata med Arduino över COM porten har jag gjort följande funktion.
   Skapad av Ispep
   2015-12-25
   V1 - initial version. 

.DESCRIPTION
   Genom att köra funktionen så kopplar Powershell upp sig mot vald com port och skickar vald text.

.EXAMPLE
    Skickar kommando OPEN till Arduino en gång på COM3 med en baudrate på 9600. 

    Send-MJ-ArduinoData -Data OPEN -Mode Write -ComPort COM3 -BaudRate 9600
.EXAMPLE
    Skivker kommandot CLOSE till Arduinon två gånger på COM3 med en baudrte på 9600

    Send-MJ-ArduinoData -Data CLOSE -Mode Write -ComPort COM3 -BaudRate 9600 -Retryes 2
#>
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Välj vilket data som ska skickas till Arduinon.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Data,
        
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Read", "Write")]
        [string]$Mode,
# Param1 help description
        [Parameter(Mandatory=$true,
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "COM10", "COM11" ,"COM12", "COM13", "COM14" ,"COM15" ,"COM16" ,"COM17" ,"COM18", "COM19", "COM20")]
        [Alias("Port")] 
        $ComPort,
        
        # Param1 help description
        [Parameter(Mandatory=$false,
                   Position=3)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(9600, 19200,38400,57600,74880,115200,230400,250000)]
        [int]$BaudRate = 9600,
        [int]$Retryes  = 1
    )

    Begin
    {
    # SerialPort Class
        
        Write-Verbose "kommer nu att skapa COM objektet" 
        $serialPort = new-Object System.IO.Ports.SerialPort

        # välj COM-port settings
        $serialPort.PortName = $ComPort
        $serialPort.BaudRate = $BaudRate
        $serialPort.WriteTimeout = 500
        $serialPort.ReadTimeout = 3000
        $serialPort.DtrEnable = "true"

        Write-Verbose "bauderate = $BaudRate"

        Write-Verbose "Följande COM port har skapats: $($serialPort.PortName)"
 
    }
    Process
    {
        try 
        {
            $serialPort.Close()
            Write-Verbose "Försöker öppna port $($serialPort.PortName)"
            $serialPort.Open()
            Start-Sleep -Milliseconds 350
        }
        catch
        {
            Write-Warning "Kunde inte koppla upp på första försöket..."
            Start-Sleep -Milliseconds 200 # låter porten öppnas
            $serialPort.Open() 
        }

            Write-Verbose "$($serialPort.PortName) är nu öppnad"
            if ($Mode -eq "Write")
            {
                Write-Verbose "[WRITE]: kommer att skicka $Data till $($serialPort.PortName) $Retryes gånger"
                $i = 1; 
                while ($i -le $Retryes){
                Write-Verbose "[WRITE]: gång $i av $Retryes"                       
                $serialPort.WriteLine("$Data"); 
                Start-Sleep -Milliseconds 300
                $i++ 
                         
                }
            }
            else 
            {
                Write-Verbose "[READ]: kommer att försöka läsa från port $($serialPort.PortName)"
            }

    }
    End
    
    {
        try 
        {
          $serialPort.Close(); # stänger alltid porten när den är klar. 
        }
        catch 
        {
           Write-Warning "Kunde inte stänga porten $($serialPort.PortName)"
        }
    }
}

########################## slut Send-MJ-ArduinoData

########################## set-mj-ArduinohttpServo ##################################################################

function set-mj-ArduinohttpServo {
<#
.Synopsis
   skriven av: Ispep
   skapad:     2015-12-27 

   Funktion för att öppna och stänga ett servo på en Arduino.  
.DESCRIPTION
   funktionen gör det möjligt att styra ett servo 90 grader med http kommandon
.EXAMPLE
    följande rad tänder en röd diod och släcker en grön på Arduinon, samt vrider servot 90 grader.
    set-mj-ArduinohttpServo -mode Lock -IP "10.20.30.40"
.EXAMPLE
    följande rad släcker den röda dioden och tänder en grön diod, servot vrids 90 grader åt motsatt håll.
   set-mj-ArduinohttpServo -mode Open -IP "10.20.30.40"
#>
[cmdletbinding()]
param(
        # Öppna eller stänga Servot 
        [Parameter(Mandatory=$true, 
                   Position=0)]
        [ValidateSet("Lock", "Open")]
        [Alias("Status")] 
        $Mode,
                # Param1 help description
        [Parameter(Mandatory=$true, 
                   Position=1)]
        [Alias("ArduinoIP")] 
        $IP
)


$MyCommandON = 'http://' + $IP + '/?3on'
$MyCommandOFF = 'http://' + $IP + '/?3off'


    if ($mode -eq "Lock")
    {
        Write-Verbose "skickar kommatdo: $MyCommandON"
        if (((Invoke-WebRequest -Uri $MyCommandON).StatusCode) -eq 204){$true} else {$false}
    }
    elseif ($mode -eq "Open")
    {
        Write-Verbose "skickar kommatdo: $MyCommandOFF"
        if (((Invoke-WebRequest -Uri $MyCommandOFF).StatusCode) -eq 204){$true} else {$false}

    }
    else
    {
        Write-Warning "EJ uppmappat kommando!"
    }


}

########################## slut - set-mj-ArduinohttpServo ###########################################################

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

        .EXAMPLE
        SET-TDDevice -DeviceID 123456 -Action bell
     
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
          [ValidateSet("turnOff","turnOn","bell")]
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

function Get-TDDeviceHistory
    {
        <#
        .SYNOPSIS
        Retrieves all events associated with the specified device.

        .DESCRIPTION
        This command will list all events associated with the specified device

        .EXAMPLE
        Get-TDDeviceHistory

        .EXAMPLE
        Get-TDDeviceHistory | Format-Table

        #>

        [cmdletbinding()]
        param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [string] $DeviceID)

        BEGIN {
            if ($Telldus -eq $null) {
                Write-Error "You must first connect using the Connect-TelldusLive cmdlet"
                return
            }
        }

        PROCESS {
            $PostActionURI="http://live.telldus.com/device/history?id=$DeviceID"

            $HistoryEvents = Invoke-RestMethod -Uri $PostActionURI -WebSession $Global:Telldus | select -ExpandProperty History

            foreach ($HistoryEvent in $HistoryEvents)
            {
                $PropertiesToOutput = @{
                                     'DeviceID' = $DeviceID
                                     'State' = switch ($HistoryEvent.state)
                                               {
                                                     1 { "On" }
                                                     2 { "Off" }
                                                    16 { "Dimmed" }
                                                    default { "Unknown" }
                                               }
                                     'Statevalue' = $HistoryEvent.statevalue
                                     'Origin' = $HistoryEvent.Origin;
                                     'EventDate' = (Get-Date "1970-01-01 00:00:00").AddSeconds($HistoryEvent.ts)
                                     }

                $returnObject = New-Object -TypeName PSObject -Property $PropertiesToOutput

                Write-Output $returnObject | Select-Object DeviceID, EventDate, State, Statevalue, Origin
            }
        }

        END { }
    }


function Get-TDSensorHistoryData
    {
        <#
        .SYNOPSIS
        Retrieves sensor data history from Telldus Live!
    
        .DESCRIPTION
        This command will retrieve the sensor history data of the specified sensor.
    
        .EXAMPLE
        Get-TDSensorHistoryData -DeviceID 123456

        .EXAMPLE
        Get-TDSensorHistoryData -DeviceID 123456 | Format-Table

        #>

        [cmdletbinding()]
        param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [string] $DeviceID)

        BEGIN {
            if ($Telldus -eq $null) {
                Write-Error "You must first connect using the Connect-TelldusLive cmdlet"
                return
            }
        }

        PROCESS {
            $PostActionURI="http://live.telldus.com/sensor/history?id=$DeviceID"

            $HistoryDataPoints = Invoke-RestMethod -Uri $PostActionURI -WebSession $Global:Telldus | select -ExpandProperty History

            foreach ($HistoryDataPoint in $HistoryDataPoints)
            {
                $PropertiesToOutput = @{
                                     'DeviceID' = $DeviceID
                                     'Humidity' = ($HistoryDataPoint.data | Where-Object { $_.Name -eq 'humidity' }).value
                                     'Temperature' = ($HistoryDataPoint.data | Where-Object { $_.Name -eq 'temp' }).value
                                     'Date' = (Get-Date "1970-01-01 00:00:00").AddSeconds($HistoryDataPoint.ts)
                                     }

                $returnObject = New-Object -TypeName PSObject -Property $PropertiesToOutput

                Write-Output $returnObject | Select-Object DeviceID, Humidity, Temperature, Date
            }
        }

        END { }
    }

#===================== SLUT Telldus Live funktioner======================
# Created By: Anders Wahlqvist
# Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
#========================================================================
