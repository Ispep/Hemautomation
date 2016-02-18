/**
 *   2016-01-11 - Automatiserar.se 
 *   Skapad av Ispep - Automatiserar.se 
 *   
 *   V1.5 - 2016-02-14
 *    Testar att stänga alla kommenterar: 
 *      * bugg - Läses en temperatur inte ur ds18b20 så hamnar sensorn i en loop och drar ur batteriet....
 *      * nytt thingspeak IP!
 *      
 *   V1.4 - 2016-02-09
 *   
 *      Städar upp i koden och flyttar in skickning in i en funktion.
 *      
 *      Buggfix
 *        Variabeln skickadeOK kontrollerar nu att sista skicknignen är resultat 200. 
 *        
 *   
 *   V1.3 - 2016-01-18
 *    Byter till ett annat WIFI bibliotek, detta kommer att köra fast ip för att snabba upp koden. 
 *    
 *    Från och med Version 1.3 kan man nyttja Statiskt ip på ESP8266 genom att fylla på adresser nedan.
 *      IPAddress ip(10, 20, 30, 42);  
 *      IPAddress gateway(10,20,30,1);
 *      IPAddress subnet(255,255,0,0);
 *      
 *        Genom att nyttja statiskt IP går det att minska tiden från ca 8 sekunder 4.2 sekunder! vilket borde ge nästan dubbel batteritid!
 *          Utan thingspeak med loggning direkt till http logservern tar det ca 2.2 sekunder! dvs 4 ggr snabbare än version 1.2
 *
 *   V1.2 - 2016-01-17 
 *    Lägger till stöd för batteriavläsning.
 *    Lägger till rapport till http servern för att se tidsåtgång för att rapportera
 *    Lägger till Version nummer i loggningen till http servern.
 *    
 *   V1.1 - 2016-01-12
 *    Stänger sleep funktionen i Setup (sparar 4 sekunder / uppstart)
 *    Lägger till ThingSpeakStöd.
 *    Lägger till stöd för versionsnummer av koden (skickas till http loggservern)
 *   
 *   V1.0 - 2016-01-11
 *   
 *   Stöd för:
 *     
 *      Vera (UI7)
 *      Automatiseras.se -  http loggserver. ( http://www.automatiserar.se/loggning-med-http/ ) 
 *   
 *   Temperatursensor på Port 4
 *   Klarar en DS18B20 sensor
 *
 *   Loggar till vald server, går sedan ner i sovläge.
 *   
 *    *  Delar av temperatur koden kommer från detta: 
 *    *     BasicHTTPClient.ino ( Created on: 24.05.2015 ) 
 *    *     http://www.jerome-bernard.com/blog/2015/10/04/wifi-temperature-sensor-with-nodemcu-esp8266/
 */

String MinKodVersion  = "1.5"; // lägger till version av kod som körs. 

#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>

#define USE_SERIAL Serial

// One Wire stöd 
#include <OneWire.h>
#include <DallasTemperature.h>
#define ONE_WIRE_BUS 4       // Anger pinnen där du ska köra temp sensorn. 

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature DS18B20(&oneWire);
char temperatureString[6];


ESP8266WiFiMulti WiFiMulti;

// V1.3 Faster http request - testar att boosta så att mindre tid går att vänta på IP adress.
IPAddress ip(10, 20, 30, 40);  // Ange ett ledig ip på ditt subnät
IPAddress gateway(10,20,30,1);
IPAddress subnet(255,0,0,0);

// Ange ditt wifi och lösenord. 
  const char* WifiNamn      = "DittWifiNamn";      // Ange namnet på ditt WIFI
  const char* WifiPass      = "DittWifiPass";    // Lösenordet till ditt wifi nätverk.
  const int sleepTimeS      = 300; // Ange hur länge sensorn ska sova, 300 sekunder = 5 minuter, 900 = 15 min.    


// Vera UI7 - Loggning till tempsensor (http://www.automatiserar.se/guide-skapa-temperatur-luftfuktighet-och-ljusenhet-i-vera-ui7/)

  int VeraDeviceID = 147;  // Ange id på den virtuella sensorn du skapat i vera enligt guiden 
  String VeraIP    = "10.20.30.40"; // Ange ip eller namn till din vera kontroller. 
  bool LoggaTillVera = true;   // Ange om du vill logga till Veran (sätts till True då!)


// Loggning till Automatiserar.se - HTTP server ( http://www.automatiserar.se/loggning-med-http/ ) 

  String EnhetsNamn         = "ESP8266-NR4";  // Ange namnet som Din esp modul ska registrera 
  String DestinationsServer = "10.20.30.41"; // ange namnet eller ip dit du vill skicka datat.
  int DestinationsPort      =  86;  // ange porten du vill skicka datat på (normalt port 80)
  bool LoggaTillHttpServern =  true; // anger om detta ska loggas till klienten från länken ovan.  


// Loggning till Thingspeak -- OBS man kan inte skicka oftare än var 15:e sekund! 

  String ThingSpeakKey     = "ThingSpeakKey"; 
  int    ThingSpeakID      = 5;   // ange vilket av de 5 thingspeak id:n du vill uppdatera.
  String ThingSpeakIP      = "184.106.153.149"; // IP till thingspeak tjänsten (enheten klarar inte dns just nu)
  bool LoggaTillThingSpeak = true; 

// Läs av batterispäningen på enheten (OBS Resistorerna måste beräknas! Jag har baserat detta på 470K Ohm (R1) och 100K Ohm (R2))
  float BatteryPower = 6; // Ange hur många volt du matar enheten med ( detta kommer sedan att nyttjas i omräkningen från 1V till korrekt volt)
  bool  LoggaBatteri = true; // Anger om funktionen för att läsa av batterispänning ska nyttjas.
  int   VoltDivdierVoltage = 1024; // Agne vilket spänning din spänningsbrygga lämnade vid "full effetkt"  dvs i mitt fall 6V blev ca 1V med 470K ohm och 100k Ohm,dvs värdet att dela med då blir 1024 


// varibler som nyttjas i programmet. 
  bool skickadeOK           = false; 
  float BatteryLevel = 0;   // variabel som sätts till noll vid varje uppstart.  

// V1.4 - lägger till max antal ggr enheten försöker koppla upp innan den tvingas ner i sovläge igen.
  int MaxWifiTests = 50;  // sensorn får max vänta 50 ggr med att försöka koppla upp, enheten läggs i sovläge om detta misslyckas mer än 50 X 100ms = 
  int WIFILoopCount = 0;  // räkanre som ej får nå MaxWifiTest, om den gör det kommer enheten att läggas i sovläge igen.
  bool RequireDataTobeSent = false; // används om data verkligen måste levereras varje gång enheten vaknar. 
  
void setup() {


    USE_SERIAL.begin(115200);
    USE_SERIAL.setDebugOutput(true);

    USE_SERIAL.println();
    USE_SERIAL.println();
    USE_SERIAL.println();

    // ---- V1.2 - Lägger till Mätning av batteri
    pinMode(A0, INPUT);  // kommer att nyttjas för att läsa av 1V med hjälp av två resistorer som aggerar spänningsdelare (OBS Resistorerna måste beräknas!)

    
    DS18B20.begin(); // aktiverar sensorn. 

    WiFi.begin(WifiNamn, WifiPass);
    WiFi.config(ip, gateway, subnet);
    //WiFiMulti.addAP(WifiNamn, WifiPass);
    //WIFI.config(ip, gateway, subnet);
}

// funktion för att hämta temperaturen från temp sensorn. 
float ReadDS18B20Temperature() {
  USE_SERIAL.print("Requesting DS18B20 temperature...");
  float temp;
  do {
    DS18B20.requestTemperatures(); 
    temp = DS18B20.getTempCByIndex(0);
    USE_SERIAL.println("sensorn fick: " + String(temp)); 
    delay(100);
  } while (temp == 85.0 || temp == (-127.0));
  return temp;
}

// Funktion för att läsa av batterispänningen på ESP med hjälp av 1V (kräver en spännings delare).
float getBatteryStatus(){
    // V1.2 --- testar att räkna batteristatus.
    BatteryLevel= analogRead(A0);
    USE_SERIAL.print("Raw batteri status: ");
    USE_SERIAL.println(String(BatteryLevel)); 

    BatteryLevel = analogRead(A0);
    BatteryLevel = (BatteryLevel * BatteryPower) / VoltDivdierVoltage;  // värdet 978 baseras på det värdet jag fick fram när jag matade 6V genom spänningsdelaren och mätte fram 0.978v
    USE_SERIAL.print("riktigt batterivarde: ");
    USE_SERIAL.println(String(BatteryLevel));
    return BatteryLevel; 

    
}

// --- V 1.3 Bygger en egen funktion av http get, detta för att minska koden.
int SendHttpData(String DestIP, int DestPort,String MyData){
   USE_SERIAL.print("[HTTP] begin...\n");

   HTTPClient http;
   http.begin(DestIP, DestPort,MyData);
   
   USE_SERIAL.print("[HTTP] GET...\n");
   
   int httpCode = http.GET();
   
   return httpCode;
}

void GoToDeepSleep(int SleepDelay){

 // USE_SERIAL.print("Enheten kommer nu att sova i " + String(SleepDelay) + " sekunder");
  ESP.deepSleep(SleepDelay * 1000000);
}

void loop() {
    // wait for WiFi connection
    
    while (WiFi.status() != WL_CONNECTED) {
    delay(100);
    USE_SERIAL.print(".");

      // V1.4 - lägger till ett tak på hur länge enheten får försöka koppla upp.
      if (WIFILoopCount >= MaxWifiTests){  
        USE_SERIAL.print("Enheten kunde ej koppla upp till WIFI... deep sleep aktiverat");
        GoToDeepSleep(60); // sover i 60 sekunder.....
      }
    WIFILoopCount++;
    }
        
      
          float myTemp = ReadDS18B20Temperature(); // V1.3 -- läser temperatur från DS18B20

          if (LoggaBatteri)
          {
             float test = getBatteryStatus(); 
          } else {}

          if (LoggaTillThingSpeak)
          {
            
             String myDataTest2 =  "/update?key=" + ThingSpeakKey + "&field" + String(ThingSpeakID) + "=" + String(myTemp); 
             skickadeOK = SendHttpData(ThingSpeakIP, 80, myDataTest2);
             USE_SERIAL.println("Logga till Thingspeak klart"); 
          }

          if (LoggaTillVera)
          {
            USE_SERIAL.println("[IF] Logga till Vera"); 
            String myDataTest1 = "/data_request?id=variableset&DeviceNum=" + String(VeraDeviceID) + "&serviceId=urn:upnp-org:serviceId:TemperatureSensor1&Variable=CurrentTemperature&Value=" + String(myTemp);
            skickadeOK = SendHttpData(VeraIP, 3480, myDataTest1);
          }
          
          if (LoggaTillHttpServern)
          {
             
             String myData = "/" + EnhetsNamn + "/" + MinKodVersion + "/" + String(WiFi.RSSI()) + "/" + String(myTemp) + "/TID:/" + String(millis());
             skickadeOK = SendHttpData(DestinationsServer, DestinationsPort, myData); 
     //        USE_SERIAL.println("Logga till HTTP servern"); 
 
          }


    if (RequireDataTobeSent){
    if (skickadeOK == 200)
    {
        GoToDeepSleep(sleepTimeS); 
    }
    delay(2500); // Om data inte skickas så försöker den igen efter 2,5 sekunder.
    } else 
    {
        GoToDeepSleep(sleepTimeS);      
    }
    
    
}




