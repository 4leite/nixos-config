#!/usr/bin/env python3
"""Keep Mutter's laptop transform aligned with the current SensorProxy reading."""

import sys

from gi.repository import Gio, GLib

SENSOR_NAME = "net.hadess.SensorProxy"
SENSOR_PATH = "/net/hadess/SensorProxy"
DISPLAY_NAME = "org.gnome.Mutter.DisplayConfig"
DISPLAY_PATH = "/org/gnome/Mutter/DisplayConfig"

# Mutter's logical transform for each chassis orientation on this
# right-side-up portrait-native panel.
TRANSFORMS = {
    "right-up": 0,
    "normal": 1,
    "left-up": 2,
    "bottom-up": 3,
}


def proxy(bus_type, name, path, interface):
    return Gio.DBusProxy.new_for_bus_sync(
        bus_type,
        Gio.DBusProxyFlags.NONE,
        None,
        name,
        path,
        interface,
        None,
    )


class TabletExitOrientation:
    def __init__(self):
        self.sensor = proxy(
            Gio.BusType.SYSTEM, SENSOR_NAME, SENSOR_PATH, SENSOR_NAME
        )
        self.display = proxy(
            Gio.BusType.SESSION, DISPLAY_NAME, DISPLAY_PATH, DISPLAY_NAME
        )
        managed = self.display.get_cached_property("PanelOrientationManaged")
        self.was_managed = managed is not None and managed.get_boolean()
        self.display.connect("g-properties-changed", self.properties_changed)

    def properties_changed(self, _proxy, changed, _invalidated):
        managed = changed.lookup_value("PanelOrientationManaged", None)
        if managed is None:
            return

        is_managed = managed.get_boolean()
        if self.was_managed and not is_managed:
            # Run after Mutter's own unmanaged-orientation configuration.
            GLib.idle_add(self.restore_measured_orientation)
        self.was_managed = is_managed

    def restore_measured_orientation(self):
        orientation = self.sensor.call_sync(
            "org.freedesktop.DBus.Properties.Get",
            GLib.Variant("(ss)", (SENSOR_NAME, "AccelerometerOrientation")),
            Gio.DBusCallFlags.NONE,
            -1,
            None,
        ).unpack()[0]
        transform = TRANSFORMS.get(orientation)
        if transform is None:
            print(f"Ignoring unknown SensorProxy orientation: {orientation}", file=sys.stderr)
            return GLib.SOURCE_REMOVE

        serial, monitors, logical_monitors, _properties = self.display.call_sync(
            "GetCurrentState", None, Gio.DBusCallFlags.NONE, -1, None
        ).unpack()

        connector_modes = {}
        for monitor in monitors:
            spec, modes, properties = monitor
            connector = spec[0]
            current_mode = next(
                (mode[0] for mode in modes if mode[6].get("is-current", False)),
                next((mode[0] for mode in modes if mode[6].get("is-preferred", False)), None),
            )
            if current_mode is not None:
                connector_modes[connector] = current_mode

        updated = []
        for x, y, scale, old_transform, primary, monitor_specs, properties in logical_monitors:
            connectors = []
            builtin = False
            for spec in monitor_specs:
                connector = spec[0]
                mode = connector_modes.get(connector)
                if mode is None:
                    continue
                connectors.append((connector, mode, {}))
                for candidate_spec, _modes, monitor_properties in monitors:
                    if candidate_spec[0] == connector:
                        builtin = builtin or monitor_properties.get("is-builtin", False)
                        break
            updated.append(
                (x, y, scale, transform if builtin else old_transform, primary, connectors)
            )

        parameters = GLib.Variant(
            "(uua(iiduba(ssa{sv}))a{sv})",
            (serial, 1, updated, {}),
        )
        self.display.call_sync(
            "ApplyMonitorsConfig",
            parameters,
            Gio.DBusCallFlags.NONE,
            -1,
            None,
        )
        print(f"Restored laptop transform {transform} from SensorProxy {orientation}")
        return GLib.SOURCE_REMOVE


def main():
    handler = TabletExitOrientation()
    if "--apply-once" in sys.argv:
        handler.restore_measured_orientation()
        return
    GLib.MainLoop().run()


if __name__ == "__main__":
    main()