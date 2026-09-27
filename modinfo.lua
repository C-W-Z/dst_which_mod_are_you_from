---@diagnostic disable: lowercase-global, undefined-global

local modid = 'which_mod_are_you_from'

local hover_or_disable_zh = {
    { '禁用', false },
    { '浮动提示', 'hover', '与 Show Me 一样的显示方式，兼容 Show Me 类模组' },
}

local hover_or_disable_en = {
    { 'Disabled',      false },
    { 'Hover Tooltip', 'hover', 'Displays like "Show Me". Compatible with "Show Me" type mods.' },
}

local LANGS = {
    ['zh'] = {
        name = '[Client] Which Mod Are You From?（模组来源检视器）',
        description = '模组来源检视器。显示游戏内物品/实体来自哪个模组。',
        config = {
            { modid .. '_mode', '显示模式', '选择模组名称显示的位置', 'name', {
                { '物品名称', 'name', '直接将模组名称加在物品名称的最后，可在T键页面显示' },
                { '浮动提示', 'hover', '与 Show Me 一样的显示方式，兼容 Show Me 类模组' },
            } },
            { modid .. '_hotkey', '按键显示', '只支援浮动提示模式。按住按键时才显示信息', false, {
                { '总是显示', false },
                { 'Alt', 'KEY_ALT', '按住 Alt 时显示' },
                { 'Ctrl', 'KEY_CTRL', '按住 Ctrl 时显示' },
                { 'Shift', 'KEY_SHIFT', '按住 Shift 时显示' },
            } },
            { 'Dev Tools' },
            { modid .. '_force_show', '强制显示资讯', '是否能在不可检视的实体（如玩家自己）上强制显示资讯', false, {
                { '禁用', false, '' },
                { '启用', true, '' },
            } },
            { modid .. '_guid', 'Show GUID', '是否显示 GUID', false, hover_or_disable_zh },
            { modid .. '_prefab', 'Show Prefab', '是否显示 Prefab 名称', false, hover_or_disable_zh },
            { modid .. '_as', 'Show AnimState', '是否显示 AnimState 信息', false, hover_or_disable_zh },
            { modid .. '_sg', 'Show StateGraph', '是否显示 StateGraph 信息', false, { { '不支援', false, '' }, } },
        }
    },
    ['en'] = {
        name = '[Client] Which Mod Are You From? (Mod Source Viewer)',
        description = 'Mod Source Viewer. Displays which mod an in-game item/entity comes from.',
        config = {
            { modid .. '_mode', 'Display Mode', 'Choose where the mod name is displayed', 'name', {
                { 'Item Name',     'name',  'Appends mod name to item name. Can show in T-key menu' },
                { 'Hover Tooltip', 'hover', 'Displays like "Show Me". Compatible with "Show Me" type mods.' },
            } },
            { modid .. '_hotkey', 'Hotkey to Show', 'Only support Hover mode. Hold a key to show info', false, {
                { 'Always Show', false, },
                { 'Alt',         'KEY_ALT',   'Hold Alt to show' },
                { 'Ctrl',        'KEY_CTRL',  'Hold Ctrl to show' },
                { 'Shift',       'KEY_SHIFT', 'Hold Shift to show' },
            } },
            { 'Dev Tools' },
            { modid .. '_force_show', 'Force Show Tooltip', 'Show info on uninspectable entities (like player yourself)', false, {
                { 'Disabled', false, '' },
                { 'Enabled',  true,  '' },
            } },
            { modid .. '_guid',   'Show GUID',       'Show GUID',            false, hover_or_disable_en },
            { modid .. '_prefab', 'Show Prefab',     'Show Prefab Name',     false, hover_or_disable_en },
            { modid .. '_as',     'Show AnimState',  'Show AnimState info',  false, hover_or_disable_en },
            { modid .. '_sg',     'Show StateGraph', 'Show StateGraph info', false, { { 'Unsupported', false, '' }, } },
        }
    },
}

-- 决定当前用的语言
local cur = (locale == 'zh' or locale == 'zhr' or locale == 'zht') and 'zh' or 'en'

-- mod相关信息
version = '1.4.0'
author = 'Icya'
forumthread = ''
api_version = 10
-- 晚點加載確保 hover 模式時 MOD 名稱顯示在物品名稱下第一行（雖然不明原理因為沒看其他 MOD 怎麼寫的）
-- 比 Server 版更晚一點，以偵測 Server 版是否開啟
priority = -100001                 -- 加载优先级，越低加载越晚，默认为0

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
