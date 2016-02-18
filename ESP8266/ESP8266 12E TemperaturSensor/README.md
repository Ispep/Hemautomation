# Hemautomation - www.automatiserar.se

![alt tag](https://raw.githubusercontent.com/Ispep/Hemautomation/master/Bilder/Automatiserar.png "Description goes here")

Med följande projekt är målet att bygga en batteridriven WIFI sensor som rapportar till olika destinationer.

2016-01-11 - Automatiserar.se 
Skapad av Ispep - Automatiserar.se 
   
V1.5 - 2016-02-14
	Testar att stänga alla kommenterar: 	
	bugg - Läses en temperatur inte ur ds18b20 så hamnar sensorn i en loop och drar ur batteriet....
	nytt thingspeak IP!
       
V1.4 - 2016-02-09
    
	Städar upp i koden och flyttar in skickning in i en funktion.
         
    
V1.3 - 2016-01-18
     Byter till ett annat WIFI bibliotek, detta kommer att köra fast ip för att snabba upp koden. 
     
     Från och med Version 1.3 kan man nyttja Statiskt ip på ESP8266 genom att fylla på adresser nedan.
       IPAddress ip(10, 20, 30, 42);  
       IPAddress gateway(10,20,30,1);
       IPAddress subnet(255,255,0,0);
       
	Genom att nyttja statiskt IP går det att minska tiden från ca 8 sekunder 4.2 sekunder! vilket borde ge nästan dubbel batteritid!	
	Utan thingspeak med loggning direkt till http logservern tar det ca 2.2 sekunder! dvs 4 ggr snabbare än version 1.2
 
 V1.2 - 2016-01-17 
     Lägger till stöd för batteriavläsning.
     Lägger till rapport till http servern för att se tidsåtgång för att rapportera
     Lägger till Version nummer i loggningen till http servern.
    

V1.1 - 2016-01-13 - 21:20

	Stöd för 
	Vera UI7
	ThingSpeak 
	HTTP loggserver. 

 
Läs allt om projektet här:
http://www.automatiserar.se/wifi-temperatursensor-vera/

// Ispep
