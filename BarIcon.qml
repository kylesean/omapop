import QtQuick
import QtQuick.Shapes

// Omapop's bar mark: a small action pill with three dots floating above a
// highlighted text selection. Drawn as one even-odd path so the dots and the
// text line are real holes and the mark works over any bar background. Paused
// swaps the dots for pause bars.
//
// Sizing follows the bar's de-facto icon standard. There is no written Omarchy
// spec, so the built-in widgets are the reference: BarIconButton draws a Nerd
// Font glyph at Style.bar.iconFont, and every Nerd Font icon glyph paints its
// ink at exactly half the font size (measured from the font outline: the MDI
// advance is 0.5em, so 15px -> 7.5px). A drawn mark has to paint that same ink
// width, or it reads as heavier than its neighbours even when the box matches.
//
// The caller passes the ink width. The bar passes Style.bar.iconFont / 2; the
// panel header passes a display-size width.
Item {
    id: root

    property color color: "white"
    property bool paused: false

    // Painted ink width in pixels. Bar glyphs are Nerd Font icons whose ink is
    // half their font size, so the bar passes Style.bar.iconFont / 2.
    property real inkWidth: 8

    // The art spans grid units 1..15, i.e. 14 units, in both axes. The Shape is
    // authored at its native 16x16 and scaled exactly once about its centre;
    // scaling both the Shape's width and its transform (as an earlier version
    // did) overflowed the box and pushed the mark off-centre.
    readonly property real artSpan: 14
    readonly property real unit: inkWidth / artSpan

    Shape {
        anchors.centerIn: parent
        width: 16
        height: 16
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        transform: Scale { origin.x: 8; origin.y: 8; xScale: root.unit; yScale: root.unit }

        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill
            PathSvg {
                path: {
                    // Pill spanning x 1.5..14.5, y 1..7 (radius 3).
                    var d = "M4.5 1 H11.5 A3 3 0 0 1 11.5 7 H4.5 A3 3 0 0 1 4.5 1 Z "
                    if (root.paused) {
                        // Two pause bars, 1.5 wide and 3 tall, cut from the pill.
                        d += "M5.75 2.5 H7.25 V5.5 H5.75 Z M8.75 2.5 H10.25 V5.5 H8.75 Z "
                    } else {
                        // Three dots of radius 1 on y 4, a pixel apart at 16px.
                        var cx = [5, 8, 11]
                        for (var i = 0; i < cx.length; i++)
                            d += "M" + (cx[i] - 1) + " 4 A1 1 0 1 0 " + (cx[i] + 1) + " 4 A1 1 0 1 0 " + (cx[i] - 1) + " 4 Z "
                    }
                    // Selection block x 1..15, y 10..15 (radius 1.5) with a
                    // one-pixel line of text cut out of the middle.
                    d += "M2.5 10 H13.5 A1.5 1.5 0 0 1 15 11.5 V13.5 A1.5 1.5 0 0 1 13.5 15 H2.5 A1.5 1.5 0 0 1 1 13.5 V11.5 A1.5 1.5 0 0 1 2.5 10 Z "
                    d += "M4.5 12 H11.5 A0.5 0.5 0 0 1 11.5 13 H4.5 A0.5 0.5 0 0 1 4.5 12 Z"
                    return d
                }
            }
        }
    }
}
