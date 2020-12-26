repo: {
  enabled = 1;
  hidden = false;
  description = "${repo} pull requests";

  nixexprinput = "local";
  nixexprpath = "jobsets.nix";

  checkinterval = "120";
  schedulingshares = 1;
  enableemail = false;
  emailoverride = "";
  keepnr = 1;

  inputs = {
    local = {
      type = "path";

      value = "/etc/hydra/";

      emailresponsible = false;
    };

    repo = {
      type = "string";

      value = "${repo}";

      emailresponsible = false;
    };

    nixpkgs = {
      type = "git";

      value = "https://github.com/NixOS/nixpkgs.git 89acf89f6b214377de4fffdeca597d13241a0dd0";

      emailresponsible = false;
    };

    pullRequestsJSON = {
      type = "githubpulls";

      value = "svthalia ${repo}";

      emailresponsible = false;
    };
  };
}
