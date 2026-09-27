GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

---@type string
local modid        = 'which_mod_are_you_from' -- 定义唯一modid

local display_mode = GetModConfigData(modid .. "_mode")
local show_guid    = GetModConfigData(modid .. "_guid")
local show_prefab  = GetModConfigData(modid .. "_prefab")
local show_sg      = GetModConfigData(modid .. "_sg")
local show_as      = GetModConfigData(modid .. "_as")

---Converts a table values into a string.
---Converts a table:
---   { "one", "two", "three" }
---To string:
---   one | two | three"
---@param t table
---@return string
local function TableSplit(t)
    if type(t) == "table" and #t > 0 then
        local value, value_clean

        value = ""
        for _, v in pairs(t) do
            value_clean = v

            -- and math.floor(value_clean) ~= value_clean
            if type(value_clean) == "number" then
                value_clean = string.format("%0.2f", v or 0)
            end

            value = value .. value_clean
            if next(t, _) ~= nil then
                value = value .. " | "
            end
        end

        return value
    end
end

---@param inst ent
---@return string
local function GetDevInfoText(inst)
    if not inst or not inst:IsValid() then return "" end
    local text = ""

    -- if inst.name then
    --     text = text .. inst.name .. "\n"
    -- end

    if show_guid == "hover" then
        text = text .. "\nGUID: " .. tostring(inst.GUID)
    end

    if show_prefab == "hover" then
        text = text .. "\nPrefab: " .. tostring(inst.prefab or inst.entity:GetPrefabName())
    end

    if show_sg == "hover" and inst.sg then
        local debug = tostring(inst.sg)
        local sg_name = string.match(debug, 'sg="(%S+)",')
        local sg_state = string.match(debug, 'state="(%S+)",')
        if sg_name and string.len(sg_name) > 0 then
            text = text
                .. "\nStateGraph: "
                .. TableSplit({ sg_name, sg_state })
        end
    end

    if show_as == "hover" and inst.AnimState then
        local debug = inst:GetDebugString()
        local as_bank = string.match(debug, "AnimState:.*bank:%s+(%S+)")
        local as_build = inst.AnimState:GetBuild()
        local as_anim = string.match(debug, "AnimState:.*anim:%s+(%S+)")
        if as_bank and string.len(as_bank) > 0 then
            text = text
                .. "\nAnimState: "
                .. TableSplit({ as_bank, as_build, as_anim })
        end
    end

    return text
end

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

local need_hover_hook = (display_mode == "hover") or (show_prefab == "hover") or (show_sg == "hover") or (show_as == "hover")

if need_hover_hook then
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

            if target then
                if display_mode == "hover" and target.prefab ~= nil then
                    local origin = prefab_to_modname[target.prefab]
                    if origin then
                        str = (str and str .. "\nMOD: " .. origin) or ("MOD: " .. origin)
                    end
                end

                local dev_info = GetDevInfoText(target)
                if dev_info ~= "" then
                    str = (str and str .. dev_info) or dev_info:sub(2)
                end
            end

            return old_SetString(text, str)
        end
    end)
end
