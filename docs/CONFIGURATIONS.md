# Configurating

## Console Commands

A player can configure this for themselves:

* `minigolf_show_hints` (client): Whether to show hints on screen in Minigolf
  * `0`: Don't show hints
  * `1`: Show hints

Admins can use these commands:

* `minigolf_time_limit_multiplier`: Set a time limit multiplier for yourself or another player.
  * `1` by default (no multiplier)
  * Example: `minigolf_time_limit_multiplier 1000` to give yourself a very long time limit
  * Example: `minigolf_time_limit_multiplier 0.5 JaneDoe` to make Jane Doe's time limit half as long

Server owners can set these:

* `minigolf_command_prefix`: The prefix for all minigolf commands.
  * `+` by default (`+enablehints`, `+enableautopower`)

* `minigolf_allow_change_power_mode`: Can a player change their own power mode?
  * `0`: Stop players from user `+enableautopower` and `+disableautopower`
  * `1`: Allow players to set auto power mode using commands

* `minigolf_auto_power_mode`: Should the powerbar bounce back and forth until the player releases a key?
  * `0`: Let the player set the power by using their scroll wheel or PAGE UP and PAGE DOWN
  * `1`: Let the powerbar bounce back and forth with a certain velocity

* `minigolf_auto_power_velocity`: How fast should the powerbar bounce back and forth? (lower number is slower)
  * `50` by default

* `minigolf_time_limit_multiplier_global`: Set a global time limit multiplier for all players.
  * `1` by default (no multiplier)
  * Example: `minigolf_time_limit_multiplier_global 2` to make everyone's time limit twice as long

## Integrations

### Reward points or money for certain scores

Copy the file at [`docs/examples/sv_rewards.lua`](https://github.com/luttje/gmod-minigolf/blob/main/docs/examples/sv_rewards.lua) to your custom addon _or_ to `garrysmod/lua/autorun/server`. Within it you can configure the reward for each type of scoring on a hole.

### Minigolf Items

There are 3 different item types by default:

* **Ball Area Effects:** A texture flat on the ground underneath the ball.
* **Ball Trails:** Trails, but not for a player but their Minigolf ball.
* **Balls:** A skin or completely different model for a players' ball.

None of these items affect the performance of a ball. So even though a model is not perfectly spherical, it'll still roll as if it is (which is good).

#### Equiping an item

The following snippet equips an item. Making it's effect visible for everyone.

```lua
-- ball_skull is the UniqueID of an item that changes a players' balls to a skull
local item = Minigolf.Items.Get("ball_skull")
local receiver = player.GetByID(1)

Minigolf.Items.Equip(item, receiver)
-- Minigolf.Items.Unequip works the exact same way, but does the opposite
```

With that you can integrate these default items in any gamemode or addon.

#### Custom items

You can also create your own variations of these items in your gamemode. You can find an example in the included `gm_minigolf` gamemode.

Be sure to:

1. Place items in a directory named `balls`, `ball_trails` or `ball_area_effects` (otherwise you'll have to make your own type)
2. Include the `items` directory in your gamemode like so:

```lua
Minigolf.Items.IncludeDirectory(Minigolf.PathCombine("gamemodes/<your gamemode folder>/gamemode", "items/"))
```

For an example, checkout: ([gamemodes/gm_minigolf/gamemode/items/ball_trails/lovely_ball.lua](https://github.com/luttje/gmod-minigolf/blob/main/gamemodes/gm_minigolf/gamemode/items/ball_trails/lovely_ball.lua)) and ([gamemodes/gm_minigolf/gamemode/sh_init.lua](https://github.com/luttje/gmod-minigolf/blob/main/gamemodes/gm_minigolf/gamemode/sh_init.lua)).

#### Examples

##### PointShop 1 Item (untested)

```lua
ITEM.Name = "Minigolf Skull Ball"
ITEM.Price = 50
ITEM.Model = "models/gibs/hgibs.mdl";
ITEM.NoPreview = true

function ITEM:OnEquip(player, modifications)
  local item = Minigolf.Items.Get("ball_skull")
  Minigolf.Items.Equip(item, player)
end

function ITEM:OnHolster(player)
  local item = Minigolf.Items.Get("ball_skull")
  Minigolf.Items.Unequip(item, player)
end
```

##### Clockwork Schema Item (untested)

```lua
local ITEM = Clockwork.item:New();

ITEM.name = "Minigolf Skull Ball";
ITEM.uniqueID = "minigolf_ball_skull";
ITEM.cost = 50;
ITEM.model = "models/gibs/hgibs.mdl";
ITEM.weight = 1;
ITEM.category = "Minigolf Accessories"
ITEM.business = true;
ITEM.description = "A skull-shaped ball for golfing";
ITEM.customFunctions = {"Equip", "Unequip"};

if (SERVER) then
  function ITEM:OnCustomFunction(player, name)
    local item = Minigolf.Items.Get("ball_skull");

    if (name == "Equip") then
      Minigolf.Items.Equip(item, player);
    elseif (name == "Equip") then
      Minigolf.Items.Unequip(item, player);
    end;
  end;
end;

ITEM:Register();
```
