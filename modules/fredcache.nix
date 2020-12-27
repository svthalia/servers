{pkgs, ...}:
{
  config = {
    nix.binaryCaches = [
      "https://cache.technicie.nl/"
    ];
    nix.binaryCachePublicKeys = [
      "cache.technicie.nl:vf0V6R4wHTs6ax27H0hJJDvVEbtHEL2u1ilznzRyNY8="
    ];
  };
}
