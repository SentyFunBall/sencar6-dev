-- Author: SentyFunBall
-- GitHub: https://github.com/SentyFunBall
-- Workshop: 

--Code by STCorp. Do not reuse.--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

local inputMap = {
    "AppMap",
    "AppInfo",
    "AppWeather",
    "AppCar",
    "AppSettings",
    "DisplayCentral",
    "DisplayMedia",
    "DisplayWidgets",
    "DisplayDash1",
    "DisplayDashIcons",
    "DisplayDash2",
    "StartupTiming",
    "Odometer",
    "ScriptMotor",
    "ScriptBattery",
    "ScriptVPedal",
    "MCExtras",
}
local numInputs = 17

local lastValues = {}

local wdt = 0
local wdt_limit = 60 -- 60 tick watchdog timer to see if any scripts are frozen
local triggers = 0
local time_since_last_trigger = 0
local max_triggers = 2 -- Number of triggers before we assume the script is frozen and declare emergency
local reset_time = 120 -- Time in ticks to before resetting triggers
local active_issues = {}
local reason = 0 -- 0 = none, 1 = wdt, 2 = trigger count
local crash_detected = false
local bad_script = 0
local firstTicks = 20
local ticks = 0

function onTick()
    ticks = ticks + 1
    local reset = input.getBool(2)
    if reset or ticks % 3600 == 0 then -- reset every minute just in case, or if we get a reset signal
        wdt = 0
        triggers = 0
        time_since_last_trigger = 0
        active_issues = {}
        reason = 0
        crash_detected = false
        bad_script = 0
        return
    end

    if ticks < firstTicks then
        return
    end
    for i = 1, numInputs do
        local value = input.getNumber(i)
        local old = lastValues[i] or 0

        if value == old then -- If not changing, then things are bad
            wdt = wdt + 1
            time_since_last_trigger = 0

            if not active_issues[i] then
                active_issues[i] = true
                triggers = triggers + 1
            end
        else
            wdt = 0
            active_issues[i] = false
            time_since_last_trigger = time_since_last_trigger + 1

            if time_since_last_trigger > reset_time then
                triggers = 0
            end
        end

        lastValues[i] = value
    end

    if wdt > wdt_limit or triggers >= max_triggers then
        crash_detected = true
        for i = 1, numInputs do
            if active_issues[i] then
                bad_script = i
                break
            end
        end
    end
    
    if wdt > wdt_limit then reason = 1 end
    if triggers >= max_triggers then reason = 2 end

    output.setBool(1, crash_detected)
    output.setNumber(1, reason)
    if crash_detected then
        output.setNumber(2, wdt)
        output.setNumber(3, triggers)
        output.setNumber(4, time_since_last_trigger)
        output.setNumber(5, bad_script)
    else
        output.setNumber(2, 0)
        output.setNumber(3, 0)
        output.setNumber(4, time_since_last_trigger)
        output.setNumber(5, 0)
    end
end
