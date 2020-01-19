using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;

class XTDetailedDistanceDataFieldView extends Ui.DataField {

    hidden var currentLapDistance = 0;
    hidden var onTimerLapDistance = 0;
    hidden var distance = 0;
    hidden var kmOrMileInMeters = 1000;
	hidden var distanceUnits = null;
    hidden const ZERO_DISTANCE3 = "0.000";
    hidden const ZERO_DISTANCE2 = "0.00";
    hidden const ZERO_DISTANCE1 = "0.0";
    hidden const ZERO_DISTANCE = "0";
    hidden var lastLapDistance = 0;
    hidden var showLastLap = false;
    hidden var prevLapDistance = 0;
    hidden var screenHeigth = 0;
    hidden var labelResource = Rez.Strings.label;
    hidden var lastLabLabelResource = Rez.Strings.lastlaplabel;
    hidden var deviceSettings = Sys.getDeviceSettings();
    hidden var version = deviceSettings.monkeyVersion;
	hidden var versionString = Lang.format("$1$.$2$.$3$", version);
	hidden var majorversionString = Lang.format("$1$", version);
	hidden var devicePartNumber = null;
	hidden var zerotooneDigits = 3;
	hidden var onetotenDigits = 2;
	hidden var tentohundredDigits = 2;
	hidden var hundredonwardsDigits = 1;
	hidden var valuePosY = 0;
	hidden var lastLapDistanceString = setDistStr(lastLapDistance);
	hidden var valueFont = Gfx.FONT_NUMBER_THAI_HOT;
	hidden var labelFont =  Gfx.FONT_XTINY;
	hidden var lastValueFont =  Gfx.FONT_XTINY;
	hidden var debugMode = false;	

    function initialize() {
        DataField.initialize();
    	if (debugMode == true) {showLastLap = true;}  
		else{showLastLap = getShowLastLapProp();}
		screenHeigth = deviceSettings.getDeviceSettings().screenHeight;
		devicePartNumber = getDevicePartNumber();
    	//Digits
		zerotooneDigits = App.getApp().getProperty("zerotoone");
		onetotenDigits = App.getApp().getProperty("onetoten");
		tentohundredDigits = App.getApp().getProperty("tentohundred");
		hundredonwardsDigits = App.getApp().getProperty("zerotoone");
		
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
    }

    // The given info object contains all the current workout
    // information. Calculate a value and save it locally in this method.
    function compute(info) {
        // See Activity.Info in the documentation for available information.
        if(info has :elapsedDistance){
            if(info.elapsedDistance != null){
                distance = (info.elapsedDistance != null ? info.elapsedDistance : 0);
                currentLapDistance =  distance - onTimerLapDistance;
               } 
            else {
                currentLapDistance = 0.000;
             }
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        
		// Get showLastLapp value
    	if (debugMode == true) {showLastLap = true;}  
		else{showLastLap = getShowLastLapProp();}  

    	//Digits
		zerotooneDigits = App.getApp().getProperty("zerotoone");
		onetotenDigits = App.getApp().getProperty("onetoten");
		tentohundredDigits = App.getApp().getProperty("tentohundred");
		hundredonwardsDigits = App.getApp().getProperty("hundredonwards");
               
		setDeviceSettingsDependentVariables();
			
		var lapDistanceString = setDistStr(currentLapDistance);		
	    
     	var width = dc.getWidth();
        var height = dc.getHeight();

        var backgroundColor = getBackgroundColor();
        // set background color
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        // set foreground color
        dc.setColor((backgroundColor == Gfx.COLOR_BLACK) ? Gfx.COLOR_WHITE : Gfx.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

		var valueFontHeight = Gfx.getFontHeight(valueFont);
		var valueFontDimentions = dc.getTextDimensions(lapDistanceString,valueFont);
		var labelFontHeight = Gfx.getFontHeight(labelFont);
		var labelFontDimentions = dc.getTextDimensions(Ui.loadResource(labelResource),labelFont);
		var labelPosY = 0;
		var lastValueFontHeight = Gfx.getFontHeight(lastValueFont);
		var lastValueFontDimentions = dc.getTextDimensions(lastLapDistanceString,lastValueFont);
		var lastValuePosY = 0;
		var combinedFontHeight = (labelFontHeight + valueFontHeight + lastValueFontHeight);
		var justification = getTextJustification();
		var justificationlvalue = getTextJustificationLValue();
		var startPosX = getStartPosX(width);

		if (isSingleFieldLayout()) {
			valueFont = Gfx.FONT_NUMBER_THAI_HOT;
			valueFontHeight = Gfx.getFontHeight(valueFont);
			valueFontDimentions = dc.getTextDimensions(lapDistanceString,valueFont);	

			var valuePosY = height / 2; 
			var labelPosY = valuePosY - ((labelFontHeight/2) + (valueFontHeight/2));
			var lastValuePosY = valuePosY + ((valueFontHeight/2) + (lastValueFontHeight/2));
			
            dc.drawText(startPosX, labelPosY, labelFont, Ui.loadResource(labelResource), justification);
			writeDebug("labelPosY = " + labelPosY);
            dc.drawText(startPosX, valuePosY, valueFont, lapDistanceString, justification);
			writeDebug("valuePosY = "+ valuePosY);
    		if (showLastLap == true){
				lastLapDistanceString = Ui.loadResource(lastLabLabelResource) + " " + setDistStr(lastLapDistance);
				writeDebug("lastValuePosY = " + lastValuePosY);
            	dc.drawText(startPosX, lastValuePosY, lastValueFont, lastLapDistanceString, justificationlvalue);
			}
        } 
        else {
        	valueFont = getValueFont(dc,lapDistanceString);
			valueFontHeight = Gfx.getFontHeight(valueFont);
			valueFontDimentions = dc.getTextDimensions(lapDistanceString,valueFont);

			//Top left or right
			var obscurityFlags = DataField.getObscurityFlags();
			var valuePosY = height / 2; 
			var labelPosY = valuePosY - ((valueFontHeight/2) + (labelFontHeight/2));
			var lastValuePosY = valuePosY + ((valueFontHeight/2) + (lastValueFontHeight/2));
			
			if ((obscurityFlags == 9) or (obscurityFlags == 12)){
				writeDebug("Top Left/Right location");
				valuePosY = height / 3; 
				labelPosY = valuePosY - ((valueFontHeight/2) + (labelFontHeight/2));
				lastValuePosY = valuePosY + ((valueFontHeight/2) + (lastValueFontHeight/2));			
			}
			if ((obscurityFlags == 3) or (obscurityFlags == 6)){
				writeDebug("Bottom Left/Right location");
				lastValuePosY = height - (lastValueFontHeight/2);	
				valuePosY = lastValuePosY - ((valueFontHeight/2) + (lastValueFontHeight/2)); 
				labelPosY = valuePosY - ((valueFontHeight/2) + (labelFontHeight/2));
			}
			/*		
			if ((obscurityFlags == 4)){
				justification = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
				justificationlvalue = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
			}
			if ((obscurityFlags == 8)){
				justification = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
				justificationlvalue = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
			}
			*/				
		
            dc.drawText(startPosX, labelPosY, labelFont, Ui.loadResource(labelResource), justification);
			writeDebug("labelPosY = "+ labelPosY);
            dc.drawText(startPosX, valuePosY, valueFont, lapDistanceString, justification);
			writeDebug("valuePosY = "+ valuePosY);
    		if (showLastLap == true){
				lastLapDistanceString = Ui.loadResource(lastLabLabelResource) + " " + setDistStr(lastLapDistance);
				writeDebug("lastValuePosY = " + lastValuePosY);
            	dc.drawText(startPosX, lastValuePosY, lastValueFont, lastLapDistanceString, justificationlvalue);
			}
        }
		//Debug info
		if (debugMode == true) {
				writeDebug("--------------");
				writeDebug("width: " + width);
				writeDebug("height: " + height);
				writeDebug("backgroundColor: " + backgroundColor);
				writeDebug("valueFont: " + valueFont);
				writeDebug("valueFontHeight: " + valueFontHeight);
				writeDebug("valueFontDimentions: " + valueFontDimentions);
				writeDebug("valuePosY: " + valuePosY);
				writeDebug("labelFont: " + labelFont);
				writeDebug("labelFontHeight: " + labelFontHeight);
				writeDebug("labelFontDimentions: " + labelFontDimentions);
				writeDebug("labelPosY: " + labelPosY);
				writeDebug("lastValueFont: " + lastValueFont);
				writeDebug("lastValueFontHeight: " + lastValueFontHeight);
				writeDebug("lastValueFontDimentions: " + lastValueFontDimentions);
				writeDebug("lastValuePosY: " + lastValuePosY);
				writeDebug("combinedFontHeight: " + combinedFontHeight);
				writeDebug("justification: " + justification);
				writeDebug("justificationlvalue: " + justificationlvalue);
				writeDebug("startPosX: " + startPosX);
 				writeDebug("devicePartNumber: " + devicePartNumber);
 				writeDebug("getObscurityFlags: " + DataField.getObscurityFlags());
				writeDebug("justification: " + getTextJustification());
 				writeDebug("--------------");												 
		}
    }
    
   	function isSingleFieldLayout() {
        return (DataField.getObscurityFlags() == OBSCURE_TOP | OBSCURE_LEFT | OBSCURE_BOTTOM | OBSCURE_RIGHT);
    }
    
    function getTextJustification() {
    	var justification;
        var textCenter = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
        writeDebug("textCenter = " + textCenter);
        var textRight = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
        writeDebug("textRight = " + textRight);
        var textLeft = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
        writeDebug("textLeft = " + textLeft);        
	    if ( (DataField.getObscurityFlags() == 12) or (DataField.getObscurityFlags() == 6)){
	    	justification = textLeft;
	    }
	    else if ((DataField.getObscurityFlags() == 3) or (DataField.getObscurityFlags() == 9)){
	    	justification = textRight;
	    }
	    else{
	    	justification = textCenter;
	    }
	    return justification;
    }
    
    function getTextJustificationLValue() {
    	var justification;
        var textCenter = Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER;
        var textRight = Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER;
        var textLeft = Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER;
	    if ( (DataField.getObscurityFlags() == 12) or (DataField.getObscurityFlags() == 6)){
	    	justification = textLeft;
	    }
	    else if ((DataField.getObscurityFlags() == 3) or (DataField.getObscurityFlags() == 9)){
	    	justification = textRight;
	    }
	    else{
	    	justification = textCenter;
	    }
	    return justification;
    }
    
    function getStartPosX(width) {
    	var startPosX = 0;
		var margin = Math.round((width /100) * 2);
	
	    if ( (DataField.getObscurityFlags() == 12) or (DataField.getObscurityFlags() == 6)){
	    	startPosX = 0 + margin;
	    }
	    else if ((DataField.getObscurityFlags() == 3) or (DataField.getObscurityFlags() == 9)){
	    	startPosX = width - margin;
	    }
	    else{
	    	startPosX = width /2;
	    }
	    return startPosX;
    }
   
	function onTimerLap(){
		lastLapDistance = distance - prevLapDistance;
		onTimerLapDistance = distance;
		prevLapDistance = distance;		
	}
	
	function onWorkoutStepComplete(){
		lastLapDistance = distance - prevLapDistance;
		onTimerLapDistance = distance;
		prevLapDistance = distance;		
	}

	function getShowLastLapProp(){        
        var showLastLap_prop = App.getApp().getProperty("showLastLap_prop");
        if(null==showLastLap_prop)
        {
            showLastLap = false;
        }
        else{
        	showLastLap = showLastLap_prop;
    	}
    	return showLastLap;
	}

	function setDistStr(distance) {
	    var distStr;
	    if (distance > 0) {
	        var distanceKmOrMiles = distance / kmOrMileInMeters;
	        if (distanceKmOrMiles < 1) {
	            distStr = distanceKmOrMiles.format("%." + zerotooneDigits + "f");
	            }
	        else if (distanceKmOrMiles < 10) {
	           	distStr = distanceKmOrMiles.format("%." + onetotenDigits + "f");
	        }
	        else if (distanceKmOrMiles < 100) {
	            distStr = distanceKmOrMiles.format("%." + tentohundredDigits + "f");
	        } 
	        else {
	            distStr = distanceKmOrMiles.format("%." + hundredonwardsDigits + "f");
	        }
	    } else {
	        if (zerotooneDigits == 3){
		        distStr = ZERO_DISTANCE3;
		        }
		    else if (zerotooneDigits == 2){
		    	distStr = ZERO_DISTANCE2;
		    	}
		    else if (zerotooneDigits == 1){
		    	distStr = ZERO_DISTANCE1;
		    	}		    	
	    	else {
	    		distStr = ZERO_DISTANCE;
	    	}
	    }
		return distStr;	
	}
	
	function setFontColor(item){
        // Set font color 
        if (getBackgroundColor() == Gfx.COLOR_BLACK) {
            item.setColor(Gfx.COLOR_WHITE);
        } else {
            item.setColor(Gfx.COLOR_BLACK);
        }
	}

	function setDeviceSettingsDependentVariables() {
        if (Sys.getDeviceSettings().distanceUnits == System.UNIT_METRIC) {
            kmOrMileInMeters = 1000;
        } 
        else {
            kmOrMileInMeters = 1610;
        }
    }
    
    function showDataField() {
        
		// Get showLastLapp value
    	showLastLap = getShowLastLapProp();  
    	if (debugMode == true) {showLastLap = false;}  
    	
    	//Digits
		zerotooneDigits = App.getApp().getProperty("zerotoone");
		onetotenDigits = App.getApp().getProperty("onetoten");
		tentohundredDigits = App.getApp().getProperty("tentohundred");
		hundredonwardsDigits = App.getApp().getProperty("zerotoone");
		    	       
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());
 
        // Set the foreground color and value
        var value = View.findDrawableById("value");
        setFontColor(value);
        
        // Set the font color and value
        var label = View.findDrawableById("label");
        setFontColor(label);
        
        // Set the font color and value
        var lastvalue = View.findDrawableById("lastvalue");
        setFontColor(lastvalue);
          
		setDeviceSettingsDependentVariables();
			
		var lapDistanceString = setDistStr(currentLapDistance);		
		value.setText(lapDistanceString);
		
		if (showLastLap == true){
			var lastLapDistanceString = setDistStr(lastLapDistance);
			lastvalue.setText(lastLapDistanceString);
		}
    }

	function getDevicePartNumber() {
		var deviceSettings = Sys.getDeviceSettings();
		// device part numbers come from ${SDKROOT}/bin/devices.xml
		var partNumber = deviceSettings.partNumber;
		return partNumber;
	}
	
	function getValueFont(dc,lapDistanceString) {
		var height = dc.getHeight();
		var width = dc.getWidth();
		var valueFont = Gfx.FONT_NUMBER_THAI_HOT;
		var valueFontHeight = Gfx.getFontHeight(valueFont);
		var labelFontHeight = Gfx.getFontHeight(labelFont);
		var lastValueFontHeight = Gfx.getFontHeight(lastValueFont);
		
		if ((valueFontHeight + labelFontHeight + lastValueFontHeight) > height){
			while (((valueFontHeight + labelFontHeight + lastValueFontHeight) > height) && valueFont >= 1 ){
				valueFont = valueFont - 1;
				valueFontHeight = Gfx.getFontHeight(valueFont);
			}
			writeDebug("heigth to small");
		}

		var valueFontWidth = dc.getTextWidthInPixels(lapDistanceString,valueFont);
		valueFontWidth = valueFontWidth + (valueFontWidth * 0.1);
		if (valueFontWidth > width){
			while ((valueFontWidth > width) && valueFont >= 1 ){
				valueFont = valueFont - 1;
				valueFontWidth = dc.getTextWidthInPixels(lapDistanceString,valueFont);
				valueFontWidth = valueFontWidth + (valueFontWidth * 0.1);
			}
			Sys.println("width to small");	
		} 
		 
		writeDebug("valueFont = " + valueFont);
		writeDebug("valueFontWidth = " + valueFontWidth);
		writeDebug("combinedFontHeight = " + (valueFontHeight + labelFontHeight + lastValueFontHeight));
		return valueFont;
	}
	
	function writeDebug(message){
		if(debugMode == true){
			Sys.println(message);
		}
	}
}

//deviceID list:
//fr920xt = "006-B1765-00"
//fenix3 = "006-B2050-00"
//fenix3_hr = "006-B2413-00"
//fenixchronos = "006-B2432-00"
//fenix5s = "006-B2544-00"
//fenix5x = "006-B2604-00"	
//fr935 = "006-B2691-00" 
//fenix5 = "006-B2697-00"
//vivoactive3 = "006-B2700-00"
//fr645	= "006-B2886-00"
//fr645m = "006-B2888-00"
//fenix5splus = "006-B2900-00"						
//vivoactive3m = "006-B2988-00"
   	//vivoactive3mlte = "006-B3066-00"
   	//fenix5plus = "006-B3110-00"
//fenix5xplus = "006-B3111-00"	
//fr245 = "006-B3076-00"
//fr245music = "006-B3077-00"
//fr945 = "006-B3113-00"

//Not used deviceID list:
//approachs60 = "006-B2656-00"
//d2bravo = "006-B2262-00"
//d2bravo_titanium = "006-B2547-00"
//d2charlie = "006-B2819-00"
//d2delta = "006-B3197-00"
//d2deltapx = "006-B3198-00"
//d2deltas = "006-B3196-00"
//descentmk1 = "006-B2859-00"
//edge1030 = "006-B2713-00"
//edge1030bontrager = "006-B3095-00"
//edge130 = "006-B2909-00"
//edge520plus = "006-B3112-00"
//edge820 = "006-B2530-00"
//edgeexplore = "006-B3011-00"
//edge_1000 = "006-B1836-00"
//edge_520 = "006-B2067-00"
//epix = "006-B1988-00"

//gpsmap66 = "006-B3028-00"
//oregon7xx = "006-B2512-00"
//rino7xx = "006-B2444-00"
//vivoactive_hr = "006-B2337-00"
//marqathlete = "006-B3251-00"
//fenix6pro = "006-B3290-00"
//fenix6 = "006-B3289-00"
//fenix6s = "006-B3287-00"
//fenix6spro = "006-B3288-00"
//fenix6xpro = "006-B3291-00"
//vivoactive4 = "006-B3225-00"
//vivoactive4s = "006-B3224-00"

