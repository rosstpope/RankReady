# MacroMate

A small WoW Forever spellbook companion (Interface 16001). Open your spellbook
and MacroMate appears beside it; it hides when the book closes or switches away
from the spellbook tab. `/mm` also toggles the companion independently. It uses a
330 x 506 panel with six reusable rows, paged controls, and no polling loop.

## Manual creation

MacroMate never creates, edits, or deletes macros automatically. Learning a new
rank or ranked spell shows a **Review / Later** reminder, without creating anything.
Reminders wait until combat ends and are baselined at login/reload to avoid
announcing your entire spellbook. Existing rank-free macros already cast the
highest learned rank, so learning another rank does not require a new macro.

Click **Create** beside a spell or **Create included** for all checked spells.
Drag or click a ready spell icon to pick up its macro, then place it on your bar.
Creation and dragging are blocked in combat; no creation is queued for later.
Checking a spell, logging in, reopening the window, or deleting a macro never
creates a replacement. Exclusions and account-slot preferences are per-character.
The old automatic-creation setting is retired, including on existing installs.

## Older ranks on action bars

While the spellbook is open, visible Blizzard action-bar spell buttons using a
lower rank than you know get an orange border and their actual rank (for example,
**R2**) in the top-left corner. Hover one to see its rank and the highest learned
rank. This also identifies deliberately downranked spells without suggesting
they must be replaced.

Enable **Always show lower ranks (text only)** at the bottom of `/mm` to keep
rank labels visible with the spellbook closed. Only spells below the highest
learned rank get labels; max-rank spells stay unmarked. This option removes the
border even while the spellbook is open and is saved per character. It starts off
so existing spellbook-only highlighting is preserved until you enable it.

Highlights refresh on spell/action changes and paging. Without the persistent
option, they clear when the book closes or switches away from the spellbook.
They do not alter actions or create
macros. Macro buttons, items, pet abilities, and spells without readable rank data
are skipped; rank-free macros already handle upgrades. Third-party bar frames
outside Blizzard's button registry are not included. Overlays are reused, with no
polling or animation loops. Rank checking runs while the book is open or persistent
rank labels are enabled.

## Resource costs on action buttons

**Mana**, **Rage**, and **Energy** have separate checkboxes at the bottom of `/mm`.
All start enabled; an existing mana preference is preserved. Costs use blue for
mana, red for rage, and yellow for energy. A small number shows the cost at the
bottom of visible Blizzard spell buttons, even with the spellbook closed. Rank
labels stay at the top-left, away from the cost and existing keybind text.

Direct spells and Forever's resolved spell macros use the spell ID provided by
the action bar, including the current highest rank for MacroMate macros. On clients
that return a macro index instead, simple rank-free macros use
the highest learned rank; other spell macros use the spell resolved by the game.
Conditional macro costs follow the resolved spell when modifiers or targets change.
Items, spells using unchecked resources, and unavailable/restricted costs have no label. A reported
zero cost shows `0`. The number is the upfront cost returned by the game,
not an estimate of total ongoing/channelled mana consumption.

Costs refresh on aura, spell, equipment, form, action-bar, and macro changes.
Rage/energy changes also refresh variable costs, such as abilities using extra rage.
Labels are reused and repeated events are batched; there is no polling loop or
saved cost cache. Turning all three resources off hides the labels and unregisters
cost event listeners. Third-party bars outside Blizzard's button registry are not covered.

Generated macros have a single blank space as their name, a matching spell icon,
and `#showtooltip Spell Name` / `/cast Spell Name` without a fixed rank. Keep
separate downranking macros if you need those.

## Existing macros and slots

Before creation, MacroMate recognises simple rank-free spell macros in either
character or account slots, even if their labels, whitespace, tooltip lines, or
MacroMate comments differ. It reuses them without editing their contents or labels.
Conditional macros, downrank macros, and macros with extra commands are treated
as separate intentional behaviours. Multiple matching copies are reported in the
spell list; they are never deleted or recreated. Manage unwanted copies in
`/macro`, keeping any copy currently used on an action bar.

Character slots are used first. **Use account slots when needed** allows creation
in free account slots when character slots are full. Existing account macros are
still recognised when that option is off. Both scopes show free slot counts.

## Commands

- `/mm` or `/macromate`: toggle the companion.
- `/mm create`: explicitly create missing included macros.
- `/mm sync`: alias for `/mm create`.
- `/mm status`: report counts and free slots, without changing macros.

Restart the client if MacroMate is not yet listed in AddOns. After updates, use
`/reload`. Detection uses numeric rank subtext (including Rank 1) or multiple
learned spell IDs with the same name. It excludes passives, pet abilities,
professions, General-tab abilities, unlearned spells, and inactive specializations.

The companion docks to the right of the spellbook, or the left if that side has
more room. With a maximized book and no free side, it clamps to the screen. Close
or minimize the book as needed; `/mm` can be used as a standalone window.

API references: [Forever spellbook definitions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua),
[Forever player spells frame](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.lua),
and [Forever macro UI](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroUI.lua).
