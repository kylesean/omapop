import QtQuick
import QtTest
import ".." as Plugin

// Encodes the bar's de-facto icon standard so a drawn mark cannot drift away
// from the Nerd Font glyphs around it.
//
// There is no written Omarchy spec. The bar's own widgets are the reference:
// BarIconButton draws a Nerd Font glyph at Style.bar.iconFont, and every Nerd
// Font icon glyph paints its ink at exactly half the font size. That is a
// property of the font, not a layout coincidence: the Material Design Icons
// advance is 0.5em, so the ink width is 0.5 * font-size (verified against the
// font outline at 13/15/17/18px, and via the engine's own text metrics).
//
// The original Omapop mark painted ~16.7px in the same 19px canvas - about
// twice the weight of every neighbour - which is what made it look out of
// place. The fix is not "about 8px": the mark takes the same ink width the
// glyphs derive from the font size, so it tracks the bar when the font scales.
TestCase {
    id: test
    name: "BarIconStandard"
    when: windowShown

    // Mirror Style at this machine's font base size (14 scales the 12px default).
    readonly property real fontScale: 14 / 12
    readonly property int iconFont: Math.round(13 * fontScale)   // 15
    readonly property int iconCanvas: Math.round(16 * fontScale) // 19

    // Representative built-in icon glyphs. (Brand marks like omarchy.menu and
    // the agents logo are deliberately larger, so they are not references.)
    readonly property var referenceGlyphs: [
        "\u{F057E}", // audio / volume
        "\u{F036C}", // microphone
        "\u{F00AF}", // bluetooth
        "\u{F05A9}", // wifi
        "\u{F0079}", // battery
        "\u{F0590}", // weather
        "\u{F0425}", // power
        "\u{F0311}"  // keyboard layout
    ]

    TextMetrics {
        id: metrics
        font.family: "monospace"
        font.pixelSize: test.iconFont
    }

    function referenceInkWidth() {
        var max = 0
        for (var i = 0; i < referenceGlyphs.length; i++) {
            metrics.text = referenceGlyphs[i]
            var w = metrics.tightBoundingRect.width
            if (w > max) max = w
        }
        return max
    }

    function test_reference_glyphs_share_one_ink_width() {
        var first = -1
        for (var i = 0; i < referenceGlyphs.length; i++) {
            metrics.text = referenceGlyphs[i]
            var w = metrics.tightBoundingRect.width
            if (first < 0) first = w
            verify(Math.abs(w - first) <= 1,
                "built-in glyphs should paint one ink width; " + referenceGlyphs[i] +
                " is " + w + " vs " + first)
        }
        verify(first < iconCanvas, "glyph ink should fit inside the optical canvas")
    }

    // The standard is derived from the font size, not a fixed pixel count, so
    // the mark scales with the bar exactly like the glyphs do.
    function test_reference_ink_is_half_the_font_size() {
        verify(Math.abs(referenceInkWidth() - iconFont / 2) <= 1,
            "Nerd Font icon ink should be half the font size: " +
            referenceInkWidth() + " vs " + (iconFont / 2))
    }

    function test_bar_mark_matches_glyph_ink_width() {
        var icon = Qt.createQmlObject(
            'import QtQuick\nimport ".."\nBarIcon { width: ' + iconCanvas + '; height: ' + iconCanvas +
            '; inkWidth: ' + (iconFont / 2) + ' }',
            test, "BarIconProbe")
        var painted = icon.unit * icon.artSpan
        verify(Math.abs(painted - referenceInkWidth()) <= 0.5,
            "drawn mark should paint the same width as the glyphs: " + painted +
            " vs " + referenceInkWidth())
        // It must not fill the canvas the way the old double-scaled art did.
        verify(painted < iconCanvas * 0.7,
            "drawn mark must keep optical padding, not fill the canvas: " + painted)
        // Both states are the same optical size.
        icon.paused = true
        verify(Math.abs(icon.unit * icon.artSpan - painted) <= 0.01,
            "paused mark must keep the same optical size")
        icon.destroy()
    }

    // Scaling the bar font must scale the mark with it, the way it scales the
    // glyphs, rather than leaving the mark pinned to one pixel size.
    function test_mark_scales_with_font() {
        var small = Qt.createQmlObject(
            'import QtQuick\nimport ".."\nBarIcon { inkWidth: 6.5 }', test, "P1")
        var large = Qt.createQmlObject(
            'import QtQuick\nimport ".."\nBarIcon { inkWidth: 9 }', test, "P2")
        verify(Math.abs(small.unit * small.artSpan - 6.5) <= 0.01)
        verify(Math.abs(large.unit * large.artSpan - 9) <= 0.01)
        verify(large.unit * large.artSpan > small.unit * small.artSpan)
        small.destroy(); large.destroy()
    }

    function test_shape_is_authored_once_and_scaled_once() {
        // The earlier bug set the Shape width to `unit * 16` AND applied a
        // `unit` Scale transform, so the art overflowed and sat off-centre.
        var icon = Qt.createQmlObject(
            'import QtQuick\nimport ".."\nBarIcon { width: ' + iconCanvas + '; height: ' + iconCanvas + ' }',
            test, "BarIconProbe2")
        var shape = null
        for (var i = 0; i < icon.children.length; i++)
            if (icon.children[i] && icon.children[i].hasOwnProperty("width") && icon.children[i].width === 16)
                shape = icon.children[i]
        verify(shape !== null, "the Shape should be authored at its native 16-unit grid")
        icon.destroy()
    }
}
