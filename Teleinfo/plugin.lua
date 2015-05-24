local base = require("plugin.plugin")
local ComponentManager = require("plugin.componentManager")
local json = require('json')
local table = require('table')
local print = print
local Device = require('teleinfo.device')
local Control = require('teleinfo.control')
local Promixis = Promixis

module(...)

base:subclass(_M)

-- if you need access to the instance of this plugin from Lua use this instance variable.
instance = nil


function start ( self )
	base.start(self)
end

function stop ( self )
	base.stop(self)
end

function actions ( self )
	return self._actions;	
end

--[[
function inbound ( self, id, msgId, data )	
	if ( msgId == 1 ) then		
		--self.plugin.sendOutbound( self.plugin.id, 1, json.encode(self.detector:list()))
	end
end
]]--

function create ( self, json )
	return self.cComponentManager:createDevs(json)
end


function createComponentManager( self, cComponentManager )
   self.cComponentManager = cComponentManager 
	self.componentManager = ComponentManager.new( self, cComponentManager, nil, function ( cdevice, component)
		-- device factory!
		return Device.new(cdevice, component)
		
	end, function ( ccontrol, device )
		
		return Control.new(ccontrol, device)

	end	) 
	return self.componentManager
end

function init ( self, plugin )
	base.init(self)
	self.plugin = plugin
	self._actions = {}
   instance = self	
end

function deinit( self )
	base.deinit(self)
	self._actions = {}	
	self.componentManager = nil
   instance = nil
end
