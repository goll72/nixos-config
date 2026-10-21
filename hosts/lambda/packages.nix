{ pkgs, ... }:

{
  environment.systemPackages = [
    # For `hydroxide auth` (overlay version with CAPTCHA patch, see overlays/hydroxide.nix)
    pkgs.hydroxide
  ];
}
