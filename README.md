# Hemautomation

Powershell modul för hemautomation. 

Funktioner för att hantera

Vera Med UI7
Telldus Live

Målet är att göra en smidig och öppen modul för hemautomation, bidra gärna med bra funktioner för hemautomation. 


Grundläggande information finns här (kommer att portas in till den här sidan så fort jag hinner). 

http://www.automatiserar.se/powershell-modul-for-hemautomation/

För att installera den på datorn kör en Powershell som administratör och klistra in följande: 

$tmpPath = "C:\Program Files\WindowsPowerShell\Modules"; (New-Item -Path $tmpPath -Name "Automatiserar" -ItemType directory); Out-File -InputObject $((Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Ispep/Hemautomation/master/Automatiserar.psm1").content) -FilePath "$($tmpPath)\Automatiserar2\Automatiserar.psm1"

Har lite strul med åäö, men så fort jag hinner ska jag fixa det med. 

// Ispep
