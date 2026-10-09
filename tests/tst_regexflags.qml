import QtQuick
import QtTest
import "../Actions.js" as Actions

// compileRegex passes its flags straight into the QML engine's RegExp. Node
// accepts the ES2018 `s` (dotAll) flag, so tests/actions.test.mjs cannot catch
// the engine rejecting it; this QML-side case is the regression guard for the
// `(?s)` bug that silently hid the approved Google Translate extension.
TestCase {
    name: "RegexFlags"
    when: windowShown

    function test_engine_rejects_s_flag() {
        // Documents why the emulation exists. If a future Qt accepts `s`, this
        // test will fail and the emulation can be dropped.
        var rejected = false
        try { new RegExp("a.b", "s") } catch (e) { rejected = true }
        verify(rejected, "this Qt build accepts the s flag; the dotAll emulation is no longer needed")
    }

    function test_dotall_matches_newlines() {
        var r = Actions.applyRegex("(?s)^.{1,1900}$", "a\nb\nc")
        verify(r.ok, "dotAll regex must match multi-line text")
        compare(r.text, "a\nb\nc")

        var single = Actions.applyRegex("(?s)^.{1,1900}$", "hello")
        verify(single.ok)
        compare(single.text, "hello")
    }

    function test_dotall_bounds_still_apply() {
        verify(Actions.applyRegex("(?s)^.{1,5}$", "abcde").ok)
        verify(!Actions.applyRegex("(?s)^.{1,5}$", "abcdef").ok)
    }

    function test_dot_without_dotall_does_not_cross_lines() {
        verify(!Actions.applyRegex("^a.b$", "a\nb").ok)
        verify(Actions.applyRegex("(?s)^a.b$", "a\nb").ok)
    }

    function test_literal_dots_survive_emulation() {
        verify(Actions.applyRegex("(?s)^a\\.b$", "a.b").ok)
        verify(!Actions.applyRegex("(?s)^a\\.b$", "axb").ok)
        verify(Actions.applyRegex("(?s)^a[.]b$", "a.b").ok)
        verify(Actions.applyRegex("(?s)[.]+$", "abc...").ok)
    }

    function test_bad_regex_still_hides() {
        var r = Actions.applyRegex("(unclosed", "x")
        verify(!r.ok)
    }
}
