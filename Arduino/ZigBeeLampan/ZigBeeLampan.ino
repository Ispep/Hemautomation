/*
  Automatiserar.se - Web Server för att styra Zigbee
  Made by Ispep :D 
  
  Detta är ett snabbt editering av Ethernet som finns i studion, adderade lite Iframe med webbserver som jag använder i andra projekt. 

 A simple web server that shows the value of the analog input pins.
 using an Arduino Wiznet Ethernet shield.

 Circuit:
 * Ethernet shield attached to pins 10, 11, 12, 13
 * Analog inputs attached to pins A0 through A5 (optional)

 created 18 Dec 2009
 by David A. Mellis
 modified 9 Apr 2012
 by Tom Igoe
 modified 02 Sept 2015
 by Arturo Guadalupi

 */

#include <SPI.h>
#include <Ethernet.h>

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = {
  0xAA, 0xAA, 0xDD, 0x00, 0xFF, 0x78
};
IPAddress ip(10, 20, 30, 40);

// Initialize the Ethernet server library
// with the IP address and port you want to use
// (port 80 is default for HTTP):
EthernetServer server(80);

// för att hantera ethernet och sånt.
String readString; //Används för att läsa det som tas emot från webbläsaren
String FirmwareVersion = "0.5"; // anger vilken firmware som körs 
String SenastUppdaterad = "2017-02-11"; // anger när koden installerades

// Min Arduino LAMPA

// Pinnar till funktioner på lampan
const int dimUppPin = 5;
const int dimDownPin = 6;
const int onOffPin = 7; 
const int changeColorUpPin = 8;
const int changeColorDownPin = 9;  

// Anger hur länge en knapptryckning ska vara
const int highDelay = 150; // anger hur många MS en HIGH ska vara 
const int lowDelay  = 500; // Anger hur länge en low ska komma efter en HIGH

// Anger hur många ggr en dimmring kan vara. 
const int maxDimmring = 10; // ökar värdet 10 ggr för max dimmer
const int minDimmring = 10; // minskar värdet 10 ggr för min dimmring

// Anger hur många färger det finns i lampan
const int antalcolors = 4;  // anger hur många färger som finns att tillgå.

// Anger vad man senast skickade.  (den blir true om man kör dimmring ++
bool senasteOnOff = false; // anger senaste värdet som skickades


void setup() {
  // Open serial communications and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
  pinMode(dimUppPin, OUTPUT);
  pinMode(dimDownPin, OUTPUT);
  pinMode(onOffPin, OUTPUT);
  pinMode(changeColorUpPin, OUTPUT);
  pinMode(changeColorDownPin, OUTPUT);
  
  digitalWrite(dimUppPin, LOW);
  digitalWrite(dimDownPin, LOW);
  digitalWrite(onOffPin, LOW);
  digitalWrite(changeColorUpPin, LOW);
  digitalWrite(changeColorDownPin, LOW);


  // start the Ethernet connection and the server:
  Ethernet.begin(mac, ip);
  server.begin();
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());
}

// FUnktion för att tända / släcka 
void turnONOFF(){

  digitalWrite(onOffPin, HIGH);
  delay(lowDelay);
  digitalWrite(onOffPin, LOW);
}

// dimmra upp lampan x antal ggr
// tar emot ett värde med hur många ggr den ska köras.
void dimUpp(int antalGGR){

   // Kör loopen tills värdet är samma som antalGGr 
   int iupp = 0; 
   while (iupp <= antalGGR){

    digitalWrite(dimUppPin, HIGH);
    delay(lowDelay); 
    digitalWrite(dimUppPin, LOW);

   iupp++;
   }

}

// dimmra ner lampan x antal ggr
// tar emot ett värde med hur många ggr den ska köras.
void dimDown(int antalGGR){

   // Kör loopen tills värdet är samma som antalGGr 
   int idown = 0; 
   while (antalGGR >= idown){

    digitalWrite(dimDownPin, HIGH);
    delay(lowDelay); 
    digitalWrite(dimDownPin, LOW);

   idown++;
   }

}

// Byt färg upp
void colorUpp(){

  digitalWrite(changeColorUpPin, HIGH);
  delay(lowDelay); 
  digitalWrite(changeColorUpPin, LOW);
}

void colorDown(){
  
  digitalWrite(changeColorDownPin, HIGH);
  delay(lowDelay); 
  digitalWrite(changeColorDownPin, LOW);
}

void loop() {
  // listen for incoming clients
  EthernetClient client = server.available();
 
 
  if (client) {
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
         
        //read char by char HTTP request
        if (readString.length() < 100) {

          //store characters to string 
          readString += c; 
          //Serial.print(c);
        } 

        //if HTTP request has ended
        if (c == '\n') {
        Serial.println("new client");
          ///////////////
          Serial.print(readString); //print to serial monitor for debuging 

            //now output HTML data header
          if(readString.indexOf('?') >=0) { //don't send new page
            client.println(F("HTTP/1.1 204 Automatiserar"));
            client.println();
            client.println();  
          }
          else {   
            client.println(F("HTTP/1.1 200 OK")); //send new page on browser request
            client.println(F("Content-Type: text/html"));
            client.println();

            client.println(F("<HTML>"));
            client.println(F("<HEAD>"));
            client.println(F("<TITLE>Automatiserar.se - IKEAS ZIGBEE LAMPA</TITLE>"));
            client.println(F("</HEAD>"));
            client.println(F("<BODY>"));

            client.println(F("<H1>Automatiserar.se - IKEAS ZIGBEE LAMPA via Ethernet</H1>"));

            // Tänd släck Arduinon
            client.println(F("Lampa on / off"));
            client.println(F("<a href=/?1 target=inlineframe>DO IT!</a><br><br>")); 
            // Dimmra Upp
            client.println(F("Dimra:"));
            client.println(F("<a href=/?2 target=inlineframe>Dimra Upp</a> | ")); 
            client.println(F("<a href=/?3 target=inlineframe>Dimra Ner</a><br><br>")); 
        
            // All on / off
            client.println(F("Color:"));
            client.println(F("<a href=/?4 target=inlineframe>Color +</a> | ")); 
            client.println(F("<a href=/?5 target=inlineframe>Color -</a><br><br>")); 
                       
            client.println(F("<IFRAME name=inlineframe style='display:none'>"));          
            client.println(F("</IFRAME>"));

            client.print(F("<p>Firmware Version " )); 
            client.print(FirmwareVersion); 
            client.println("</p>");
            
            client.print(F("<p>Senast uppdaterad: " )); 
            client.print(SenastUppdaterad); 
            client.println("</p>");
            client.println(F("</BODY>"));
            client.println(F("</HTML>"));
          }

          delay(1);
          //stopping client
          client.stop();

          Serial.print("Http info som parsas: ");
          Serial.println(readString.substring(5,7));

           
          if (readString.substring(5,7) == "?1")
          {
            Serial.println("aktiverade / avaktiverade lampa"); 
            turnONOFF();        
          }

          if (readString.substring(5,7) == "?2")
          {
            Serial.println("Dimmra upp"); 
            dimUpp(1);               
          }

          if (readString.substring(5,7) == "?3")
          {  
           Serial.println("Dimmra ner");            
           dimDown(1); 
          }

          if (readString.substring(5,7) == "?4")
          {      
             Serial.println("Color Upp");           
            colorUpp();
          }
          
          if (readString.substring(5,7) == "?5")
          {
           Serial.println("Color Down");    
           colorDown(); 
          }

          if (readString.substring(5,7) == "?6")
          {
             Serial.println("LEDIG Styrning 6");     
          }

          if (readString.substring(5,7) == "?7")
          {
            Serial.println("LEDIG Styrning 7");   
          }

          //clearing string for next read
          readString="";

        }
      }
    }
  }
}

