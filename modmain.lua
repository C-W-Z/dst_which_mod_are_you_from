---@diagnostic disable: undefined-global

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

---@type string
local modid          = 'server_mod_source_viewer' -- 定义唯一modid

local display_mode   = GetModConfigData(modid .. "_mode")
local hotkey_setting = GetModConfigData(modid .. "_hotkey")
local force_show     = GetModConfigData(modid .. "_force_show")
local show_guid      = GetModConfigData(modid .. "_guid")
local show_prefab    = GetModConfigData(modid .. "_prefab")
local show_sg        = GetModConfigData(modid .. "_sg")
local show_as        = GetModConfigData(modid .. "_as")

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

    -- SG 要從 Server 用網路變數向 Client 傳值，UI 才能知道，還會有效能問題，暫時不考慮做
    -- if show_sg == "hover" and inst.sg then
    --     local sg_name = inst.sg.sg and tostring(inst.sg.sg.name)
    --     local sg_state = inst.sg.currentstate and tostring(inst.sg.currentstate.name) or "<None>"
    --     if sg_name and string.len(sg_name) > 0 then
    --         text = text .. "\nStateGraph: " .. sg_name .. " | " .. sg_state
    --     end
    -- end

    if show_as == "hover" and inst.AnimState then
        local debug = inst:GetDebugString()
        local as_bank = string.match(debug, "AnimState:.*bank:%s+(%S+)")
        local as_build = inst.AnimState:GetBuild()
        local as_anim = string.match(debug, "AnimState:.*anim:%s+(%S+)")
        if as_bank and string.len(as_bank) > 0 then
            text = text .. "\nAnimState: " .. as_bank .. " | " .. as_build .. " | " .. as_anim
        end
    end

    return text
end

local prefab_to_modname = {}

AddSimPostInit(function()
    if not ModManager then return end

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
end)

local need_hover_hook = (display_mode == "hover") or (show_prefab == "hover") or (show_sg == "hover") or
    (show_as == "hover")

if need_hover_hook then
    ---@param self widget_hoverer
    AddClassPostConstruct("widgets/hoverer", function(self)
        local old_OnUpdate = self.OnUpdate
        self.OnUpdate = function(s)
            -- 執行原本的 OnUpdate，決定原始字串和顏色，並更新 self.str
            if old_OnUpdate then
                old_OnUpdate(s)
            end

            -- 獲取滑鼠下的目標實體
            local target = TheInput:GetHUDEntityUnderMouse()
            if target ~= nil then
                target = target.widget ~= nil and target.widget.parent ~= nil and target.widget.parent.item
            else
                target = TheInput:GetWorldEntityUnderMouse()
            end

            if target then
                local current_str = s.str or ""
                local original_str = current_str

                if original_str == "" and not force_show then
                    return
                end

                -- 檢查是否按下了指定按鍵
                local show_custom_info = true
                if hotkey_setting == "KEY_ALT" then
                    show_custom_info = TheInput:IsKeyDown(KEY_ALT)
                elseif hotkey_setting == "KEY_CTRL" then
                    show_custom_info = TheInput:IsKeyDown(KEY_CTRL)
                elseif hotkey_setting == "KEY_SHIFT" then
                    show_custom_info = TheInput:IsKeyDown(KEY_SHIFT)
                end

                if show_custom_info then
                    if display_mode == "hover" and target.prefab ~= nil then
                        local origin = prefab_to_modname[target.prefab]
                        if origin then
                            if current_str ~= "" then
                                current_str = current_str .. "\nMOD: " .. origin
                            else
                                current_str = "MOD: " .. origin
                            end
                        end
                    end

                    local dev_info = GetDevInfoText(target)
                    if dev_info ~= "" then
                        if current_str ~= "" then
                            current_str = current_str .. dev_info
                        else
                            current_str = dev_info:sub(2) -- 去掉第一個 \n
                        end
                    end
                end

                -- 如果字串被我們修改了，手動覆寫顯示
                if current_str ~= original_str then
                    s.str = current_str
                    s.text:SetString(current_str)

                    -- 因為原本 str == nil 時 s.text 會被隱藏，我們必須強制顯示它
                    s.text:Show()

                    -- 讓整個 Hoverer 也顯示出來 (防止因為其他原因被隱藏)
                    if not s.shown and not s.forcehide then
                        s:Show()
                    end

                    -- 強制更新一次位置，防止字串變長超出邊界
                    local pos = TheInput:GetScreenPosition()
                    s:UpdatePosition(pos.x, pos.y)
                end
            end
        end
    end)
end
