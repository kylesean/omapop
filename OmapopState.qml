pragma Singleton
import QtQuick

// Process-wide, plugin-local state shared by the two entry points.
//
// Service.qml and BarWidget.qml are separate components created by the shell,
// but they run in the same Quickshell process. The widget needs the service
// instance for every status and control call it makes.
//
// The shell's own `bar.shell.serviceFor(pluginId)` works under the built-in
// bar, but a replacement bar (a third-party `kind: "bar"` plugin) receives a
// capability-scoped facade whose `serviceFor` only resolves services the
// replacement bar itself owns, so it returns null for ours. Under a
// replacement bar the widget then had no service at all: the panel opened
// empty and every toggle was inert.
//
// Publishing the live instance here gives the widget a path that does not
// depend on which bar is hosting it. The service registers itself on load and
// clears the slot on destruction; the widget prefers this instance and keeps
// `bar.shell.serviceFor` as a fallback for hosts that do provide it.
QtObject {
    property var service: null
}
