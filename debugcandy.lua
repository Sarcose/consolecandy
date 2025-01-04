CANDYDEBUGMODE = true
CANDYDEBUGBASELEVEL = 2   --for ccandy. console print functions, this usually means [callingfile.lua:line][datafile.lua:line]
CANDYPATHDEPTH = 10
CANDYTODOEXPIRATION = 5

--[[
	yellow: Warning | Reminder
	red:	Error
	green:	Success
	blue: 	Debug
	cyan:	Todo
--]]

local ccandy = {}
ccandy.filename = "debugcandy"

local function extractCallerInfo(level, parseStart)
    local stack = debug.traceback("", 2)
    local lines = {}
    for line in stack:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local ret = ""
    parseStart = parseStart or 4
    local lastFile = nil
    local currentRange = {}
	local depth = CANDYPATHDEPTH
    if level then
        for i = 1, level do
            local n = (i - 1) + parseStart
            local callerInfo = lines[n]
            if callerInfo then
                local file, line = callerInfo:match("([^:]+):(%d+)")
                if file and line then
                    -- Handle the file path depth
                    local pathParts = {}
                    for part in file:gmatch("[^/\\]+") do
                        table.insert(pathParts, part)
                    end
                    
                    -- Adjust the file path based on the depth
                    if depth > 0 then
                        local startIdx = math.max(#pathParts - depth, 1)
                        file = table.concat({unpack(pathParts, startIdx)}, "/")
                    else
                        file = pathParts[#pathParts]  -- Only the filename
                    end

                    file = string.gsub(file, "%s", "")  -- Remove spaces
                    local num = tonumber(line)

                    if lastFile == file then
                        -- Add the line number to the current range
                        table.insert(currentRange, num)
                    else
                        -- If there is a previous range, collapse it
                        if #currentRange > 0 then
                            if #currentRange > 1 then
                                ret = ret .. "[" .. lastFile .. ":" .. table.concat(currentRange, ":") .. "]"
                            else
                                ret = ret .. "[" .. lastFile .. ":" .. currentRange[1] .. "]"
                            end
                        end
                        -- Start a new range for the new file
                        lastFile = file
                        currentRange = {num}
                    end
                end
            end
        end

        -- Handle the last range (if any)
        if #currentRange > 0 then
            if #currentRange > 1 then
                ret = ret .. "[" .. lastFile .. ":" .. table.concat(currentRange, ":") .. "]"
            else
                ret = ret .. "[" .. lastFile .. ":" .. currentRange[1] .. "]"
            end
        end
    end
    return ret
end

local function getCallLine(n,level,parseStart)
	level = level or CANDYDEBUGBASELEVEL
	local line = extractCallerInfo(level,parseStart)
	return n.." "..line..": "
end
local limit = 9--to avoid infinite recursion
local function getDeepest(t, refs, deep)
	deep = deep or 1
	if deep >= limit then deep = limit return deep, refs end
	refs = refs or {}
	refs[tostring(t)] = true
	local deepest = 1
	local d = 0
	for k,v in pairs(t) do
		if type(v) == "table" then
			--first, determine if it's a self reference
			if not refs[tostring(v)] then
				refs[tostring(v)] = true
				d, refs = getDeepest(v, refs, deepest)
				deepest = deepest + d
			end
			if deepest > deep then deep = deepest end
			if deep >= limit then deep = limit break end
			d = 0
		end
	end
	--ccandy.debug("refs: "..tostring(refs),0)
	return deep, refs
end
local function getSpacing(space, name)
	space = space or 9 --the size of a type label
	name = tostring(name)
	local spaces = ""
	local diff = space - #name
	for i = 1, diff do
		spaces = spaces.." "
	end
	return spaces
end
local function inspect(i, refs)
	local t = type(i)
	t = "("..t..")"
	local ret = ""
	local symbol = "= "
	if type(i) == "table" then
		symbol = ""
		local addr = string.gsub(tostring(i),"table: ","")
		--t = string.gsub(t,"table","t")
		ret = ret.."[ addr:"..tostring(addr)
		local ind, key
		if #i > 0 then ind = true end
		local n = 0
		local deep = 1
		local deepest = 1
		local d = 0
		refs = refs or {}
		refs[tostring(i)] = true
		for k,v in pairs(i) do
			deepest = 1
			if not tonumber(k) then n = n + 1 end
			if type(v) == "table" then
				d, refs = getDeepest(v, refs)
				deepest = deepest + d
			end
			if deepest > deep then deep = deepest end
			d = 0
		end
		local keys = ""
		if n > 0 then 
			key = true 
			keys = "   keys:"..n 
		end
		if key or ind then
			ret = ret .. "   #len:"..#i..keys
			if deep >= limit then
				ret = ret .. "   depth: > LIMIT ("..tostring(limit)..")"
			elseif deep > 1 then
				ret = ret .. "   depth:"..tostring(deep)
			end
		else
			ret = ret .. "   <empty>"
		end
		ret = ret .. " ]"
	elseif type(i) == "function" then
		t = "(fn)"
		ret = string.gsub(tostring(i),"function: ","")
		ret = "addr:"..ret
		symbol = "  "

	else
		ret = tostring(i)
		if type(i) == "string" then
			ret = '"'..ret..'"'
		end
	end
	return t..getSpacing(nil,t)..symbol..ret
end
function ccandy.debug(_,level,parseStart) -- print magenta to console, takes a string or table. Only when CANDYDEBUGMODE is on.
	if CANDYDEBUGMODE then
		local p = getCallLine("DEBUG",level,parseStart)
		if type(_) ~= "table" then 
			if type(_) == "string" then
				p = p .. _		--if it's a string we don't bother with the inspection, just print it as a message
			else
				p = p ..inspect(_)
			end
		else
			local cap = "\r\n  "
			if _.horizontal then 
				cap = "|" _.horizontal = nil 
			end
			local longestname = 0
			local refs = {}
			refs[tostring(_)] = true
			for k,v in pairs(_) do
				if type(k) == "string" then
					if #k > longestname then longestname = #k end
				end
			end
			for i=1, #_ do
				p = p..cap
				p = p..getSpacing(longestname,i)..tostring(i).." : "..inspect(_[i], refs)
			end
			for k,v in pairs(_) do
				if not tonumber(k) then
					p = p..cap
					p = p..getSpacing(longestname,k)..k.." : "..inspect(v, refs)
				end
			end
			p = p:match("^(.-)[,\r\n]?$")
		end
		ccandy.printC("blue",p)
	end
end


local function checkChecked(s)
    if string.sub(s, 1, 1) == "X" then
        -- Return the string without the "X" and true (indicating it started with "X")
        return string.gsub(s,"X",""), true
    else
        -- Return the original string and false (indicating no leading "X")
        return s, false
    end
end
local function compareDate(inputString)
    local currentDate = os.date("*t")
    local currentYear = currentDate.year
    local month, day, year = inputString:match("^(%d%d)/(%d%d)/(%d%d%d%d)$")
    if month and day and year then
        month, day, year = tonumber(month), tonumber(day), tonumber(year)
    else
        month, day = inputString:match("^(%d%d)/(%d%d)$")
        if month and day then
            month, day = tonumber(month), tonumber(day)
            year = currentYear
        else
            return false, nil -- Not a valid date format
        end
    end
    if not (month >= 1 and month <= 12 and day >= 1 and day <= 31) then
        return false, nil -- Invalid date
    end
    local inputTime = os.time({year = year, month = month, day = day})
    local currentTime = os.time()
    local secondsPassed = currentTime - inputTime
    local daysPassed = math.floor(secondsPassed / (24 * 60 * 60)) -- Convert seconds to days
    return true, daysPassed
end
local todotab = "   "
function ccandy.todo(_) --ccandy.todo{"Update date","XChecked Step 1","Unchecked Step 2","Unchecked Step 3"}
	local level = 1
	if CANDYDEBUGMODE then
		if type(_) ~= "table" then _ = {tostring(_)} end
		local p1 = getCallLine("TODO",level)
		local p2 = nil
		local p3 = ""
		local checked = "[X] "
		local unchecked = "[ ] "
		local checkbox = ""
		local exTimePassed
		for i=1, #_ do
			local item = _[i]
			local date, timePassed = compareDate(item)
			if date then
				exTimePassed = timePassed
				if timePassed >= CANDYTODOEXPIRATION then
					p2 = "     WARNING: "..tostring(timePassed).." days since this Todo list was updated!"
				end
			else
				local s, isChecked = checkChecked(tostring(_[i]))
				if isChecked then
					checkbox = checked
				else
					checkbox = unchecked
				end

				local _s, count = string.gsub(s,"*","")
				local tab = ""
				for i=1, count do
					tab = tab..todotab
				end
				p3 = p3.."  "..tab..checkbox.._s
				if i < #_ then
					p3 = p3.."\r\n"
				end
			end
		end
		local warncolor = nil
		if exTimePassed then
			if exTimePassed >= (CANDYTODOEXPIRATION * 3) then
				warncolor = "red"
			elseif exTimePassed >= CANDYTODOEXPIRATION then
				warncolor = "yellow"
			end
		end
		ccandy.printCTable({"cyan",warncolor,"cyan"},{p1,p2,p3})
	end
end
ccandy.reminderheader = "==========!!!=======REMINDER=======!!!========"
ccandy.reminderfooter = "=========!!!=======================!!!========"
function ccandy.remind(setdate,reminderdate,_)
	if CANDYDEBUGMODE then
		local date, timePassedSinceSet = compareDate(setdate)
		assert(date,"ccandy.reminder called without setdate!")
		date, timePassedSinceReminder = compareDate(reminderdate)
		assert(date,"ccandy.reminder called without reminderdate!")
		if timePassedSinceReminder >= 0 then
			local heading = ccandy.reminderheader
			local since = "A reminder was set on "..setdate.." "..timePassedSinceSet.." days ago!"
			local reminder = ""
			local post = ccandy.reminderfooter
			if type(_) == "table" then
				for i,v in ipairs(_) do
					if type(v)=="string" then
						reminder = reminder..v
						if i < #_ then
							reminder = reminder.."\r\n"
						end
					end
				end
			else
				reminder = reminder.._
			end
			ccandy.printCTable("yellow",{heading,since,reminder})
			for k,v in pairs(_) do
				if type(v) == "function" then
					_[k]()
				end
			end
			ccandy.printC("yellow",post)
		end
	end
end

function ccandy.success(_,level) --print green to console, takes a string or table
	level = level or 0	--success uses its own default, 0, because that makes sense to me
    if type(_) ~= "table" then _ = {_} end
	local p = getCallLine("SUCCESS!",level)
	for i=1, #_ do
		p = p..tostring(_[i])
		if i < #_ then
			p = p..", "
		end
    end
    ccandy.printC("green",p)
end
function ccandy.warn(_,level,parseStart) --print yellow to console, takes a string or table
    if type(_) ~= "table" then _ = {_} end
	local p = getCallLine("WARNING",level,parseStart)
	for i=1, #_ do
		p = p..tostring(_[i])
		if i < #_ then
			p = p..", "
		end
    end
    ccandy.printC("yellow",p)
end
function ccandy.stop(_,level) --print red to console then stop the program
	ccandy.error(_,level,5)
	error("Stopped by ccandy.stop()")
end
function ccandy.error(_,level,parseStart) --print red to console, takes a string or table
    if type(_) ~= "table" then _ = {_} end
    local p = getCallLine("ERROR",level,parseStart)
    for i=1, #_ do
		p = p..tostring(_[i])
		if i < #_ then
			p = p..", "
		end
    end
    ccandy.printC("red",p)
end
local consolecolors = 
{reset = "\x1B[m", red = "\x1B[31m", 		--red: error
yellow = "\x1b[33m", green = "\x1B[32m", 	--yellow: warn (looks orange)  green: good stuff like "finished loading!" probably
blue = "\x1b[34m", cyan = "\x1b[36m"}		--blue: debug messages		cyan: TODO
function ccandy.printC(colour, ...)
	if not consolecolors[colour] then error("Undefined colour: " .. colour) end
	io.write(consolecolors[colour])
	if colour == "blue" then io.write("\x1b[1m") end
	print(...)
	io.write(consolecolors.reset)
end
function ccandy.blank(msg,n)
	if type(msg) == "number" then n = msg; msg = nil end
	n = n or 10
	local p = ""
	for i=1,n do
		p = p .. "\r\n"
	end
	if msg then printC("green",tostring(msg)) end
	print(p)
end
function ccandy.printCTable(cTable, sTable)	--print a table of strings with a table of colors, used in Todo list mainly
	local onlyColor
	if type(cTable) ~= "table" then onlyColor = cTable end
	for i=1, #sTable do
		local s = sTable[i]
		if s then
			local c = onlyColor or cTable[i]
			c = c or "reset"
			ccandy.printC(c,s)
		end
	end
end


function ccandy:export(n)
	n = n or "_c_"
	local ignore = {"export","printC","printCTable"}
	n = n or ""
	for k,v in pairs(self) do
		local f = n..k
		_G[f] = v
	end
	_G.printC = self.printC
	_G.printCTable = self.printCTable
end

return ccandy
