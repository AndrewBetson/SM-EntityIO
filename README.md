Allows server staff to execute entity inputs and outputs.

Console Commands
==================
This plugin exposes the following console commands:
| Name | Description | Notes |
|------|------|------|
| `sm_eio_input` | Execute an input on an entity by name, classname, or Hammer ID; optionally with an int/float/vector/color parameter. | Requires >= ADMFLAG_CONFIG command privilege. |
| `sm_eio_output` | Fire an output on an entity by name, classname, or Hammer ID; optionally with a delay and/or int/float/vector/color parameter. | Requires >= ADMFLAG_CONFIG command privilege. |

Examples
==================
## Tint a model-based entity yellow:
	sm_eio_input name some_prop_dynamic_probably Color 255 255 0 255
## Disable the round timer:
	sm_eio_input class team_round_timer first Disable
## Remove some unnamed entity:
	sm_eio_input hammerid 761999 Kill
## Make all players scream:
	sm_eio_input class player all SpeakResponseConcept HalloweenLongFall

Notes
==================
- Most logic entities are not supported due to limitations outside of my control.
- I would recommend issuing EIO commands from the console, as chat formatting/character limit can cause parsing issues.

Compatibility
==================
Should theoretically work with any game, but I've only tested it with TF2.

License
==================
This plugin is released under version 3 of the GNU Affero General Public License. For more info, see `LICENSE.md`.
