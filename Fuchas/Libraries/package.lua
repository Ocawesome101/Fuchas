local package = {}

local backupPackagePath = "A:/Fuchas/Libraries/?.lua;./?.lua;A:/?.lua;A:/Users/Shared/Libraries/?.lua"
package.path = backupPackagePath

local loading = {}

local loaded = {
	["_G"] = _G,
	["bit32"] = bit32,
	["coroutine"] = coroutine,
	["math"] = math,
	["os"] = os,
	["package"] = package,
	["string"] = string,
	["table"] = table,
	["component"] = component,
	["computer"] = computer
}
package.loaded = loaded

function package.searchpath(name, path, sep, rep)
  checkArg(1, name, "string")
  checkArg(2, path, "string")
  sep = sep or '.'
  rep = rep or '/'
  sep, rep = '%' .. sep, rep
  name = string.gsub(name, sep, rep)
  local fs = require("filesystem")
  local errorFiles = {}
  for subPath in string.gmatch(path, "([^;]+)") do
    subPath = string.gsub(subPath, "?", name)
    if fs.exists(subPath) then
      local file = fs.open(subPath, "r")
      if file then
        file:close()
        return subPath
      end
    end
    table.insert(errorFiles, "\tno file '" .. subPath .. "'")
  end
  return nil, table.concat(errorFiles, "\n")
end

local mtSetup = false
function require(module)
	checkArg(1, module, "string")
	if loaded[module] ~= nil then
		return loaded[module]
	elseif not loading[module] then
		local library, status, step
		if not mtSetup and os and os.getenv then -- compatible before and after launching
			if os.getenv("LIB_PATH") then
				package.path = nil
				setmetatable(package, {
					__index = function(self, key)
						if key == "path" then
							return os.getenv("LIB_PATH") or backupPackagePath
						end
					end,
					__newindex = function(self, key, value)
						if key == "path" then
							print("new value: " .. value)
							os.setenv("LIB_PATH", value)
						end
					end
				})
				mtSetup = true
			end
		end
		step, library, status = "not found", package.searchpath(module, package.path)
		if library then
			step, library, status = "loadfile failed", loadfile(library)
		end

		if library then
			loading[module] = true
			step, library, status = "load failed", pcall(library, module)
			loading[module] = false
		end

		assert(library, string.format("module '%s' %s:\n%s", module, step, status))
		loaded[module] = status
		return status
	else
		error("already loading: " .. module .. "\n" .. debug.traceback(), 2)
	end
end

function package.delay(lib, file)
	local mt = {
		__index = function(tbl, key)
			setmetatable(lib, nil)
			setmetatable(lib.internal or {}, nil)
			dofile(file)
			return tbl[key]
		end
	}
	if lib.internal then
		setmetatable(lib.internal, mt)
	end
	setmetatable(lib, mt)
end

-------------------------------------------------------------------------------

return package
