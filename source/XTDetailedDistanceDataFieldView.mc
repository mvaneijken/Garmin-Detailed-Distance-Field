using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Math as Math;

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
    hidden var deviceSettings = Sys.getDeviceSettings();
    hidden var version = deviceSettings.monkeyVersion;
	hidden var versionString = Lang.format("$1$.$2$.$3$", version);
	hidden var majorversionString = Lang.format("$1$", version);
	hidden var devicePartNumber = null;
	hidden var zerotooneDigits = 3;
	hidden var onetotenDigits = 2;
	hidden var tentohundredDigits = 2;
	hidden var hundredonwardsDigits = 1;

    function initialize() {
        DataField.initialize();
        showLastLap = getShowLastLapProp();
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
    	showLastLap = getShowLastLapProp();  
    	//showLastLap = false;  

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

		var valueFont = Gfx.FONT_NUMBER_THAI_HOT;
		var valueFontHeight = Gfx.getFontHeight(valueFont);
		var valuePosY = height / 2;
		var labelFont =  Gfx.FONT_XTINY;
		var labelFontHeight = Gfx.getFontHeight(labelFont);
		var labelPosY = 0;
		var lastValueFont =  Gfx.FONT_XTINY;
		var lastValueFontHeight = Gfx.getFontHeight(lastValueFont);
		var lastValuePosY = 0;
		var indentY = getIndentY(height);
		var combinedFontHeight = (labelFontHeight + valueFontHeight + lastValueFontHeight);
		var justification = getTextJustification();
		var justificationlvalue = getTextJustificationLValue();
		var startPosX = getStartPosX(width);

		//For devices where Gfx.FONT_XTINY has the same height as Gfx.FONT_TINY, use FONT_TINY.
		//if (Gfx.getFontHeight(Gfx.FONT_TINY) == Gfx.getFontHeight(Gfx.FONT_XTINY)){
	//		labelFont =  Gfx.FONT_TINY;
	//		labelFontHeight = Gfx.getFontHeight(labelFont);
	//	} 
				
        // do layout
			//Used deviceID list:
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

			//Sys.println(devicePartNumber);
        if (isSingleFieldLayout()) {
			valueFont = Gfx.FONT_NUMBER_THAI_HOT;
			valueFontHeight = Gfx.getFontHeight(valueFont);
			valuePosY = Math.round(height / 2) + indentY;
	
			if (
				devicePartNumber.equals("006-B2432-00") //fenixchronos 
				|devicePartNumber.equals("006-B2544-00") //fenix5s
				|devicePartNumber.equals("006-B2604-00") //fenix5x 
				|devicePartNumber.equals("006-B2691-00") //fr935 
				|devicePartNumber.equals("006-B2697-00") //fenix5 
				|devicePartNumber.equals("006-B2886-00") //fr645	
				|devicePartNumber.equals("006-B2888-00") //fr645m
				|devicePartNumber.equals("006-B2900-00") //fenix5splus	
				|devicePartNumber.equals("006-B3110-00") //fenix5plus
				|devicePartNumber.equals("006-B3111-00") //fenix5xplus	 	
				|devicePartNumber.equals("006-B3076-00") //fr245
				|devicePartNumber.equals("006-B3077-00") //fr245music
				 	
				){
					labelPosY = valuePosY - Math.round(valueFontHeight / 1.5) + indentY - 5;
					lastValuePosY = valuePosY + Math.round(valueFontHeight / 1.5) + indentY + 5;
					//Sys.println("Single If ");
			}
			else {
				labelPosY = valuePosY - Math.round(valueFontHeight / 2) + Math.round(labelFontHeight / 2) + indentY - 5;
				lastValuePosY = valuePosY + Math.round(valueFontHeight / 2)  - Math.round(lastValueFontHeight /2) + indentY + 5;
				//Sys.println("Single Else ");
			}
            dc.drawText(startPosX, labelPosY, labelFont, Ui.loadResource(labelResource), justification);
            dc.drawText(startPosX, valuePosY, valueFont, lapDistanceString, justification);
    		if (showLastLap == true){
				var lastLapDistanceString = setDistStr(lastLapDistance);
            	dc.drawText(startPosX, lastValuePosY, lastValueFont, lastLapDistanceString, justificationlvalue);
			}
        } 
        else {
        	valueFont = Gfx.FONT_NUMBER_MILD;
			valueFontHeight = Gfx.getFontHeight(valueFont);
			
			labelPosY = valuePosY - (valueFontHeight );
			lastValuePosY = valuePosY + (valueFontHeight );
			
			if 	(
				devicePartNumber.equals("006-B2432-00") //fenixchronos 
				|devicePartNumber.equals("006-B2544-00") //fenix5s	
				|devicePartNumber.equals("006-B2604-00") //fenix5x 
				|devicePartNumber.equals("006-B2691-00") //fr935 
				|devicePartNumber.equals("006-B2697-00") //fenix5 
				|devicePartNumber.equals("006-B2886-00") //fr645	
				|devicePartNumber.equals("006-B2888-00") //fr645m
				|devicePartNumber.equals("006-B2900-00") //fenix5splus	
				|devicePartNumber.equals("006-B3110-00") //fenix5plus
				|devicePartNumber.equals("006-B3111-00") //fenix5xplus
				){
			   		labelPosY = valuePosY - Math.round(valueFontHeight / 1.2) + indentY - 5;
					lastValuePosY = valuePosY + Math.round(valueFontHeight / 1.2) + indentY + 5;
					//Sys.println("Multi if " +  DataField.getObscurityFlags()  + " " + height);
	   		} 			
			else {	
				if ((height > 67) && !(
						devicePartNumber.equals("006-B1765-00") //fr920xt
						|devicePartNumber.equals("006-B2050-00") //fenix3
						|devicePartNumber.equals("006-B2413-00") //fenix3_hr
						|devicePartNumber.equals("006-B2700-00") //vivoactive3
						|devicePartNumber.equals("006-B2988-00") //vivoactive3m
		   				|devicePartNumber.equals("006-B3066-00") //vivoactive3mlte		
						|devicePartNumber.equals("006-B3076-00") //fr245
						|devicePartNumber.equals("006-B3077-00") //fr245music
						|devicePartNumber.equals("006-B3113-00") //fr945
						
						)){
							valueFont = Gfx.FONT_NUMBER_MEDIUM;
							labelPosY = valuePosY - Math.round(valueFontHeight / 1.5) + indentY - 5;
							lastValuePosY = valuePosY + Math.round(valueFontHeight / 1.5) + indentY + 5;
							//Sys.println("Multi else 1 " +  DataField.getObscurityFlags() + " " + height);
					}
				else if ((height > 67) && (
							devicePartNumber.equals("006-B1765-00") //fr920xt
							|devicePartNumber.equals("006-B2050-00") //fenix3
							|devicePartNumber.equals("006-B2413-00") //fenix3_hr
							)){
						valueFont = Gfx.FONT_NUMBER_MEDIUM;
						labelPosY = valuePosY - Math.round(valueFontHeight / 1.5) + indentY - 5;
						lastValuePosY = valuePosY + Math.round(valueFontHeight / 1.5) + indentY + 7;
						//Sys.println("Multi else 2 " +  DataField.getObscurityFlags() + " " + height);
				}
				else{
					labelPosY = valuePosY - Math.round(valueFontHeight / 2) + indentY - 5;// + Math.round(labelFontHeight / 2);
					lastValuePosY = valuePosY + Math.round(valueFontHeight / 2) + indentY + 5;//  - Math.round(lastValueFontHeight /2);
					//Sys.println("Multi else 3 " +  DataField.getObscurityFlags() + " " + height);
					}
			}
			valuePosY = Math.round(height / 2) + indentY;

            dc.drawText(startPosX, labelPosY, labelFont, Ui.loadResource(labelResource), justification);
            dc.drawText(startPosX, valuePosY, valueFont, lapDistanceString, justification);
    		if (showLastLap == true){
				var lastLapDistanceString = setDistStr(lastLapDistance);
            	dc.drawText(startPosX, lastValuePosY, lastValueFont, lastLapDistanceString, justificationlvalue);
			}
        }
    }
    
   	function isSingleFieldLayout() {
        return (DataField.getObscurityFlags() == OBSCURE_TOP | OBSCURE_LEFT | OBSCURE_BOTTOM | OBSCURE_RIGHT);
    }
    
    function getTextJustification() {
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

    function getIndentY(height) {
    	var indentY = 0;
    	var margin = Math.round((height /100) * 2);

	    if ( (DataField.getObscurityFlags() == 3) or (DataField.getObscurityFlags() == 6)){
	    	indentY = 20 - margin;
	    }
	    else if ((DataField.getObscurityFlags() == 12) or (DataField.getObscurityFlags() == 9)){
	    	indentY = -20 + margin;
	    }
	    else{
	    	indentY = 0;
	    }
	    return indentY;
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
    	//showLastLap = false;  
    	
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
}