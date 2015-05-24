--[[
  teleinfo
  Copyright 2015 (c) Romain GOUYET
--]]

-- the base class for this object.
local Base = require('Class') 

-- Includes that we'll need
local Promixis = Promixis
local transport = require('transport')
local string = require('string')
local print = print
--local timer = require("timer")
local table = require("table")
local math = require("math")
local date = require("date")
--local ipairs = ipairs
local pairs        = pairs
local gir = gir
local socket = require('socket')
local publisher = require('publisher')
local delay = require('delay')


module (...)

Base:subclass( _M)

local teleinfoLabels = {
         ["PAPP"]="Puissance apparente",
         ["ADCO"]="Identification",
         ["OPTARIF"]="Option tarifaire",
         ["ISOUSC"]="Intensite souscrite",
         ["BASE"]="Index",
         ["HCHC"]="Index heures creuses",
         ["HCHP"]="Index heures pleines",
         ["EJP HN"]="Index heures normales",
         ["EJP HPM"]="Index heures de pointe mobile",
         ["BBR HC JB"]="Index heures creuses jours bleus",
         ["BBR HP JB"]="Index heures pleines jours bleus",
         ["BBR HC JW"]="Index heures creuses jours blancs",
         ["BBR HP JW"]="Index heures pleines jours blancs",
         ["BBR HC JR"]="Index heures creuses jours rouges",
         ["BBR HP JR"]="Index heures pleines jours rouges",
         ["PEJP"]="Preavis EJP",
         ["PTEC"]="Période tarifaire",
         ["DEMAIN"]="Couleur du lendemain",
         ["IINST"]="Intensite instantanee",
         ["ADPS"]="Avertissement de depassement de puissance souscrite",
         ["IMAX"]="Intensite maximale",
         ["HHPHC"]="Groupe horaire",
         ["MOTDETAT"]="Mot d\’etat"
         }

function get_name_for_label( t, label )
  for k,v in pairs(t) do
    if k==label then
       return v
    end
  end
  return nil
end

-- Return a display string for a date and time object
local FormatDateTime = function(t)
	return string.format("%02u/%02u/%04u   %02u:%02u:%02u", t.Day, t.Month, t.Year, t.Hour, t.Minute, t.Second)
end

-- Parse the teleinfo DATA TRAME RECEIVED FROM DEVICE 
function ParseteleinfoData(self, data) 

   if string.sub (data,1,1) == math.hextobyte ("02")  then
      local messages = {}
      messages = string.split(string.sub(data,2,string.len(data)), math.hextobyte ("0D"))
      --print ("Nombre de messages" , table.getn(messages))

      local Info = {}
      for i= 1, table.getn(messages)-1 do
           Info = string.split( string.sub (messages[i],2,string.len(messages[i])), math.hextobyte("20"))
           --print ('Received  ',Info[1],' with data ',Info[2], 'checksum',Info[3])
           local teleinfoLabel = string.trim(Info[1])
           local teleinfoValue = string.trim(Info[2])
           local teleinfoChecksum = string.trim(Info[3])
           
           publisher:publish("ADDCONTROL",teleinfoLabel , teleinfoValue,get_name_for_label(teleinfoLabels,teleinfoLabel))
           if self.values[teleinfoLabel] ~= teleinfoValue then
                --gir.triggerEvent(teleinfoLabel.."_changed",self.pluginID,EVENT_MOD_NONE,{teleinfoValue})
                publisher:publish("VALUECHANGE",teleinfoLabel , teleinfoValue,get_name_for_label(teleinfoLabels,teleinfoLabel))
                --publisher:publish("VALUECHANGE",teleinfoLabel , "500")
               
               if self.values.PTEC == "HP.." and teleinfoValue == "HC.." then
       		        gir.triggerEvent("HeuresCreuses",self.pluginID,EVENT_MOD_NONE,"")
       		     elseif  self.values.PTEC == "HC.." and teleinfoValue == "HP.."  then
       		     	   gir.triggerEvent("HeuresPleines",self.pluginID,EVENT_MOD_NONE,"")
       		   end
           end
           self.values[teleinfoLabel] = teleinfoValue
           
       end  -- for
      self.values.LastUpdate = date.now()
      self.values.DateText = FormatDateTime(date:now())
      self.values.LastUpdateUnixTime = socket.gettime()*1000
   end --if string.sub (data,1,1) == math.hextobyte ("02")
end   --ParseteleinfoData


function receiveData ( self, callback )
	if not self.connection then
		return false
	end
	
	local tx = self.connection:newTransaction( 
      --Sent
      function()
		end, 

		--Received
      function( data )
			if callback then
				callback(data)
			end
			return Promixis.Transport.ITransactionCallback.Results.TX_KEEP
			
		end, 

		-- Timeout
      function ()
		end
	)
	tx:persistent(true)	
   tx:timeout(5000)
	self.connection:send(tx, true)
	
end

local connectionCallback = function(self, event, reason ,callback)


	if event == Promixis.Transport.IConnectionCallback.Status.CONNECTION_ESTABLISHED then
		print("Connection Established")
      gir.log(Promixis.Log.OK, self.pluginID, "teleinfo started on port" .. " " .. self.Comport)
     
      receiveData(self, function( data )
        ParseteleinfoData(self, data)
		end)		
      
      if callback then
		  callback(true)
	   end
      
	end
	
	if event == Promixis.Transport.IConnectionCallback.Status.CONNECTION_CLOSED then
		print("Connection Closed")
      if not self.closing then
			delay.run(2000, function()
				if self.connection then
               print("Retry to connect")
					self.connection:connect();
				end
			end)
		end
      
      if callback then
		  callback(false)
	   end
	end
	
   	
	if event == Promixis.Transport.IConnectionCallback.Status.CONNECTION_FAILED then
		
		print("Connection failed")
      gir.triggerEvent("Connection failed",self.pluginID,EVENT_MOD_NONE)
      gir.log(Promixis.Log.ERROR, self.pluginID, "Connection failed")
      
      delay.run(5000, function() 
         if ( self.connection ) then
            print("Retry to connect")
            self.connection:connect();
         end
      end)
	end
end

function connect( self, callback )

	connection = transport.new ( Promixis.Transport.Connection.Type.CON_SERIAL, self.Comport, function ( event, reason )		
		connectionCallback(self, event,reason,callback)	
	end)
	
	--Sets the baud rate for the connection. Call before actually connecting.
   self.connection:baud ( self.Baud )
   --Sets the flow control for the connection.
   self.connection:flow ( self.Flow )
   --Sets the parity for the connection.
   self.connection:parity( self.Parity )
   --Sets the number of stop bits for the connection.
   self.connection:stopBits( self.StopBits )
   --Sets the number of bits in a character.
   self.connection:characterSize( self.CharacterSize )
   --Sets the ending char
   self.connection:parser( Promixis.Transport.IParser.Type.PARSER_TERMINATED, math.hextobyte("03") ) --ETX
   self.closing = false
   self.connection:connect()
	
end


function disconnect( self )
   print ("Asking for Disconnect")
   if self.connection then
      print ("connection exists")
      self.closing = true
      self.connection:close()	
      self.connection = nil
   end
end


function subscribe(self, cb)
	return publisher:subscribe(cb)
end
function unsubscribe(self, id)
	return publisher:unsubscribe(id)
end

function init ( self, COMport,PluginID )
   Base.init(self)
   Comport = COMport
   pluginID = PluginID
   
   if not self.Comport then
         self.Comport = "COM5"
   end
   if not self.PluginID then
         self.PluginID = 1028
   end
   
   
   Baud = 1200
   Flow = Promixis.Transport.SerialConnection.FlowControl.FLOW_HARDWARE
   Parity = Promixis.Transport.SerialConnection.Parity.PARITY_ODD
   CharacterSize = 7
   StopBits = Promixis.Transport.SerialConnection.StopBits.STOP_ONE   
   values = {}
   publisher = publisher.new()
   closing = false
end

function deinit( self )	
  disconnect(self)
  publisher:deinit()
  Base.deinit(self)
end

