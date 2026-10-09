{
  lib,
  pkgs,
  meta,
  config,
  ...
}:

let
  domain = meta.domain;

  lambda = meta.toV4 "lambda" "lambda";
  mu = meta.toV4 "lambda" "mu";

  # Keymgr must parse the same config knotd uses (it needs the database
  # section to find the KASP db). The module exposes the rendered config
  # only via environment.etc.
  knotConf = config.environment.etc."knot/knot.conf".source;
  keymgr = "${config.services.knot.package}/bin/keymgr";

  # Declarative source of truth for the static records. knotd never reads
  # this file; static-sync pushes it into the zone via RFC 2136 updates,
  # carrying over nothing because dynamic records live at disjoint names.
  staticRecords = pkgs.writeText "${domain}.static.rr" ''
    ${domain}. 3600 IN NS ns1.${domain}.
    ${domain}. 3600 IN NS ns2.${domain}.
    ${domain}. 3600 IN TXT "google-site-verification=Ug0mcDDr8ddKc--jA7jVKpIr1Ceb91RCkloX-Zs3RQs"

    ${domain}. 3600 IN A ${meta.perHost.lambda.publicIP.v4}
    ${domain}. 3600 IN AAAA ${meta.perHost.lambda.publicIP.v6}

    ns1.${domain}. 3600 IN A ${meta.perHost.lambda.publicIP.v4}
    ns1.${domain}. 3600 IN AAAA ${meta.perHost.lambda.publicIP.v6}
    lambda.${domain}. 3600 IN A ${meta.perHost.lambda.publicIP.v4}
    lambda.${domain}. 3600 IN AAAA ${meta.perHost.lambda.publicIP.v6}

    ns2.${domain}. 3600 IN A ${meta.perHost.mu.publicIP.v4}
    ns2.${domain}. 3600 IN AAAA ${meta.perHost.mu.publicIP.v6}
    mu.${domain}. 3600 IN A ${meta.perHost.mu.publicIP.v4}
    mu.${domain}. 3600 IN AAAA ${meta.perHost.mu.publicIP.v6}

    vault.${domain}. 3600 IN CNAME ${domain}.
  '';

  # Prints the RFC 2136 update batch that turns the currently applied
  # static records (state file) into the desired ones (staticRecords).
  # One full RR per line, "owner ttl IN type rdata". On a missing state
  # file (first boot, or after the operator wiped the zone to
  # re-bootstrap) the batch starts with an SOA add, which Knot requires
  # to create a zone from an empty journal.
  staticPlan = pkgs.writeScriptBin "knot-static-plan" ''
    #!${pkgs.python3}/bin/python3
    import os
    import sys

    desired_path, state_path = sys.argv[1:3]

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
        "server 127.0.0.1",
        "zone ${domain}.",
    ]
    
    if bootstrapping:
        out.append(
            "update add ${domain}. 3600 IN SOA ${domain}. "
            "hostmaster.${domain}. 1 3600 900 604800 300"
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
  '';

  staticSync = pkgs.writeShellApplication {
    name = "knot-static-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      
      config.services.knot.package
    ];
    text = ''
      state="/var/lib/knot/static-sync.state"

      plan="$(${staticPlan}/bin/knot-static-plan ${staticRecords} "$state")"
      if ! grep -q '^update ' <<<"$plan"; then
        exit 0
      fi

      # set -e: a refused update aborts here and the state file keeps
      # pointing at the last applied records, so the next run retries.
      # Delete the state file to force a full re-sync (e.g. after
      # restoring the zone from a backup without it).
      knsupdate <<<"$plan"
      rm -f "$state" && cp ${staticRecords} "$state"
    '';
  };

  # ACLs for the three classes of update writer. Everything not matched
  # here is refused.
  staticOwners =
    [ "${domain}." ]
    ++ map (x: "${x}.${domain}.") 
      [
        "ns1"
        "ns2"
        "lambda"
        "mu"
        "vault"
      ]
    ;

  dynamicAcls = lib.listToAttrs (
    map (x: {
      name = "dynamic-${x}";
      value = {
        action = [ "update" ];
        key = [ "${x}.${domain}" ];
        update-owner = "key";
        update-type = [ "AAAA" ];
      };
    }) meta.dynamicHosts
  );
in
{
  sops.templates."knot-secrets" = {
    # keymgr and keyFiles reads happen as the knot user in preStart.
    owner = "knot";
    content = let
      keys = [
        {
          keyName = "acme";
          algorithm = "hmac-sha512";
          secret = config.sops.placeholder."acme-tsig-key";
        }
      ]
      ++ map (x: {
        keyName = "${x}.${domain}";
        algorithm = "hmac-sha512";
        secret = config.sops.placeholder."host-tsig-key/${x}";
      }) meta.dynamicHosts;
      # Each entry is a separate '' block, and '' blocks strip their own
      # indentation, so entries cannot carry leading indent when
      # interpolated. That is fine: the sequence items sit at the same
      # indentation as `key:` (valid YAML), which needs no leading
      # indent. Entry blocks close on their last content line so the
      # separator below is the only newline between entries.
      entry =
        { keyName, algorithm, secret }:
        ''
          - id: ${keyName}
            algorithm: ${algorithm}
            secret: "${secret}" '';
    in
    ''
      key:
      ${lib.concatMapStringsSep "\n" entry keys}
    '';
  };

  services.knot = {
    enable = true;

    # The rendered config includes the sops template above, which only
    # exists at runtime, so build-time conf-check is off (the keyFiles
    # default already disables it). The config is validated by the live
    # test instead.
    keyFiles = [ config.sops.templates."knot-secrets".path ];

    settings = {
      server = {
        # Public service on port 53. The Wireguard VPN addresses are
        # served on port 54 so that the VPN's dnsmasq can own port 53 on
        # the tunnel addresses; that is also where mu pulls its zone
        # transfers from.
        listen = [
          "127.0.0.1@53"
          "::1@53"
          "${meta.perHost.lambda.privateIP.v4}@53"
          "${meta.perHost.lambda.publicIP.v6}@53"
          "${lambda}@54"
        ];

        # Derive implicit NOTIFY/transfer authorizations from the remote
        # definitions (complements the explicit mu-xfr acl below).
        automatic-acl = true;
      };

      remote.mu.address = "${mu}@54";

      policy.default = {
        algorithm = "ecdsap256sha256";
        # The imported KSK must never roll automatically; its DS is
        # published at the registrar and rolling would break validation
        # until the DS is updated by hand. Knot manages only the ZSK.
        ksk-lifetime = 0;
        nsec3 = true;
      };

      template.default = {
        # Zonefileless: the zone lives entirely in the journal; knotd
        # never reads or writes a zone file, and restarts reload the
        # full (signed) zone from the journal, so DDNS records survive.
        zonefile-sync = -1;
        zonefile-load = "none";
        journal-content = "all";

        dnssec-signing = true;
        dnssec-policy = "default";
        serial-policy = "increment";
      };

      zone.${domain} = {
        notify = [ "mu" ];

        acl = [
          # Unauthenticated zone transfers to mu over the Wireguard VPN
          "mu-xfr"
          "static-update"
          "acme-update"
        ]
        ++ (map (x: "dynamic-${x}") meta.dynamicHosts);
      };

      acl = {
        mu-xfr = {
          action = [ "transfer" ];
          address = [ mu ];
        };

        # Nix-owned static records: pushed by knot-static-sync on
        # this host over localhost, unauthenticated but restricted
        # to the exact static owner names (and away from all dynamic
        # types), so no local process can touch ipup/ACME names.
        static-update = {
          action = [ "update" ];
          address = [
            "127.0.0.1"
            "::1"
          ];
          update-owner = "name";
          update-owner-name = staticOwners;
          update-owner-match = "equal";
          update-type = [
            "SOA"
            "NS"
            "TXT"
            "A"
            "AAAA"
            "CNAME"
          ];
        };

        acme-update = {
          action = [ "update" ];
          key = [ "acme" ];
          update-owner = "name";
          update-owner-name = [ "_acme-challenge.${domain}." ];
          update-owner-match = "equal";
          update-type = [ "TXT" ];
        };
      }
      // dynamicAcls;
    };
  };

  # Import the existing KSK into Knot's KASP database before knotd first
  # signs the zone, so DNSSEC validation keeps working. The secret is
  # only read here; afterwards the key lives in the KASP db. The secret
  # is a PKCS#8 PEM file.
  #
  # Knot's automatic key management requires both a KSK and a ZSK to be
  # present in the KASP db (unless single-type-signing is on); with only
  # the imported KSK it would start a scheme rollover and generate a
  # second KSK, breaking the KSK continuity we are trying to preserve.
  # We generate a ZSK here (with zero propagation delay so it becomes
  # active immediately) and leave ksk-lifetime=0 so the imported KSK
  # never rolls; from then on Knot manages only ZSK rollovers.
  systemd.services.knot.preStart = ''
    if ${keymgr} --config=${knotConf} -l 2>/dev/null | grep -q '${domain}'; then
      exit 0
    fi

    ts="$(date +%s)"
    ${keymgr} --config=${knotConf} ${domain} import-pem \
      ${config.sops.secrets."dns-ksk".path} \
      algorithm=ecdsap256sha256 ksk=yes \
      created=$ts publish=$ts active=$ts retire=0 remove=0

    # Generate the initial ZSK so signing_scheme_present() is satisfied
    # and automatic key management does not start a scheme rollover.
    # active=$ts makes it active immediately (no propagation delay).
    ${keymgr} --config=${knotConf} ${domain} generate \
      algorithm=ecdsap256sha256 zsk=yes \
      created=$ts publish=$ts active=$ts retire=0 remove=0
  '';

  # Reconcile the static records with the declarative set above. Runs
  # after knotd is up (Type=notify) and is a no-op while the desired
  # records match the last successfully applied ones.
  systemd.services.knot-static-sync = {
    description = "Reconcile static DNS records via RFC 2136 updates";
    after = [ "knot.service" ];
    requires = [ "knot.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "knot";
      StateDirectory = "knot";
      ExecStart = lib.getExe staticSync;
    };
  };

  environment.systemPackages = [
    staticSync
  ];
}
