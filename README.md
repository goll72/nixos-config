# Usage

Clone this repo and then the private secrets repo to `./secrets`.

To install NixOS using the config for a given host (for instance, phi), run

```sh
nix shell nixpkgs#disko
disko --mode destroy,format,mount --flake .#phi
nixos-install --no-channel-copy --no-root-password --flake .#phi
```

To update an existing NixOS host, use `nixos-rebuild`.

## phi

The following actions must be taken manually when installing from scratch:

 - Make a symlink from `/etc/nixos` to here (optional)

 - Comment out `fixate-volume-key=...` in the disko config

 - Change Secure Boot to Setup Mode (check with `sbctl status`)

   Note that on some laptops (such as phi) there is no explicit option
   to change to "Setup Mode", rather, clearing the Secure Boot settings
   and then disabling Secure Boot will make the firmware change it to
   Setup Mode automatically on the next reboot.
   
 - Place the SOPS AGE private key for phi in `/var/lib/sops-nix/keys.txt`

 - Enroll a TPM2 credential for LUKS unlocking

   ```sh
   systemd-cryptenroll --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs=0+2+7+15:sha256=$(printf %64s | tr ' ' 0) ...
   ```

   Note that the enrollment of the TPM2 keyslot must be done after the
   Lanzaboote bootloader setup stanza is over, to guarantee that the
   PCRs being enrolled will have stable values.

 - Uncomment the `fixate-volume-key` line in the disko config and replace the hash
   with the expected hash after having unlocked the LUKS device using TPM:

   ```sh
   grep volume-key /run/log/systemd/tpm2-measure.log | jq -r --seq '.digests[].digest'
   ```

 - Log in to GNOME Online Accounts (e-mail, CalDAV, etc.), Mozilla account (firefox),
   password manager, etc.

## lambda, mu

The DNS server and VPN settings, unfortunately, have an interdependency, so you may
have to temporarily set mu's DNS server to lambda's public IPv4 address so that it
can connect to the VPN. 

# Secrets

To edit/add secrets, you can run e.g.

```sh
sudo env SOPS_AGE_KEY_FILE=/var/lib/sops-nix/keys.txt sops edit secrets/secrets.yaml
```

---

> [!NOTE]
> 
> Some modules and package definitions in this repository contain AI-generated code.
