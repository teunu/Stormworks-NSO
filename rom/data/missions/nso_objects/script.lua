--[[
	[ ] Add command help
	[*] Add command to list tags that can be used to spawn things.
	[*] Protect against spawning static vehicles multiple times.
	[ ] Add better output to spawn commands, using a context object with counters etc.
]]


local script_name = "NSO_Objects"
local script_version = "0.0.0"


local http_port = 8080
local HttpLogFilePath = "/log/NSO_Objects/server.log"


local file_version = 1

local addon_index


local spawned = {
	vehicle_id__to__component = {},

	---@type table<integer, true>
	no_duplicates_component_id_set = {},
	objects = {},
}

---@param t table
local function tableCount(t)
	local count = 0
	for _, _ in pairs(t) do
		count = count + 1
	end
	return count
end



local function tableAny(t)
	return next(t)
end

local function mergeTableShallow(target, extra)
	for k,v in pairs(extra) do
		target[k] = v
	end
	return target
end


---Merges local data and the g_saveData table specified.
---The localData table is preserved (reference identity) so additions later will automatically appear in savedata.
---@param saveData table
---@param localData table
---@return table
local function mergeSaveDataTable(saveData, localData)
	return mergeTableShallow(localData, saveData or {})
end



local function matrixToXyz(matrix)
	return matrix[14], matrix[15], matrix[16]
end

local function matrixToVector(matrix)
	return {x=matrix[13], y=matrix[14], z=matrix[15]}
end

---Removes all entries from a table.
---Use this when re-assigning a new (empty) table is not an option.
---@param t any
local function clearTable(t)
	for k,_ in pairs(t) do
		t[k] = nil
	end
end

---Round a number to integer.
---@param v number
---@return integer
local function round(v)
	return math.floor(v + 0.5)
end

---Converts a list of keys into a map of keys to themselves, in place.
---@generic TKey
---@param t TKey[]
---@return table<TKey, TKey>
local function listToMap(t)
	for i, v in ipairs(t) do
		t[v] = v
		t[i] = nil
	end
	return t
end


--------------------------------------------------------------------------------
--#region Fake Basic Lua Functions

---@diagnostic disable-next-line: undefined-global
local _ENV = _G or _ENV
local _G = _ENV

---If not defined makes a pretend-getmetatable that just does nothing.
---@param t table
---@return table|nil
getmetatable = getmetatable or function(t) return nil end

	
---If not defined makes a pretend-setmetatable that just does nothing.
---@param t table
---@param mt table
setmetatable = setmetatable or function(t, mt) end

---If not defined makes a pretend-pcall that just runs the function without protection.
---@param f function
---@vararg any Parameters to f
---@return boolean success
---@return any ... Return values from f
pcall = pcall or function(f, ...) return true, f(...) end

---Selects from the first 16 arguments.
---@param n integer The index of the first argument to select.
---@vararg any The arguments to select from.
---@return any ...
local function select(n, ...)
	local r = {...}
	return r[n], r[n+1], r[n+2], r[n+3], r[n+4], r[n+5], r[n+6], r[n+7], r[n+8], r[n+9], r[n+10], r[n+11], r[n+12], r[n+13], r[n+14], r[n+15], r[n+16]
end


--#endregion
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--#region Serpent Serializer

local serpent
do
	local n, v = "serpent", "0.303" -- (C) 2012-18 Paul Kulchenko; MIT License
	local c, d = "Paul Kulchenko", "Lua serializer and pretty printer"
	local snum = { [tostring(1/0)] = '1/0 --[[math.huge]]', [tostring(-1/0)] = '-1/0 --[[-math.huge]]', [tostring(0/0)] = '0/0'}
	local badtype = {thread = true, userdata = true, cdata = true}
	local getmetatable = debug and debug.getmetatable or getmetatable
	local pairs = function(t) return next, t end -- avoid using __pairs in Lua 5.2+
	local keyword, globals, G = {}, {}, (_G or _ENV)
	for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
		'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
		'return', 'then', 'true', 'until', 'while'})
		do keyword[k] = true
	end
	for k,v in pairs(G) do globals[v] = k end -- build func to name mapping
	for _,g in ipairs({'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os'}) do
		for k,v in pairs(type(G[g]) == 'table' and G[g] or {}) do globals[v] = g..'.'..k end
	end

	local function s(t, opts)
		local name, indent, fatal, maxnum = opts.name, opts.indent, opts.fatal, opts.maxnum
		local sparse, custom, huge, nohuge = opts.sparse, opts.custom, not opts.nohuge, opts.nohuge
		local space, maxl = (opts.compact and '' or ' '), (opts.maxlevel or math.huge)
		local maxlen, metatostring = tonumber(opts.maxlength), opts.metatostring
		local iname, comm = '_'..(name or ''), opts.comment and (tonumber(opts.comment) or math.huge)
		local numformat = opts.numformat or "%.17g"
		local seen, sref, syms, symn = {}, {'local '..iname..'={}'}, {}, 0
		local function gensym(val)
			return '_'..(tostring(tostring(val)):gsub("[^%w]",""):gsub("(%d%w+)",
			-- tostring(val) is needed because __tostring may return a non-string value
			function(s)
				if not syms[s] then
					symn = symn+1; syms[s] = symn
				end
				return tostring(syms[s])
			end))
		end
		local function safestr(s)
			return type(s) == "number" and (huge and snum[tostring(s)] or numformat:format(s))
			or type(s) ~= "string" and tostring(s) -- escape NEWLINE/010 and EOF/026
			or ("%q"):format(s):gsub("\010","n"):gsub("\026","\\026")
		end
		-- handle radix changes in some locales
		if opts.fixradix and (".1f"):format(1.2) ~= "1.2" then
			local origsafestr = safestr
			safestr = function(s) return type(s) == "number"
			and (nohuge and snum[tostring(s)] or numformat:format(s):gsub(",",".")) or origsafestr(s)
			end
		end
		local function comment(s,l)
			return comm and (l or 0) < comm and ' --[['..select(2, pcall(tostring, s))..']]' or ''
		end
		local function globerr(s,l)
			return globals[s] and globals[s]..comment(s,l) or not fatal
			and safestr(select(2, pcall(tostring, s))) or error("Can't serialize "..tostring(s))
		end
		local function safename(path, name) -- generates foo.bar, foo[3], or foo['b a r']
			local n = name == nil and '' or name
			local plain = type(n) == "string" and n:match("^[%l%u_][%w_]*$") and not keyword[n]
			local safe = plain and n or '['..safestr(n)..']'
			return (path or '')..(plain and path and '.' or '')..safe, safe
		end
		local alphanumsort = type(opts.sortkeys) == 'function' and opts.sortkeys or function(k, o, n) -- k=keys, o=originaltable, n=padding
			local maxn, to = tonumber(n) or 12, {number = 'a', string = 'b'}
			local function padnum(d)
				return ("%0"..tostring(maxn).."d"):format(tonumber(d))
			end
			table.sort(k,
				function(a,b)
					-- sort numeric keys first: k[key] is not nil for numerical keys
					return (k[a] ~= nil and 0 or to[type(a)] or 'z')..(tostring(a):gsub("%d+",padnum))
					< (k[b] ~= nil and 0 or to[type(b)] or 'z')..(tostring(b):gsub("%d+",padnum))
				end
			)
		end
		local function val2str(t, name, indent, insref, path, plainindex, level)
			local ttype, level, mt = type(t), (level or 0), getmetatable(t)
			local spath, sname = safename(path, name)
			local tag = plainindex and
				((type(name) == "number") and '' or name..space..'='..space) or
				(name ~= nil and sname..space..'='..space or '')
			if seen[t] then -- already seen this element
				sref[#sref+1] = spath..space..'='..space..seen[t]
				return tag..'nil'..comment('ref', level)
			end
			-- protect from those cases where __tostring may fail
			if type(mt) == 'table' and metatostring ~= false then
				local to, tr = pcall(function() return mt.__tostring(t) end)
				local so, sr = pcall(function() return mt.__serialize(t) end)
				if (to or so) then -- knows how to serialize itself
					seen[t] = insref or spath
					t = so and sr or tr
					ttype = type(t)
				end -- new value falls through to be serialized
			end
			if ttype == "table" then
				if level >= maxl then return tag..'{}'..comment('maxlvl', level) end
				seen[t] = insref or spath
				if next(t) == nil then return tag..'{}'..comment(t, level) end -- table empty
				if maxlen and maxlen < 0 then return tag..'{}'..comment('maxlen', level) end
				local maxn, o, out = math.min(#t, maxnum or #t), {}, {}
				for key = 1, maxn do o[key] = key end
				if not maxnum or #o < maxnum then
					local n = #o -- n = n + 1; o[n] is much faster than o[#o+1] on large tables
					for key in pairs(t) do
						if o[key] ~= key then n = n + 1; o[n] = key end
					end
				end
				if maxnum and #o > maxnum then o[maxnum+1] = nil end
				if opts.sortkeys and #o > maxn then alphanumsort(o, t, opts.sortkeys) end
				local sparse = sparse and #o > maxn -- disable sparsness if only numeric keys (shorter output)
				for n, key in ipairs(o) do
					local value, ktype, plainindex = t[key], type(key), n <= maxn and not sparse
					if opts.valignore and opts.valignore[value] -- skip ignored values; do nothing
					or opts.keyallow and not opts.keyallow[key]
					or opts.keyignore and opts.keyignore[key]
					or opts.valtypeignore and opts.valtypeignore[type(value)] -- skipping ignored value types
					or sparse and value == nil then -- skipping nils; do nothing
					elseif ktype == 'table' or ktype == 'function' or badtype[ktype] then
						if not seen[key] and not globals[key] then
							sref[#sref+1] = 'placeholder'
							local sname = safename(iname, gensym(key)) -- iname is table for local variables
							sref[#sref] = val2str(key,sname,indent,sname,iname,true)
						end
						sref[#sref+1] = 'placeholder'
						local path = seen[t]..'['..tostring(seen[key] or globals[key] or gensym(key))..']'
						sref[#sref] = path..space..'='..space..tostring(seen[value] or val2str(value,nil,indent,path))
					else
						out[#out+1] = val2str(value,key,indent,nil,seen[t],plainindex,level+1)
						if maxlen then
						maxlen = maxlen - #out[#out]
						if maxlen < 0 then break end
						end
					end
				end
				local prefix = string.rep(indent or '', level)
				local head = indent and '{\n'..prefix..indent or '{'
				local body = table.concat(out, ','..(indent and '\n'..prefix..indent or space))
				local tail = indent and "\n"..prefix..'}' or '}'
				return (custom and custom(tag,head,body,tail,level) or tag..head..body..tail)..comment(t, level)
			elseif badtype[ttype] then
				seen[t] = insref or spath
				return tag..globerr(t, level)
			elseif ttype == 'function' then
				seen[t] = insref or spath
				if opts.nocode then return tag.."function() --[[..skipped..]] end"..comment(t, level) end
				local ok, res = pcall(string.dump, t)
				local func = ok and "((loadstring or load)("..safestr(res)..",'@serialized'))"..comment(t, level)
				return tag..(func or globerr(t, level))
			else
				return tag..safestr(t)
			end -- handle all other types
		end
		local sepr = indent and "\n" or ";"..space
		local body = val2str(t, name, indent) -- this call also populates sref
		local tail = #sref>1 and table.concat(sref, sepr)..sepr or ''
		local warn = opts.comment and #sref>1 and space.."--[[incomplete output with shared/self-references skipped]]" or ''
		return not name and body..warn or "do local "..body..sepr..tail.."return "..name..sepr.."end"
	end

	local function deserialize(data, opts)
		local env = (opts and opts.safe == false) and G
			or setmetatable({}, {
				__index = function(t,k) return t end,
				__call = function(t,...) error("cannot call functions") end
			  })
		local f, res = nil, nil --(loadstring or load)('return '..data, nil, nil, env)
		if not f then
			f, res = nil, nil --(loadstring or load)(data, nil, nil, env)
		end
		if not f then
			return f, res
		end
		if setfenv then
			setfenv(f, env)
		end
		return pcall(f)
	end

	local function merge(a, b)
		if b then
			for k,v in pairs(b) do
				a[k] = v
			end
		end
		return a
	end
	serpent =
	{
		_NAME = n,
		_COPYRIGHT = c,
		_DESCRIPTION = d,
		_VERSION = v,
		serialize = s,
		load = deserialize,
		dump = function(a, opts) return s(a, merge({name = '_', compact = true, sparse = true, nocode = true}, opts)) end,
		line = function(a, opts) return s(a, merge({sortkeys = true, comment = true, nocode = true}, opts)) end,
		block = function(a, opts) return s(a, merge({indent = '\t', sortkeys = true, comment = true, nocode = true}, opts)) end
	}
end
--#endregion
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--#region Base64
-- Copied from http2@845b527b62975c383b5200679de52751be5388ac

local base64 = {}
do
--[[
 base64 -- v1.5.3 public domain Lua base64 encoder/decoder
 no warranty implied; use at your own risk
 Needs bit32.extract function. If not present it's implemented using BitOp
 or Lua 5.3 native bit operators. For Lua 5.1 fallbacks to pure Lua
 implementation inspired by Rici Lake's post:
   http://ricilake.blogspot.co.uk/2007/10/iterating-bits-in-lua.html
 author: Ilya Kolbin (iskolbin@gmail.com)
 url: github.com/iskolbin/lbase64
 COMPATIBILITY
 Lua 5.1+, LuaJIT
 LICENSE
 See end of file for license information.
]]

local extract = nil --_G.bit32 and _G.bit32.extract -- Lua 5.2/Lua 5.3 in compatibility mode
if not extract then
	if _G.bit then -- LuaJIT
		local shl, shr, band = _G.bit.lshift, _G.bit.rshift, _G.bit.band
		extract = function( v, from, width )
			return band( shr( v, from ), shl( 1, width ) - 1 )
		end
	elseif --[[_G._VERSION == "Lua 5.1"]] true then
		extract = function( v, from, width )
			local w = 0
			local flag = 2^from
			for i = 0, width-1 do
				local flag2 = flag + flag
				if v % flag2 >= flag then
					w = w + 2^i
				end
				flag = flag2
			end
			return w
		end
	else -- Lua 5.3+
---@diagnostic disable-next-line: param-type-mismatch
		extract = load[[return function( v, from, width )
			return ( v >> from ) & ((1 << width) - 1)
		end]]()
	end
end


function base64.makeencoder( s62, s63, spad )
	local encoder = {}
	for b64code, char in pairs{[0]='A','B','C','D','E','F','G','H','I','J',
		'K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y',
		'Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n',
		'o','p','q','r','s','t','u','v','w','x','y','z','0','1','2',
		'3','4','5','6','7','8','9',s62 or '+',s63 or'/',spad or'='} do
		encoder[b64code] = char:byte()
	end
	return encoder
end

function base64.makedecoder( s62, s63, spad )
	local decoder = {}
	for b64code, charcode in pairs( base64.makeencoder( s62, s63, spad )) do
		decoder[charcode] = b64code
	end
	return decoder
end

local DEFAULT_ENCODER = base64.makeencoder()
local DEFAULT_DECODER = base64.makedecoder()

local char, concat = string.char, table.concat

function base64.encode( str, encoder, usecaching )
	encoder = encoder or DEFAULT_ENCODER
	local t, k, n = {}, 1, #str
	local lastn = n % 3
	local cache = {}
	for i = 1, n-lastn, 3 do
		local a, b, c = str:byte( i, i+2 )
		local v = a*0x10000 + b*0x100 + c
		local s
		if usecaching then
			s = cache[v]
			if not s then
				s = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[extract(v,0,6)])
				cache[v] = s
			end
		else
			s = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[extract(v,0,6)])
		end
		t[k] = s
		k = k + 1
	end
	if lastn == 2 then
		local a, b = str:byte( n-1, n )
		local v = a*0x10000 + b*0x100
		t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[64])
	elseif lastn == 1 then
		local v = str:byte( n )*0x10000
		t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[64], encoder[64])
	end
	return concat( t )
end

function base64.decode( b64, decoder, usecaching )
	decoder = decoder or DEFAULT_DECODER
	local pattern = '[^%w%+%/%=]'
	if decoder then
		local s62, s63
		for charcode, b64code in pairs( decoder ) do
			if b64code == 62 then s62 = charcode
			elseif b64code == 63 then s63 = charcode
			end
		end
		pattern = ('[^%%w%%%s%%%s%%=]'):format( char(s62), char(s63) )
	end
	b64 = b64:gsub( pattern, '' )
	local cache = usecaching and {}
	local t, k = {}, 1
	local n = #b64
	local padding = b64:sub(-2) == '==' and 2 or b64:sub(-1) == '=' and 1 or 0
	for i = 1, padding > 0 and n-4 or n, 4 do
		local a, b, c, d = b64:byte( i, i+3 )
		local s
		if usecaching then
			local v0 = a*0x1000000 + b*0x10000 + c*0x100 + d
			s = cache[v0]
			if not s then
				local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40 + decoder[d]
				s = char( extract(v,16,8), extract(v,8,8), extract(v,0,8))
				cache[v0] = s
			end
		else
			local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40 + decoder[d]
			s = char( extract(v,16,8), extract(v,8,8), extract(v,0,8))
		end
		t[k] = s
		k = k + 1
	end
	if padding == 1 then
		local a, b, c = b64:byte( n-3, n-1 )
		local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40
		t[k] = char( extract(v,16,8), extract(v,8,8))
	elseif padding == 2 then
		local a, b = b64:byte( n-3, n-2 )
		local v = decoder[a]*0x40000 + decoder[b]*0x1000
		t[k] = char( extract(v,16,8))
	end
	return concat( t )
end

--[[
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2018 Ilya Kolbin
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
--]]

end
--#endregion
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--#region Http
-- Copied from http2@845b527b62975c383b5200679de52751be5388ac



---@alias HttpAction
---|'Append'
---|'Replace'
---|'Delete'


---@param port integer
---@param path string
---@return HttpService
local function HttpService(port, path)
	---@class HttpService
	local service = {}

	service.port = port
	service.path = path

	service.serializerOpts = nil


	-- https://en.wikipedia.org/wiki/Base64

	---Should be divisible by 4 or will break the encoding!
	service.maxQueryLength = 1000
	service.sequenceNumber = 0

	do -- Ensure querylength is divisible by 4 so that we don't break up a base64 group.
		local ql = service.maxQueryLength or 1000
		local rem = ql % 4
		ql = ql - rem

		service.maxQueryLength = ql
	end

	---Requests a unique file name and modifies path accordingly.
	function service.getUnique()
		-- todo: implement.
		-- Will need to defer sending file commands till a response has been received.

	end

	local function splitData(container, ...)
		container = container or {}
		clearTable(container)

		local args = {...}
		local data = ""

		if #args == 1 and type(args[1]) == "string" then
			data = args[1]
		elseif #args == 1 then
			data = serpent.block(args[1], service.serializerOpts)
		else
			data = serpent.block(args, service.serializerOpts)
		end

		repeat
			local d = base64.encode(data:sub(1, service.maxQueryLength))
			table.insert(container, d)
			data = data:sub(service.maxQueryLength + 1, -1)
			service.sequenceNumber = service.sequenceNumber + 1
		until #data < 1

		return container
	end

	---Send data
	---@param action HttpAction
	---@param time integer
	---@param content string[]
	local function send(action, time, content)
		local partNo = 0
		for i, d in ipairs(content) do
			server.httpGet(service.port, string.format("%s?action=%s&sequence_no=%i&part_no=%i&t=%i&data=%s",
			                                  service.path,
			                                               action, service.sequenceNumber,
			                                                                 partNo, time, d))
			partNo = partNo + 1
			action = "Append" --Subsequent parts of data will always append.
		end
	end


	---Append the arguments to the file.
	---If it is a string single it is appended verbatim.
	---Otherwise all arguments are serialized using serpent.block()
	---If the data is too long it is automatically split into sections.
	---@param ... unknown
	function service.append(...)
		local time = server.getTimeMillisec()
		local datas = splitData({}, ...)
		send('Append', time, datas)
	end

	---Delete the file.
	function service.delete()
		local time = tostring(server.getTimeMillisec())
		server.httpGet(service.port, string.format("%s?action=%s&t=%i", service.path 'Delete', time))
	end

	function service.replace(...)
		local time = server.getTimeMillisec()
		local datas = splitData({}, ...)
		send('Replace', time, datas)
	end


	---Flush pending requests.
	function flush()

	end

	return service
end

local httplog = HttpService(http_port, HttpLogFilePath)


--#endregion
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--#region Logging

---@param title string
---@param message string
---@param user_peer_id Peer_ID|nil Exists to that it's easy to switch between HttpLog and server.announce, or to re-direct the log to server.announce
local function LogHttp(title, message, user_peer_id)
	httplog.append(string.format("[%s] %s", title, message))
end

---@param title string
---@param message string
---@param user_peer_id Peer_ID
local function LogBoth(title, message, user_peer_id)
	httplog.append(string.format("[%s] %s", title, message))
	server.announce(title, message, user_peer_id or -1)
end


---Log with title and format string
---@param title string title
---@param format string format
---@param ... unknown data for format
function LogFormat(title, format, ...)
	LogHttp(title, string.format(format, ...))
end


--#endregion
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--#region Addon stuff
-- Copied from http2@845b527b62975c383b5200679de52751be5388ac


---Searches for targetTag in the array of tags
---@param tags string[]
---@param targetTag string
---@return boolean
local function hasTag(tags, targetTag)
	for _, tag in ipairs(tags) do
		if tag == targetTag then
			return true
		end
	end
	return false
end

local function splitStringOnce(value, separator)
	local pos = value:find(separator, 1, true)
	if pos or 0 > 1 then
		return value:sub(1, pos - 1), value:sub(pos + separator:len())
	else
		return value
	end
end

---Parse tags into a key value container.
---Tags with no explicit value become true.
---@param tags string[]
---@param container table<string, string|boolean>
---@return table<string, string|boolean>
local function parseTags(tags, container)
	for _, tag in ipairs(tags) do
		local k, v = splitStringOnce(tag, "=")
		if v == nil then v = true end
		container[k] = v
	end
	return container
end

local function splitString(value, separator)
	local parts = {}
	while value and value:len() > 0 do
		local part, tail = splitStringOnce(value, separator)
		table.insert(parts, part)
		value = tail
	end
	return parts
end

local function joinStringArray(stringArray, separator)
	local out, first = "", true
	for _, str in ipairs(stringArray) do
		if first then first = false else out = out .. separator end
		out = out .. str
	end
	return out
end

local function sortTypeParts(typeString)
	local parts = splitString(typeString, "&")
	table.sort(parts)
	return joinStringArray(parts, "&")
end

local function iterComponents(addon_index, location_index)
	local location_data = server.getLocationData(addon_index, location_index)
	local object_count = 0
	if location_data then object_count = location_data.component_count end
	local object_index = 0

	return function()
		local object_data = nil
		local index = object_count

		while not object_data and object_index < object_count do
			object_data = server.getLocationComponentData(addon_index, location_index, object_index)
			index = object_index
			object_index = object_index + 1
		end

		if object_data then
			return index, object_data
		else
			return nil
		end
	end
end

local function iterLocations(addon_index)
	local addon_data = server.getAddonData(addon_index)
	local location_count = 0
	if addon_data then location_count = addon_data.location_count end
	local location_index = 0

	return function()
		local location_data = nil
		local index = location_count

		while not location_data and location_index < location_count do
			location_data = server.getLocationData(addon_index, location_index)
			local local_location_index = location_index
			location_data.iterate = function() return iterComponents(addon_index, local_location_index) end
			index = location_index
			location_index = location_index + 1
		end

		if location_data then
			return index, location_data
		else
			return nil
		end
	end
end

--- Iterate over all loaded addons.
local function iterAddons()
	local addon_count = server.getAddonCount()
	local addon_index = 0

	return function()
		local addon_data = nil
		local index = addon_count

		while not addon_data and addon_index < addon_count do
			addon_data = server.getAddonData(addon_index)
			local local_addon_index = addon_index
			addon_data.iterate = function() return iterLocations(local_addon_index) end
			index = addon_index
			addon_index = addon_index + 1
		end

		if addon_data then
			return index, addon_data
		else
			return nil
		end
	end
end



---@class VehicleSpawnPrefab : GetLocationComponentDataResult 
---@field meta table<string, true|string>
---@field spawn fun(position: Transform): vehicle_id: integer|nil, is_success: boolean

--- Search all addons for vehicles that are relevant and put them in a mapping by the type.
---@param tag string
---@param default_type string
---@return table<string, VehicleSpawnPrefab>
local function generateObjectByTypeMapping(tag, default_type)
	local type_tag = "spawn_".. tag .. "_type" -- Use spawn prefix so we don't get unintended matches with vehicles that are spawned directly instead of going through the zone abstraction.

	LogFormat("generateObjectByTypeMapping", "(tag: '%s', default_type: '%s')", tag, default_type)

	---@type table<string, VehicleSpawnPrefab>
	local objects_by_type = {}
	local our_addon_index = server.getAddonIndex()
	for addon_index, addon_data in iterAddons() do
		for _, location_data in addon_data.iterate() do
			if not location_data.env_mod then
				for _, component_data in location_data.iterate() do
					local meta = {}
					component_data.meta = parseTags(component_data.tags, meta)
					LogFormat("generateObjectByTypeMapping", "Working on component: %s", serpent.block(component_data))
					if component_data.type == "vehicle"
					and meta[type_tag]
					then
						meta[type_tag] = sortTypeParts(meta[type_tag] or default_type)

						LogFormat("generateObjectByTypeMapping", "meta: %s", serpent.block(meta))
						if 
							addon_index ~= our_addon_index
							or objects_by_type[meta[type_tag]] == nil
						then
							local local_addon_index = addon_index
							local local_component_index = component_data.id

							component_data.spawn = function(position)
								return server.spawnAddonVehicle(matrix.multiply(position, component_data.transform), local_addon_index, local_component_index)
							end
							---@cast component_data -GetLocationComponentDataResult, +VehicleSpawnPrefab
							objects_by_type[meta[type_tag]] = component_data
						end
					end
				end
			end
		end
	end

	--LogHttp2(string.format("generateObjectByTypeMapping(%s, %s)", tag, default_type), serpent.block(objects_by_type))
	return objects_by_type
end


--#endregion
--------------------------------------------------------------------------------


---@param cdata CommandEventArgs
local function complain_if_not_admin(cdata)
	if cdata.is_admin then return false end

	server.announce('Not authorized', 'You don\'t have access to the \''..cdata.subCommand..'\' subcommand!', cdata.user_peer_id)
	return true
end



local type_to_default_variant = {
	train_station = "default",
	junction = "symm",
	signalling_equipment_type = "Asig",
	train_buffer = "default"
}



local type_to_variant_map = {}

local function getTypeAndVariant(meta)
	local type_str, variant

	do
		local junction_type = meta.junction
		if junction_type then
			type_str = "junction"
			variant = junction_type

			return type_str, variant
		end
	end
	do
		local signal_type = meta.signalling_equipment_type
		if signal_type then
			type_str = "signalling_equipment"
			variant = signal_type

			return type_str, variant
		end
	end
	do
		local buffer = meta.train_buffer
		if buffer then
			type_str = "train_buffer"
			variant = buffer == true and "default" or buffer
		end
	end
	do
		local variant = meta.train_station_vehicle
		if variant then
			type_str = "train_station"
			return type_str, variant
		end
	end
end


---@param meta table<string, true|string>
---@return VehicleSpawnPrefab?
local function getPrefab(meta)
	local type_str, variant = getTypeAndVariant(meta)

	local r = type_to_variant_map[type_str]

	if not r then
		local default = type_to_default_variant[type_str]

		if not default then
			return nil
		end

		r = generateObjectByTypeMapping(type_str, default)
		type_to_variant_map[type_str] = r
	end

	return r[variant]
end


---@param cdata CommandEventArgs
---@param addon_index integer
---@param location_index integer
---@param location_matrix Transform
---@param component_index integer
---@param component GetLocationComponentDataResult
local function spawn_component_vehicle(cdata, addon_index, location_index, location_matrix, component_index, component)
	if spawned.no_duplicates_component_id_set[component.id] then
		LogHttp("do_component_vehicle", string.format("Not spawning Component %i in location %i in addon %i because it's static and has already been spawned.", component.id, location_index, addon_index))
		return
	end

	local global_transform = matrix.multiply(location_matrix, component.transform)
	local spawned_id, did_succ = server.spawnAddonVehicle(global_transform, addon_index, component.id)

	if not spawned_id or not did_succ then
		LogHttp("do_component_vehicle", "Failed to spawn vehicle: location_index: "..location_index.." / component_index: "..component_index, cdata.user_peer_id)
		return
	end
	LogHttp('do_component_vehicle', string.format('Spawned vehicle: \'%s\' with id %i', component.display_name, spawned_id), cdata.user_peer_id)
	component.vehicle_id = spawned_id
	spawned.vehicle_id__to__component[spawned_id] = component

	local vehicle_data = server.getVehicleData(spawned_id)

	component.vehicle_is_static = vehicle_data.static or false

	if vehicle_data.static or component.meta.no_duplicate_spawn then
		spawned.no_duplicates_component_id_set[component.id] = true
	end
	return true
end

---@param cdata CommandEventArgs
---@param addon_index integer
---@param location_index integer
---@param location_matrix Transform
---@param component_index integer
---@param component GetLocationComponentDataResult
local function spawn_component_zone_vehicle(cdata, addon_index, location_index, location_matrix, component_index, component)
---@diagnostic disable-next-line: undefined-field
	local prefab = getPrefab(component.meta)

	if not prefab then
		LogHttp("do_component_zone_vehicle", "Did not get a prefab: location_index: "..location_index.." / component_index: "..component_index, cdata.user_peer_id)
		return
	end

	if spawned.no_duplicates_component_id_set[component.id] then
		LogHttp("do_component_vehicle", string.format("Not spawning Component %i in location %i in addon %i because it's static and has already been spawned.", component.id, location_index, addon_index))
		return
	end


	local global_transform = matrix.multiply(location_matrix, component.transform)
	local spawned_id, did_succ = prefab.spawn(global_transform)

	if not spawned_id or not did_succ then
		LogHttp("do_component_zone_vehicle", "Failed to spawn vehicle: location_index: "..location_index.." / component_index: "..component_index, cdata.user_peer_id)
		return
	end
	LogHttp('do_component_zone_vehicle', string.format('Spawned vehicle: \'%s\' with id %i', component.display_name, spawned_id), cdata.user_peer_id)
	component.vehicle_id = spawned_id
	spawned.vehicle_id__to__component[spawned_id] = component

	local vehicle_data = server.getVehicleData(spawned_id)

	component.vehicle_is_static = vehicle_data.static or false

	if vehicle_data.static or component.meta.no_duplicate_spawn then
		spawned.no_duplicates_component_id_set[component.id] = true
	end

	return true
end



---@param cdata CommandEventArgs
---@param addon_index integer
---@param location_index integer
---@param location_matrix Transform
---@param component_index integer
---@param filter? string
local function spawn_at_component_index(cdata, addon_index, location_index, location_matrix, component_index, filter)
	local component, did_succ = server.getLocationComponentData(addon_index, location_index, component_index)

	if not component or not did_succ then
		LogHttp("do_component_index", "no component data for location_index: "..location_index.." / component_index: "..component_index, cdata.user_peer_id)
		return
	end

	local meta = {}
	component.meta = parseTags(component.tags, meta)

	--LogFormat("do_component_index", "Looking at component #%2d '%s', type=%s: %s", component_index, component.display_name, component.type, serpent.block(component))

	if filter and
	(
		not hasTag(component.tags, filter)
		and not component.meta[filter]
	) then
		LogFormat("do_component_index", "No match with filter.")
		return
	end


	if component.type == 'vehicle' then
		return spawn_component_vehicle(cdata, addon_index, location_index, location_matrix, component_index, component)
	elseif component.type == 'zone' then
		return spawn_component_zone_vehicle(cdata, addon_index, location_index, location_matrix, component_index, component)
	else
		LogFormat("do_component_index", "No handler for type %s", component.type)
	end
end

---returns "env" or "mis" depending on if the input is an Environment Location or Mission Location. Or "nil" if the input was nil.
---@param location GetLocationDataResult
---@return string
local function location_type_str(location)
	return location and (location.env_mod and "env" or "mis") or "nil"
end

---@param cdata CommandEventArgs
---@param addon_index integer
---@param location_index integer
---@param filter? string
---@return integer count_spawned
local function spawn_at_location_index(cdata, addon_index, location_index, filter)
	local location, did_succ = server.getLocationData(addon_index, location_index)

	---The id in the playlist, because ofc they had to make them be off by one.
	local location_id = location_index + 1

	if not did_succ then
		LogFormat("do_location_index", "No location data for location_index: %i", location_index)
		return 0
	end

	local location_matrix, did_suck = server.getTileTransform(matrix.translation(0, 0, 0), location.tile, 999999)

	if did_suck == false then
		LogFormat("do_location_index", "Error   on location #%2d %s '%s' tile: '%s'", location_id, location_type_str(location), location.name, location.tile or "<<nil>>")
		return 0
	end
	---@cast location_matrix -nil

	local counter = 0

	LogFormat("do_location_index", "Working on location #%2d %s '%s' tile: '%s' ...", location_id, location_type_str(location), location.name, location.tile or "<<nil>>" )
	for component_index = 0, location.component_count do
		local did_spawn = spawn_at_component_index(cdata, addon_index, location_index, location_matrix, component_index, filter)

		if did_spawn then
			counter = counter + 1
		end
	end

	return counter
end

--------------------------------------------------------------------------------
--#region Commands

local commands = {}

---@param cdata CommandEventArgs
function commands.spawn(cdata)
	if complain_if_not_admin(cdata) then return end

	local addon_index, did_succ = server.getAddonIndex()

	if not addon_index or not did_succ then
		return "error", "no addon index"
	end

	local addon = server.getAddonData(addon_index)

	if not addon then
		return "error", "no addon data for addon_index: "..addon_index
	end

	local filter = cdata.args[1] or "NSO_objects"
	if cdata.args[1] then
		LogBoth('Cat Spawn', string.format("Spawning components that match filter: '%s'...", filter), cdata.user_peer_id)
	else
		LogBoth('Cat Spawn', string.format("Spawning all components using the everything filter: '%s'...", filter), cdata.user_peer_id)
	end

	local counter = 0
	for location_index = 0, addon.location_count -1 do
		counter = counter + spawn_at_location_index(cdata, addon_index, location_index, filter)
	end

	LogHttp("spawn", "Done spawning, %i items spawned. Total counts of currently spawned vehicles %i", counter, tableCount(spawned.vehicle_id__to__component))

	return 'Cat Spawn', string.format('Spawning Catenary completed!\nSpawned %i total things. There are currently %i vehicles and %i objects total.', counter, tableCount(spawned.vehicle_id__to__component), tableCount(spawned.objects))
end

---@param cdata CommandEventArgs
function commands.despawn(cdata)
	if complain_if_not_admin(cdata) then return end

	local filter = cdata.args[1]
	if filter then
		server.announce('Cat Despawn', string.format("Despawning components that match filter '%s'...", filter), cdata.user_peer_id)
	end

	local vc, oc = 0, 0
	for id, data in pairs(spawned.vehicle_id__to__component) do
		if not filter or hasTag(data.tags, filter) then
			server.despawnVehicle(id, true)
			spawned.vehicle_id__to__component[id] = nil
			vc = vc + 1

			spawned.no_duplicates_component_id_set[data.id] = nil
		end
	end
	for id, data in pairs(spawned.objects) do
		if not filter or hasTag(data.tags, filter) then
			server.despawnObject(id, true)
			spawned.objects[id] = nil

			oc = oc + 1
		end
	end

	return 'Cat Despawn', 'Despanwing completed!\nRemoved '..vc..' vehicles and '..oc..' objects.'
end

---@param cdata CommandEventArgs
function commands.respawn(cdata)
	if complain_if_not_admin(cdata) then return end

	commands.despawn(cdata)
	commands.spawn(cdata)

	return 'Cat Respawn', 'Respawning Catenary completed!'
end

---@param cdata CommandEventArgs
function commands.deleteAll(cdata)
	if complain_if_not_admin(cdata) then return end

	server.notify(cdata.user_peer_id, 'Cat deleteAll start', 'Despawning all vehicles!', 7)
	local cnt = 0
	for i = 0, 10000 do
		local succ = server.despawnVehicle(i, true)
		if succ then cnt = cnt + 1 end
	end

	spawned.vehicle_id__to__component = {}
	spawned.objects  = {}
	spawned.no_duplicates_component_id_set = {}

	return 'Cat deleteAll end', 'Despawning all vehicles completed!\nRemoved '..cnt..' vehicles.'
end

---@param cdata CommandEventArgs
function commands.help(cdata)
	-- todo: after refactor there should be a framework for this.

	return "Info", string.format("Addon: %s, Version: %s", script_name, script_version)
end





local list_tags_exclude_patterns = {
	"^id_%d+$",
}

--- Returns true if the tag is excluded from listings.
---@param name string
---@return boolean
local function is_excluded_tag(name)
	for _, pattern in pairs(list_tags_exclude_patterns) do
		if name:match(pattern) then
			return true
		end
	end

	return false
end

local function increment_or_create_key(table, key)
	local value = table[key] or 0

	value = value + 1
	table[key] = value

	return value
end

---@param cdata CommandEventArgs
function commands.list_tags(cdata)
	local results = {}

	for location_index, location_data in iterLocations(addon_index) do
		for component_index, component in iterComponents(addon_index, location_index) do
			local meta = {}
			component.meta = parseTags(component.tags, meta)

			for name, value in pairs(meta) do
				local test_name = name
				if value ~= true then
					test_name = string.format("%s=%s", tostring(name), tostring(value))
				end

				if not is_excluded_tag(test_name) then
					increment_or_create_key(results, test_name)
				end
			end
		end
	end

	local entries = {}

	for k,v in pairs(results) do
		table.insert(entries, { name = k, occ = v})
	end

	table.sort(entries, function(a, b) return a.occ > b.occ end)

	local lines = {}
	for k,v in pairs(entries) do
		table.insert(lines, string.format("[%3i] %s", v.occ, v.name))
	end

	server.announce("Tags list", "[Occurrances] Tag\n"..table.concat(lines, "\n"), cdata.user_peer_id)
end


---@param cdata CommandEventArgs
function commands.dump(cdata)
	LogHttp("dump", serpent.block(spawned))
end

local commandNames = {}
for k,v in pairs(commands) do
	table.insert(commandNames, k)
end

--#endregion
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--#region Callbacks

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, subCommand, arg2, arg3, arg4, arg5)
	if string.lower(command) ~= "?nso" then
		-- Not a command for this addon.
		return
	end

	---@class CommandEventArgs
	local cdata = {
		full_message = full_message,
		user_peer_id = user_peer_id,
		is_admin = is_admin,
		is_auth = is_auth,
		command = string.lower(string.sub(command, 2)),
		subCommand = string.lower(subCommand),
		args = {arg2, arg3, arg4, arg5}
	}

	if not subCommand then
		server.announce('Missing subcommand', 'Missing subcommand, possible subcommands are:\n'..table.concat(commandNames, ', '), user_peer_id)
		return
	end

	local commandFunction = commands[subCommand]
	if not commandFunction then
		server.announce('Unknown subcommand', 'Subcommand \''..subCommand..'\' is not a known command.\nPossible subcommands are:\n'..table.concat(commandNames, ', '), user_peer_id)
		return
	end


	local title, message
	if xpcall then
		local function handler(e)
			local s = debug.traceback(e, 2)
			LogFormat(string.format("Uncaught Error in script: %s", script_name or "unknown"), s)

			title = "Error"
			message = s
		end

		local s, t, m = xpcall(commandFunction, handler, cdata)
		if s then
			title = t
			message = m
		end
	else
		title, message = commandFunction(cdata)
	end

	if title and message then
		server.announce(title, message, cdata.user_peer_id)
	end
end




function onCreate()
	addon_index = server.getAddonIndex()
	spawned = g_savedata or spawned or {}
	spawned.vehicles = spawned.vehicles or {}
	spawned.objects  = spawned.objects or {}
	spawned.no_duplicates_component_id_set = spawned.no_duplicates_component_id_set or {}
	g_savedata = spawned

	LogBoth(script_name, string.format('version: %s', script_version), -1)


	for type_str, default_variant in pairs(type_to_default_variant) do
		local r = generateObjectByTypeMapping(type_str, default_variant)

		type_to_variant_map[type_str] = r
	end

	LogHttp("onCreate", "type_to_variant_map:\n" .. serpent.block(type_to_variant_map))
end

--#endregion Callbacks
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
--#region Hacks

if xpcall and debug and debug.traceback then
	LogFormat("sandbox/meta", "Applying xpcall wrappers around entryPoints...")

	local function handler(e)
		local s = debug.traceback(e, 2)
		LogFormat(string.format("Uncaught Error in script: %s", script_name or "unknown"), s)
	end

	local protect = {
		"onTick",
		"onCreate",
		"onDestroy",
		"onChatMessage",
		"onPlayerJoin",
		"onPlayerSit",
		"onPlayerUnsit",
		"onCharacterSit",
		"onCharacterUnsit",
		"onPlayerRespawn",
		"onPlayerLeave",
		"onPlayerUnsit",
		"onToggleMap",
		"onPlayerDie",
		"onVehicleSpawn",
		"onVehicleDespawn",
		"onVehicleLoad",
		"onVehicleUnload",
		"onVehicleTeleport",
		"onObjectLoad",
		"onObjectUnload",
		"onButtonPress",
		"onSpawnAddonComponent",
		"onVehicleDamaged",
		"httpReply",
		"onFireExtinguished",
		"onForestFireSpawned",
		"onForestFireExtinguished",
	}

	original_global_env = original_global_env or {}
	for i,name in pairs(protect) do
		original_global_env[name] = original_global_env[name] or _ENV[name]
	end

	for i, name in pairs(protect) do
		if type(original_global_env[name]) == "function" then
			_ENV[name] = function(...) return xpcall(original_global_env[name], handler, ...) end
		end
 	end
end

--#endregion Hacks
--------------------------------------------------------------------------------
