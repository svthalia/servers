{ pullRequestsJSON, nixpkgs, ... }:

let
  pkgs = import nixpkgs { config = {}; };

  pullRequests = builtins.fromJSON (builtins.readFile pullRequestsJSON);

  toJobset = ref: info: {
    enabled = 1;

    hidden = false;

    description = info.title;

    flake = "github:svthalia/servers/${ref}";

    checkinterval = 120;

    schedulingshares = 1;

    enableemail = false;

    emailoverride = "";

    keepnr = 1;
  };

  pullToJobset = pull: toJobset "pull/${pull}/head";

  main = toJobset "refs/heads/main" {
    base.repo = { owner.login = "svthalia"; name = "main"; };

    title = "main";
  };

  jobsets = pkgs.lib.mapAttrs pullToJobset pullRequests // { inherit main; };

in
  { jobsets = pkgs.writeText "jobsets.json" (builtins.toJSON jobsets);
  }
