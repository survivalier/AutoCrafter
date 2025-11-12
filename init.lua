-- AutoCrafter mod for Minetest
-- AutoCrafter toujours actif (pas de désactivation)
-- AutoCrafter: configure recette (3x3)
-- AutoCrafter Chest: fournit ingrédients (input) et reçoit résultats (output)
-- Licence: MIT

local S = minetest.get_translator("autocrafter")

-- ===============================
-- Données persistantes
-- ===============================
local storage_path = minetest.get_worldpath() .. "/autocrafter_data.json"
local autocrafter_registry = {}

local function save_autocrafter_data()
    local f = io.open(storage_path, "w")
    if f then
        f:write(minetest.write_json(autocrafter_registry))
        f:close()
    end
end

local function load_autocrafter_data()
    local f = io.open(storage_path, "r")
    if f then
        local data = f:read("*all")
        f:close()
        local decoded = minetest.parse_json(data)
        if type(decoded) == "table" then autocrafter_registry = decoded end
    end
end

load_autocrafter_data()
minetest.register_on_shutdown(save_autocrafter_data)

-- ===============================
-- Helpers
-- ===============================
local function pos_to_s(pos) return pos.x .. "," .. pos.y .. "," .. pos.z end
local function s_to_pos(s) return minetest.string_to_pos(s) end

-- ===============================
-- Formspecs
-- ===============================
local function get_autocrafter_formspec(pos)
    local spos = pos_to_s(pos)
    return "size[14,9]" ..
        "label[0,0;AutoCrafter - Template 3x3]" ..
        "list[nodemeta:" .. spos .. ";template;0,0.5;3,3;]" ..
        "label[4,0;État : Actif]" ..
        "label[11,0;Input chests nearby]" ..
        "list[current_player;main;0,5;14,4;]" ..
        "listring[nodemeta:" .. spos .. ";template]" ..
        "listring[current_player;main]"
end

local function get_chest_formspec(pos)
    local spos = pos_to_s(pos)
    return "size[14,9]" ..
        "label[0,0;AutoCrafter Chest - Input]" ..
        "list[nodemeta:" .. spos .. ";input;0,0.5;9,2;]" ..
        "label[0,3.2;Output]" ..
        "list[nodemeta:" .. spos .. ";output;0,3.7;9,2;]" ..
        "list[current_player;main;0,6.5;14,2;]" ..
        "listring[nodemeta:" .. spos .. ";input]" ..
        "listring[current_player;main]" ..
        "listring[nodemeta:" .. spos .. ";output]" ..
        "listring[current_player;main]"
end

-- ===============================
-- AutoCrafter Node
-- ===============================
minetest.register_node("autocrafter:autocrafter", {
    description = S("Auto Crafter"),
    tiles = {
        "autocrafter_top.png", "autocrafter_bottom.png",
        "autocrafter_side.png", "autocrafter_side.png",
        "autocrafter_side.png", "autocrafter_front.png"
    },
    groups = {cracky = 2, oddly_breakable_by_hand = 2},
    sounds = (default and default.node_sound_metal_defaults()) or nil,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("AutoCrafter (Actif)"))
        meta:set_string("formspec", get_autocrafter_formspec(pos))
        local inv = meta:get_inventory()
        inv:set_size("template", 9)
    end,

    after_place_node = function(pos, placer)
        autocrafter_registry[minetest.pos_to_string(pos)] = {
            pos = pos,
            owner = placer and placer:get_player_name() or "",
            state = "actif",
        }
        save_autocrafter_data()
    end,

    on_destruct = function(pos)
        autocrafter_registry[minetest.pos_to_string(pos)] = nil
        save_autocrafter_data()
    end,

    on_rightclick = function(pos, node, player, _, _)
        local meta = minetest.get_meta(pos)
        minetest.show_formspec(player:get_player_name(),
            "autocrafter:autocrafter:" .. pos_to_s(pos),
            meta:get_string("formspec"))
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "template" then return stack:get_count() end
        return 0
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        if listname == "template" then return stack:get_count() end
        return 0
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if from_list == "template" or to_list == "template" then return count end
        return 0
    end,
})

-- ===============================
-- AutoCrafter Chest Node
-- ===============================
minetest.register_node("autocrafter:chest", {
    description = "AutoCrafter Chest",
    tiles = {
        "autocrafter_chest_top.png", "autocrafter_chest_bottom.png",
        "autocrafter_chest_side.png", "autocrafter_chest_side.png",
        "autocrafter_chest_side.png", "autocrafter_chest_front.png"
    },
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    sounds = (default and default.node_sound_wood_defaults()) or nil,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "AutoCrafter Chest")
        meta:set_string("formspec", get_chest_formspec(pos))
        local inv = meta:get_inventory()
        inv:set_size("input", 18)
        inv:set_size("output", 18)
    end,

    on_rightclick = function(pos, node, player, _, _)
        local meta = minetest.get_meta(pos)
        minetest.show_formspec(player:get_player_name(),
            "autocrafter:chest:" .. pos_to_s(pos),
            meta:get_string("formspec"))
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "input" then return stack:get_count() end
        if listname == "output" then return 0 end
        return 0
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        return stack:get_count()
    end,
})

-- ===============================
-- Crafts
-- ===============================
minetest.register_craft({
    output = "autocrafter:autocrafter",
    recipe = {
        {"", "default:steel_ingot", ""},
        {"default:steel_ingot", "default:chest", "default:steel_ingot"},
        {"default:wood", "default:steel_ingot", "default:wood"},
    },
})

minetest.register_craft({
    output = "autocrafter:chest",
    recipe = {
        {"default:wood", "default:wood", "default:wood"},
        {"default:wood", "default:chest", "default:wood"},
        {"default:wood", "default:wood", "default:wood"},
    },
})

-- ===============================
-- Vérification et retrait d'ingrédients
-- ===============================
local function chest_has_and_take_required(chest_inv, required_list)
    for i = 1, 9 do
        local req = required_list[i]
        if req and not req:is_empty() then
            local need = req:get_count()
            local name = req:get_name()
            local total_found = 0
            for j = 1, chest_inv:get_size("input") do
                local s = chest_inv:get_stack("input", j)
                if s:get_name() == name then total_found = total_found + s:get_count() end
                if total_found >= need then break end
            end
            if total_found < need then return false end
        end
    end
    for i = 1, 9 do
        local req = required_list[i]
        if req and not req:is_empty() then
            local remaining = req:get_count()
            local name = req:get_name()
            for j = 1, chest_inv:get_size("input") do
                local s = chest_inv:get_stack("input", j)
                if s:get_name() == name then
                    local take = math.min(s:get_count(), remaining)
                    s:set_count(s:get_count() - take)
                    chest_inv:set_stack("input", j, s)
                    remaining = remaining - take
                    if remaining <= 0 then break end
                end
            end
        end
    end
    return true
end

-- ===============================
-- Fonction principale
-- ===============================
local function auto_craft()
    for id, data in pairs(autocrafter_registry) do
        local ac_pos = data.pos
        local ac_meta = minetest.get_meta(ac_pos)
        if not ac_meta then goto continue end

        local ac_inv = ac_meta:get_inventory()
        local template_items = {}
        local empty = true
        for i = 1, 9 do
            local stack = ac_inv:get_stack("template", i)
            template_items[i] = stack
            if not stack:is_empty() then empty = false end
        end
        if empty then goto continue end

        local result = minetest.get_craft_result({method="normal", width=3, items=template_items})
        if not result or result.item:is_empty() then goto continue end

        local neighbors = {
            {x=ac_pos.x+1, y=ac_pos.y, z=ac_pos.z},
            {x=ac_pos.x-1, y=ac_pos.y, z=ac_pos.z},
            {x=ac_pos.x, y=ac_pos.y, z=ac_pos.z+1},
            {x=ac_pos.x, y=ac_pos.y, z=ac_pos.z-1},
            {x=ac_pos.x, y=ac_pos.y+1, z=ac_pos.z},
            {x=ac_pos.x, y=ac_pos.y-1, z=ac_pos.z},
        }

        for _, chest_pos in ipairs(neighbors) do
            local node = minetest.get_node_or_nil(chest_pos)
            if node and node.name == "autocrafter:chest" then
                local chest_meta = minetest.get_meta(chest_pos)
                local chest_inv = chest_meta:get_inventory()
                if chest_has_and_take_required(chest_inv, template_items) then
                    local leftover = chest_inv:add_item("output", result.item)
                    if leftover and not leftover:is_empty() then
                        local spawn_pos = vector.add(chest_pos, {x=0.5, y=1, z=0.5})
                        minetest.add_item(spawn_pos, leftover)
                    end
                    break
                end
            end
        end

        ::continue::
    end
end

-- ===============================
-- Timer global (1s)
-- ===============================
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < 1 then return end
    auto_craft()
    save_autocrafter_data()
    timer = 0
end)