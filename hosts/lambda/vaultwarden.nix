{
  meta,
  ...
}:

{
  services.vaultwarden = {
    enable = true;

    config = {
      DOMAIN = "https://vault.${meta.domain}";

      SHOW_PASSWORD_HINT = false;
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = false;

      DATABASE_URL = "/var/lib/vaultwarden/db.sqlite3";
    };
  };
}
