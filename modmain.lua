GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

---@type string
local modid = 'which_mod_are_you_from' -- 定义唯一modid

---@type string
local display_mode = GetModConfigData(modid .. "_mode")

local prefab_to_modname = {}

AddSimPostInit(function()
    if ModManager then
        for _, modname in ipairs(ModManager:GetEnabledModNames()) do
            local mod = ModManager:GetMod(modname)

            if mod and mod.Prefabs then
                local fancy_name = GetModFancyName(modname) or modname

                -- 清除前後的空白與換行符號，以及中間的換行符號
                fancy_name = string.gsub(string.match(fancy_name, "^%s*(.-)%s*$"), "[\r\n]", "") or fancy_name

                for prefab_name, _ in pairs(mod.Prefabs) do
                    if display_mode == "hover" then
                        prefab_to_modname[prefab_name] = fancy_name
                    elseif display_mode == "name" then
                        local upper_name = string.upper(prefab_name)
                        local current_string = STRINGS.NAMES[upper_name]

                        if current_string then
                            local suffix = "\nMOD: " .. fancy_name
                            if not string.find(current_string, suffix, 1, true) then
                                STRINGS.NAMES[upper_name] = current_string .. suffix
                            end
                        end
                    end
                end
            end
        end
    end
end)

if display_mode == "hover" then
    ---@param self widget_hoverer
    AddClassPostConstruct("widgets/hoverer", function(self)
        local old_SetString = self.text.SetString
        self.text.SetString = function(text, str)
            -- 取得鼠標當下指著的實體 (UI 優先，然後才是世界實體)
            local target = TheInput:GetHUDEntityUnderMouse()
            if target ~= nil then
                target = target.widget ~= nil and target.widget.parent ~= nil and target.widget.parent.item
            else
                target = TheInput:GetWorldEntityUnderMouse()
            end

            if target and target.prefab ~= nil then
                local origin = prefab_to_modname[target.prefab]
                if origin then
                    if str then
                        str = str .. "\nMOD: " .. origin
                    else
                        str = "MOD: " .. origin
                    end
                end
            end

            return old_SetString(text, str)
        end
    end)
end
