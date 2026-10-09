{
  meta,
  ...
}:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = meta.email;
  };
}
