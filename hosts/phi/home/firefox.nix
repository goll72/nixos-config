{
  pkgs,
  ...
}:

{
  programs.firefox = {
    enable = true;

    languagePacks = [
      "en-US"
      "pt-BR"
    ];

    policies = {
      AutofillCreditCardEnabled = false;
      AutofillAddressEnabled = false;

      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
        SuspectedFingerprinting = true;
        Category = "strict";
        BaselineExceptions = true;
        ConvenienceExceptions = false;
      };

      GenerativeAI.Enabled = false;

      OfferToSaveLogins = false;

      ExtensionSettings = {
        "uBlock0@raymondhill.net".private_browsing = true;
        # bitwarden-password-manager
        "{446900e4-71c2-419f-a6a7-df9c091e268b}".private_browsing = true;
      };
    };

    profiles.default = {
      search = {
        force = true;
        default = "ddg";
        privateDefault = "ddg";
      };

      extensions = {
        force = true;

        packages = [
          pkgs.firefoxAddons.ublock-origin
          pkgs.firefoxAddons.darkreader
          pkgs.firefoxAddons.tab-reload-notify
          pkgs.firefoxAddons.bitwarden-password-manager

          # pt-BR@dictionaries.addons.mozilla.org
          pkgs.firefoxAddons.corretor
          # en-US@dictionaries.addons.mozilla.org
          pkgs.firefoxAddons.united-states-english-spellche
        ];

        settings = {
          "uBlock0@raymondhill.net".settings = {
            selectedFilterLists = [
              "ublock-filters"
              "ublock-badware"
              "ublock-privacy"
              "ublock-unbreak"
              "ublock-quick-fixes"
            ];
          };

          "addon@darkreader.org".settings = {
            # Disable Dark Mode by default
            enabled = false;
            syncSettings = false;
            previewNewDesign = true;
            previewNewestDesign = true;
          };
        };
      };

      settings = {
        "extensions.autoDisableScopes" = 0;
      };
    };

    nativeMessagingHosts = [ pkgs.tab-reload-notify-native ];
  };
}
