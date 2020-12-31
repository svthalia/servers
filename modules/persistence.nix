{ pkgs, config, lib, ... }:

with lib;
let
  cfg = config.environment.persistence;
  persistentStoragePaths = attrNames cfg;

  inherit (pkgs.callPackage ../lib {}) splitPath dirListToPath concatPaths;
in
{
  options = {

    environment.persistence = mkOption {
      default = {};
      type = with types; attrsOf (
        submodule {
          options =
            {
              links = mkOption {
                type = with types; listOf str;
                default = [];
                description = ''
                  Directories to link to persistent storage.
                '';
              };
              mounts = mkOption {
                type = with types; listOf str;
                default = [];
                description = ''
                  Directories to bind mount to persistent storage.
                '';
              };
            };
        }
      );
    };

  };

  config = {
    # Erase your darlings
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r rpool/local/root@blank
    '';

    systemd.tmpfiles.rules =
      let
        tmpfilesLine = persistentStoragePath: dir:
          let
            targetDir = concatPaths [ persistentStoragePath dir ];
          in
            "L ${dir} - - - - ${targetDir}";
        mkTmpfilesLines = persistentStoragePath:
          map (tmpfilesLine persistentStoragePath) cfg.${persistentStoragePath}.links;
      in
        concatMap mkTmpfilesLines persistentStoragePaths;

    system.activationScripts =
      let
        # Create a directory in persistent storage, so we can bind
        # mount it.
        mkDirCreationSnippet = persistentStoragePath: dir:
          let
            targetDir = concatPaths [ persistentStoragePath dir ];
          in
            ''
              if [[ ! -e "${targetDir}" ]]; then
                  mkdir -p "${targetDir}"
              fi
            '';

        # Build an activation script which creates all persistent
        # storage directories we want to bind mount.
        mkDirCreationScriptForPath = persistentStoragePath:
          nameValuePair
            "create dirs in ${persistentStoragePath}"
            (
              noDepEntry (
                concatMapStrings
                  (mkDirCreationSnippet persistentStoragePath)
                  (cfg.${persistentStoragePath}.links ++ cfg.${persistentStoragePath}.mounts)
              )
            );
      in
        listToAttrs (map mkDirCreationScriptForPath persistentStoragePaths);

    fileSystems =
      let
        # Create fileSystems bind mount entry.
        mkBindMountNameValuePair = persistentStoragePath: dir: {
          name = concatPaths [ "/" dir ];
          value = {
            device = concatPaths [ persistentStoragePath dir ];
            noCheck = true;
            options = [ "bind" ];
          };
        };

        # Create all fileSystems bind mount entries for a specific
        # persistent storage path.
        mkBindMountsForPath = persistentStoragePath:
          listToAttrs (
            map
              (mkBindMountNameValuePair persistentStoragePath)
              cfg.${persistentStoragePath}.mounts
          );
      in
        foldl' recursiveUpdate {} (map mkBindMountsForPath persistentStoragePaths);

    assertions =
      let
        files = concatMap (p: p.files or []) (attrValues cfg);
        markedNeededForBoot = cond: fs: (config.fileSystems.${fs}.neededForBoot == cond);
      in
        [
          {
            # Assert that all persistent storage volumes we use are
            # marked with neededForBoot.
            assertion = all (markedNeededForBoot true) persistentStoragePaths;
            message =
              let
                offenders = filter (markedNeededForBoot false) persistentStoragePaths;
              in
                ''
                  environment.persistence:
                      All filesystems used for persistent storage must
                      have the flag neededForBoot set to true.
                      Please fix or remove the following paths:
                        ${concatStringsSep "\n      " offenders}
                '';
          }
        ];
  };

}
