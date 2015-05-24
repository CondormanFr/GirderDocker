local print = print
local base = require("plugin.control")

module (...)

base:subclass( _M)


function onRequestValueChanged(self, value, sender )
	self.device.onControlValueChangeRequest(self.device, self, value, sender )	
end

function init ( self, ccontrol, device )	
	base.init(self, ccontrol, device)
end

function deinit( self )
	base.deinit(self)
end

