
--- @module datafile.openers.luarocks
-- datafile module for modules installed with LuaRocks
local luarocks = {}

local ok, path = pcall(require, "luarocks.path")
if not ok then
   -- LuaRocks not found, bail out!
   return {}
end
local manif_core = require("luarocks.manif_core")
local util = require("datafile.util")

function luarocks.opener(file, mode, context)
   local level, source = util.stacklevel()
   if not level then return nil, source end
   source = source:gsub("\\", "/")
   if source:match("^@") then
      local prefix, luaver, modpath = source:match("@(.*)/share/lua/([^/]*)/(.*)")
      if prefix and luaver and modpath then
         local modname = path.path_to_module(modpath):gsub("\\","."):gsub("/",".")
         local rocks_dir = prefix.."/lib/luarocks/rocks-"..luaver
         local manifest, err = manif_core.load_local_manifest(rocks_dir)
         if not manifest then -- look for generic rocks_dir
            rocks_dir = prefix.."/lib/luarocks/rocks"
            manifest, err = manif_core.load_local_manifest(rocks_dir)
         end
         if not manifest then
            return nil, "could not open LuaRocks manifest for "..prefix
         end
         local providers = manifest.modules[modname]
   
         -- try versioned module names
         while not providers do
            local strip = modname:match("(.*)_[^_]+")
            if not strip then break end
            providers = manifest.modules[strip]
         end
         local dirs = {
            prefix .. "/share/lua/" .. luaver,
            prefix .. "/lib/lua/" .. luaver,
         }
         
         if providers then
            for _, provider in ipairs(providers) do
               table.insert(dirs, prefix .. "/lib/luarocks/rocks/" .. provider)
               table.insert(dirs, prefix .. "/lib/luarocks/rocks-"..luaver.."/" .. provider)
            end
         end
         return util.try_dirs(dirs, file, mode)
      end
   end
   return nil, "could not recognize "..source.." as a LuaRocks module"
end

return luarocks

