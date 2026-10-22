# MacroMate

A spellbook companion for **WoW Forever (Interface 16001)** that helps you:

- Create spell macros that always cast your highest learned rank.
- Spot lower-rank spells on your action bars.
- See mana, rage, and energy costs on action buttons.

## Quick start

1. Open your spellbook, or type `/mm` to toggle MacroMate independently.
2. Click **Create** beside a spell, or check the spells you want and click **Create included**.
3. Click or drag a ready spell icon, then place its macro on your action bar.

Macros are created only when you ask. MacroMate never automatically creates,
edits, or deletes them. Creation and dragging are unavailable in combat.
Rank-free macros already use your highest learned rank, so they do not need
replacing when you learn an upgrade. Keep separate macros for deliberate downranking.

## Controls

| Control | What it does |
| --- | --- |
| `/mm` or `/macromate` | Toggle the companion window. |
| `/mm create` | Create missing macros for included spells. |
| `/mm sync` | Alias for `/mm create`. |
| `/mm status` | Show spell counts and free macro slots. |
| **Always show lower ranks (text only)** | Keep lower-rank labels visible with the spellbook closed, without orange borders. Off by default. |
| **Mana**, **Rage**, **Energy** | Toggle action-button cost labels independently. All on by default. |
| **Use account slots when needed** | Allow new macros to use account slots when character slots are full. |

Preferences are saved per character. The companion normally opens and closes
with the spellbook; `/mm` also works as a standalone window.

## Action-bar labels

With the spellbook open, lower-rank spells get an orange border and a rank label
such as **R2**. Hover to compare that rank with your highest learned rank.
Enable the text-only option above to keep rank labels visible at all times.
Highest-rank spells remain unmarked; macro buttons are skipped for rank highlighting.

Resource costs appear at the bottom of spell buttons: **blue** for mana, **red**
for rage, and **yellow** for energy. Supported spell macros also show costs,
including the resolved spell for conditional macros. These are upfront costs
reported by the game, not total ongoing or channelled costs.

Both features support Blizzard action bars; third-party bars outside Blizzard's
button registry are not covered. Updates are event-driven, with no polling loop.

## Macro handling

- Learning a new ranked spell or rank shows a **Review / Later** reminder after
  combat. Logging in or reloading does not announce your existing spellbook.
- Existing simple rank-free spell macros are reused in either character or
  account slots without editing them. Conditional macros, downrank macros, and
  macros with extra commands are kept separate.
- Duplicate matches are reported, never deleted. Manage unwanted copies in
  `/macro`, keeping any copy used on an action bar.
- New macros use character slots first, a blank name, the spell's icon, and
  `#showtooltip Spell Name` / `/cast Spell Name` without a fixed rank.

Passive spells, pet abilities, professions, General-tab abilities, unlearned
spells, and inactive specializations are excluded from the companion's spell list.

## Installation

Place the `MacroMate` folder in your client's `Interface/AddOns` directory.
Restart the client if it is not listed in AddOns; use `/reload` after updates.
