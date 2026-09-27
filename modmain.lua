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
            fancy_name = string.gsub(string.match(fancy_name, "^%s*(.-)%s*$"), "[\r\n]", "") or fancy_name

            for prefab_name, _ in pairs(mod.Prefabs) do
                -- 無論哪種模式，都將快取存起來，為了 force_show 做準備
                prefab_to_modname[prefab_name] = fancy_name

                if display_mode == "name" then
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

---@param self widget_hoverer
AddClassPostConstruct("widgets/hoverer", function(self)
    -- 攔截 SetString (回歸舊版的「最後關卡」做法)
    -- 負責把所有送到 UI 介面的文字串接上我們的資訊，完美相容 Show Me
    local old_SetString = self.text.SetString
    self.text.SetString = function(text, str)
        local target = TheInput:GetHUDEntityUnderMouse()
        if target ~= nil then
            target = target.widget ~= nil and target.widget.parent ~= nil and target.widget.parent.item
        else
            target = TheInput:GetWorldEntityUnderMouse()
        end

        if target then
            local show_custom_info = true
            if hotkey_setting == "KEY_ALT" then
                show_custom_info = TheInput:IsKeyDown(KEY_ALT)
            elseif hotkey_setting == "KEY_CTRL" then
                show_custom_info = TheInput:IsKeyDown(KEY_CTRL)
            elseif hotkey_setting == "KEY_SHIFT" then
                show_custom_info = TheInput:IsKeyDown(KEY_SHIFT)
            end

            if show_custom_info then
                local clean_str = str or ""

                if target.prefab ~= nil then
                    local origin = prefab_to_modname[target.prefab]
                    if origin then
                        if display_mode == "hover" then
                            clean_str = clean_str ~= "" and (clean_str .. "\nMOD: " .. origin) or ("MOD: " .. origin)
                        elseif display_mode == "name" then
                            -- 雙重保險：檢查是否已經透過 STRINGS.NAMES 加上了
                            -- 如果沒有（例如遇到調味料理等動態名稱），就在這裡動態補上
                            if not string.find(clean_str, origin, 1, true) then
                                clean_str = clean_str ~= "" and (clean_str .. "\nMOD: " .. origin) or ("MOD: " .. origin)
                            end
                        end
                    end
                end

                local dev_info = GetDevInfoText(target)
                if dev_info ~= "" then
                    clean_str = clean_str ~= "" and (clean_str .. dev_info) or dev_info:sub(2)
                end

                str = clean_str
            end
        end

        return old_SetString(text, str)
    end

    -- 攔截 OnUpdate (保留新版的強制顯示邏輯)
    -- 專門用來處理沒有互動選項、原本會被遊戲強制 Hide() 的實體
    local old_OnUpdate = self.OnUpdate
    self.OnUpdate = function(s)
        if old_OnUpdate then
            old_OnUpdate(s)
        end

        if force_show then
            local target = TheInput:GetHUDEntityUnderMouse()
            if target ~= nil then
                target = target.widget ~= nil and target.widget.parent ~= nil and target.widget.parent.item
            else
                target = TheInput:GetWorldEntityUnderMouse()
            end

            if target then
                -- 如果原生邏輯字串為空，且提示框處於隱藏狀態
                if (s.str == nil or s.str == "") and not s.text.shown then
                    -- 強制丟一個空字串給 SetString，這會觸發我們上面的攔截器
                    s.text:SetString("")

                    -- 強制顯示 UI 元件
                    s.text:Show()
                    if not s.shown and not s.forcehide then
                        s:Show()
                    end

                    -- 修正位置防止超出螢幕
                    local pos = TheInput:GetScreenPosition()
                    s:UpdatePosition(pos.x, pos.y)
                end
            end
        end
    end
end)
