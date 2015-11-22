wifi.setmode(wifi.STATION)
wifi.sta.config("Wifinetwork","password")
print(wifi.sta.getip())
