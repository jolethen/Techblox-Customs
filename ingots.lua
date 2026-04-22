local S = minetest.get_translator(minetest.get_current_modname())

-- Hex color for Orange-Red: #ff4500
-- The escape sequence format is: \27(c#ff4500)Text\27(ce)
local orange_text = "\27(c#ff4500)Used to craft special Volcanic items and very useful as a fuel\27(ce)"

minetest.register_craftitem("techblox:magma_ingot", {
    description = S("Magma Ingot\n" .. orange_text),
    inventory_image = "techblox_magma_ingot.png",
    stack_max = 15,
    groups = {material = 1, fuel = 1},
})

-- Corrected fuel registration
minetest.register_craft({
    type = "fuel",
    recipe = "techblox:magma_ingot",
    burntime = 100,
})
