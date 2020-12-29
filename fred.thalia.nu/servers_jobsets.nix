{ pullRequestsJSON, nixpkgs, ... }:

let
  pkgs = import nixpkgs { config = {}; };

  pullRequests = builtins.fromJSON (builtins.readFile pullRequestsJSON);

  toJobset = ref: info: {
    enabled = 1;

    hidden = false;

    description = info.title;

    type = 1;

    flake = "git+https://github.com/svthalia/servers?ref=${ref}";

    checkinterval = 120;

    schedulingshares = 1;

    enableemail = false;

    emailoverride = "";

    keepnr = 1;
  };

  pullToJobset = pull: toJobset "refs/pull/${pull}/head";

  main = toJobset "refs/heads/main" {
    head.sha = "main";

    title = "main";
  };

  jobsets = pkgs.lib.mapAttrs pullToJobset pullRequests // { inherit main; };

in
  { jobsets = pkgs.writeText "jobsets.json" (builtins.toJSON jobsets);
  }
