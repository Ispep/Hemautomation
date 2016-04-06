<#

SKAPAT AV : ISPEP 
Blogg:      www.Automatiserar.se 

Efter att ha skrivit några inlägg på www.automatiserar.se om att skicka sms och sedan insett att jag inte delat själva "motorn" jag nyttar. 
Dvs min Powershell server. 

Här är servern, den stödjer just att skicka SMS, logga data och läsa upp data.

$port=54320 <== om du väljer att nyttja porten eller ta en annan GLÖM inte att öppna i brandväggen på klienten! 
$serverIP = "Din servers IP" Ange IP på klienten du kör scriptet på
$ComPort =  "COM4"           Ange COM porten för ditt modem som ska skicka sms:et, i mitt fall blev det COM4
$ModemSpeed = 9600           Ange hastigheten för ditt modem, i mitt fall blev det 9600
$loggpath   = C:\temp\       Ange mappen dit du vill att loggfilen ska skapas.
För att köra scriptet i powershell kan du behöva köra följande rad:
    Set-ExecutionPolicy remotesigned   # detta gör att du får köra script på ditt system. 

v 1.0 [2016-04-06] - 
        Buggfix - Favicon och teckenuppsättning

V 0.9 [2016-04-05] - 
    * Klara nu att ta emot och verifiera mobilnummer och meddelande

    Buggar:
    
    Problem med ÅÄÖ i SMS tyvärr..
    
    
Exempel: 
    vid korrekt skickat sms returneras: "SMS-OK" bodyn på sidan

    För att skicka ett sms skriv följande rad:
        http://10.20.30.40:54320/?SMS/0701234567/Ett meddelande

        detta returnerar sedan följande i webbläsaren om det gick iväg ett sms: 
            SMS-OK
   
   För att få mer information om vad som händer i programmet går det att ändra till 
   Följande värde $VerbosePreference från "SilentlyContinue" till ”Continue”

#>
 

param ($port=54320,$serverIP="10.20.30.40",$ComPort="COM4",[int]$ModemSpeed=9600,$loggpath = "C:\Temp\Loggar")
$VerbosePreference = "silentlyContinue"
[void][reflection.Assembly]::loadWithPartialName("system.net.sockets")

cls
if (!(Test-Path $loggpath)){Write-Warning "Mappen $loggpath är ej skapad!, skapa mappen och testa igen"; break}
try {
# Stoppar lyssnaren för http scriptet om den redan är aktiverad.
$server.stop()
}
catch{
  Write-Verbose "HTTP Klienten stoppades" 
}

function CreateWebHead ($content,$title = "Automatiserar.se - SMS")
{
#Följande funktion används för att bygga huvudet på sidan.
@"
<!DOCTYPE html>
 <html>  
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
	    <meta http-equiv="Pragma" content="no-cache" />
	    <meta http-equiv="Expires" content="-1" />
	    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />        

        <title>$title</title>

    </head>

"@
}

function write-LogfileInformation{
    [cmdletbinding()]
    param(
    [string]$DestinationPath = $loggpath, # sätts default till variablen längst upp i scriptet.
    [string]$Destinationfilename = "DATA",
    [string]$SensorName, # använder Data som default om inte annat anges.
    [string]$SensorData, # värdet som sensorn skickat.
    [bool]$logdefault = $true # anger om data ska loggas i default loggen.
    )

    begin {
    $tmppath = Join-Path $DestinationPath -ChildPath "$($Destinationfilename).log"
    }

    process {

        write-host "Sparar datat `"$Destinationfilename, $SensorData`" i filen $tmppath"

        Out-File -InputObject "$SensorName|$(get-date)|$SensorData" -FilePath $tmppath -Append
        if ($logdefault){Out-File -InputObject "$SensorName|$(get-date)|$SensorData" -FilePath $(Join-Path -Path $loggpath -ChildPath "Data.log") -Append}

    }

    end{

    }


}


function get-KorrektaSvenskaTecken {
param(
[string]$TextAttKorrigera
)
# hämta och översätt till korrekta tecken
            
            

            $TextAttKorrigera = $TextAttKorrigera -creplace '%C3%85', 'Å'#
            $TextAttKorrigera = $TextAttKorrigera -creplace '%C3%84', 'Ä' #
            $TextAttKorrigera = $TextAttKorrigera -creplace '%C3%96', 'Ö' #
            $TextAttKorrigera = $TextAttKorrigera -creplace '%C3%A5', 'å' #
            $TextAttKorrigera = $TextAttKorrigera -creplace '%C3%A4', 'ä' #
            $TextAttKorrigera = $TextAttKorrigera -creplace '%C3%B6', 'ö' #

$TextAttKorrigera
}

function get-KorrektaHTMLTecken {
param(
[string]$TextAttKorrigera
)
# hämta och översätt till korrekta tecken
            
            

            $TextAttKorrigera = $TextAttKorrigera -creplace 'Å','&#197;'  #
            $TextAttKorrigera = $TextAttKorrigera -creplace 'Ä','&#196;' #
            $TextAttKorrigera = $TextAttKorrigera -creplace 'Ö','&#214;' #
            $TextAttKorrigera = $TextAttKorrigera -creplace 'å','&#229;' #
            $TextAttKorrigera = $TextAttKorrigera -creplace 'ä','&#228;' #
            $TextAttKorrigera = $TextAttKorrigera -creplace 'ö','&#246;' #

$TextAttKorrigera
}




# Skicka sms 
function Send-SMS{
[cmdletbinding()]
param(
$mobilnummer,  # Nummmer dit sms kommer att skickas
$meddelande    # meddelandet som ska skickas.
)

[bool]$smsresultat = $true; 
    # SerialPort Class

    $serialPort = new-Object System.IO.Ports.SerialPort

    # välj COM-port settings

    $serialPort.PortName = $ComPort
    $serialPort.BaudRate = $ModemSpeed
    $serialPort.WriteTimeout = 500
    $serialPort.ReadTimeout = 3000
    $serialPort.DtrEnable = "true"

    # lägg till vilket nummer du vill skicka 
    $phoneNumber = $mobilnummer
    $textMessage = $meddelande

    try {
        $serialPort.Open()

    }

    catch {
        $smsresultat = $false;
        Write-Verbose "$($MyInvocation.InvocationName):: kunde ej öppna porten $ComPort"
        # väntar 5 sek på porten 
        Start-Sleep -Seconds 3
        $serialPort.Open()
        
    }

    If ($serialPort.IsOpen -eq $true) {


        Write-Verbose "$($MyInvocation.InvocationName):: SKickar nu sms till: $phoneNumber med meddelandet: `"$textMessage`"" 

        $serialPort.Write("AT+CMGF=1`r`n")
        $serialPort.Write("AT+CMGS=`"$phoneNumber`"`r`n")

        # vänta lite på modemet
        Start-Sleep -Seconds 1
    
        # skickar meddelandet till modemet
        $serialPort.Write("$textMessage`r`n")
    
        # skickar Ctrl+Z för att avsluta meddelandet.
        $serialPort.Write($([char] 26))
    
        # väntar på att de ska bli skickat
        Start-Sleep -Seconds 1
    }

    # stänger porten
    $serialPort.Close()

    if ($serialPort.IsOpen -eq $false) {

        Write-Verbose "$($MyInvocation.InvocationName):: Porten är korrket stängd.."
        return $smsresultat
    }
}


function CreateWebBody {
[cmdletbinding()]
param(
$status = "OK"  # anger default ok om data mottagits
)
# Creating the body of the webpage

@"
       <body>
       $status
       </body>                           
"@

}

function CreateWebFotter {
# Creating the bottom of the webpage
@"

</html>
"@

}

function Create-Table{
[cmdletbinding()]
param(
$DataToParse
)
[string[]]$TabelData = "<table style=`"width:100%`" border=`"1`">" 
[string[]]$tmpdata

$tmpdata +=  "<tr>"
$tmpdata +=  "<td><B>Sensor</B></td>"
$tmpdata +=  "<td><B>Time</B></td>"
$tmpdata +=  "<td><B>Value</B></td>"
$tmpdata +=  "</tr>"

foreach ($objekt in $DataToParse){

$Sensid = $objekt.Split("|")[0] 
$senstid = $objekt.split("|")[1]
$sensvalue = $objekt.Split("|")[2]

 
$tmpdata +=  "<tr>"
$tmpdata +=  "<td>$Sensid</td>"
$tmpdata +=  "<td>$senstid</td>"
$tmpdata +=  "<td>$sensvalue</td>"
$tmpdata +=  "</tr>"

}

$TabelData += $tmpdata
$TabelData += "</table>" 
$TabelData
}


function read-Logdata{
# Används för att läsa in allt data från filen
[cmdletbinding()]
param(
[string]$logpath,
[string]$logname,
[bool]$ReadAlldata,
[bool]$CreateTabel
)
begin {
$returnData = @()    
}

process {
    $tmplogpath = Join-Path -Path $logpath -ChildPath "$($logname).log"
    if (Test-Path ($tmplogpath))
    {
        if ($ReadAlldata)
        {
            $returnData =  Get-Content $tmplogpath 
        
        }
        else 
        {
            $returnData = Get-Content $tmplogpath | Select-Object -Last 1
        }
    }
    else 
    {
       $returnData = "Hittar inte filen $tmplogpath"
    }
}

end {
      if ($CreateTabel)
      {
        $returnData =  Create-Table -DataToParse $returnData #$returnData 

      }

      return $returnData
}

}



## This part will send web response to clients

function SendResponse ($sock, $string)
{
    if ($sock.connected)
        {
            $bytesSent = $sock.Send(
            [text.Encoding]::Ascii.GetBytes($string))
        if ($bytesSent -eq -1)
        
           {
            Write-Warning ("$($sock.RemoteEndPoint) - Unable to send")
           }
        else
           {
            Write-Verbose ("$($sock.RemoteEndpoint) - Sent $bytesSent Bytes" )
           }
        }
}
# End Function SendResponse

Function SendHeader (
    [net.sockets.socket] $sock,
    $length,
    $statusCode = "200 OK",
    $mimeHeader = "text/html; charset=utf-8",
    $httpVersion = "HTTP/1.1"
    
)
{
    $response = "HTTP/1.1 $statusCode `r`nServer: " + "Hemautomation`r`nX-Powered-By: Automatiserar.se`r`nContent-Type: $mimeHeader`r`n" + "Accept-Ranges:bytes`r`nContent-Length : $length`r`n`r`n"
    SendResponse $sock $response
    Write-Verbose "header Sent"
}
# End function SendHeader


# Bygger classen coh Startar webbservern på angiven port.
$server = [System.Net.Sockets.TcpListener]$port
$server.start()

$buffer = New-Object byte[] 1024

write-host "Servern har nu startat på $serverIP och port $port (Kontrollera att brandväggen tillåter porten $port)"
write-host ""
write-host "För att skicka sms skriv i en webbläsare: http://$($serverIP):$($port)/?SMS/0701234567/Ditt Meddelande"
write-host "För att spara data skriv i en webbläsare: http://$($serverIP):$($port)/?LOGGA/VERA/Sensor 33/-11,7"
write-host "För att läsa upp loggar skriv i en webbläsare: http://$($serverIP):$($port)/?READLOG/Vera/Sensor 33/ALL (läser hela filen sensor 33.log)"
write-host "För att läsa upp loggar skriv i en webbläsare: http://$($serverIP):$($port)/?READLOG/Vera/Data/LAST (läser sista raden i data.log)"
write-host "För att läsa upp loggar skriv i en webbläsare: http://$($serverIP):$($port)/?READLOG/Vera/Data/TABEL (läser hela filen och visar som tabel)"

#Starting loop 
 while($true)
 {

    if ($server.Pending())
    {
        $socket = $server.AcceptSocket()
    }

    if ($socket.Connected)
    {
        Write-Verbose ("{1} - Uppkoppling {0} klockan " -f (get-date), $socket.RemoteEndPoint)
        
        [void] $socket.receive($buffer, $buffer.Length, '0')
        $received = [Text.Encoding]::ASCII.GetString($buffer)
        
        $received = [regex]::Split($received, "`r`n") 
        $received = @($received -match "GET")[0] 
       
        if ($received)
        {
        
        
        $expression = $received -replace "GET */" -replace 'HTTP.*$' -replace '%20',' '
        Write-Verbose "[WEBSERVER]:: `$expression = $expression"
            
            Write-Verbose "[WEBSERVER]:: Översätter till Svenska tecken: $expression"
            $expression = get-KorrektaSvenskaTecken $expression
            Write-Verbose "[WEBSERVER]:: Tecken översatta till Svenska: $expression"

            write-LogfileInformation -DestinationPath $loggpath -Destinationfilename "ScriptInfo" -SensorName "Uppkoppling" -SensorData ("{1} - klockan {0} - Data - {2}" -f $(get-date), $($socket.RemoteEndPoint), $expression) -logdefault $false # loggar till en speciell logg.

            if ($expression -match '\?SMS')  # Match för att skicka sms.
            {
                $SentSMS = $false # anger att sms inte skickats ännu
                Write-Verbose "[SMS FUNKTIONEN] - TRÄFF"
                Write-Verbose $expression

                Write-Verbose "[WEBSERVER]:: Träff på: $($Matches[0])"
                
                if ($expression -match "\?SMS\/(?<Nummer>\d*)\/(?<Meddelande>.*)"){
                    
                    write-host "SKickar SMS! - [ $($Matches.Nummer) ] / [ $($Matches.Meddelande) ]"
                    $SMSSvaret = Send-SMS -mobilnummer $Matches.Nummer -meddelande $Matches.Meddelande

                    if ($SMSSvaret)
                    {
                        Write-Host "SMS skickat!"
                        $SentSMS = $true # Anger att ett sms skickats.
                    }
                    else 
                    {
                        Write-Host "De gick inte att skicka sms"
                    }
                }
               

                
                Write-Debug "Expression: $expression"

                Start-Sleep -Milliseconds 100

                $result =   CreateWebHead
                $result +=  if (!($SMSSvaret)){CreateWebBody -status "ERROR"} else {CreateWebBody -status "SMS-OK"}
                $result +=  CreateWebFotter

                
                


            }
            elseif ($expression -match "\?LOGGA\/(?<System>\w.*)\/(?<Sensor>.*)\/(?<Data>.*)") # Match för att logga data. ?LOGGA/Vera/givare22/33
            {
                Write-Verbose "[Logga FUNKTIONEN] - TRÄFF"
                #Write-Verbose $expression

                #Out-File -InputObject "$($Matches.System),$($Matches.Sensor),$($Matches.Data)
                Write-Verbose "Loggade data: $($Matches.System), $($Matches.Sensor), $($Matches.Data)"

                Write-LogfileInformation -DestinationPath $loggpath -Destinationfilename $($Matches.Sensor) -SensorName $($Matches.Sensor) -SensorData $($Matches.Data) # loggar data till specifik fil.
         
                $result =   CreateWebHead
                $result +=  CreateWebBody -status "Data Loggat"
                $result +=  CreateWebFotter

            }
            
            # Funktion för att läsa tillbaka data till webbläsare. 
            elseif ($expression -match "\?READLOG\/(?<System>.*)\/(?<Sensor>.*)\/(?<Mode>.*)")
            {
                $ReadAlldata = $true # anger om all data ska läsas från filen.
                $Outtabel = $false   # anger om resultatet tillbaka ska bli i Tabellform
                Write-Verbose "FICK: $($matches.mode)"
                switch ($Matches.mode.trim())
                {
                    'ALL'     {$ReadAlldata = $true; break}
                    'LAST'    {$ReadAlldata = $false; break}
                    'TABEL'   {$Outtabel = $true; break;}
                       
                     default  {write-host "Ingen träff på filter"}
                }


                

                
                $result =   CreateWebHead
                $result +=  CreateWebBody -status (get-KorrektaHTMLTecken $(read-Logdata -logpath $loggpath -logname $($Matches.sensor) -ReadAlldata $ReadAlldata -CreateTabel $Outtabel))
                $result +=  CreateWebFotter


            }
            elseif ($expression -match "favicon.ico")
            {
                write-vebose "favicon data..."
                $result =   CreateWebHead
                $result +=  CreateWebBody -status "- Ingen Favicon finns... - "
                $result +=  CreateWebFotter
            }
            else   
            {
                Write-Verbose "[Ingen träff på något filter]"
                
                $result =   CreateWebHead
                $result +=  CreateWebBody -status "Ingen Data registrerades"
                $result +=  CreateWebFotter

            }

################# - skickar data till klienten.
        SendHeader $socket $result.Length
        SendResponse $socket $(get-KorrektaSvenskaTecken $result)
        
        }
      $socket.Close()
    }
    else
    {
        Start-Sleep -Milliseconds 1000
    }
}