-- Thin accessor over Save.data.settings so audio/UI code needn't know about the save file.
local Settings = {}

local function store()
  local ok, Save = pcall(require, "src.core.save")
  return ok and Save.data and Save.data.settings or {}
end

function Settings.get(key) return store()[key] end
function Settings.set(key, value) store()[key] = value end

return Settings
