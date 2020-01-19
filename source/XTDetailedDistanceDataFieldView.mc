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
    hidden var deviceSettings = Sys.getDeviceSettings();
    hidden var version = deviceSettings.monkeyVersion;
	hidden var versionString = Lang.format("$1$.$2$.$3$", version);
	hidden var majorversionString = Lang.format("$1$", version);
	hidden var devicePartNumber = null;
	hidden var zerotooneDigits = 3;
	hidden var onetotenDigits = 2;
	hidden var tentohundredDigits = 2;
	hidden var hundredonwardsDigits = 1;
	hidden var debugmode = true;
	hidden var valuePosY = 0;
	hidden var lastLapDistanceString = setDistStr(lastLapDistance);
	hidden var valueFont = Gfx.FONT_NUMBER_THAI_HOT;
	hidden var labelFont =  Gfx.FONT_XTINY;
	hidden var lastValueFont =  Gfx.FONT_XTINY;
	
	

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
    	if (debugmode == true) {showLastLap = true;}  

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
		var indentY = getIndentY(height);
		var combinedFontHeight = (labelFontHeight + valueFontHeight + lastValueFontHeight);
		var justification = getTextJustification();
		var justificationlvalue = getTextJustificationLValue();
		var startPosX = getStartPosX(width);

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
		//fenix6pro = "006-B3290-00"
		//fenix6 = "006-B3289-00"
		//fenix6s = "006-B3287-00"
		//fenix6spro = "006-B3288-00"
		//fenix6xpro = "006-B3291-00"
		//vivoactive4 = "006-B3225-00"
		//vivoactive4s = "006-B3224-00"
		
        if (isSingleFieldLayout()) {
			valueFont = Gfx.FONT_NUMBER_THAI_HOT;
			valueFontHeight = Gfx.getFontHeight(valueFont);
			valueFontDimentions = dc.getTextDimensions(lapDistanceString,valueFont);	
		

			var valuePosY = height / 2; 
			var labelPosY = valuePosY - ((labelFontHeight/2) + (valueFontHeight/2));
			var lastValuePosY = valuePosY + ((valueFontHeight/2) + (lastValueFontHeight/2));

						
			
            dc.drawText(startPosX, labelPosY, labelFont, Ui.loadResource(labelResource), justification);
			Sys.println(labelPosY);
            dc.drawText(startPosX, valuePosY, valueFont, lapDistanceString, justification);
			Sys.println(valuePosY);
    		if (showLastLap == true){
				lastLapDistanceString = setDistStr(lastLapDistance);
				Sys.println(lastValuePosY);
            	dc.drawText(startPosX, lastValuePosY, lastValueFont, lastLapDistanceString, justificationlvalue);
			}


			
			
		/*	valueFont = Gfx.FONT_NUMBER_THAI_HOT;
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
				if (debugmode == true) {Sys.println("isSingleFieldLayout - If ");}
			}
			else {
				labelPosY = valuePosY - Math.round(valueFontHeight / 2) + Math.round(labelFontHeight / 2) + indentY - 5;
				lastValuePosY = valuePosY + Math.round(valueFontHeight / 2)  - Math.round(lastValueFontHeight /2) + indentY + 5;
				if (debugmode == true) {Sys.println("isSingleFieldLayout - Else");}
			}
            dc.drawText(startPosX, labelPosY, labelFont, Ui.loadResource(labelResource), justification);
            Sys.println(labelPosY);
            dc.drawText(startPosX, (labelPosY + (labelFontHeight/2) + (valueFontHeight/2)), valueFont, lapDistanceString, justification);
            Sys.println((labelPosY + (labelFontHeight*2)));
    		if (showLastLap == true){
				lastLapDistanceString = setDistStr(lastLapDistance);
				Sys.println((labelPosY + ((labelFontHeight*2) + valueFontHeight)));
            	dc.drawText(startPosX, (labelPosY + (labelFontHeight/2) + (valueFontHeight/2) + (valueFontHeight/2) + (lastValueFontHeight/2)), lastValueFont, lastLapDistanceString, justificationlvalue);
			}
			*/

			//Temp
			//dc.drawText(startPosX, (labelPosY + (labelFontHeight*2)), valueFont, "TEST", justification);
			//dc.drawText(startPosX, labelPosY , labelFont, "TEST2", justification);


        } 
        else {
        	valueFont = getValueFont(dc,lapDistanceString);
			valueFontHeight = Gfx.getFontHeight(valueFont);
			valueFontDimentions = dc.getTextDimensions(lapDistanceString,valueFont);

			//Top left or right
			/*
Sys.println("OBSCURE_TOP|OBSCURE_LEFT " + OBSCURE_TOP|OBSCURE_LEFT);
Sys.println("OBSCURE_BOTTOM|OBSCURE_LEFT " + OBSCURE_BOTTOM|OBSCURE_LEFT);
Sys.println("OBSCURE_TOP|OBSCURE_RIGHT " + OBSCURE_TOP|OBSCURE_RIGHT);
Sys.println("OBSCURE_BOTTOM|OBSCURE_RIGHT " + OBSCURE_BOTTOM|OBSCURE_RIGHT);
			/* if ( (DataField.getObscurityFlags() == OBSCURE_TOP|OBSCURE_LEFT) or (DataField.getObscurityFlags() == (OBSCURE_BOTTOM|OBSCURE_LEFT)){
				var lastValuePosY = height - (lastValueFontHeight/2);
				var valuePosY = lastValuePosY - ((valueFontHeight/2) + (lastValueFontHeight/2)); 
				var labelPosY = valuePosY - ((valueFontHeight/2) + (labelFontHeight/2));
			}
			//Bottom left or right
			else if ((DataField.getObscurityFlags() == 6) or (DataField.getObscurityFlags() == 9)){
				var valuePosY = height / 2; 
				var labelPosY = valuePosY - ((valueFontHeight/2) + (labelFontHeight/2));
				var lastValuePosY = valuePosY + ((valueFontHeight/2) + (lastValueFontHeight/2));
			}
			else{ */						
				var valuePosY = height / 2; 
				var labelPosY = valuePosY - ((valueFontHeight/2) + (labelFontHeight/2));
				var lastValuePosY = valuePosY + ((valueFontHeight/2) + (lastValueFontHeight/2));
			//}				

            dc.drawText(startPosX, labelPosY, labelFont, Ui.loadResource(labelResource), justification);
			Sys.println(labelPosY);
            dc.drawText(startPosX, valuePosY, valueFont, lapDistanceString, justification);
			Sys.println(valuePosY);
    		if (showLastLap == true){
				lastLapDistanceString = setDistStr(lastLapDistance);
				Sys.println(lastValuePosY);
            	dc.drawText(startPosX, lastValuePosY, lastValueFont, lastLapDistanceString, justificationlvalue);
			}
			
			
			/* labelPosY = valuePosY - (valueFontHeight );
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
					if (debugmode == true) {Sys.println("isMultiFieldLayout - If " +  DataField.getObscurityFlags()  + " " + height);}
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
						|devicePartNumber.equals("006-B3225-00") //vivoactive4						
						|devicePartNumber.equals("006-B3224-00") //vivoactive4s					
						
						)){
							valueFont = Gfx.FONT_NUMBER_MEDIUM;
							labelPosY = valuePosY - Math.round(valueFontHeight / 1.5) + indentY - 5;
							lastValuePosY = valuePosY + Math.round(valueFontHeight / 1.5) + indentY + 5;
							if (debugmode == true) {Sys.println("isMultiFieldLayout - Else - If " +  DataField.getObscurityFlags() + " " + height);}
					}
					else if ((height > 67) && (
								devicePartNumber.equals("006-B1765-00") //fr920xt
								|devicePartNumber.equals("006-B2050-00") //fenix3
								|devicePartNumber.equals("006-B2413-00") //fenix3_hr
								)){
							valueFont = Gfx.FONT_NUMBER_MEDIUM;
							labelPosY = valuePosY - Math.round(valueFontHeight / 1.5) + indentY - 5;
							lastValuePosY = valuePosY + Math.round(valueFontHeight / 1.5) + indentY + 7;
							if (debugmode == true) {Sys.println("isMultiFieldLayout - Else - Else If " +  DataField.getObscurityFlags() + " " + height);}						
					}
					else{
						labelPosY = valuePosY - Math.round(valueFontHeight / 2) + indentY - 5;// + Math.round(labelFontHeight / 2);
						lastValuePosY = valuePosY + Math.round(valueFontHeight / 2) + indentY + 5;//  - Math.round(lastValueFontHeight /2);
						if (debugmode == true) {Sys.println("isMultiFieldLayout - Else - Else " +  DataField.getObscurityFlags() + " " + height);}
					}
			}
			valuePosY = Math.round(height / 2) + indentY;

            dc.drawText(startPosX, labelPosY, labelFont, Ui.loadResource(labelResource), justification);
            dc.drawText(startPosX, valuePosY, valueFont, lapDistanceString, justification);
    		if (showLastLap == true){
				lastLapDistanceString = setDistStr(lastLapDistance);
            	dc.drawText(startPosX, lastValuePosY, lastValueFont, lastLapDistanceString, justificationlvalue);
			}*/
        }
		//Debug info
		if (debugmode == true) {
				Sys.println("--------------");
				Sys.println("width: " + width);
				Sys.println("height: " + height);
				Sys.println("backgroundColor: " + backgroundColor);
				Sys.println("valueFont: " + valueFont);
				Sys.println("valueFontHeight: " + valueFontHeight);
				Sys.println("valueFontDimentions: " + valueFontDimentions);
				Sys.println("valuePosY: " + valuePosY);
				Sys.println("labelFont: " + labelFont);
				Sys.println("labelFontHeight: " + labelFontHeight);
				Sys.println("labelFontDimentions: " + labelFontDimentions);
				Sys.println("labelPosY: " + labelPosY);
				Sys.println("lastValueFont: " + lastValueFont);
				Sys.println("lastValueFontHeight: " + lastValueFontHeight);
				Sys.println("lastValueFontDimentions: " + lastValueFontDimentions);
				Sys.println("lastValuePosY: " + lastValuePosY);
				Sys.println("indentY: " + indentY);
				Sys.println("combinedFontHeight: " + combinedFontHeight);
				Sys.println("justification: " + justification);
				Sys.println("justificationlvalue: " + justificationlvalue);
				Sys.println("startPosX: " + startPosX);
 				Sys.println("devicePartNumber: " + devicePartNumber);
 				Sys.println("getObscurityFlags: " + DataField.getObscurityFlags());
				Sys.println("justification: " + getTextJustification());
 				Sys.println("--------------");												 
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
    	if (debugmode == true) {showLastLap = false;}  
    	
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
			Sys.println("heigth to small");
		}

		var valueFontWidth = dc.getTextWidthInPixels(lapDistanceString,valueFont);
		if (valueFontWidth > width){
			while ((valueFontWidth > width) && valueFont >= 1 ){
				valueFont = valueFont - 1;
				valueFontWidth = dc.getTextWidthInPixels(lapDistanceString,valueFont);
			}
			Sys.println("width to small");	
		} 
		 
		Sys.println("valueFont = " + valueFont);
		Sys.println("valueFontWidth = " + valueFontWidth);
		Sys.println("combinedFontHeight = " + (valueFontHeight + labelFontHeight + lastValueFontHeight));

		
		return valueFont;

		
		// device part numbers come from ${SDKROOT}/bin/devices.xml
		var partNumber = deviceSettings.partNumber;
		return partNumber;
	}
	

	
	
}