local base = require("plugin.device")
local teleinfo = require('teleinfo')
local print = print
local Promixis = Promixis
--local bit = require('bit')
local json = require('json')
local string = require('string')
local gir = gir
local tonumber = tonumber
local tostring = tostring
local table = require('table')
local ipairs = ipairs
local type=type
local unpack = unpack
local print = print


module(...)

base:subclass(_M)


function onControlValueChangeRequest(self, control, value, sender)
	
	if not self.teleinfo then
		return
	end
   control.ccontrol.hardwareValue = value
	
end


function start(self)	
	
   base.start(self)	
   self.teleinfo:connect( function ( connected )
		if not self.cdevice then
			return
		end

		
		if connected then
			self.cdevice.hardwareStatus = Promixis.Device.Status.STATUS_OK	
		else
			self.cdevice.hardwareStatus = Promixis.Device.Status.STATUS_UNKNOWN			
		end
		if self.cdevice then
			self.cdevice:hardwareStatusChanged( self.cdevice.id, self.cdevice.hardwareStatus)
		end
	end)
	
end

function stop(self)	
	base.stop(self)
	if self.teleinfo then
		self.teleinfo:disconnect()
	end	
end

local addGeneric = function(self, internalId, name, t,v  )

	
	local component = {}
	component.id = self.component.ccomponent.id
	component.pluginId = self.component.ccomponent.pluginId
	
   local device = {}
	device.id = self.cdevice.id
	component.devices = {
		device
	}
	
	local control = {}
	control.internalId = internalId
	control.name = string.local8BitToUtf8 (name)
	control.dtype = t
	if v then
		control.value = tostring(v)
	end
	
	device.controls = {
		control
	}

	local j = json.encode(component)
	self.component.componentManager.cComponentManager:createDevs(j)		
end

local addLabel = function ( self, item, name, value )	
	local internalId = item
	local name = name
	local t = Promixis.Control.DType.LABEL
	addGeneric(self, internalId, name, t, value)
end


local handleDEVICEEvent = function( self, event, item, value,name )

	if ( event == "VALUECHANGE" ) then		
		self:forEachControl( function( internalId, control )
				
				if internalId == item then
					if control.ccontrol then
						control.ccontrol.hardwareValue = value
					end
				end
		end)
		return
	end
	
	if (event == "ADDCONTROL") then
      local internalId = item
		local control = self:findControl(  internalId )
		if not control then
   		addLabel( self, item, name,value )
		end
	end
end


local teleinfoInit = function(self)
	self.teleinfo = teleinfo.new( self.cdevice.internalId,self.component.ccomponent.pluginId )
	self.teleinfo:subscribe( function( ... )
		handleDEVICEEvent(self, unpack(arg))
	end)
end

local teleinfoDeinit = function(self)
	if self.teleinfo then
		self.teleinfo:deinit()
		self.teleinfo = nil
	end
end

function onInternalIdChanged(self)
	teleinfoDeinit(self)
   base.onInternalIdChanged(self)	
	teleinfoInit(self)
end


--[[
	cdevice is c-based device object
	component is the lua based parent component.
--]]

function init ( self, cdevice, component )
	base.init(self, cdevice, component)
	self.evenCCF = true	
	teleinfoInit(self)	
end

function deinit( self )
	teleinfoDeinit(self)
	base.deinit(self)
end
