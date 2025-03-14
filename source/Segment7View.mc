import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;

class Segment7View extends WatchUi.WatchFace {

    hidden var screenHeight as Number;
    hidden var screenWidth as Number;
    hidden var clockHeight as Number;
    hidden var clockWidth as Number;
    hidden var dataHeight as Number;
    hidden var fontClock as WatchUi.FontResource;
    hidden var fontData as WatchUi.FontResource;
    

    function initialize() {
        WatchFace.initialize();

        screenHeight = Toybox.System.getDeviceSettings().screenHeight;
        screenWidth = Toybox.System.getDeviceSettings().screenWidth;

        if(screenHeight < 240) {
            fontClock = WatchUi.loadResource(Rez.Fonts.SevenSegment72) as WatchUi.FontResource;
            fontData = WatchUi.loadResource(Rez.Fonts.LedSmall) as WatchUi.FontResource;
            clockHeight = 72;
            clockWidth = 207;
            dataHeight = 13;
        } else if(screenHeight >= 240 and screenHeight <= 280) {
            fontClock = WatchUi.loadResource(Rez.Fonts.SevenSegment72) as WatchUi.FontResource;
            fontData = WatchUi.loadResource(Rez.Fonts.LedLines) as WatchUi.FontResource;
            clockHeight = 72;
            clockWidth = 207;
            dataHeight = 20;
        } else {
            fontClock = WatchUi.loadResource(Rez.Fonts.SevenSegment124) as WatchUi.FontResource;
            fontData = WatchUi.loadResource(Rez.Fonts.LedBig) as WatchUi.FontResource;
            clockHeight = 124;
            clockWidth = 372;
            dataHeight = 27;
        }
        
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

        drawWatchface(dc, now);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    hidden function drawWatchface(dc as Dc, now as Gregorian.Info) as Void {
        var time_to_draw = Lang.format("$1$:$2$", [now.hour.format("%02d"), now.min.format("%02d")]);
        var center_x = Math.round(screenWidth / 2);
        var center_y = Math.round(screenHeight / 2);
        var half_clock_height = Math.round(clockHeight / 2);
        var half_clock_width = Math.round(clockWidth / 2);
        var margin_y = Math.round(screenHeight / 20);

        // Clear
        dc.setColor(0x333333, 0x000000);
        dc.clear();

        // Draw Clock
        dc.drawText(center_x, center_y, fontClock, "##:##", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(center_x, center_y, fontClock, time_to_draw, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Draw Data fields
        dc.drawText(center_x - half_clock_width, center_y - half_clock_height - margin_y - dataHeight, fontData, "FRI 14", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(center_x + half_clock_width, center_y - half_clock_height - margin_y - dataHeight, fontData, "12C", Graphics.TEXT_JUSTIFY_RIGHT);

        dc.drawText(center_x - half_clock_width, center_y + half_clock_height + margin_y , fontData, "12345", Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(center_x + half_clock_width, center_y + half_clock_height + margin_y , fontData, "ABCD", Graphics.TEXT_JUSTIFY_RIGHT);
    }

}
