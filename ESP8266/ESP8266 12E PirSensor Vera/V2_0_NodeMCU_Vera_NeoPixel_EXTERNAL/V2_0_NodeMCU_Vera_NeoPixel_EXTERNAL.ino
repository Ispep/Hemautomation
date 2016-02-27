/**
 *   2016-01-11 - Automatiserar.se 
 *   Skapad av Ispep - Automatiserar.se 
 *   
 *   Att göra: 
 *    * optimera websvar
 *    * Städa koden
 *    * Extern datakälla för Variabler
 *    * Ljus
 *    * Temperatur
 *    * FIFO köer för att stacka meddelanden. 
 *    * Flytta ut alla delayer ur NeoPixel funktionerna
 *    * Temperatur sensor (DHT22 Externt)
 *    * Skapa en class till vera enheter.
 *    
 *    
 *   V2.0 - Optimering 
 *      * Buggfixa
 *        HTTP Skickning - mottagning tar ibland lång tid.
 *          * Detta orsakdes av Vera... Vera kan ta upp till 7 sekunder för att "släppa" tråden sensorn rapporterar till! därav en delay innan dom röda dioderna tänds...
 *      
 *      * Stor städning och Optimering av koden. Koden kommer nu att delas från min andra kodbas: https://github.com/Ispep/Hemautomation/tree/master/ESP8266/ESP8266%2012E%20TemperaturSensor
 *    
 *   V1.9 - Färdig för test
 *    
 *    * Temperatur sensor Internt ( DS18b20 )
 *    * Pir sensor - CHECK 
 *      * Aktiverar Vera - CHECK 
 *      * Avaktiverar Vera - CCHEK 
 *      
 *   V1.8 - Paketera lösningen.
 *   
 *   Stöd för:
 *     
 *      Vera (UI7)
 *      Automatiseras.se -  http loggserver. ( http://www.automatiserar.se/loggning-med-http/ ) 
 *   
   *  Delar av temperatur koden kommer från detta: 
 *    *     BasicHTTPClient.ino ( Created on: 24.05.2015 ) 
 *    *     http://www.jerome-bernard.com/blog/2015/10/04/wifi-temperature-sensor-with-nodemcu-esp8266/
 */


String MinKodVersion  = "2.0"; // lägger till version av kod som körs. 


#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>

// Neopixel kod (V1.6)
#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
  #include <avr/power.h>
#endif

#define ONE_WIRE_BUS 4       // Anger pinnen där du ska köra temp sensorn. 
#define PIN 5  // sätter pinne 5 som neopixel port. 
#define USE_SERIAL Serial


// Parameter 1 = number of pixels in strip
// Parameter 2 = Arduino pin number (most are valid)
// Parameter 3 = pixel type flags, add together as needed:

Adafruit_NeoPixel strip = Adafruit_NeoPixel(12, PIN, NEO_GRB + NEO_KHZ800);
int NeoLastUpdated = 0;       // anger när sensorn senast aktiverades.

    // Dimm variabler 
    int NeoPixelBrightness = 255; // anger maximalt värde, denna ändras sedan och kontrolleras genom koden.
    bool AutoDimm = true;          // anger om man sakta ska dimma ner
    int LastDimmValue = 0; // anger hur många ms sedan man senast dimmrade. 
    int DimmDelay    = 50; // anger hur lång tid det ska ta mellan varje gång innan sensorn dimmrar ner. 

// --- Slut NeoPixel
 
// One Wire stöd 
#include <OneWire.h>
#include <DallasTemperature.h>

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature DS18B20(&oneWire);
char temperatureString[6];


ESP8266WiFiMulti WiFiMulti;

// Fast IP rekommenderas eftersom sensorn kör dubbelriktad kommunikation! 
IPAddress ip(10, 20, 30, 31);  // - ändra detta
IPAddress gateway(10,20,30,1);
IPAddress subnet(255,0,0,0);

// Ange ditt wifi och lösenord. 
  const char* WifiNamn      = "BraWifiNamn";      // Ange namnet på ditt WIFI
  const char* WifiPass      = "BraWifilösenord";    // Lösenordet till ditt wifi nätverk.


// Vera UI7 - Loggning till tempsensor (http://www.automatiserar.se/guide-skapa-temperatur-luftfuktighet-och-ljusenhet-i-vera-ui7/)

  String VeraIP    = "10.20.30.30"; // Ange ip eller namn till din vera kontroller. 
  bool LoggaTillVera = false;   // Ange om du vill logga temperatur till Veran (sätts till True då!)
  int VeraTemperatureDeviceID = 147;  // Ange id på den virtuella sensorn du skapat i vera enligt guiden 
  int VeraPirDeviceID = 136; // id på sensorn i vera som ska ta emot rörelser från ESP8266

// Loggning till Automatiserar.se - HTTP server ( http://www.automatiserar.se/loggning-med-http/ ) 

  String EnhetsNamn         = "ESP8266-P_NR1";  // Ange namnet som Din esp modul ska registrera 
  String DestinationsServer = "10.20.30.32"; // ange namnet eller ip dit du vill skicka datat.
  int DestinationsPort      =  86;  // ange porten du vill skicka datat på (normalt port 80)
  bool LoggaTillHttpServern =  false; // anger om detta ska loggas till klienten från länken ovan.  


// Loggning till Thingspeak -- OBS man kan inte skicka oftare än var 15:e sekund! 

  String ThingSpeakKey     = "dinThingSpeakKey"; 
  int    ThingSpeakID      = 4;   // ange vilket av de 5 thingspeak id:n du vill uppdatera.
  String ThingSpeakIP      = "184.106.153.149"; // OBS GAMMALT IP! "144.212.80.10"; // IP till thingspeak tjänsten (enheten klarar inte dns just nu)
  bool LoggaTillThingSpeak = false; 

// varibler som nyttjas i programmet. 
  bool skickadeOK           = false;  // Nyttjas för att spara http resultatet. 
 
// V1.4 - lägger till max antal ggr enheten försöker koppla upp innan den tvingas ner i sovläge igen.
  int MaxWifiTests = 50;  // sensorn får max vänta 50 ggr med att försöka koppla upp, enheten läggs i sovläge om detta misslyckas mer än 50 X 100ms = 
  int WIFILoopCount = 0;  // räkanre som ej får nå MaxWifiTest, om den gör det kommer enheten att läggas i sovläge igen.
  
// V1.5 - 
      //* lägger till kontroll om temperaturen diffade sedan senaste skicknigen samt när senaste skickningen gick. 
      float LastSentTemperature = 0;  // anger senaste temperaturen som skickades. 
      float DiffTemperatur = 0.1;      // anger hur många grader det ska skilja innan den rapporterar igen.
      int   LastTimeStamp = 0;        // anger när senaste datan skickades i ms   


// V1.8 - Pir sensor
    //* lägger nu till stöd för pir sensor
    int pirPin = 15;  // sätter pin 15 (d5 på node MCU) som pir pinnen 
    int lastPirReport = 30000; // sätter detta till 30 sekunder eftersom sensorn behöver 30 sekunder att kallibrera sig. 
    int pirDelay = 30000; // anger hur länge det ska väntas mellan rapporteringar om pir sensorn triggar. Standard sätter jag 30 sekunder.
    int lastPirMotionSent = false; // anger om den senaste skickningen är rapporterad till Vera 


 
WiFiServer server(80);    
    

 
void setup() {

    // V 1.6 - neopixel start
    #if defined (__AVR_ATtiny85__)
      if (F_CPU == 16000000) clock_prescale_set(clock_div_1);
    #endif

     strip.begin(); 
     strip.show();  // V 1.6 - stänger alla dioder. 
     
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

    // 1.5 NodeMCU

    // 1.8 - Pir sensor
    pinMode(pirPin, INPUT);  // lägger till pinnen som ska nyttas för PIR sensorn.
    digitalWrite(pirPin, LOW);
    
    server.begin();  // V1.5 - server delen som tar emot kommandon via HTTP. 

}


// V1.8 
// PirSensorn 
bool ReadPirStatus(){

  //USE_SERIAL.println("Kontrollerar pir sensor"); 
  if(digitalRead(pirPin) == HIGH){
      return true;
  } 
  else 
  {
    return false;
    
  } 
  false; 
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



// NeoPixelKod 
void colorWipe(uint32_t c, uint8_t wait) {
  NeoPixelBrightness = 255;
  strip.setBrightness(NeoPixelBrightness);
  for(uint16_t i=0; i<strip.numPixels(); i++) {
    strip.setPixelColor(i, c);
    strip.show();
    delay(wait);
  }
}

// neoPixelkod - Automatiserar - Motionsensor V1.8
void colorMotionDetected(uint32_t c, uint8_t wait){
    NeoPixelBrightness = 255;
    strip.setBrightness(NeoPixelBrightness);
    // delar antalet dioder på 4 som ett int värde och tänder sedan var 4:e diod. 
    int basecount = strip.numPixels() / 4;   

    strip.setPixelColor(0, c); 
    strip.setPixelColor((basecount * 1), c); 
    strip.setPixelColor((basecount * 2), c); 
    strip.setPixelColor((basecount * 3), c); 
    //strip.setPixelColor((strip.numPixels()), c); 
    strip.show();  
}

// neoPixelkod - Automatiserar - Motionsensor V1.9
void colorNewInfo(uint32_t c, uint8_t wait){
    NeoPixelBrightness = 255;
    strip.setBrightness(NeoPixelBrightness);
    // delar antalet dioder på 4 som ett int värde och tänder sedan var 4:e diod. 
    int basecount = strip.numPixels() / 4;   

    strip.setPixelColor(1, c); 
    strip.setPixelColor((basecount * 1 + 1), c); 
    strip.setPixelColor((basecount * 2 + 1), c); 
    strip.setPixelColor((basecount * 3 + 1), c); 
    //strip.setPixelColor((strip.numPixels()), c); 
    strip.show();  
}


// NeoPixelKod - Automatiserar - MotionSensor V1.7
// Funktionen tar emot en färg och antal ms det ska lysa.
void colorStatusUpdate(uint32_t c, uint8_t wait){
   NeoPixelBrightness = 255;
   strip.setBrightness(NeoPixelBrightness);
   for (uint16_t i=0; i<strip.numPixels(); i++){
   strip.setPixelColor(i, c); 
   strip.show();  
   }
   delay(wait); 

   for (uint16_t i=0; i<strip.numPixels(); i++){
   strip.setPixelColor(i, strip.Color(0, 0, 0)); 
   strip.show();  
   }
   
}

void colorDimmern(int DimmValue){
strip.setBrightness(DimmValue);  
strip.show();
}



// --- V 1.3 Bygger en egen funktion av http get, detta för att minska koden.
int SendHttpData(String DestIP, int DestPort,String MyData){
   USE_SERIAL.println("[HTTP] begin...\n");
     
   HTTPClient http;
   http.begin(DestIP, DestPort,MyData);
   
   USE_SERIAL.println("[HTTP] GET...\n");
   
   int httpCode = http.GET();
   USE_SERIAL.println("[HTTPCODE]= " + String(httpCode)); 
   return httpCode;
}
bool ParseWebInformation (String WebData){

   if (WebData.indexOf("/home") != -1){

   colorWipe(strip.Color(0, 255, 0), 50); // Green
   USE_SERIAL.println("huset i mode HOME"); 
   return true; 
   }
   
   if (WebData.indexOf("/away") != -1){

   colorWipe(strip.Color(255, 0, 0), 50); // Red
   USE_SERIAL.println("huset i mode AWAY"); 
   return true; 
   }

   if (WebData.indexOf("/vacation") != -1){
    colorWipe(strip.Color(127, 127, 0), 50); // Yellow 
   USE_SERIAL.println("huset i mode AWAY"); 
   return true; 
   }

   if (WebData.indexOf("/night") != -1){

   colorWipe(strip.Color(0, 0, 255), 50); // Blue
   USE_SERIAL.println("huset i mode Night"); 
   return true; 
   }
   
   // Om en sensor triggats så blinkar sensorn till i grönt (50%) 
   if (WebData.indexOf("/status") != -1){

   colorStatusUpdate(strip.Color(0, 127, 0), 150); // blinkar grönt en gång med 50%. 
   USE_SERIAL.println("huset i mode Night"); 
   return true; 
   }

   // Används för att nytja sensorn som ljus. 
   if (WebData.indexOf("/light") != -1){

   colorWipe(strip.Color(255, 255, 255), 150); // vit?
   USE_SERIAL.println("huset i mode Night"); 
   return true; 
   }

   if (WebData.indexOf("/newinfo") != -1){
    colorNewInfo(strip.Color(127, 0, 0), 50); 
   USE_SERIAL.println("Info mottagen externt system");
   return true; 
   }
   

   
   return false; // ingen träff på något! 
}

// --- V1.7 ------
// All kod för att skicka kommandon flyttas hit.

void HTTPSendVera(String MyData){

            skickadeOK = SendHttpData(VeraIP, 3480, MyData);
            USE_SERIAL.println("Skickade data till Vera"); 
            USE_SERIAL.println("skickadeOK = " + String(skickadeOK)); 
}

void HTTPSendThingspeak(String MyData){

             skickadeOK = SendHttpData(ThingSpeakIP, 80, MyData);
             USE_SERIAL.println("Logga till Thingspeak klart");
             USE_SERIAL.println("skickadeOK = " + String(skickadeOK));  
}

void HTTPSendLogserver(String MyData){
             
             skickadeOK = SendHttpData(DestinationsServer, DestinationsPort, MyData); 
             USE_SERIAL.println("Logga till HTTP servern"); 
             USE_SERIAL.println("skickadeOK = " + String(skickadeOK)); 
                          
}

void HTTPWebClient(WiFiClient client){

  String request = client.readStringUntil('\r');
  USE_SERIAL.println(request);
  request.toLowerCase(); // 1.7 - Gör det till små tecken för att undvika stora små tecken från webläsaren.
  if (ParseWebInformation(request)){
          USE_SERIAL.println("Data OK MED MODE");
  
          client.println("HTTP/1.1 200 OK"); 
          client.println(""); // do not forget this one
          client.println("<!DOCTYPE HTML>");
          client.println("<html>");
          client.println("<body>");
          client.println("OK");
          client.println("</body>");
          client.println("</html>");
          
          } 
          else
          {
          USE_SERIAL.println("Data ej om med ett MODE");
          
          client.println("HTTP/1.1 200 OK"); 
          client.println(""); // do not forget this one
          client.println("<!DOCTYPE HTML>");
          client.println("<html>");
          client.println("<body>");
          client.println("ERROR");
          client.println("</body>");
          client.println("</html>");
          } 
        
        client.flush();

}

// kontrollerar om temperaturen är samma nu som tidigare.
bool checkIfNewTemperature(float newTemperature){

      USE_SERIAL.println("kommer nu att kolla om: " + String(newTemperature) +" is bigger then: " + String(LastSentTemperature));
         
      if ((newTemperature + DiffTemperatur) < LastSentTemperature || (newTemperature - DiffTemperatur) > LastSentTemperature){

           USE_SERIAL.println("temperaturen diffade mer eller mindre än: " + String(DiffTemperatur)); 
           LastSentTemperature = newTemperature;  // sätter nu temperaturen till samma.
           LoggaTillHttpServern = true;

          } else {

          USE_SERIAL.println("temperaturen diffade inte " + String(DiffTemperatur) + " skickar inte data"); 
          LoggaTillHttpServern = false; 

          }
  
}




// SLUT --- V1.7 ----------

// Nyttjas EJ i version 1.5 MODE MCU!
void GoToDeepSleep(int SleepDelay){

 // USE_SERIAL.print("Enheten kommer nu att sova i " + String(SleepDelay) + " sekunder");
  ESP.deepSleep(SleepDelay * 1000000);
}




void loop() {
    // wait for WiFi connection
    
    while (WiFi.status() != WL_CONNECTED) {
    //delay(100); -- tar bor den i 1.7 eftersom pixel ringen nu ska köras
    USE_SERIAL.print(".");

    // VÄNTA PÅ WIFI
    colorWipe(strip.Color(0, 0, 255), 50); // Blue
    colorWipe(strip.Color(0, 0, 0), 1);    // släcker allt. 

    // V1.4 - lägger till ett tak på hur länge enheten får försöka koppla upp.
    if (WIFILoopCount >= MaxWifiTests){  
        USE_SERIAL.println("Enheten kunde ej koppla upp till WIFI... deep sleep aktiverat");
        //GoToDeepSleep(60); // sover i 60 sekunder.....

         colorStatusUpdate(strip.Color(255, 0, 0), 255); // Röd varning att den inte kopplat upp!
               
      }
    WIFILoopCount++;
    }

    
   
    WiFiClient client = server.available();
    if (client) {

       USE_SERIAL.println("Nu kopplade en klient upp!");
       HTTPWebClient(client); 
      
    }
     
          // Kontrollerar om temperaturen har ändrats mer än X +-
          float myTemp = 22.3;
          //float myTemp = ReadDS18B20Temperature(); // V1.3 -- läser temperatur från DS18B20           
          //checkIfNewTemperature(myTemp); // kontrollerar om temperaturen har ändrats mer än X grader i så fall aktiveras loggning till loggservern igen.

          // OBS detta behöver kontrolleras så att man inte skickar oftare än var 15:e sekund heller!
          if (LoggaTillThingSpeak)
          {
             HTTPSendThingspeak(("/update?key=" + ThingSpeakKey + "&field" + String(ThingSpeakID) + "=" + String(myTemp)));
          }

          // OBS detta behöver kontrolleras så att man inte skickar oftare än varje minut
          if (LoggaTillVera)
          {
            HTTPSendVera(("/data_request?id=variableset&DeviceNum=" + String(VeraTemperatureDeviceID) + "&serviceId=urn:upnp-org:serviceId:TemperatureSensor1&Variable=CurrentTemperature&Value=" + String(myTemp)));
          }
          
          if (LoggaTillHttpServern)
          {
             HTTPSendLogserver(("/" + EnhetsNamn + "/" + MinKodVersion + "/" + String(WiFi.RSSI()) + "/" + String(myTemp)));
          }

        // // dimmar alltid nu... inte så bra kanske.
        

        // Dimmar och släcker efter en stund. 1.7
        if (AutoDimm && NeoPixelBrightness >= 0)
        {
          //USE_SERIAL.println("--------- den ska dimmra! ---------  ");
          if (millis() > (LastDimmValue + DimmDelay)){
           
           USE_SERIAL.println("--------- dimmrar!! --------- " + String(NeoPixelBrightness));
          LastDimmValue = millis(); 
          colorDimmern(NeoPixelBrightness);
          NeoPixelBrightness--; 
        }
        }

        // Kontrollera om det är nått som rört sig
        // lastPirReport
        if (lastPirReport <= millis()){
        
          if (ReadPirStatus())
          {
            // true på att ett värde läst in.
            //colorStatusUpdate(strip.Color(0, 127, 0), 150);
            lastPirReport = (millis() + pirDelay);

            colorMotionDetected(strip.Color(0, 255, 0), 50); // V1.8 - rapporterar att en rörelse detekterades. 
            HTTPSendLogserver(("/" + EnhetsNamn + "/" + MinKodVersion + "/" + String(WiFi.RSSI()) + "/MotionDetected"));
            lastPirMotionSent = true; 

            // skickar rörelsen till Vera
            HTTPSendVera(("/data_request?id=variableset&DeviceNum=" + String(VeraPirDeviceID) + "&serviceId=urn:micasaverde-com:serviceId:SecuritySensor1&Variable=Tripped&Value=1")); 
           
          } 
          else 
          {
            // om den senaste skickningen är true då ska den återställas till false.
            if (lastPirMotionSent){

              // avvaktiverar rörelsen i vera
              HTTPSendVera(("/data_request?id=variableset&DeviceNum=" + String(VeraPirDeviceID) + "&serviceId=urn:micasaverde-com:serviceId:SecuritySensor1&Variable=Tripped&Value=0"));              
              HTTPSendLogserver(("/" + EnhetsNamn + "/" + MinKodVersion + "/" + String(WiFi.RSSI()) + "/MotionStopped"));
              lastPirMotionSent = false; 
            }
            // ingen rörelse detekterad
          }
        }
        
        
       // USE_SERIAL.println("......... Klar med hela loopen..........");
        
}
