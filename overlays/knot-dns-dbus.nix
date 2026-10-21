# Build knot-dns with dbus support, so the `server.dbus-event` setting (consumed by
# modules/knot-zone-watch.nix via zone_updated signals on the system bus) may be used.
#
# libsystemd's sd-bus is used (already a dependency via XDP support).
#
# The policy allowing knotd to own its bus name ships with the package
# (picked up via services.dbus.packages).

final: prev: {
  knot-dns =
    let
      # Signals are broadcasts, so clients need no send permission.
      dbusPolicy = final.writeText "cz.nic.knotd.conf" ''
        <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
         "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
        <busconfig>
          <policy user="knot">
            <allow own="cz.nic.knotd"/>
          </policy>
        </busconfig>
      '';
    in
    prev.knot-dns.overrideAttrs (old: {
      configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-dbus=systemd" ];

      postFixup = (old.postFixup or "") + ''
        install -Dm644 ${dbusPolicy} $out/share/dbus-1/system.d/cz.nic.knotd.conf
      '';
    });
}
