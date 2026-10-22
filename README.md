# RankReady

A spellbook companion for **WoW Forever (Interface 16001)** that helps you:

- Create spell macros that always cast your highest learned rank.
- See mana, rage, and energy costs on action buttons.
- Spot lower-rank spells on your action bars.

## Spellbook companion

1. Open your spellbook, or type `/rr` to toggle RankReady independently.
2. Click **Create** beside a spell, or check the spells you want and click **Create included**.
3. Click or drag a ready spell icon, then place its macro on your action bar.

Macros are created only when you ask. RankReady never automatically creates,
edits, or deletes them. Creation and dragging are unavailable in combat.
Rank-free macros already use your highest learned rank, so they do not need
replacing when you learn an upgrade. Keep separate macros for deliberate downranking.

### Companion window

![Spellbook with RankReady docked on the right, showing spell checkboxes, Create and Ready buttons, free macro slots, and display settings](docs/screenshots/RankReady%20companion.png)

*Choose spells, create missing macros, and adjust action-bar labels from the companion window.*

## Controls

| Control | What it does |
| --- | --- |
| `/rr` or `/rankready` | Toggle the companion window. |
| `/rr create` | Create missing macros for included spells. |
| `/rr sync` | Alias for `/rr create`. |
| `/rr status` | Show spell counts and free macro slots. |
| **Always show lower ranks (text only)** | Keep lower-rank labels visible with the spellbook closed, without orange borders. Off by default. |
| **Mana**, **Rage**, **Energy** | Toggle action-button cost labels independently. All on by default. |
| **Use account slots when needed** | Allow new macros to use account slots when character slots are full. |

Preferences are saved per character. The companion normally opens and closes
with the spellbook; `/rr` also works as a standalone window.

## Mana, rage, and energy costs

Resource costs appear at the bottom of spell buttons: **blue** for mana, **red**
for rage, and **yellow** for energy. Toggle each resource with the **Mana**,
**Rage**, and **Energy** checkboxes at the bottom of `/rr`.

Supported spell macros also show costs, including the resolved spell for
conditional macros. These are upfront costs reported by the game, not total
ongoing or channelled costs.

### Action-bar costs and ranks

![Action buttons with blue mana, red rage, and yellow energy costs at the bottom, plus R1 and R2 labels on lower-rank spells](docs/screenshots/Spell%20cost%20and%20downranks.png)

*Resource costs sit below spell icons; lower-rank labels appear at the top-left so both remain readable.*

## Lower-rank spell highlights

With the spellbook open, spells below your highest learned rank get an orange
border and a rank label such as **R2**. Hover to compare the ranks.

Enable **Always show lower ranks (text only)** in `/rr` to keep labels visible
with the spellbook closed, without orange borders. Highest-rank spells remain
unmarked; macro buttons are skipped for rank highlighting. Deliberately
downranked spells are highlighted too; replacing them is your choice.

The [action-bar screenshot above](docs/screenshots/Spell%20cost%20and%20downranks.png)
shows cost labels alongside lower-rank spell highlights.

Cost labels and rank highlights support Blizzard action bars; third-party bars
outside Blizzard's button registry are not covered. Updates are event-driven,
with no polling loop.

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

### A created macro

![Character macro window with a Thorns macro selected, showing #showtooltip Thorns and /cast Thorns without a fixed rank](docs/screenshots/Created%20macros.png)

*Created macros use the spell's icon and omit a fixed rank, so they continue to cast your highest learned rank.*

## Installation

Place the `RankReady` folder in your client's `Interface/AddOns` directory.
Restart the client if it is not listed in AddOns; use `/reload` after updates.

### Upgrading from MacroMate

Close WoW and replace the old `MacroMate` folder with `RankReady`. Use `/rr`
or `/rankready` instead of the old commands. Existing spell macros are reused
without changes. Do not keep separate copies in both folders.

To carry over character preferences, copy each character's
`SavedVariables/MacroMate.lua` to `SavedVariables/RankReady.lua` under your
client's `WTF/Account` directory while WoW is closed. RankReady imports the old
settings automatically when that file is loaded. Otherwise, preferences start
with their defaults.

The screenshots were taken before the rename and still show the old window title.
