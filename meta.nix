{ lib, ... }:

let
  self = {
    email = "joaog.bastos@protonmail.ch";

    domain = "goll.cc";
    domainCreatedAt = "2023-12";
    internalDomain = "internal";

    toV4 = subnet: host: "${self.wireguard.${subnet}.v4.prefix}${lib.toString self.perHost.${host}.id}";
    toV6 =
      subnet: host: "${self.wireguard.${subnet}.v6.prefix}${lib.toHexString self.perHost.${host}.id}";

    dynamicHosts = [
      "phi"
      "tau"
      "eta"
      "xylo"
    ];

    authoritative = [
      "lambda"
      "mu"
    ];

    allHosts = [
      "lambda"
      "mu"
    ]
    ++ self.dynamicHosts;

    perHost = {
      lambda = {
        id = 1;

        publicIP = {
          v4 = "144.22.210.111";
          v6 = "2603:c021:c000:ab6d::3d7f";
        };

        privateIP.v4 = "10.0.0.171";

        wireguard = "+E5ogxrJBGwhAu8vWaMquc9JJR6aV6UtGk4LievkiVM=";
      };

      mu = {
        id = 2;

        publicIP = {
          v4 = "152.67.54.20";
          v6 = "2603:c021:c000:ab6d::3d80";
        };

        privateIP.v4 = "10.0.0.75";

        wireguard = "u0GDI71/ClMj3Z6o6CsqyhcLkascFY3VO7cmOZ52dn4=";
      };

      phi = {
        id = 3;

        ssh = {
          lambda = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6Qtb4gaj3NqvdWQpJD5rCnqXP2xvKrp8hMeLfw0a3k -";
          mu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDWQHI1ivNPj+HchE6XjDOKTSGJf3AdVK+Ge5BytbSnz -";
          tau = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID1oGpTRUgzxMQ7bFzxNnLWlNwuezjdQ4rr7aTmcYmb1 -";
        };

        wireguard = "y0vz84/bNuCyF94btXpVRZ7JwLRgfC+9bBLgyOzYPH0=";
      };

      tau = {
        id = 4;

        ssh = {
          lambda = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVXj8Gjc0nSGvyncyc0m4GtOIsoBBWUN3i+RrXAjc7x -";
          mu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINAo+HJWj3f7m2BvRPJpwCMYIPw0sYb6D0IbYOXoEry+ -";
          phi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJfTE07rQbofWOixaBshUS2G1lYlJXRUBd1nlZSzJNET -";
        };

        wireguard = "NlhCEP9OWXNbzSy+ehkw9O7cvAKel3nzq9TVomZyvWY=";
      };

      eta = {
        id = 5;

        ssh = {
          lambda = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII6k3qVGm9dNbbTMslW24ODwkOjvvvhfv22gbybNVGy1 -";
          mu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSWe3u3jjJDpNrIM4mro7jUCyoXjwaTwAwWiWmcifI2 -";
          phi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQtadSLi7mxl96TijIMYtZYicz6cDgP5Ae9mwH8YEwy -";
          tau = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHAp4LAQFHw4G2S2DTHUAAhKmzYqbX9ci7AxWsYPmUEJ -";
        };

        wireguard = "y1rK6DE5VjW+rYj62Eo+Hs6q9DacMQAIsBy+vRegF2U=";
      };
    };

    # Two Wireguard networks in a star topology
    # Each key must correspond to a host key in `meta.perHost`
    wireguard = {
      lambda = {
        v4 = {
          prefix = "10.1.0.";
          len = 24;
        };

        v6 = {
          prefix = "fd01::";
          len = 64;
        };

        port = 51820;
      };

      phi = {
        v4 = {
          prefix = "10.2.0.";
          len = 24;
        };

        v6 = {
          prefix = "fd02::";
          len = 64;
        };

        port = 51820;
      };
    };
  };
in
self
