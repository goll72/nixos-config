state="/var/lib/knot/static-sync.state"

plan="$(@STATIC_PLAN@/bin/knot-static-plan @STATIC_RECORDS@ "$state")"
if ! grep -q '^update ' <<<"$plan"; then
  exit 0
fi

# set -e: a refused update aborts here and the state file keeps
# pointing at the last applied records, so the next run retries.
# Delete the state file to force a full re-sync (e.g. after
# restoring the zone from a backup without it).
knsupdate <<<"$plan"
rm -f "$state" && cp @STATIC_RECORDS@ "$state"
