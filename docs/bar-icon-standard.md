# Omarchy bar icon standard

How bar icons are sized so a row of widgets looks like one designed set.

Omarchy does not publish a written icon specification. This document records
the standard that the bar's own first-party widgets already follow, derived
from their source and measured against the shipping font, so third-party
plugins can match them instead of guessing.

## The problem

Every bar widget draws its own icon, and nothing says how big it should be.
Three implementations are in use today:

| Approach | Used by | How the size is chosen |
|---|---|---|
| Nerd Font glyph in `text` | `omarchy.audio`, `omarchy.network`, `omarchy.bluetooth`, `omarchy.microphone`, `omarchy.power`, `omarchy.weather`, `omarchy.keyboard-layout`, `omarchy.agents`, `omarchy.menu` | Implicit: the font size `Style.bar.iconFont` |
| `iconComponent` with a drawn shape | `omarchy.dropbox`, `omarchy.tailscale`, Omapop | The author picks a number |
| `iconComponent` with an `Image` | a few third-party plugins | The author picks a number |

Because the drawn approaches pick their own number, a mark routinely ends up
two or three times the visual weight of the glyphs beside it. Omapop's mark,
for example, painted 16.7px of a 19px canvas while every neighbouring glyph
painted 7.5px. Nothing was broken; it simply overfilled its box.

## The standard

> **A bar icon paints its ink at half the icon font size.**
>
> `inkWidth = Style.bar.iconFont / 2`

At the default font size (`fontBaseSize = 12`) this is 6.5px; at the
`fontBaseSize = 14` many people set in `~/.config/omarchy/shell.toml` it is
7.5px. The mark scales with the font, exactly as the glyphs do.

### Why half the font size

It is a property of the font, not a layout convention. The icons come from
Material Design Icons (the `󰂯`/`󰍬`/`󰖩` ranges in the Nerd Font patch), whose
glyphs are drawn on a 24×24 grid with an **advance of 0.5em**. So the painted
ink width is `0.5 × font-size` at every size, verified against the font's
outline:

| `Style.bar.iconFont` | glyph ink width | `iconFont / 2` |
|---|---|---|
| 13px | 6.5px | 6.5px |
| 15px | 7.5px | 7.5px |
| 17px | 8.5px | 8.5px |
| 18px | 9.0px | 9.0px |

### Height varies; width does not

Icon glyphs are not square. Their *width* is a constant 0.5em, but their
*height* depends on the picture: audio 7.3px, wifi 6.3px, power 8.0px,
microphone 10.2px, bluetooth 11.8px, battery 12.5px at a 15px font. Do not
force a fixed height. Match the **ink width** and let the shape be as tall as
the drawing needs; that is what makes the row read as a set.

### "The icons look different sizes"

They are, and that is the intended result. This is the first question most
people ask, because bluetooth visibly outweighs wifi:

| glyph | ink width | ink height |
|---|---|---|
| battery | 7.50px | 12.48px |
| bluetooth | 7.50px | 11.79px |
| microphone | 7.50px | 10.20px |
| power | 7.50px | 7.95px |
| audio | 7.50px | 7.29px |
| wifi | 7.50px | 6.27px |
| keyboard / weather | 7.50px | 4.74px |

Every one of those *widths* is identical; only the heights differ, by a factor
of 2.6. The row still reads as a set because it follows the rules of type:

- **One advance width.** Horizontal spacing is even, so the row has rhythm.
- **One shared baseline.** Vertical alignment comes from sitting on the same
  line, the way `l`, `o` and `b` do in a word.
- **Similar ink density.** The glyphs carry comparable visual weight even when
  their bounding boxes differ.

`OpticalGlyph` shows the intent. Its own comment says it best: "Keep the
shared line box and baseline intact. Correcting only the horizontal painted
bounds avoids per-glyph vertical drift."

A tall thin glyph (bluetooth, battery, wifi) and a short wide one (keyboard,
weather) are both correct. Forcing every icon to one bounding box would break
the baseline and rhythm and look worse. Match the width; let the height be
whatever the picture needs.

A shape with little ink - a solid speaker, for example - can also read as
"small" even at the right width, because its mass is concentrated. That is a
property of the drawing, not a sizing error.

### Do not size from the optical canvas

`BarIconButton` also exposes `Style.bar.iconCanvas`, the rounded box it hands
an `iconComponent`. It is **not** the size reference. `iconCanvas` and
`iconFont` are rounded independently:

```
iconCanvas = round(16 * fontScale)   // 19 at fontScale 1.1667
iconFont   = round(13 * fontScale)   // 15 at fontScale 1.1667
```

Deriving the mark from the canvas (`canvas * 0.42`) lands about half a pixel
off and stops tracking the font correctly. Derive it from `iconFont`.

## How to apply it

### If your icon is a Nerd Font glyph

Do nothing. `BarIconButton` already draws `text` at `Style.bar.iconFont`; the
standard is what you get for free. This is the preferred way to add an icon.

```qml
BarIconButton {
  id: button
  anchors.fill: parent
  bar: root.bar
  text: "\u{F05E7}"   // md-cursor-text; ink is 0.5 * iconFont
  onPressed: function(b) { /* ... */ }
}
```

### If your icon is a drawn shape or an image

Match `inkWidth` to the glyphs. Wrap the drawing in an `Item` sized by
`inkWidth`, not by the optical canvas:

```qml
BarIconButton {
  id: button
  anchors.fill: parent
  bar: root.bar
  iconComponent: Component {
    Item {
      // The drawing knows its own natural size; scale it so its painted ink
      // is exactly this wide.
      property real inkWidth: Style.bar.iconFont / 2
      anchors.fill: parent
      MyMark {
        anchors.centerIn: parent
        width: button.inkWidth
        height: button.inkWidth
        color: button.foreground
      }
    }
  }
}
```

Omapop's `BarIcon.qml` is a worked example: it takes an `inkWidth` property,
authored its art on a fixed grid, and scales once to that width.

### Accessible variants: keep them the same optical size

If the mark changes shape by state (active/paused/alarm), keep every state at
the same ink width. A state that grows or shrinks is the most common way a set
stops looking uniform.

### Brand marks are the documented exception

A few first-party icons are deliberately larger because they are logos, not
icons: `omarchy.menu` paints 12px and `omarchy.agents` 14px where the icons
paint 8px. If your widget is genuinely a brand mark, a modest enlargement is
acceptable; if it is an icon, follow the standard.

## Reference numbers

At `fontBaseSize = 14` (`fontScale = 1.1667`, the common Omarchy default):

| Token | Value | Meaning |
|---|---|---|
| `Style.bar.iconFont` | 15px | Glyph font size |
| **standard ink width** | **7.5px** | `iconFont / 2` |
| `Style.bar.iconCanvas` | 19px | Optical box (`BarIconButton`) — not the size |
| `Style.bar.iconSlot` | 32px | Reserved cell width |
| brand marks | 12–14px | `omarchy.menu`, `omarchy.agents` |

## Verifying your icon

1. Render a reference glyph and your mark in the same row and compare painted
   ink width. `Style.bar.iconCanvas` and `Style.bar.iconSlot` are visible on
   screen with `OMARCHY_DEBUG_BAR_ICONS=1`.
2. Match the `Style.bar.iconFont / 2` number from the table above, or reuse
   the assertions in `tests/tst_bariconstandard.qml`.

## Changing the standard in Omarchy

The standard is a measurement of the shipping bar, not an upstream API.
If a future Omarchy release changes the bar tokens or ships a different icon
font, re-derive it: read the glyph outline's advance (it should be 0.5em) and
confirm the built-in glyphs still share one ink width.
