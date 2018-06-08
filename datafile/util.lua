
-- utilities for the implementation of datafile modules
local util = {}

-- cache separator
local sep

function util.try_dirs(dirs, file, mode)
   if not sep then
      if (package.config and package.config:sub(1,1) == "\\") or package.path:match("\\") then
         sep = "\\"
      else
         sep = "/"
      end
   end
   local tried = {}
   for _, dir in ipairs(dirs) do
      local path
      if dir:sub(-1) == "|" then
         path = (dir:sub(1,-2)..file)
      else
         path = (dir..sep..file)
      end
      path = path:gsub(sep.."+", sep)
      local fd, err = io.open(path, mode)
      if fd then return fd, path end
      tried[#tried+1] = "can't open "..err
   end
   return nil, table.concat(tried, "\n")
end

-- returns the stack level (for the caller) + sourcefile from where
-- 'datafile' module was called or nil + error
function util.stacklevel()
   local level, info = 1, ""
   while info do
      info = debug.getinfo(level, "S")
      level = level + 1  -- inc before check because me need the match + 1
      if info and info.source:match("datafile.lua$") then
         info = debug.getinfo(level, "S")
         break
      end
   end
   if not info then
      return nil, "could not determine the code file on the callstack to look up"
   else
      return level - 1, info.source  -- use -1 to substract the call to this function
   end
end

return util
