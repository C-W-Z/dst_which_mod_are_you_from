GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

---@type string
local modid = 'which_mod_are_you_from' -- 定义唯一modid

-- 建立一個快取表，將物品代碼對應到模組顯示名稱
local prefab_to_modname = {}

-- 確保在所有模組的 Prefab 註冊完畢後，再建立對應字典
AddSimPostInit(function()
    if ModManager then
        -- 遍歷所有已啟用的模組
        for _, modname in ipairs(ModManager:GetEnabledModNames()) do
            local mod = ModManager:GetMod(modname)

            -- 檢查該模組是否有註冊 Prefabs
            if mod and mod.Prefabs then
                -- 取得模組的格式化名稱
                local fancy_name = GetModFancyName(modname) or modname

                -- 將該模組下的所有物品代碼記錄到快取表中
                for prefab_name, _ in pairs(mod.Prefabs) do
                    prefab_to_modname[prefab_name] = fancy_name
                end
            end
        end
    end
end)

-- 攔截 hoverer 元件，附加模組來源資訊 (採用你的無衝突設計)
---@param self widget_hoverer
AddClassPostConstruct("widgets/hoverer", function(self)
    local old_SetString = self.text.SetString
    self.text.SetString = function(text, str)
        -- 獲取游標當下指著的實體 (UI 優先，其次為世界實體)
        local target = TheInput:GetHUDEntityUnderMouse()
        if target ~= nil then
            target = target.widget ~= nil and target.widget.parent ~= nil and target.widget.parent.item
        else
            target = TheInput:GetWorldEntityUnderMouse()
        end

        -- 若目標存在且具有預製物代碼
        if target and target.prefab ~= nil then
            -- 從快取表中查詢該物品是否屬於某個模組
            local origin = prefab_to_modname[target.prefab]
            if origin then
                -- 若來源不為空，則附加到提示字串後方
                if str then
                    str = str .. "\nMOD: "  .. origin
                else
                    str = "MOD: " .. origin
                end
            end
        end

        -- 呼叫原始的 SetString 確保與其他 UI 模組相容
        return old_SetString(text, str)
    end
end)

-- 鼠标显示物品代码
-- local function GetBuild(inst)
--     local strnn = ""
--     local str = inst.entity:GetDebugString()

--     if not str then
--         return nil
--     end

--     local bank, build = str:match("bank: (.+) build: (.+) anim: .+:(.+) Frame")

--     if bank ~= nil and build ~= nil then
--         strnn = strnn .. "动画: anim/" .. bank .. ".zip"
--         strnn = strnn .. "\n" .. "贴图: anim/" .. build .. ".zip"
--     end
--     return strnn
-- end

-- AddClassPostConstruct("widgets/hoverer", function(self)
--     local old_SetString = self.text.SetString
--     self.text.SetString = function(text, str)
--         local target = GLOBAL.TheInput:GetHUDEntityUnderMouse()
--         if target ~= nil then
--             target = target.widget ~= nil and target.widget.parent ~= nil and target.widget.parent.item
--         else
--             target = GLOBAL.TheInput:GetWorldEntityUnderMouse()
--         end
--         if target and target.entity ~= nil then
--             if target.prefab ~= nil then
--                 str = str .. "\n" .. "代码: " .. target.prefab
--             end
--             local build = GetBuild(target)
--             if build ~= nil then
--                 str = str .. "\n" .. build
--             end
--         end
--         return old_SetString(text, str)
--     end
-- end)
