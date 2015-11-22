--  Skrivit av Ispep
--  2015-11-22 
--  Automatiserat.se 
--
--  Följande program släcker en enhet och loggar till loggserver
--  om ljuset understiger eller överstiger ett visst värde. 

local Powerdevice = 1 -- ID på lampan som ska tändas/släckas. 
local device = 2      -- Enheten som mäter ljus.
local lowLight = 10   -- Minsta gräns, under släcks lampan.
local highLight = 20   -- Högsta gräns, över så släcks lampan. 
local ICurrent = tonumber ((luup.variable_get("urn:micasaverde-com:serviceId:LightSensor1","CurrentLevel",device))) -- Hämtar ljusnivån och sparar detta som ett värde.
local Ipadress = '192.168.1.1:80' -- Ip adressen till loggserver.  saknar du loggserver så kan du välja att sätta "--" framför luup.inet.wget

if (ICurrent >= highLight) then
	luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget",{ newTargetValue="0" },Powerdevice )
	  luup.inet.wget('http://'..Ipadress..'/?Vera/Enhet1/OFF/Ljuset/'..ICurrent..'')
else 
     luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget",{ newTargetValue="1" },Powerdevice )
	 luup.inet.wget('http://'..Ipadress..'/?Vera/Enhet1/ON/Ljuset/'..ICurrent..'')

end