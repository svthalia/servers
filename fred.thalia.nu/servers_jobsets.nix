{ pullRequestsJSON, nixpkgs, ... }:

let
  pkgs = import nixpkgs { config = {}; };

  pullRequests = builtins.fromJSON (builtins.readFile pullRequestsJSON);

  toJobset = num: info: {
    enabled = 1;

    hidden = false;

    description = info.title;

    type = 1;

    flake = "github:svthalia/servers/${info.head.sha}";

    checkinterval = 120;

    schedulingshares = 1;

    enableemail = false;

    emailoverride = "";

    keepnr = 1;
  };


  main = toJobset "main" {
    head.sha = "main";

    title = "main";
  };

  jobsets = pkgs.lib.mapAttrs toJobset pullRequests // { inherit main; };

in
  { jobsets = pkgs.writeText "jobsets.json" (builtins.toJSON jobsets);
  }
