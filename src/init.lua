--!nonstrict
--Version 1.0.0

--Dependencies
local Signal = require(script.Parent:FindFirstChild("Signal") or script.Signal)
local Trove = require(script.Parent:FindFirstChild("Trove") or script.Trove)
local WaitFor = require(script.Parent:FindFirstChild("WaitFor") or script.WaitFor)

--[=[
    @class Cooldown

    Countdown is a Debounce utility which is meant to make it easier to create Debounce easily, with minimal effort.
	Basic Usage:
	```lua
	local Cooldown = require(Path.Cooldown)

	local DebounceTime = 5
	local Debounce = Cooldown.new(DebounceTime)
	```
]=]
local Cooldown = {}
Cooldown.__index = Cooldown

type self = {
	Time: number,
	LastActivation: number,
	AutoReset: boolean,

	OnReady: RBXScriptSignal | Signal,
}

--[=[
    @interface Cooldown
	@within Cooldown
	.Time number -- The time of the debounce
	.LastActivation number -- The last time the debounce reset
	.AutoReset boolean -- Whether or not the debounce should reset after running.

	.OnReady RBXScriptSignal | Signal -- Fires whenever the Cooldown can be be fired.
]=]

--[=[
    @prop Time
	@within Cooldown
	The time property signifies how much time is needed to wait before using :Run()

	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce = Cooldown.new(5) -- The first parameter is the Time
	-- Can be changed with Debounce.Time = 5

	Debounce:Run(function()
		print("This will run")  -- prints
	end)

	Debounce:Run(function()
		print("This won't run")  -- won't print because the debounce hasn't finished waiting 5 seconds
	end)
	```

	:::note
		Calling :Run() when the debounce isn't ready won't yield.
	:::
]=]

--[=[
    @prop AutoReset
	@within Cooldown
	When AutoReset is on, the debounce will reset after a succesful Run() call.

	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce = Cooldown.new(5)
	Debounce.AutoReset = false

	Debounce:Run(function()
		print("This will run")  -- prints
	end)

	Debounce:Run(function()
		print("This will still run")  -- still prints because AutoReset is false and the debounce did not reset
	end)

	Debounce:Reset() -- Reset the debounce
	```
]=]

export type Cooldown = typeof(setmetatable({} :: self, Cooldown))

function Cooldown.__tostring(_: Cooldown)
	return "Cooldown"
end

--[=[
    Returns a new Cooldown.

	@param Time number -- The time property, for more info check the "Time" property.
	@error "No Time" -- Happens when no Time property is provided.
]=]
function Cooldown.new(Time: number): Cooldown
	assert(type(Time) == "number", "You must provide a number for the Time")

	local self = setmetatable({}, Cooldown)

	--Non Usable
	self._Trove = Trove.new()
	self._Connections = {
		OnReadyHandler = nil,
	}

	-- Usable
	self.Time = Time
	self.LastActivation = 0
	self.AutoReset = true

	self.OnReady = self._Trove:Construct(Signal)

	return self
end

--[=[
	@method Reset
	@within Cooldown
    Resets the debounce. Just like calling a sucessful :Run() with AutoReset set to true
]=]
function Cooldown.Reset(self: Cooldown)
	self.LastActivation = os.clock()

	task.defer(function()
		self._Connections.OnReadyHandler = WaitFor.Custom(function()
			return os.clock() - self.LastActivation >= self.Time
		end):andThen(function()
			self.OnReady:Fire()
			self._Connections.OnReadyHandler:cancel()
		end)
	end)
end

--[=[
	@method RunIf
	@within Cooldown
    If the given Predicate (The First parameter) is true or returns true, it will call :Run() on itself.

	@error "No Predicate" -- Happens when no Predicate, indicated by a boolean or boolean-returning function is provided.
	@error "No Callback" -- Happens when no callback is provided.

	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce = Cooldown.new(5)
	Debounce.AutoReset = false

	Debounce:RunIf(true, function()
		print("This will run")  -- prints
	end)

	Debounce:RunIf(false, function()
		print("This will not run")  -- does not print because the first parameter (Predicate) is false.
	end)
	```
]=]
function Cooldown.RunIf(self: Cooldown, Predicate: boolean | () -> boolean, Callback: () -> ()): boolean
	local PredicateType = type(Predicate)
	assert(PredicateType == "boolean" or PredicateType == "function", "Please provide a boolean or function as the predicate.")

	local Output = if PredicateType == "function" then Predicate() else Predicate

	if Output then
		return self:Run(Callback)
	end

	return false
end

--[=[
	@method RunOrElse
	@within Cooldown
    if the :Run() will not be succesful, it will instead call callback2. This won't reset the debounce.

	@error "No Callback" -- Happens when no Callback is provided.
	@error "No Callback2" -- Happens when no Callback2 is provided.

	An example would be:
	```lua
	local Cooldown = require(Path.Cooldown)

	local Debounce = Cooldown.new(5)

	Debounce:RunOrElse(function()
		print("This will run")  -- prints
	end, function()
		print("This will not print") -- doesn't print because the :Run() will be successful.
	end)

	Debounce:RunOrElse(function()
		print("This will not run")  -- does not print because the debounce hasn't finished waiting.
	end, function()
		print("This will run") -- will print because the :Run() failed.
	end)
	```
]=]
function Cooldown.RunOrElse(self: Cooldown, Callback: () -> (), Callback2: () -> ())
	assert(type(Callback2) == "function", "Callback2 needs to be a function.")

	if not self:Run(Callback) then
		Callback2()
	end
end

--[=[
	@method Run
	@within Cooldown
    Runs the given callback function if the passed time is higher than the Time property.
	If AutoReset is true, it will call :Reset() after a succesful run.

	@error "No Callback" -- Happens when no callback is provided.
]=]
function Cooldown.Run(self: Cooldown, Callback: () -> ()): boolean
	assert(type(Callback) == "function", "Callback needs to be a function.")

	if os.clock() - self.LastActivation >= self.Time then
		if self.AutoReset then
			self:Reset()
		end
		Callback()

		return true
	end

	return false
end

--[=[
	@method IsReady
	@within Cooldown
    Returns a boolean indicating if the Cooldown is ready to :Run().
]=]
function Cooldown.IsReady(self: Cooldown): boolean
	return os.clock() - self.LastActivation >= self.Time
end

--[=[
    Returns a boolean indicating if the given table is a Cooldown.
]=]
function Cooldown.Is(Table: Cooldown?): boolean
	return getmetatable(Table) == Cooldown
end

--[=[
	@method Destroy
	@within Cooldown
    Destroys the Cooldown.
]=]
function Cooldown.Destroy(self: Cooldown)
	self._Trove:Destroy()
end

return Cooldown
