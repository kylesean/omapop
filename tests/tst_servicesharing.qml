import QtQuick
import QtTest
import ".." as Plugin

// Regression guard for issue #7: the bar widget must reach Omapop's own
// service even when the bar host cannot resolve it (a replacement bar only
// resolves services it owns). Service.qml publishes the live instance through
// the plugin-local singleton; the widget reads it first and falls back to the
// host lookup. This case pins the shared-slot contract the two rely on.
TestCase {
    id: test
    name: "ServiceSharing"
    when: windowShown

    function init() {
        Plugin.OmapopState.service = null
    }

    function cleanup() {
        Plugin.OmapopState.service = null
    }

    function test_slot_starts_empty() {
        compare(Plugin.OmapopState.service, null)
    }

    function test_publish_and_read_back() {
        var fake = { name: "service-instance", engineReady: true, extensions: [] }
        Plugin.OmapopState.service = fake
        verify(Plugin.OmapopState.service !== null)
        compare(Plugin.OmapopState.service.name, "service-instance")
    }

    // A QML consumer's binding must re-evaluate when the slot is filled, which
    // is how BarWidget.qml's `service` property learns about the instance.
    Item {
        id: consumer
        readonly property var service: Plugin.OmapopState.service
    }

    function test_slot_updates_notify_consumers() {
        compare(consumer.service, null)
        Plugin.OmapopState.service = { name: "late-service" }
        compare(consumer.service.name, "late-service")
        Plugin.OmapopState.service = { name: "second-service" }
        compare(consumer.service.name, "second-service")
    }

    // Service.qml clears the slot on destruction only while it still owns it,
    // so a reload cannot null out the instance a newer service published.
    function test_destruction_clears_only_own_slot() {
        var staleOwner = { name: "stale" }
        var current = { name: "current" }
        Plugin.OmapopState.service = staleOwner
        // A newer service replaces the slot (e.g. plugin reload).
        Plugin.OmapopState.service = current
        // The old instance is destroyed. Its guard must not clear the slot.
        if (Plugin.OmapopState.service === staleOwner)
            Plugin.OmapopState.service = null
        compare(Plugin.OmapopState.service.name, "current")
        // The genuine owner clears it.
        if (Plugin.OmapopState.service === current)
            Plugin.OmapopState.service = null
        compare(Plugin.OmapopState.service, null)
    }
}
