import dbus
import json
import logging
import os
import subprocess
import sys

from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

log = logging.getLogger("knot-zone-watch")

KNOT_BUS = "cz.nic.knotd"
KNOT_PATH = "/cz/nic/knotd"
KNOT_IFACE = "cz.nic.knotd.events"

DNSMASQ_BUS = "uk.org.thekelleys.dnsmasq"
DNSMASQ_PATH = "/uk/org/thekelleys/dnsmasq"
DNSMASQ_IFACE = "uk.org.thekelleys.dnsmasq"

KDIG = "@KDIG@"
SYSTEMCTL = "@SYSTEMCTL@"
BASH = "@BASH@"
KNOT_PORT = "@KNOT_PORT@"

CACHE_PATH = "/var/lib/knot-zone-watch/cache.json"
COALESCE_MS = 1000

with open("@RULES_FILE@") as f:
    RULES = json.load(f)


def norm_name(name):
    return name.rstrip(".").lower()


def query(rrtype, name):
    out = subprocess.run(
        [
            KDIG,
            "@127.0.0.1",
            "-p",
            KNOT_PORT,
            rrtype,
            name,
            "+short",
            "+time=2",
            "+tries=1",
        ],
        check=True,
        capture_output=True,
        text=True,
        timeout=15,
    )
    return sorted(line for line in out.stdout.splitlines() if line)


def fingerprint(rule):
    return ";".join(
        rrtype + "=" + ",".join(query(rrtype, rule["name"])) for rrtype in rule["rrtypes"]
    )


def load_cache():
    try:
        with open(CACHE_PATH) as f:
            return json.load(f)
    except OSError:
        return {}


def save_cache(cache):
    tmp = CACHE_PATH + ".tmp"
    with open(tmp, "w") as f:
        json.dump(cache, f, sort_keys=True, indent=2)
    os.replace(tmp, CACHE_PATH)


class Watcher:
    def __init__(self):
        self.cache = load_cache()
        self.pending = set()
        self.coalesce_id = None
        DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SystemBus()
        self.dnsmasq = dbus.Interface(
            self.bus.get_object(DNSMASQ_BUS, DNSMASQ_PATH), DNSMASQ_IFACE
        )

    def prime(self):
        for rule in RULES:
            try:
                self.cache[rule["name"]] = fingerprint(rule)
                log.info("primed %s = %s", rule["name"], self.cache[rule["name"]])
            except (subprocess.SubprocessError, OSError) as e:
                log.warning("could not prime %s: %s", rule["name"], e)
        save_cache(self.cache)

    def on_zone_updated(self, zone, serial, *args):
        log.info("zone_updated zone=%s serial=%s", zone, serial)
        self.pending.add(norm_name(zone))
        if self.coalesce_id is None:
            self.coalesce_id = GLib.timeout_add(COALESCE_MS, self.process)

    def on_zone_not_updated(self, zone, *args):
        log.warning("zone_not_updated zone=%s", zone)

    def process(self):
        self.coalesce_id = None
        zones, self.pending = self.pending, set()
        changed = []
        for rule in RULES:
            if norm_name(rule["zone"]) not in zones:
                continue
            try:
                fp = fingerprint(rule)
            except (subprocess.SubprocessError, OSError) as e:
                log.warning("could not query %s: %s", rule["name"], e)
                continue
            if self.cache.get(rule["name"]) == fp:
                log.info("%s unchanged (%s)", rule["name"], fp)
                continue
            log.info(
                "%s changed: %r -> %r", rule["name"], self.cache.get(rule["name"]), fp
            )
            self.cache[rule["name"]] = fp
            changed.append(rule)
        if changed:
            # Flush first: without it a peer restart would resolve
            # through this dnsmasq's own (stale) cache.
            self.flush_dnsmasq()
            self.restart_units(changed)
            self.run_commands(changed)
            save_cache(self.cache)
        return False

    def flush_dnsmasq(self):
        try:
            self.dnsmasq.ClearCache()
            log.info("dnsmasq cache cleared")
            return
        except dbus.exceptions.DBusException as e:
            log.warning("ClearCache failed (%s), restarting dnsmasq", e)
        try:
            subprocess.run([SYSTEMCTL, "restart", "dnsmasq.service"], check=True)
        except (subprocess.SubprocessError, OSError) as e:
            log.error("restarting dnsmasq failed: %s", e)

    def restart_units(self, rules):
        units = []
        for rule in rules:
            for unit in rule["units"]:
                if unit not in units:
                    units.append(unit)
        for unit in units:
            try:
                subprocess.run([SYSTEMCTL, "restart", unit], check=True)
                log.info("restarted %s", unit)
            except (subprocess.SubprocessError, OSError) as e:
                log.error("restarting %s failed: %s", unit, e)

    def run_commands(self, rules):
        for rule in rules:
            for cmd in rule.get("commands", []):
                log.info("running: %s", cmd)
                try:
                    subprocess.run([BASH, "-c", cmd], check=True)
                except (subprocess.SubprocessError, OSError) as e:
                    log.error("command failed (%s): %s", cmd, e)


def main():
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    watcher = Watcher()
    # Prime before subscribing: a startup-time kdig may briefly block
    # the loop, and signal matching on the well-known bus name stays
    # valid across knot restarts.
    watcher.prime()
    watcher.bus.add_signal_receiver(
        watcher.on_zone_updated,
        signal_name="zone_updated",
        dbus_interface=KNOT_IFACE,
        bus_name=KNOT_BUS,
        path=KNOT_PATH,
    )
    watcher.bus.add_signal_receiver(
        watcher.on_zone_not_updated,
        signal_name="zone_not_updated",
        dbus_interface=KNOT_IFACE,
        bus_name=KNOT_BUS,
        path=KNOT_PATH,
    )
    log.info("watching %d rule(s)", len(RULES))
    GLib.MainLoop().run()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        log.exception("fatal error")
        sys.exit(1)
