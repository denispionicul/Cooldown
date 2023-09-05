return function()
	local CooldownModule = require(script.Parent)
	local Cooldown = CooldownModule.new(2)

	afterAll(function()
		Cooldown:Destroy()
	end)

	describe("Basic Debouce", function()
		it("Should result in true, cooldown is 0 at start", function()
			expect(Cooldown:Run(function() end)).to.equal(true)
		end)
		it("Should Result in false, cooldown has been exceeded", function()
			expect(Cooldown:Run(function() end)).to.equal(false)
		end)
		it("Should be resseting", function()
			expect(function()
				Cooldown:Reset()
			end).never.to.throw()
		end)
	end)

	describe("Util Functions", function()
		it("Should run with an if statement, print true", function()
            local Succed = false
            task.wait(2.5)
            Cooldown:RunIf(true, function()
                Succed = true
            end)
			expect(Succed).to.equal(true)
        end)
		it("Should run the other function, cooldonw not ready", function()
			local Result = false
			Cooldown:RunOrElse(function() end, function()
				Result = true
			end)

			expect(Result).to.equal(true)
		end)
		it("Should result false when calling is ready.", function()
			expect(Cooldown:IsReady()).to.equal(false)
		end)
		it("Should result true when calling Is", function()
			expect(CooldownModule.Is(Cooldown)).to.equal(true)
		end)
	end)

	describe("Events", function()
		it("Should Fire the OnReady event", function()
            local Fired = false
            Cooldown.OnReady:Once(function()
                Fired = true
            end)
            task.wait(2.5)
			expect(Fired).to.equal(true)
		end)
		it("Should Fire the OnSuccess event", function()
			local Fired = false

			Cooldown.OnSuccess:Once(function()
				Fired = true
			end)
			Cooldown:Run(function()

			end)
			expect(Fired).to.equal(true)
		end)
		it("Should Fire the OnFail event", function()
			local Fired = false

			Cooldown.OnFail:Once(function()
				Fired = true
			end)
			Cooldown:Run(function()

			end)
			expect(Fired).to.equal(true)
		end)
	end)
end
