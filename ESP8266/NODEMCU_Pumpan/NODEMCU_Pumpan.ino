// Skapad av Ispep 
// Projektsidan: https://www.automatiserar.se/uppkopplad-pumpa/

#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
  #include <avr/power.h>
#endif

#include <Arduino.h>

#include <ESP8266WiFi.h>
#include <ESP8266WiFiMulti.h>
#include <ESP8266HTTPClient.h>
#define USE_SERIAL Serial
ESP8266WiFiMulti WiFiMulti;

// Which pin on the Arduino is connected to the NeoPixels?
// On a Trinket or Gemma we suggest changing this to 1
#define PIN            4

// How many NeoPixels are attached to the Arduino?
#define NUMPIXELS      16 

const int RADARPIN = 14; // Anger vilken pinne man har rader / pir på.
const int LEDPINNEN = 5; // Anger vilken pinne man har satt en LED på 
int slumpadDelay = 10; // används för vitt ljus 
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

// Lägger till WIFI


// the setup function runs once when you press reset or power the board
void setup() {
  // initialize digital pin LED_BUILTIN as an output.
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(RADARPIN, INPUT);   // Sätter upp radar pinnen 
 // pinMode(LEDPINNEN, OUTPUT); // Sätter upp led pinnnen. 

#if defined (__AVR_ATtiny85__)
  if (F_CPU == 16000000) clock_prescale_set(clock_div_1);
#endif
  // End of trinket special code

  pixels.begin(); // This initializes the NeoPixel library.

  // WIFI  

  USE_SERIAL.begin(115200);
   // USE_SERIAL.setDebugOutput(true);

    USE_SERIAL.println();
    USE_SERIAL.println();
    USE_SERIAL.println();

    for(uint8_t t = 4; t > 0; t--) {
        USE_SERIAL.printf("[SETUP] WAIT %d...\n", t);
        USE_SERIAL.flush();
        delay(1000);
    }

    WiFiMulti.addAP("MITTWIFINAMN", "MITTWIFIPASS");
}

// the loop function runs over and over again forever
void loop() {

  if (digitalRead(RADARPIN) == HIGH){
   // Något detekterades av radarn.
      
      digitalWrite(LED_BUILTIN, LOW);   // turn the LED on (HIGH is the voltage level)
      pulseRed(5);

      // SKICKA LARM TILL MASTERN

          if((WiFiMulti.run() == WL_CONNECTED)) {

        HTTPClient http;

        USE_SERIAL.print("[HTTP] begin...\n");
        // configure traged server and url
        //http.begin("https://10.20.0.30:86/PUMPAN/LARM", "7a 9c f4 db 40 d3 62 5a 6e 21 bc 5c cc 66 c8 3e a1 45 59 38"); //HTTPS
        http.begin("http://10.20.0.30:86/PUMPAN/LARM"); //HTTP

        USE_SERIAL.print("[HTTP] GET...\n");
        // start connection and send HTTP header
        int httpCode = http.GET();

        // httpCode will be negative on error
        if(httpCode > 0) {
            // HTTP header has been send and Server response header has been handled
            USE_SERIAL.printf("[HTTP] GET... code: %d\n", httpCode);

            // file found at server
            if(httpCode == HTTP_CODE_OK) {
                String payload = http.getString();
                USE_SERIAL.println(payload);
            }
        } else {
            USE_SERIAL.printf("[HTTP] GET... failed, error: %s\n", http.errorToString(httpCode).c_str());
        }

        http.end();
    }

      // SLUT LARM
      
  }
  else{
  // Återställ, det är nu klart att radarn kört klart.             
    digitalWrite(LED_BUILTIN, HIGH);    // turn the LED off by making the voltage LOW
    slumpadDelay = random(5, 50);
    pulseWhite(slumpadDelay);
    
  }
  
   
  //delay(100);                       // wait for a second
}


void pulseRed(uint8_t wait) {
  for(int j = 50; j < 256 ; j++){
      for(uint16_t i=0; i<pixels.numPixels(); i++) {
          pixels.setPixelColor(i, pixels.Color(j,0,0 ) );
        }
        delay(wait);
        pixels.show();
      }

  for(int j = 255; j >= 50 ; j--){
      for(uint16_t i=0; i<pixels.numPixels(); i++) {
          pixels.setPixelColor(i, pixels.Color(j,0,0 ) );
        }
        delay(wait);
        pixels.show();
      }

}


void pulseWhite(uint8_t wait) {
  for(int j = 5; j < 30 ; j++){
      for(uint16_t i=0; i<pixels.numPixels(); i++) {
          pixels.setPixelColor(i, pixels.Color(j,j,j) );
         
        }
        delay(wait);
        pixels.show();
      }

  for(int j = 30; j >= 5 ; j--){
      for(uint16_t i=0; i<pixels.numPixels(); i++) {
          pixels.setPixelColor(i, pixels.Color(j,j,j) );
        }
        delay(wait);
        pixels.show();
      }
}

