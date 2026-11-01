{ ... }:

{
  services.pipewire.configs = {
    # X11 bell isn't that useful when using a compositor
    # that supports xdg-system-bell-v1, such as Mutter.
    "99-no-x11-bell" = {
      "context.properties" = {
        "module.x11.bell" = false;
      };
    };
  };
}
