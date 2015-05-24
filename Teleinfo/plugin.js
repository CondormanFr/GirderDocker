 (function () {
    "use strict";

	
    var Plugin = function ( plugin ) {
	
		this.ds = {};
		
		this.plugin = plugin;
        this.m_Actions = [
        //     new SendIrAction(this)
        ];
		
		this.plugin.sendOutbound( this.plugin.id, 1, "" );				
    };

    Plugin.prototype.hasComponentManager = true;
   

    Plugin.prototype.actions = function () {
        return this.m_Actions;
    };

    Plugin.prototype.editDevice = function ( device, parent, manager ) {
        var ui = gir.ui("teleinfo/editDevice.ui", parent);
        ui.internalId.text = device.internalId
        ui.widget.applyButton.clicked.connect( function () {
            device.internalId = ui.internalId.text;
            manager.saveDevice(device, "UI");
            ui.close()
        });
        return ui;
    };
	
    Plugin.prototype.newDevice = function ( component, parent, manager ) {
		
		this.plugin.sendOutbound( this.plugin.id, 1, "" );	
		
		parent.windowTitle = "Add Teleinfo to Girder";
		
    var ui = gir.ui("teleinfo/newDevice.ui", parent);	
		var device = new Promixis.Device();	
		device.componentId = component.id;
		device.name = "teleinfo-";
		
  		var that = this;
		
		parent.closing.connect(function() {			
			delete that.ds[that];			
		});
        
		ui.widget.cancelButton.clicked.connect( function () {
			ui.close();
		});
		
        ui.widget.okButton.clicked.connect( function () {
            device.internalId = ui.internalId.text;
			      device.name = device.name + ui.internalId.text;
            manager.saveDevice(device, "UI");
			ui.close();
        });
        return ui;
    };	

	Plugin.prototype.flags = function ( object ) {
	
		return IGirderComponentManager.DeviceEditor | 			
			IGirderComponentManager.CanCreateDevice|
			IGirderComponentManager.CanDeleteDevice | 
			IGirderComponentManager.CanDeleteComponent;
	};
    
	Plugin.prototype.config = function( parent ) {			
		return gir.settingsInfoForm("The teleinfo setup can be found on the Device Manager pages.", parent);
	}	
   
    return Plugin;
}());