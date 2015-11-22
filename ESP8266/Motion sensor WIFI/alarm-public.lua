-- Changes made by Ispep - www.automatiserar.se
-- some code taken from ok1cdj
-- 2015 AReResearch (Andy Reischle)

SensorID = "1"
status = "CLEAR"
oldstatus = "CLEAR"

gpio.mode(4,gpio.INPUT,gpio.FLOAT)

tmr.alarm(0, 1000, 1, function() -- Set alarm to one second
	if gpio.read(4)==1 then status="1" else status="0" end
    if status ~= oldstatus then sendalarm (SensorID,status) end
	oldstatus = status
end)



function urlencode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str    
end

function sendalarm(SensorID,status)
print("Open connection...")
conn=net.createConnection(net.TCP, 0) 
conn:on("receive", function(conn, payload) print(payload) end) 
-- Add you servers ip address here.
-- If you use a host name/FQDN, it has to be all CAPITALS (Thanks Lee Rayner!) 
conn:connect(3480,'192.168.0.1') 
conn:send("GET /data_request?id=variableset&DeviceNum=136&serviceId=urn:micasaverde-com:serviceId:SecuritySensor1&Variable=Tripped&Value="..urlencode(status).." HTTP/1.1\r\n")
conn:send("Host: YOURVHOST.DOMAIN\r\n") 
conn:send("Accept: */*\r\n") 
conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
conn:send("\r\n")
conn:on("disconnection", function(conn)
     print("Disconnected...")
        end)
end
		
