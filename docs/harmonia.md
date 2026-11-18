harmonia
========

Harmonia serves a Nix store as an HTTP binary cache over the Wireguard VPN.

## Server

On the host that serves the cache, generate a binary cache key:

```sh
nix-store --generate-binary-cache-key main /tmp/main.key /tmp/main.pub
```

Store the private key in the `harmonia-key` SOPS secret, and add the public
key to `meta.nix` under `binaryCache.publicKeys`:

```nix
binaryCache.publicKeys = {
  phi = "main-1:<contents of main.pub>";
};
```

Then enable serving:

```nix
services.vpn.binaryCache = {
  enable = true;
  serve = true;
};
```

## Client

On hosts that share the server's system, enable pulling:

```nix
services.vpn.binaryCache = {
  enable = true;
  pull = true;
};
```

This configures Nix to substitute from the other VPN hosts sharing the same
system, using the public keys from `meta.nix`.
