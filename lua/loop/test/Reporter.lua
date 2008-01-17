
local print    = print
local tostring = tostring

local io     = require "io"
local os     = require "os"
local string = require "string"
local table  = require "table"

local oo = require "loop.base"

module("loop.test.Reporter", oo.class)

output = io.stdout
time = os.time
count = 0
success = 0

function started(self, test)
	if self.breakline then
		self.output:write("\n")
	else
		self.breakline = true
	end
	if self.name then self.output:write("[", self.name, "]\t") end
	self.output:write(string.rep("  ", #self), test, " ... ")
	self[#self+1] = self.time()
end

local LineEnd = "%s (%.2f sec.)\n"
local Summary = "Success Rate: %d%% (%d of %d executions)\n"
function ended(self, test, success, message)
	local timestamp = self[#self]
	self[#self] = nil
	if self.breakline then
		self.breakline = nil
		-- single test ended, not a suite
		self.count = self.count + 1
		if success then
			self.success = self.success + 1
		end
	else
		if self.name then self.output:write("[", self.name, "]\t") end
		self.output:write(string.rep("  ", #self))
	end
	self.output:write(LineEnd:format(
		success and "OK" or tostring(message),
		self.time() - timestamp
	))
	
	if #self == 0 then
		if self.name then self.output:write("[", self.name, "]\t") end
		self.output:write(Summary:format(100*self.success/self.count, self.success, self.count))
	end
end