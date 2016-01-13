/**
 *   2016-01-11 - Automatiserar.se 
 *   Skapad av Ispep - Automatiserar.se 
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



// Ange ditt wifi och lösenord. 
  const char* WifiNamn      = "DittWifiNamn";      // Ange namnet på ditt WIFI
  const char* WifiPass      = "DittWifiPass";    // Lösenordet till ditt wifi nätverk.
  const int sleepTimeS      = 300; // Ange hur länge sensorn ska sova, 300 sekunder = 5 minuter, 900 = 15 min.    


// Vera UI7 - Loggning till tempsensor (http://www.automatiserar.se/guide-skapa-temperatur-luftfuktighet-och-ljusenhet-i-vera-ui7/)

  int VeraDeviceID = 147;  // Ange id på den virtuella sensorn du skapat i vera enligt guiden 
  String VeraIP    = "10.20.30.40"; // Ange ip eller namn till din vera kontroller. 
  bool LoggaTillVera = true;   // Ange om du vill logga till Veran (sätts till True då!)


// Loggning till Automatiserar.se - HTTP server ( http://www.automatiserar.se/loggning-med-http/ ) 

  String EnhetsNamn         = "ESP8266-NR3";  // Ange namnet som Din esp modul ska registrera 
  String DestinationsServer = "10.20.30.41"; // ange namnet eller ip dit du vill skicka datat.
  int DestinationsPort      =  86;  // ange porten du vill skicka datat på (normalt port 80)
  bool LoggaTillHttpServern =  true; // anger om detta ska loggas till klienten från länken ovan.  


// Loggning till Thingspeak -- OBS man kan inte skicka oftare än var 15:e sekund! 

  String ThingSpeakKey     = "ThingSpeakKey"; 
  int    ThingSpeakID      = 5;   // ange vilket av de 5 thingspeak id:n du vill uppdatera.
  String ThingSpeakIP      = "144.212.80.10"; // IP till thingspeak tjänsten (enheten klarar inte dns just nu)
  bool LoggaTillThingSpeak = true; 


  
// varibler som nyttjas i programmet. 
  bool skickadeOK           = false; 


void setup() {


    USE_SERIAL.begin(115200);
   // USE_SERIAL.setDebugOutput(true);

    USE_SERIAL.println();
    USE_SERIAL.println();
    USE_SERIAL.println();

    
    DS18B20.begin(); // aktiverar sensorn. 
    
    WiFiMulti.addAP(WifiNamn, WifiPass);

}

// funktion för att hämta temperaturen från temp sensorn. 
float getTemperature() {
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


void loop() {
    // wait for WiFi connection
    if((WiFiMulti.run() == WL_CONNECTED)) {

        

        USE_SERIAL.print("[HTTP] begin...\n");
        // configure traged server and url

          // Översätter temperaturen till två XX.XX 
          float temperature = getTemperature();
          dtostrf(temperature, 2, 2, temperatureString);

          // nyttjas om du vill logga till en Vera kontroller. 
          if (LoggaTillVera)
          {
                  HTTPClient http;
                  // http://DittVeraIP:3480/data_request?id=variableset&DeviceNum=68&serviceId=urn:upnp-org:serviceId:TemperatureSensor1&Variable=CurrentTemperature&Value=10.0
      
                   http.begin(VeraIP, 3480, "/data_request?id=variableset&DeviceNum=" + String(VeraDeviceID) + "&serviceId=urn:upnp-org:serviceId:TemperatureSensor1&Variable=CurrentTemperature&Value=" + String(temperature));
      
                  USE_SERIAL.print("[HTTP] GET...\n");
                  // start connection and send HTTP header
                  int httpCode = http.GET();
                  
                  if(httpCode) {
             
                  // HTTP header has been send and Server response header has been handled
                  USE_SERIAL.printf("[HTTP] GET... code: %d\n", httpCode);
          
                  // file found at server
                  
                  if(httpCode == 200) {
                          
                          String payload = http.getString();
                          USE_SERIAL.println("data som mottogs: " + String(payload));
          
                          skickadeOK = true;
                      }                       
              } else 
              {
                  USE_SERIAL.print("[HTTP] GET... failed, no connection or no HTTP server\n");
              }
               
          } else
          {
            // Ingen loggning till Vera vald...
          }


          // används om du valt att logga till http servern. 
          if (LoggaTillHttpServern)
         {
             HTTPClient http;
             http.begin(DestinationsServer, DestinationsPort, "/" + EnhetsNamn + "/" + String(WiFi.RSSI()) + "/" + String(temperature)); 
      
             USE_SERIAL.print("[HTTP] GET...\n");
             
             // start connection and send HTTP header
             int httpCode = http.GET();
             if(httpCode) {
             
             // HTTP header has been send and Server response header has been handled
             USE_SERIAL.printf("[HTTP] GET... code: %d\n", httpCode);
          
              // file found at server
                if(httpCode == 200) {
                          
                          String payload = http.getString();
                          USE_SERIAL.println("data som mottogs: " + String(payload));
          
                          skickadeOK = true;
                      }                       
              } else 
              {
                  USE_SERIAL.print("[HTTP] GET... failed, no connection or no HTTP server\n");
              }
                
          } 
          else
          {
            // Ingen loggning till http server vald...
          }

          // Logga till thingspeak 
         if (LoggaTillThingSpeak)
         {
             HTTPClient http;

             // skickar info till thingspeak på vald ID.
             http.begin(ThingSpeakIP, 80, "/update?key=" + ThingSpeakKey + "&field" + String(ThingSpeakID) + "=" + String(temperature)); 
      
             USE_SERIAL.print("[HTTP] GET...\n");
             
             // start connection and send HTTP header
             int httpCode = http.GET();
             if(httpCode) {
             
             // HTTP header has been send and Server response header has been handled
             USE_SERIAL.printf("[HTTP] GET... code: %d\n", httpCode);
          
              // file found at server
                if(httpCode == 200) {
                          
                          String payload = http.getString();
                          USE_SERIAL.println("data som mottogs: " + String(payload));
          
                          skickadeOK = true;
                      }                       
              } else 
              {
                  USE_SERIAL.print("[HTTP] GET... failed, no connection or no HTTP server\n");
              }
                
          } 
          else
          {
            // Ingen loggning till http server vald...
          }
          
        
    }

    if (skickadeOK)
    {
        USE_SERIAL.println("Enheten kommer nu att sova i " + String(sleepTimeS) + " Sekunder");
        ESP.deepSleep(sleepTimeS * 1000000);
    }
    delay(2500); // Om data inte skickas så försöker den igen efter 2,5 sekunder.
    
    
    
}



