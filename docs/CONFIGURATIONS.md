# Configurating

## Console Commands

A player can configure this for themselves:

* `minigolf_show_hints` (client): Whether to show hints on screen in Minigolf
  * `0`: Don't show hints
  * `1`: Show hints

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


## How do I reward PointShop points for scoring in a hole?

Copy the file at [`docs/examples/sv_pointshop_rewards.lua`](docs/examples/sv_pointshop_rewards.lua) to your custom addon _or_ to `garrysmod/lua/autorun/server`. Within it you can configure the reward for each type of scoring on a hole.

## Can I add PointShop items that change the ball skins or something?

Yes something: we've included examples in [`docs/examples/pointshop_items`](docs/examples/pointshop_items) where you can see how to have:
* **Ball Area Effects:** A texture flat on the ground underneath the ball.
* **Ball Trails:** Trails, but not for a player but their Minigolf ball.
* **Balls:** A skin or completely different model for a players' ball.

None of these items affect the performance of a ball. So even though a model is not perfectly spherical, it'll still roll as if it is (which is good).

