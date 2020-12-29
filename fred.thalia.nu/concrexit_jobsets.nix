{ pullRequestsJSON, nixpkgs, repo, ... }:

let
  pkgs = import nixpkgs { config = {}; };

  pullRequests = builtins.fromJSON (builtins.readFile pullRequestsJSON);

  toJobset = ref: info: {
    enabled = 1;

    hidden = false;

    description = info.title;

    nixexprinput = "src";

    nixexprpath = "release.nix";

    checkinterval = 0;

    schedulingshares = 1;

    enableemail = false;

    emailoverride = "";

    keepnr = 1;

    inputs = {
      src = {
        type = "git";

        value = "https://github.com/${info.base.repo.owner.login}/${info.base.repo.name}.git ${ref}";

        emailresponsible = false;
      };

      nixpkgs = {
        type = "git";

        value = "https://github.com/NixOS/nixpkgs.git nixos-20.09";

        emailresponsible = false;
      };
    };
  };

  pullToJobset = pull: toJobset "refs/pull/${pull}/head";

  mainBranch = if repo == "servers" then "main" else "master";

  main = toJobset mainBranch {
    base.repo = { owner.login = "svthalia"; name = repo; };

    title = mainBranch;
  };

  jobsets = pkgs.lib.mapAttrs pullToJobset pullRequests // { inherit main; };

in
  { jobsets = pkgs.writeText "jobsets.json" (builtins.toJSON jobsets);
  }
