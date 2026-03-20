---@diagnostic disable: cast-local-type, assign-type-mismatch
-- Customization options
local newline = "\r\n"
local ccandy = {
	colorsOff = false,
	debugOn = true,
   debugLevel = 2,   --1 = warn and error, 2 = log, 3 = everything
	baseLevel = 2,
	pathDepth = 1,
   tableDepth = 2,
	toDoExpiration = 5,
	reminderheader = "==========!!!=======REMINDER=======!!!========",
	reminderfooter = "=========!!!=======================!!!========",
	toDoTab = "   ",
	backgrounds = false,
	tableDepthLimit = 9,
	colors = {
		warn = "yellow",
		error = "red",
		debug = "blue",
		todo = "cyan",
		remind = "yellow",
		success = "green"
	},
	bgcolors = {
		warn = "red",
		error = "white",
		debug = "yellow",
		todo = "magenta",
		remind = "blue",
		success = "black"
	},
}

-- ANSI sequences
local resetANSI = "\x1B[m"
local consolecolors = {
	black = "\x1b[30m",			white = "\x1b[37m",
	red = "\x1B[31m", 			green = "\x1B[32m", 	
	yellow = "\x1b[33m", 		blue = "\x1b[94m",
	magenta = "\x1b[35m",		cyan = "\x1b[36m"	}		
		
local bgcolors = {
	white = "\x1b[47m",				black = "\x1b[40m",
	red = "\x1b[41m",				yellow = "\x1b[43m",	   		
	green = "\x1b[42m",				blue = "\x1b[44m",
	magenta = "\x1b[45m",			cyan = 	"\x1b[46m"	}

-- Helper functions

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
	local depth = ccandy.pathDepth
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
					file = string.gsub(file, "%s", "")  -- Remove spaces	--TODO: this might interfere with filenames that have spaces. Solution: don't use spaces imo
                    file = string.gsub(file, "/", ".")  -- Replace '/' with '.'
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
	level = level or ccandy.baseLevel
	local line = extractCallerInfo(level,parseStart)
	return n.." "..line..": "
end
local function getDeepest(t, refs, deep)
	deep = deep or 1
	local limit = ccandy.tableDepthLimit
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
local function getSpacing(space, name, div)
	space = space or 9 --the size of a type label
	div = div or 1
	name = tostring(name)
	local spaces = ""
	local diff = space - #name
	diff = diff / div
	for i = 1, diff do
		spaces = spaces.." "
	end
	return spaces
end
local function inspect(i, refs)
	local t = type(i)
	local limit = ccandy.tableDepthLimit
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
local function getANSI(name)	--getANSI todo is passed
	local e = consolecolors[ccandy.colors[name]]
	if ccandy.backgrounds then
		e = e ..bgcolors[ccandy.bgcolors[name]]
	end
	return e
end

local function dump(value, curDepth, refs, indent)
   refs = refs or {}
   indent = indent or ""
   local open = "{\n"
   local close = "}"
   local p = ""
   -- NON-TABLE OR DEPTH LIMIT
   if type(value) ~= "table" or curDepth <= 0 then
      if type(value) == "string" then
         return p .. value
      else
         return p .. inspect(value)
      end
   end
   -- cycle detection
   local id = tostring(value)
   if refs[id] then
      return indent .. "<cycle " .. id .. ">"
   end
   refs[id] = true

   local t = value
   local nextIndent = indent .. "  "

   p = p .. indent .. open
   -- formatting helper
   local function addLine(key, valStr)
      p = p .. nextIndent .. tostring(key) .. " = " .. valStr .. ",\n"
   end
   -- numeric indices
   for i = 1, #t do
      local child = t[i]
      addLine(i, dump(child, curDepth - 1, refs, nextIndent))
   end
   -- string keys
   for k, v in pairs(t) do
      if k ~= "_tableName" and not tonumber(k) then
         addLine(k, dump(v, curDepth - 1, refs, nextIndent))
      end
   end
   p = p .. indent .. close

   return p
end
local function write(c)
   if type(c) == "table" then
      if not ccandy.RETURNSTRING then io.write(c:tostring()) end
      return c:tostring() 
   else
      if not ccandy.RETURNSTRING then io.write(tostring(c)) end
      return tostring(c)
   end
   
end
local function concat(...)
   return table.tostring({...})
end

--== PARSING FUNCTION ==--



local function parseArgs(...)
   if select("#", ...) == 0 then return end
   local a, b = select(1, ...)      -- or simply: local a, b = ...
   process(a, b)
   return parse(select(3, ...))
end

--== REPORTING TOOLS ==--

--==== VISUAL TEMPLATES ====--
function ccandy.title(_)
   local h = "==============================\r\n"
   local f = "\r\n=============================="
   local msg = h .. tostring(_) .. f
   ccandy.printC(getANSI("debug"),msg)

end

function ccandy.debug(_,level,parseStart,depth) -- print magenta to console, takes a string or table. Only when debugOn is on.
   depth = depth or ccandy.tableDepth or 1--TODO: add better arg parsing to this
	if not ccandy.debugOn then return end
   local header = getCallLine("DEBUG",level,parseStart)
   local body = dump(_, depth, nil, "")
   local msg = header .. body
   msg = msg:match("^(.-)[,\r\n]?$")  -- keep your trailing cleanup

   ccandy.printC(getANSI("debug"), msg)
   
end
function ccandy.todo(_) --ccandy.todo{"Update date","XChecked Step 1","Unchecked Step 2","Unchecked Step 3"}
	local level = 1
	local todotab = ccandy.toDoTab
	if ccandy.debugOn then
		if type(_) ~= "table" then _ = {tostring(_)} end
		local p1 = getCallLine("TODO",level)
		local p2 = nil
		local p3 = ""
		local checked = "[X] "
		local unchecked = "[ ] "
		local checkbox = ""
		local exTimePassed
		local datefound,date,timePassed
		for i=1, #_ do
			local item = _[i]
			if not datefound then date, timePassed = compareDate(item) end
			if date then
				exTimePassed = timePassed
				if timePassed >= ccandy.toDoExpiration then
					p2 = "     WARNING: "..tostring(timePassed).." days since this Todo list was updated!"
				end
				datefound = true
				date = false
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
			if exTimePassed >= (ccandy.toDoExpiration * 3) then
				warncolor = getANSI("error")
			elseif exTimePassed >= ccandy.toDoExpiration then
				warncolor = getANSI("error")
			end
		end
		ccandy.printCTable({getANSI("todo"),warncolor,getANSI("todo")},{p1,p2,p3})
	end
end
function ccandy.remind(setdate,reminderdate,_)
	if ccandy.debugOn then
		local date, timePassedSinceSet = compareDate(setdate)
		assert(date,"ccandy.reminder called without setdate!")
		date, timePassedSinceReminder = compareDate(reminderdate)
		assert(date,"ccandy.reminder called without reminderdate!")
		if timePassedSinceReminder >= 0 then
			local heading = ccandy.reminderheader
			local since = "A reminder was set on "..setdate.." "..timePassedSinceSet.." days ago!"
			local reminder = ""
			local post = ccandy.reminderfooter
			ccandy.printCTable(ccandy.colors.warn,{heading, since})
			if type(_) == "table" then
				for i,v in ipairs(_) do
					if type(v)=="string" then
						reminder = reminder..v
						if i < #_ then
							reminder = reminder.."\r\n"
						end
					elseif type(v)=="function" then
						v()
					end
				end
			elseif type(_) == "function" then
				_()
			else
				reminder = reminder.._
			end
			if type(_) == "table" then
				for k,v in pairs(_) do
					if type(k) ~= "number" then
						if type(v) == "function" then
							_[k]()
						end
					end
				end
			end
			ccandy.printC(ccandy.colors.warn,reminder)
			ccandy.printC(getANSI("remind"),post)
		end
	end
end
function ccandy.success(_,level) --print green to console, takes a string or table
	level = level or 0	--success uses its own default, 0, because that makes sense to me
    if type(_) ~= "table" then _ = {_} end
	local p = getCallLine("SUCCESS!",level)
	local item
    for i=1, #_ do
		item = _[i]
		if type(item)=="function" then
			item()
		else
			p = p..tostring(item)
		end
		if i < #_ then
			p = p..", "
		end
    end
    ccandy.printC(getANSI("success"),p)
end
function ccandy.warn(_,level,parseStart) --print yellow to console, takes a string or table
    if type(_) ~= "table" then _ = {_} end
	local p = getCallLine("WARNING",level,parseStart)
    for i=1, #_ do
		item = _[i]
		if type(item)=="function" then
			item()
		else
			p = p..tostring(item)
		end
		if i < #_ then
			p = p..", "
		end
    end
    ccandy.printC(getANSI("warn"),p)
end
function ccandy.stop(_,level,parseStart) --print red to console then stop the program
	parseStart = parseStart or 5
	ccandy.error(_,level,parseStart)
   if type(_) ~= "table" then _ = {_} end
	if type(_) == "table" then _ = tostring(_[1]) end
	error("Stopped by ccandy.stop(): ".._.." (console may have more info)")
end
function ccandy.error(_,level,parseStart) --print red to console, takes a string or table
    if type(_) ~= "table" then _ = {_} end
    local p = getCallLine("ERROR",level,parseStart)
	local item
    for i=1, #_ do
		item = _[i]
		if type(item)=="function" then
			item()
		else
			p = p..tostring(item)
		end
		if i < #_ then
			p = p..", "
		end
    end
    ccandy.printC(getANSI("error"),p)
end
function ccandy.blank(msg,n)
	if type(msg) == "number" then n = msg; msg = nil end
	n = n or 10
	local p = ""
	for i=1,n do
		p = p .. "\r\n"
	end
	if msg then ccandy.printC("green",tostring(msg)) end
	io.write(p)
end
---TODO: put this in a proper log system, which prints logs using io in order to parse at a later time.
function ccandy.log(...)
   if ccandy.debugLevel < 2 then return end
   debug(concat(...))
end

function ccandy.printC(ANSI, _)
   local ret = ""
	if not ccandy.colorsOff then
		local fg, bg = ANSI:match("([^|]+)|([^|]+)")
		if not fg then fg = ANSI end
		local c = consolecolors[fg]
		local b = bgcolors[bg]
		if not c then c = fg end
		if bg and not b then b = bg end
		if b then c = c..b end
		ret = ret .. write(c)
	end
	ret = ret .. write(_)
	ret = ret .. write("\r\n")
	ret = ret .. write(resetANSI)
   ccandy.RETURNSTRING = false
	::skip::
end

function ccandy._debug(...) 
   ccandy.RETURNSTRING = true
   ccandy.debug(...)
end
function ccandy._warn(...) 
   ccandy.RETURNSTRING = true
   ccandy.warn(...)
end
function ccandy._error(...) 
   ccandy.RETURNSTRING = true
   ccandy.error(...)
end
function ccandy._stop(...) 
   ccandy.RETURNSTRING = true
   ccandy.stop(...)
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
	local ignore = {export=true}
	n = n or ""
	for k,v in pairs(self) do
		if not ignore[k] then
			local f = n..k
			_G[f] = v
		end
	end
end

return ccandy
