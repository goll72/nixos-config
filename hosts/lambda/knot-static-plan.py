#!@PYTHON@

import os
import sys

desired_path, state_path = sys.argv[1:3]
domain = "@DOMAIN@"
knot_port = "@KNOT_PORT@"


def load(path):
    records = {}
    with open(path) as f:
        for line in f:
            parts = line.split(None, 4)
            if len(parts) < 5:
                continue
            owner, _ttl, _cls, rtype, rdata = parts
            records.setdefault((owner.lower(), rtype.upper()), set()).add(rdata)
    return records


desired = load(desired_path)
bootstrapping = not os.path.exists(state_path)
applied = {} if bootstrapping else load(state_path)

out = [
    f"server 127.0.0.1 {knot_port}",
    f"zone {domain}.",
]

if bootstrapping:
    out.append(
        f"update add {domain}. 3600 IN SOA {domain}. "
        f"hostmaster.{domain}. 1 3600 900 604800 300"
    )

for owner, rtype in sorted(set(applied) | set(desired)):
    old = applied.get((owner, rtype), set())
    new = desired.get((owner, rtype), set())
    if old == new:
        continue
    # Static owner names never carry dynamic records (those live at
    # dynamic-host and _acme-challenge names, which the static-update
    # acl does not allow), so a blanket per-owner-type delete cannot
    # eat ipup/ACME records.
    if old:
        out.append(f"update delete {owner} {rtype}")
    for rdata in sorted(new):
        out.append(f"update add {owner} 3600 IN {rtype} {rdata}")

out.append("send")
print("\n".join(out))
