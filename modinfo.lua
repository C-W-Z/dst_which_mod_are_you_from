---@diagnostic disable: lowercase-global, undefined-global

local modid = 'which_mod_are_you_from'

local LANGS = {
    ['zh'] = {
        name = 'Which Mod Are You From?（模组来源检视器）',
        description = '模组来源检视器，显示游戏内物品/实体来自哪个模组',
        config = {
            { modid .. '_mode', '显示模式', '选择模组名称显示的位置', 'name', {
                { '浮动提示', 'hover', '与 Show Me 一样的显示方式，兼容 Show Me 類模組' },
                { '物品名称', 'name', '直接将模组名称加在物品名称的最后，理論上兼容所有模組' }
            } },
        }
    },
    ['en'] = {
        name = 'Which Mod Are You From? (Mod Source Viewer)',
        description = 'Mod Source Viewer. Displays which mod an in-game item/entity comes from.',
        config = {
            { modid .. '_mode', 'Display Mode', 'Choose where the mod name is displayed', 'name', {
                { 'Hover Tooltip', 'hover', 'Displays like "Show Me". Compatible with "Show Me" type mods.' },
                { 'Item Name',     'name',  'Appends mod name to item name. Compatible with all mods in theory.' }
            } },
        }
    },
}

-- 决定当前用的语言
local cur = (locale == 'zh' or locale == 'zhr' or locale == 'zht') and 'zh' or 'en'

-- mod相关信息
version = '1.0.0'
author = 'Icya'
forumthread = ''
api_version = 10
-- 晚點加載確保 hover 模式時 MOD 名稱顯示在物品名稱下第一行（雖然不明原理因為沒看其他 MOD 怎麼寫的）
priority = -100000                  -- 加载优先级，越低加载越晚，默认为0

dst_compatible = true              -- 联机版适配性
dont_starve_compatible = false     -- 单机版适配性
reign_of_giants_compatible = false -- 单机版：巨人国适配性
-- all_clients_require_mod = true  -- 服务端/所有端模组
-- server_only_mod = true          -- 仅服务端模组
client_only_mod = true             -- 仅客户端模组
server_filter_tags = { 'utility' } -- 创意工坊模组分类标签
icon_atlas = 'modicon.xml'         -- 图集
icon = 'modicon.tex'               -- 图标

-- 以下自动配置
name = LANGS[cur].name
description = version .. '\n' .. LANGS[cur].description

local config = LANGS[cur].config or {}
local _configuration_options = {}
for i = 1, #config do
    local options = {}
    if config[i][5] then
        for k = 1, #config[i][5] do
            options[k] = { description = config[i][5][k][1], data = config[i][5][k][2], hover = config[i][5][k][3] }
        end
    end
    _configuration_options[i] = {
        name = config[i][1],
        label = config[i][2],
        hover = config[i][3] or '',
        default = config[i][4] or false,
        options = #options > 0 and options or { { description = "", data = false } },
    }
    if config[i].slider_data then
        _configuration_options[i].slider_data = config[i].slider_data
    end
end

configuration_options = _configuration_options
