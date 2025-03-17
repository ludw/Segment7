import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Weather;
import Toybox.Complications;

class Segment7View extends WatchUi.WatchFace {

    hidden var screenHeight as Number;
    hidden var screenWidth as Number;
    hidden var clockHeight as Number;
    hidden var clockWidth as Number;
    hidden var dataHeight as Number;
    hidden var textPadding as Number;
    hidden var centerX as Number;
    hidden var centerY as Number;
    hidden var marginY as Number;

    hidden var fontClock as WatchUi.FontResource;
    hidden var fontData as WatchUi.FontResource;
    hidden var fontPatterns as WatchUi.FontResource;
    
    hidden var dataTopLeft as String = "";
    hidden var dataTopRight as String = "";
    hidden var dataBottomLeft as String = "";
    hidden var dataBottomRight as String = "";
    hidden var dataBattery as String = "";

    hidden var canBurnIn as Boolean;
    hidden var isSleeping as Boolean = false;
    hidden var forceUpdate as Boolean = true;

    hidden var weatherCondition as CurrentConditions?;

    hidden var propFieldTopLeft as Number = 0;
    hidden var propFieldTopRight as Number = 0;
    hidden var propFieldBottomLeft as Number = 0;
    hidden var propFieldBottomRight as Number = 0;

    hidden var propTheme as Number = 0;
    hidden var propShowClockBg as Boolean = true;

    hidden var propHourFormat as Number = 0;
    hidden var propDateFormat as Number = 0;
    hidden var propShowUnits as Boolean = true;
    hidden var propUnits as Number = 0;
    hidden var propWindUnit as Number = 0;
    hidden var propPressureUnit as Number = 0;

    enum colorNames {
        clockBg = 0,
        clock,
        battBg,
        battBar,
        battEmpty
    }

    (:PaletteBase) const clockBgText = "##:##";
    (:Palette8) const clockBgText = "$$:$$";

    function initialize() {
        WatchFace.initialize();

        screenHeight = Toybox.System.getDeviceSettings().screenHeight;
        screenWidth = Toybox.System.getDeviceSettings().screenWidth;

        if(screenHeight < 240) {
            fontClock = WatchUi.loadResource(Rez.Fonts.SevenSegment47) as WatchUi.FontResource;
            fontData = WatchUi.loadResource(Rez.Fonts.LedSmall) as WatchUi.FontResource;
            clockHeight = 47;
            clockWidth = 157;
            dataHeight = 13;
            textPadding = 2;
        } else if(screenHeight >= 240 and screenHeight <= 280) {
            fontClock = WatchUi.loadResource(Rez.Fonts.SevenSegment72) as WatchUi.FontResource;
            fontData = WatchUi.loadResource(Rez.Fonts.LedLines) as WatchUi.FontResource;
            clockHeight = 72;
            clockWidth = 211;
            dataHeight = 20;
            textPadding = 3;
        } else if(screenHeight > 280 and screenHeight < 416) {
            fontClock = WatchUi.loadResource(Rez.Fonts.SevenSegment100) as WatchUi.FontResource;
            fontData = WatchUi.loadResource(Rez.Fonts.LedLines) as WatchUi.FontResource;
            clockHeight = 100;
            clockWidth = 300;
            dataHeight = 20;
            textPadding = 4;
        } else {
            fontClock = WatchUi.loadResource(Rez.Fonts.SevenSegment124) as WatchUi.FontResource;
            fontData = WatchUi.loadResource(Rez.Fonts.LedBig) as WatchUi.FontResource;
            clockHeight = 124;
            clockWidth = 364;
            dataHeight = 27;
            textPadding = 6;
        }

        centerX = Math.round(screenWidth / 2);
        centerY = Math.round(screenHeight / 2);
        marginY = Math.round(screenHeight / 25);

        fontPatterns = WatchUi.loadResource(Rez.Fonts.Patterns) as WatchUi.FontResource;
        canBurnIn = System.getDeviceSettings().requiresBurnInProtection;

        updateProperties();
        updateWeather();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var now = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

        if(now.sec % 60 == 0 or forceUpdate) {
            forceUpdate = false;
            updateData();

            if(now.min % 5 == 0 or weatherCondition == null) {
                updateWeather();
            }
        }

        drawWatchface(dc, now);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        forceUpdate = true;
        isSleeping = false;
        WatchUi.requestUpdate();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        forceUpdate = true;
        isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onSettingsChanged() as Void {
        updateProperties();
        forceUpdate = true;
        WatchUi.requestUpdate();
    }

    hidden function drawWatchface(dc as Dc, now as Gregorian.Info) as Void {
        var time_to_draw = Lang.format("$1$:$2$", [now.hour.format("%02d"), now.min.format("%02d")]);
        var half_clock_height = Math.round(clockHeight / 2);
        var half_clock_width = Math.round(clockWidth / 2);

        // Clear
        dc.setColor(0x333333, 0x000000);
        dc.clear();

        // Background pattern
        if(!isSleeping or !canBurnIn) {
            drawPattern(dc, "0000000000", 0x555555, 0);
            //drawPattern(dc, "2222222222", 0x555555, 0);
        }

        // Draw Clock
        dc.setColor(getColor(clockBg), Graphics.COLOR_TRANSPARENT);
        if(propShowClockBg) {
            dc.drawText(centerX, centerY, fontClock, clockBgText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.setColor(getColor(clock), Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, fontClock, time_to_draw, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw Data fields
        drawTextWithPadding(dc,
                            centerX - half_clock_width + textPadding, centerY - half_clock_height - marginY - dataHeight,
                            fontData, dataTopLeft, Graphics.TEXT_JUSTIFY_LEFT,
                            0xFFFFFF);
        drawTextWithPadding(dc,
                            centerX + half_clock_width - textPadding, centerY - half_clock_height - marginY - dataHeight,
                            fontData, dataTopRight, Graphics.TEXT_JUSTIFY_RIGHT,
                            0xFFFFFF);
        drawTextWithPadding(dc,
                            centerX - half_clock_width + textPadding, centerY + half_clock_height + marginY,
                            fontData, dataBottomLeft, Graphics.TEXT_JUSTIFY_LEFT,
                            0xFFFFFF);
        drawTextWithPadding(dc,
                            centerX + half_clock_width - textPadding, centerY + half_clock_height + marginY,
                            fontData, dataBottomRight, Graphics.TEXT_JUSTIFY_RIGHT,
                            0xFFFFFF);

        // Draw battery bar
        drawBatteryBar(dc);

        // AOD burn in prevention pattern
        if(isSleeping and canBurnIn) {
            drawPattern(dc, "1111111111", 0x000000, now.min % 2);
        }
    }

    hidden function drawTextWithPadding(dc as Dc, x as Number, y as Number, font as FontType, text as String, justify as TextJustification, color as ColorType) as Void {
        var text_dim = dc.getTextDimensions(text, font) as [Lang.Number, Lang.Number];
        dc.setColor(0x000000, 0x000000);
        if(justify == Graphics.TEXT_JUSTIFY_LEFT) {
            dc.fillRectangle(x - textPadding, y - textPadding, text_dim[0] + (textPadding * 2), text_dim[1] + (textPadding * 2));
        } else {
            dc.fillRectangle(x - text_dim[0] - textPadding, y - textPadding, text_dim[0] + (textPadding * 2), text_dim[1] + (textPadding * 2));
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, justify);
    }

    hidden function drawBatteryBar(dc as Dc) {
        var text_dim = dc.getTextDimensions("}}}}}}", fontData) as [Lang.Number, Lang.Number];
        dc.setColor(0x000000, 0x000000);
        dc.fillRectangle(centerX - (text_dim[0] / 2) - textPadding, screenHeight - dataHeight - marginY, text_dim[0] + (textPadding * 2), text_dim[1]);

        dc.setColor(getColor(battBg), Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX - (text_dim[0] / 2), screenHeight - dataHeight - marginY, fontData, "}}}}}}", Graphics.TEXT_JUSTIFY_LEFT);
        if(dataBattery.length() <= 1) {
            dc.setColor(getColor(battEmpty), Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(getColor(battBar), Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(centerX - (text_dim[0] / 2), screenHeight - dataHeight - marginY, fontData, dataBattery, Graphics.TEXT_JUSTIFY_LEFT);
    }

    hidden function drawPattern(dc as Dc, pattern as String, color as ColorType, offset as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var i = 0;
        while(i < Math.ceil(screenHeight / 48) + 1) {
            dc.drawText(0, i*48 + offset, fontPatterns, pattern, Graphics.TEXT_JUSTIFY_LEFT);
            i++;
        }
    }

    (:PaletteBase)
    hidden function getColor(color as colorNames) as ColorType {
        if(canBurnIn) {
            if(propTheme == 0) { return [0x222222, 0xFFFFFF, 0x222222, 0x00FF00, 0xFF0000][color]; }
            if(propTheme == 1) { return [0x052234, 0xfbcb77, 0x222222, 0x00FF00, 0xFF0000][color]; }
        } else {
            if(propTheme == 0) { return [0x555555, 0xFFFFFF, 0x555555, 0x00FF00, 0xFF0000][color]; }
            if(propTheme == 1) { return [0x555555, 0xFFFF00, 0x555555, 0x00FF00, 0xFF0000][color]; }
        }

        return 0xFFFFFF;
    }

    (:Palette8)
    hidden function getColor(color as colorNames) as ColorType {
        if(propTheme == 0) { return [0xFFFFFF, 0xFFFFFF, 0xFFFFFF, 0x00FF00, 0xFF0000][color]; }
        if(propTheme == 1) { return [0xFFFFFF, 0xFFFF00, 0xFFFFFF, 0x00FF00, 0xFF0000][color]; }

        return 0xFFFFFF;
    }

    hidden function updateProperties() as Void {
        propFieldTopLeft = Application.Properties.getValue("fieldTopLeft") as Number;
        propFieldTopRight = Application.Properties.getValue("fieldTopRight") as Number;
        propFieldBottomLeft = Application.Properties.getValue("fieldBottomLeft") as Number;
        propFieldBottomRight = Application.Properties.getValue("fieldBottomRight") as Number;
        propShowClockBg = Application.Properties.getValue("showClockBg") as Boolean;
        propHourFormat = Application.Properties.getValue("hourFormat") as Number;
        propDateFormat = Application.Properties.getValue("dateFormat") as Number;
        propShowUnits = Application.Properties.getValue("showUnits") as Boolean;
        propUnits = Application.Properties.getValue("units") as Number;
        propWindUnit = Application.Properties.getValue("windUnit") as Number;
        propPressureUnit = Application.Properties.getValue("pressureUnit") as Number;
    }

    hidden function updateData() as Void {
        dataTopLeft = getValueByType(propFieldTopLeft);
        dataTopRight = getValueByType(propFieldTopRight);
        dataBottomLeft = getValueByType(propFieldBottomLeft);
        dataBottomRight = getValueByType(propFieldBottomRight);
        dataBattery = getBatteryBars();
    }

    hidden function updateWeather() as Void {
        var now = Time.now().value();

        // Clear cached weather if older than 3 hours
        if(weatherCondition != null 
           and weatherCondition.observationTime != null 
           and (now - weatherCondition.observationTime.value() > 3600 * 3)) {
            weatherCondition = null;
        }

        if(Weather.getCurrentConditions != null) {
            weatherCondition = Weather.getCurrentConditions();
        }
    }

    hidden function getBatteryBars() as String {
        var bat = Math.round(System.getSystemStats().battery / 100.0 * 6);
        var value = "";
        for(var i = 0; i < bat; i++) {
            value += "|";
        }
        return value;
    }

    hidden function getValueByType(complicationType as Number) as String {
        var val = "";
        var numberFormat = "%d";

        if(complicationType == 1) { // Date
            val = formatDate();
        } else if(complicationType == 2) { // Active min / week
            if(ActivityMonitor.getInfo() has :activeMinutesWeek) {
                if(ActivityMonitor.getInfo().activeMinutesWeek != null) {
                    val = ActivityMonitor.getInfo().activeMinutesWeek.total.format(numberFormat);
                }
            }
        } else if(complicationType == 3) { // Active min / day
            if(ActivityMonitor.getInfo() has :activeMinutesDay) {
                if(ActivityMonitor.getInfo().activeMinutesDay != null) {
                    val = ActivityMonitor.getInfo().activeMinutesDay.total.format(numberFormat);
                }
            }
        } else if(complicationType == 4) { // distance / day
            if(ActivityMonitor.getInfo() has :distance) {
                if(ActivityMonitor.getInfo().distance != null) {
                    var distance = ActivityMonitor.getInfo().distance;
                    val = valueAndUnit(formatDistance(distance), complicationType);
                }
            }
        } else if(complicationType == 5) { // Weekly distance
            var weekly_distance = getWeeklyDistance();
            val = formatDistance(weekly_distance);
        } else if(complicationType == 6) { // Weekly run distance
            if (Toybox has :Complications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE));
                    if (complication != null && complication.value != null) {
                        var distance = complication.value;
                        val = valueAndUnit(formatDistance(distance), complicationType);
                    }
                } catch(e) {}
            }
        } else if(complicationType == 7) { // Weekly bike distance
            if (Toybox has :Complications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE));
                    if (complication != null && complication.value != null) {
                        var distance = complication.value;
                        val = valueAndUnit(formatDistance(distance), complicationType);
                    }
                } catch(e) {}
            }
        } else if(complicationType == 8) { // floors climbed / day
            if(ActivityMonitor.getInfo() has :floorsClimbed) {
                if(ActivityMonitor.getInfo().floorsClimbed != null) {
                    val = ActivityMonitor.getInfo().floorsClimbed.format(numberFormat);
                }
            }
        } else if(complicationType == 9) { // meters climbed / day
            if(ActivityMonitor.getInfo() has :metersClimbed) {
                if(ActivityMonitor.getInfo().metersClimbed != null) {
                    val = ActivityMonitor.getInfo().metersClimbed.format(numberFormat);
                }
            }
        } else if(complicationType == 10) { // Time to Recovery (h)
            if(ActivityMonitor.getInfo() has :timeToRecovery) {
                if(ActivityMonitor.getInfo().timeToRecovery != null) {
                    val = ActivityMonitor.getInfo().timeToRecovery.format(numberFormat);
                }
            }
        } else if(complicationType == 11) { // HR
            // Try to retrieve live HR from Activity::Info
            var activity_info = Activity.getActivityInfo();
            var sample = activity_info.currentHeartRate;
            if(sample != null) {
                val = sample.format("%01d");
            } else if (ActivityMonitor has :getHeartRateHistory) {
                // Falling back to historical HR from ActivityMonitor
                var hist = ActivityMonitor.getHeartRateHistory(1, /* newestFirst */ true).next();
                if ((hist != null) && (hist.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
                    val = hist.heartRate.format("%01d");
                }
            }
        } else if(complicationType == 12) { // Stress
            if ((Toybox has :SensorHistory) and (Toybox.SensorHistory has :getStressHistory)) {
                var st_iterator = Toybox.SensorHistory.getStressHistory({:period => 1});
                var st = st_iterator.next();
                if(st != null and st.data != null) {
                    val = st.data.format(numberFormat);
                }
            }
        } else if(complicationType == 13) { // Body battery
            if ((Toybox has :SensorHistory) and (Toybox.SensorHistory has :getBodyBatteryHistory)) {
                var bb_iterator = Toybox.SensorHistory.getBodyBatteryHistory({:period => 1});
                var bb = bb_iterator.next();
                if(bb != null and bb.data != null) {
                    val = bb.data.format(numberFormat);
                }
            }
        } else if(complicationType == 14) { // Steps / day
            if(ActivityMonitor.getInfo().steps != null) {
                val = ActivityMonitor.getInfo().steps.format(numberFormat);
            }
        } else if(complicationType == 15) { // Wheelchair pushes
            if(ActivityMonitor.getInfo() has :pushes) {
                if(ActivityMonitor.getInfo().pushes != null) {
                    val = ActivityMonitor.getInfo().pushes.format(numberFormat);
                }
            }
        } else if(complicationType == 16) { // Altitude (m)
            if ((Toybox has :SensorHistory) and (Toybox.SensorHistory has :getElevationHistory)) {
                var elv_iterator = Toybox.SensorHistory.getElevationHistory({:period => 1});
                var elv = elv_iterator.next();
                if(elv != null and elv.data != null) {
                    val = valueAndUnit(elv.data.format(numberFormat), complicationType);
                }
            }
        } else if(complicationType == 17) { // Altitude (ft)
            if ((Toybox has :SensorHistory) and (Toybox.SensorHistory has :getElevationHistory)) {
                var elv_iterator = Toybox.SensorHistory.getElevationHistory({:period => 1});
                var elv = elv_iterator.next();
                if(elv != null and elv.data != null) {
                    val = valueAndUnit((elv.data * 3.28084).format(numberFormat), complicationType);
                }
            }
        } else if(complicationType == 18) { // Sea level pressure
            var info = Activity.getActivityInfo();
            if (info has :meanSeaLevelPressure && info.meanSeaLevelPressure != null) {
                val = formatPressure(info.meanSeaLevelPressure / 100.0, numberFormat);
            }
        } else if(complicationType == 19) { // Raw Barometric pressure
            var info = Activity.getActivityInfo();
            if (info has :rawAmbientPressure && info.rawAmbientPressure != null) {
                val = formatPressure(info.rawAmbientPressure / 100.0, numberFormat);
            }
        } else if(complicationType == 20) { // Weight
            var profile = UserProfile.getProfile();
            if(profile has :weight) {
                if(profile.weight != null) {
                    val = valueAndUnit(formatWeight(profile.weight), complicationType);
                }
            }
        } else if(complicationType == 21) { // Calories
            if (ActivityMonitor.getInfo() has :calories) {
                if(ActivityMonitor.getInfo().calories != null) {
                    val = valueAndUnit(ActivityMonitor.getInfo().calories.format(numberFormat), complicationType);
                }
            }
        } else if(complicationType == 22) { // Act Calories
            var rest_calories = getRestCalories();
            // Get total calories and subtract rest calories
            if (ActivityMonitor.getInfo() has :calories && ActivityMonitor.getInfo().calories != null && rest_calories > 0) {
                var active_calories = ActivityMonitor.getInfo().calories - rest_calories;
                if (active_calories > 0) {
                    val = valueAndUnit(active_calories.format(numberFormat), complicationType);
                }
            }
        } else if(complicationType == 23) { // Week number
            var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var week_number = isoWeekNumber(today.year, today.month, today.day);
            val = week_number.format(numberFormat);
        } else if(complicationType == 24) { // Battery percentage
            var battery = System.getSystemStats().battery;
            val = Lang.format("$1$", [battery.format("%d")]);
        } else if(complicationType == 25) { // Battery days remaining
            if(System.getSystemStats() has :batteryInDays) {
                if (System.getSystemStats().batteryInDays != null){
                    var sample = Math.round(System.getSystemStats().batteryInDays);
                    val = Lang.format("$1$", [sample.format(numberFormat)]);
                }
            }
        } else if(complicationType == 26) { // Notification count
            var notif_count = System.getDeviceSettings().notificationCount;
            if(notif_count != null) {
                val = notif_count.format(numberFormat);
            }
        } else if(complicationType == 27) { // Solar intensity
            if (Toybox has :Complications) {
                try {
                    var complication = Complications.getComplication(new Id(Complications.COMPLICATION_TYPE_SOLAR_INPUT));
                    if (complication != null && complication.value != null) {
                        val = complication.value.format(numberFormat);
                    }
                } catch(e) {}
            }
        } else if(complicationType == 28) { // High/low temp
            val = getHighLow();
        } else if(complicationType == 29) { // Temperature
            val = getTemperature();
        } else if(complicationType == 30) { // Precipitation chance
            val = getPrecip();
        } else if(complicationType == 31) { // Wind
            val = getWind();
        } else if(complicationType == 32) { // Wind & Temp
            val = Lang.format("$1$ $2$", [getWind(), getTemperature()]);
        } else if(complicationType == 33) { // Millitary Date Time Group
            val = getDateTimeGroup();
        }

        return val;
    }

    hidden function valueAndUnit(value as String, complicationType as Number) as String {
        if(propShowUnits) {
            return Lang.format("$1$ $2$", [value, getUnit(complicationType)]);
        }
        return value;
    }

    hidden function getUnit(complicationType as Number) as String {
        var unit = "";
        if(complicationType == 21 or complicationType == 22) {
            unit = "KCAL";
        } else if(complicationType == 4 or complicationType == 5 or complicationType == 6 or complicationType == 7) {
            if(propUnits == 1 or (propUnits == 0 and System.getDeviceSettings().distanceUnits == System.UNIT_METRIC) ) {
                unit = "KM";
            } else {
                unit = "MI";
            }
        } else if(complicationType == 16) {
            unit = "M";
        } else if(complicationType == 17) {
            unit = "FT";
        } else if(complicationType == 20) {
            if(propUnits == 1 or (propUnits == 0 and System.getDeviceSettings().weightUnits == System.UNIT_METRIC) ) {
                unit = "KG";
            } else {
                unit = "LBS";
            }
        }
        return unit;
    }

    hidden function formatDate() as String {
        var now = Time.now();
        var today = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var value = "";

        switch(propDateFormat) {
            case 0: // Default: THU 14
                value = Lang.format("$1$ $2$", [
                    dayName(today.day_of_week),
                    today.day
                ]);
                break;
            case 1: // ISO: 2024-03-14
                value = Lang.format("$1$-$2$-$3$", [
                    today.year,
                    today.month.format("%02d"),
                    today.day.format("%02d")
                ]);
                break;
            case 2: // US: 03/14/2024
                value = Lang.format("$1$/$2$/$3$", [
                    today.month.format("%02d"),
                    today.day.format("%02d"),
                    today.year
                ]);
                break;
            case 3: // EU: 14.03.2024
                value = Lang.format("$1$.$2$.$3$", [
                    today.day.format("%02d"),
                    today.month.format("%02d"),
                    today.year
                ]);
                break;
             case 4: // THU 14 MAR
                value = Lang.format("$1$ $2$ $3$", [
                    dayName(today.day_of_week),
                    today.day,
                    monthName(today.month)
                ]);
                break;
            case 5: // 14 MAR
                value = Lang.format("$1$ $2$", [
                    today.day,
                    monthName(today.month)
                ]);
                break;
            case 6: // 14 MAR (Week number)
                value = Lang.format("$1$ $2$ (W$3$)", [
                    today.day,
                    monthName(today.month),
                    isoWeekNumber(today.year, today.month, today.day)
                ]);
                break;
            case 7: // THU 14 (Week number)
                value = Lang.format("$1$ $2$ (W$3$)", [
                    dayName(today.day_of_week),
                    today.day,
                    isoWeekNumber(today.year, today.month, today.day)
                ]);
                break;
        }
        return value;
    }

    hidden function getDateTimeGroup() as String {
        // 052125ZMAR25
        // DDHHMMZmmmYY
        var now = Time.now();
        var utc = Time.Gregorian.utcInfo(now, Time.FORMAT_SHORT);
        var value = Lang.format("$1$$2$$3$Z$4$$5$", [
                    utc.day.format("%02d"),
                    utc.hour.format("%02d"),
                    utc.min.format("%02d"),
                    monthName(utc.month),
                    utc.year.toString().substring(2,4)
                ]);

        return value;
    }

    hidden function formatPressure(pressureHpa as Float, numberFormat as String) as String {
        var val = "";

        if (propPressureUnit == 0) { // hPA
            val = pressureHpa.format(numberFormat);
        } else if (propPressureUnit == 1) { // mmHG
            val = (pressureHpa * 0.750062).format(numberFormat);
        } else if (propPressureUnit == 2) { // inHG
            val = (pressureHpa * 0.02953).format("%.1f");
        }

        return val;
    }

    hidden function formatDistance(meters as Number) as String {
        var distance_units = System.getDeviceSettings().distanceUnits;
        var distance;
        if((propUnits == 0 and distance_units == System.UNIT_METRIC) or propUnits == 1) {
            distance = meters / 100000.0;
        } else {
            distance = meters / 160900.0;
        }
        return distance < 10 ? distance.format("%.1f") : distance.format("%d");
    }

    hidden function formatWeight(grams as Number) as String {
        var weight_units = System.getDeviceSettings().weightUnits;
        var weight;
        if(propUnits == 0 and weight_units == System.UNIT_METRIC or propUnits == 1) {
            weight = grams / 1000.0;
        } else {
            weight = grams * 0.00220462;
        }
        return weight < 100 ? weight.format("%.1f") : weight.format("%d");
    }

    hidden function getTemperature() as String {
        if(weatherCondition != null and weatherCondition.temperature != null) {
            var temp_unit = getTempUnit();
            var temp_val = weatherCondition.temperature;
            var temp = formatTemperature(temp_val, temp_unit).format("%01d");
            return Lang.format("$1$$2$", [temp, temp_unit]);
        }
        return "";
    }

    hidden function getTempUnit() as String {
        var temp_unit_setting = System.getDeviceSettings().temperatureUnits;
        if(temp_unit_setting == System.UNIT_METRIC) {
            return "C";
        } else {
            return "F";
        }
    }

    hidden function formatTemperature(temp as Number, unit as String) as Number {
        if(unit.equals("C")) {
            return temp;
        } else {
            return ((temp * 9/5) + 32);
        }
    }

    hidden function getWind() as String {
        var windspeed = "";
        var bearing = "";

        if(weatherCondition != null and weatherCondition.windSpeed != null) {
            var windspeed_mps = weatherCondition.windSpeed;
            if(propWindUnit == 0) { // m/s
                windspeed = Math.round(windspeed_mps).format("%01d");
            } else if (propWindUnit == 1) { // km/h
                var windspeed_kmh = Math.round(windspeed_mps * 3.6);
                windspeed = windspeed_kmh.format("%01d");
            } else if (propWindUnit == 2) { // mph
                var windspeed_mph = Math.round(windspeed_mps * 2.237);
                windspeed = windspeed_mph.format("%01d");
            } else if (propWindUnit == 3) { // knots
                var windspeed_kt = Math.round(windspeed_mps * 1.944);
                windspeed = windspeed_kt.format("%01d");
            } else if(propWindUnit == 4) { // beufort
                if (windspeed_mps < 0.5f) {
                    windspeed = "0";  // Calm
                } else if (windspeed_mps < 1.5f) {
                    windspeed = "1";  // Light air
                } else if (windspeed_mps < 3.3f) {
                    windspeed = "2";  // Light breeze
                } else if (windspeed_mps < 5.5f) {
                    windspeed = "3";  // Gentle breeze
                } else if (windspeed_mps < 7.9f) {
                    windspeed = "4";  // Moderate breeze
                } else if (windspeed_mps < 10.7f) {
                    windspeed = "5";  // Fresh breeze
                } else if (windspeed_mps < 13.8f) {
                    windspeed = "6";  // Strong breeze
                } else if (windspeed_mps < 17.1f) {
                    windspeed = "7";  // Near gale
                } else if (windspeed_mps < 20.7f) {
                    windspeed = "8";  // Gale
                } else if (windspeed_mps < 24.4f) {
                    windspeed = "9";  // Strong gale
                } else if (windspeed_mps < 28.4f) {
                    windspeed = "10";  // Storm
                } else if (windspeed_mps < 32.6f) {
                    windspeed = "11";  // Violent storm
                } else {
                    windspeed = "12";  // Hurricane force
                }
            }
        }

        if(weatherCondition != null and weatherCondition.windBearing != null) {
            bearing = ((Math.round((weatherCondition.windBearing.toFloat() + 180) / 45.0).toNumber() % 8) + 97).toChar().toString();
        }

        return Lang.format("$1$$2$", [bearing, windspeed]);
    }

    hidden function getHumidity() as String {
        var ret = "";
        if(weatherCondition != null and weatherCondition.relativeHumidity != null) {
            ret = Lang.format("$1$%", [weatherCondition.relativeHumidity]);
        }
        return ret;
    }

    hidden function getHighLow() as String {
        var ret = "";
        if(weatherCondition != null) {
            if(weatherCondition.highTemperature != null or weatherCondition.lowTemperature != null) {
                var tempUnit = getTempUnit();
                var high = formatTemperature(weatherCondition.highTemperature, tempUnit);
                var low = formatTemperature(weatherCondition.lowTemperature, tempUnit);
                ret = Lang.format("$1$$2$/$3$$2$", [high.format("%02d"), tempUnit, low.format("%02d")]);
            }
        }
        return ret;
    }

    hidden function getPrecip() as String {
        var ret = "";
        if(weatherCondition != null and weatherCondition.precipitationChance != null) {
            ret = Lang.format("$1$%", [weatherCondition.precipitationChance.format("%d")]);
        }
        return ret;
    }

    hidden function getRestCalories() as Number {
        var today = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var profile = UserProfile.getProfile();

        if (profile has :weight && profile has :height && profile has :birthYear) {
            var age = today.year - profile.birthYear;
            var weight = profile.weight / 1000.0;
            var rest_calories = 0;

            if (profile.gender == UserProfile.GENDER_MALE) {
                rest_calories = 5.2 - 6.116 * age + 7.628 * profile.height + 12.2 * weight;
            } else {
                rest_calories = -197.6 - 6.116 * age + 7.628 * profile.height + 12.2 * weight;
            }

            // Calculate rest calories for the current time of day
            rest_calories = Math.round((today.hour * 60 + today.min) * rest_calories / 1440).toNumber();
            return rest_calories;
        } else {
            return -1;
        }
    }

    hidden function getWeeklyDistance() as Number {
        var weekly_distance = 0;
        if(ActivityMonitor.getInfo() has :distance) {
            var history = ActivityMonitor.getHistory();
            if (history != null) {
                // Only take up to 6 previous days from history
                var daysToCount = history.size() < 6 ? history.size() : 6;
                for (var i = 0; i < daysToCount; i++) {
                    if (history[i].distance != null) {
                        weekly_distance += history[i].distance;
                    }
                }
            }
            // Add today's distance
            if(ActivityMonitor.getInfo().distance != null) {
                weekly_distance += ActivityMonitor.getInfo().distance;
            }
        }
        return weekly_distance;
    }

    hidden function dayName(day_of_week as Number) as String {
        var names = [
            "SUN",
            "MON",
            "TUE",
            "WED",
            "THU",
            "FRI",
            "SAT",
        ];
        return names[day_of_week - 1];
    }

    hidden function monthName(month as Number) as String {
        var names = [
            "JAN",
            "FEB",
            "MAR",
            "APR",
            "MAY",
            "JUN",
            "JUL",
            "AUG",
            "SEP",
            "OCT",
            "NOV",
            "DEC"
        ];
        return names[month - 1];
    }

    hidden function isoWeekNumber(year as Number, month as Number, day as Number) as Number {
        var first_day_of_year = julianDay(year, 1, 1);
        var given_day_of_year = julianDay(year, month, day);
        var day_of_week = (first_day_of_year + 3) % 7;
        var week_of_year = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
        var ret = 0;
        if (week_of_year == 53) {
            if (day_of_week == 6) {
                ret = week_of_year;
            } else if (day_of_week == 5 && isLeapYear(year)) {
                ret = week_of_year;
            } else {
                ret = 1;
            }
        } else if (week_of_year == 0) {
            first_day_of_year = julianDay(year - 1, 1, 1);
            day_of_week = (first_day_of_year + 3) % 7;
            ret = (given_day_of_year - first_day_of_year + day_of_week + 4) / 7;
        } else {
            ret = week_of_year;
        }
        return ret;
    }

    hidden function julianDay(year as Number, month as Number, day as Number) as Number {
        var a = (14 - month) / 12;
        var y = (year + 4800 - a);
        var m = (month + 12 * a - 3);
        return day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045;
    }

    hidden function isLeapYear(year as Number) as Boolean {
        if (year % 4 != 0) {
            return false;
           } else if (year % 100 != 0) {
            return true;
        } else if (year % 400 == 0) {
            return true;
        }
        return false;
    }
}
