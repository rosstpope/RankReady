# RankReady

**Highest-rank spell macros, action-bar resource costs, and lower-rank spell highlights for WoW Forever.**

RankReady is a spellbook and action-bar companion that helps you keep up with spell upgrades. Create macros that always cast your highest learned rank, see mana/rage/energy costs on your buttons, and spot older spell ranks still on your bars.

Open your spellbook or type `/rr` to get started.

## Highest-rank spell macros

Stop replacing spells on your bars every time you learn a new rank. RankReady creates rank-free spell macros that continue to cast your highest learned rank as you learn upgrades.

1. Open the spellbook or type `/rr`.
2. Click **Create** beside a spell, or select spells and click **Create included**.
3. Click or drag a ready spell icon, then place its macro on your action bar.

**You choose when to create macros.** RankReady never automatically creates, edits, or deletes them. Creation and dragging are unavailable in combat. Keep separate macros for deliberate downranking.

### Spellbook companion

![Spellbook with the companion docked on the right, showing spell checkboxes, Create and Ready buttons, free macro slots, and display settings](https://raw.githubusercontent.com/rosstpope/RankReady/main/docs/screenshots/RankReady%20companion.png)

*Select spells, create missing macros, and adjust action-bar labels from the companion window.*

### Created spell macros

![Character macro window with a Thorns macro selected, showing #showtooltip Thorns and /cast Thorns without a fixed rank](https://raw.githubusercontent.com/rosstpope/RankReady/main/docs/screenshots/Created%20macros.png)

*Macros use the spell's icon and omit a fixed rank, so they keep casting your highest learned rank.*

## Mana, rage, and energy costs

See resource costs at the bottom of your action buttons: **blue** for mana, **red** for rage, and **yellow** for energy. Each resource has its own checkbox in `/rr`, and all three start enabled.

Supported spell macros also show costs, including the resolved spell for conditional macros. Labels show the upfront cost reported by the game, rather than total ongoing or channelled costs.

### Action-bar costs and spell ranks

![Action buttons with blue mana, red rage, and yellow energy costs at the bottom, plus R1 and R2 labels on lower-rank spells](https://raw.githubusercontent.com/rosstpope/RankReady/main/docs/screenshots/Spell%20cost%20and%20downranks.png)

*Resource costs appear below spell icons; lower-rank labels sit at the top-left so both remain readable.*

## Lower-rank spell highlights

Spot older spell ranks on your action bars. While the spellbook is open, spells below your highest learned rank receive an orange border and a label such as **R2**. Hover to compare the rank on your bar with your highest learned rank.

Enable **Always show lower ranks (text only)** in `/rr` to keep labels visible with the spellbook closed, without orange borders. This option starts off.

Highest-rank spells remain unmarked. Deliberately downranked spells are highlighted too; replacing them is your choice. Macro buttons are skipped for rank highlighting.

## Commands and settings

- `/rr` or `/rankready`: toggle the companion window.
- `/rr create`: create missing macros for included spells.
- `/rr sync`: alias for `/rr create`.
- `/rr status`: show spell counts and free macro slots.

The window normally opens and closes with the spellbook; `/rr` also works independently. Preferences are saved per character.

**Use account slots when needed** allows new macros to use account slots when character slots are full. Existing account macros are recognised even with this option off.

## Existing macros and new ranks

- Simple rank-free spell macros are reused without editing their contents or names. Conditional macros, downrank macros, and macros with extra commands are kept separate.
- Duplicate matches are reported, never deleted. Manage unwanted copies in `/macro`.
- Learning a new ranked spell or rank shows a **Review / Later** reminder after combat. Login and reload do not announce your existing spellbook.

## Compatibility and installation

Built for **WoW Forever (Interface 16001)**. Cost labels and rank highlights support Blizzard action bars; third-party bars outside Blizzard's button registry are not covered. Updates are event-driven, with no polling loop.

The companion's spell list excludes passives, pet abilities, professions, General-tab abilities, unlearned spells, and inactive specializations.

For manual installation, place the `RankReady` folder in your client's `Interface/AddOns` directory. Restart the client if the addon is not listed; use `/reload` after updates.

*Screenshots were taken before the rename and still show the old MacroMate title.*

### Upgrading from MacroMate

Close WoW and replace the old `MacroMate` folder with `RankReady`. Use `/rr` or `/rankready` instead of the old commands. Existing spell macros are reused without changes. Do not keep separate copies in both folders.

To carry over character preferences, copy each character's `SavedVariables/MacroMate.lua` to `SavedVariables/RankReady.lua` under your client's `WTF/Account` directory while WoW is closed. RankReady imports the old settings when that file is loaded. Otherwise, preferences start with their defaults.
