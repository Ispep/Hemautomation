// www.Automatiserar.se 
// 
// - V 1.0 
// - skapad av ISPEP med hjälp av koden från zoomkat. 
// 
// Kod för att använda ett servo för att låsa och öppna ett nyckelskåp med indikations lampor.
// 
// All kod kommer att finnas på https://github.com/Ispep/Hemautomation/

// ----- Kod jag utgick från för att få en webbserver och klient i ett // ISPEP

        //zoomkat 7-03-12, combined client and server
        //simple button GET with iframe code
        //for use with IDE 1.0
        //open serial monitor and send an g to test client and
        //see what the arduino client/server receives
        //web page buttons make pin 5 high/low
        //use the ' in html instead of " to prevent having to escape the "
        //address will look like http://192.168.1.102:84 when submited
        //for use with W5100 based ethernet shields
        //note that the below bug fix may be required
        // http://code.google.com/p/arduino/issues/detail?id=605
        
// ------- SLUT initial kod jag utgick från // ISPEP

#include <SPI.h>
#include <Ethernet.h>
#include <Servo.h>   // --- Automatiserar.se, add support for servo.

// Servo 
int pos = 10; // start mode for servo ( closed )
Servo myservo; 

byte mac[] = {0xAA, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; //assign arduino mac address
byte ip[] = {10, 20, 30, 40 }; // ip in lan assigned to arduino
byte gateway[] = {10, 20, 30, 20 }; // internet access via router
byte subnet[] = {255, 255, 0, 0 }; //subnet mask
EthernetServer server(80); //server port arduino server will use
EthernetClient client;
//char serverName[] = "dinservern.dindomän.se"; // (DNS) zoomkat's test web page server
byte serverName[] = { 10, 20, 30, 21 }; // (IP) zoomkat web page server IP address

String readString; //used by server to capture GET request 

//////////////////////

void setup(){

  myservo.attach(3); // Servot som låser och öppnar dörren.

  Serial.println("Startup - Locking");
  Serial.println();

  
  pinMode(6, OUTPUT); //pin selected to control
  pinMode(7, OUTPUT); //pin selected to control


  Ethernet.begin(mac,ip,gateway,gateway,subnet); 
  server.begin();
  Serial.begin(9600); 
  Serial.println("Automatiseras Servo - V 0.5 - 2015-12-26");
  Serial.println("V i serial interfacet testar kommunikationen");

  delay(5000); // låter tcp:ip koppla upp innan resterande körs.
  
  ServoClosed(); 

}

void loop(){
  // check for serial input
  if (Serial.available() > 0) 
  {
    byte inChar;
    inChar = Serial.read();
    if(inChar == 'V')
    {
      sendGET("COMTest"); // call client sendGET function
    }
  }  

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
            client.println(F("<TITLE>Automatiserar.se - Keybox</TITLE>"));
            client.println(F("</HEAD>"));
            client.println(F("<BODY>"));

            client.println(F("<H1>Command Keybox - Automatiserar.se</H1>"));

            // DIY buttons
            client.println(F("Control Door: "));
            client.println(F("<a href=/?3on target=inlineframe>Lock</a>")); 
            client.println(F("  <a href=/?3off target=inlineframe>Open</a><br><br>")); 
            
            client.println(F("<IFRAME name=inlineframe style='display:none'>"));          
            client.println(F("</IFRAME>"));

            client.println(F("</BODY>"));
            client.println(F("</HTML>"));
          }

          delay(1);
          //stopping client
          client.stop();

          ///////////////////// control arduino pin
          //if(readString.indexOf('2') >0)//checks for 2
          //if (readString.equals("?3on"));
          Serial.print("Http info som parsas: ");
          Serial.println(readString.substring(5,10));

          if (readString.substring(5,9) == "?3on")
          {              
              ServoClosed();
          }
          
          //if(readString.indexOf('3') >0)//checks for 3
          //if (readString.equals("?3off"));
          if (readString.substring(5,10) == "?3off")
          {
              ServoOpen();
          }
 
          //clearing string for next read
          readString="";

        }
      }
    }
  }
} 

//////////////////////////
void sendGET(String MyInfo) //client function to send and receive GET data from external server.
{
  if (client.connect(serverName, 86)) {
    Serial.println("connected");
    client.print("GET /?Arduino/MyMode/");
    client.print(MyInfo);
    client.println(" HTTP/1.0");
    client.println();
  } 
  else {
    Serial.println("connection failed");
    Serial.println();
  }
 
  Serial.println();
  Serial.println("disconnecting.");
  Serial.println("==================");
  Serial.println();
  client.stop();

}


// Servo koden för att öppna och stänga dörren. 

void ServoOpen(){

    digitalWrite(6, LOW);    // släcker grön diod
    digitalWrite(7, HIGH);   // tänder röd diod
    Serial.println("--- Function Servo OPEN ----");
    Serial.println();
    pos = 10;
    
    myservo.write(pos);              // tell servo to go to position in variable 'pos'
    delay(10);                       // waits 15ms for the servo to reach the position
    sendGET("OPEN");
}

void ServoClosed(){

  digitalWrite(6, HIGH);    // tänder röd diod
  digitalWrite(7, LOW);     // släcker grön diod
  Serial.println("--- Function Servo CLOSED ----");
  Serial.println();
    
    pos = 100; 

    myservo.write(pos);              // tell servo to go to position in variable 'pos'
    delay(10);                       // waits 15ms for the servo to reach the position
    sendGET("CLOSED");
}


