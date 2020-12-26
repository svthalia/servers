{ pullRequestsJSON, nixpkgs, repo, ... }:

let
  pkgs = import nixpkgs { config = {}; };

  pullRequests = builtins.fromJSON (builtins.readFile pullRequestsJSON);

  toJobset = num: info: {
    enabled = 1;

    hidden = false;

    description = info.title;

    nixexprinput = "src";

    nixexprpath = "release.nix";

    checkinterval = 20;

    schedulingshares = 1;

    enableemail = false;

    emailoverride = "";

    keepnr = 1;

    inputs = {
      src = {
        type = "git";

        value = "https://github.com/${info.base.repo.owner.login}/${info.base.repo.name}.git pull/${num}/head";

        emailresponsible = false;
      };

      nixpkgs = {
        type = "git";

        value = "https://github.com/NixOS/nixpkgs.git nixos-20.09";

        emailresponsible = false;
      };
    };
  };

  main = toJobset (if repo == "servers" then "main" else "master") {
    base.repo = { owner.login = "svthalia"; name = repo; };

    head.sha = if repo == "servers" then "main" else "master";

    title = if repo == "servers" then "main" else "master";
  };

  jobsets = pkgs.lib.mapAttrs toJobset pullRequests // { inherit main; };

in
  { jobsets = pkgs.writeText "jobsets.json" (builtins.toJSON jobsets);
  }
