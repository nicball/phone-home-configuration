{ lib, pkgs, config, ... }:

{
  systemd.user.services.factorio =
    let
      workingDir = config.home.homeDirectory + "/factorio";
      configFile = pkgs.writeText "factorio.conf" ''
        use-system-read-write-data-directories=true
        [path]
        read-data=${pkgs.factorio-headless}/share/factorio/data
        write-data=${workingDir}
      '';
    in {
      Unit = {
        Description = "Factorio Server";
      };
      Service = {
        ExecStart = toString [
          "${pkgs.factorio-headless}/bin/factorio"
          "--config=${configFile}"
          "--start-server=${workingDir + "/saves/server.zip"}"
          "--server-settings=${workingDir + "/server-settings.json"}"
          "--mod-directory=${workingDir + "/mods"}"
          "--server-adminlist=${workingDir + "/server-adminlist.json"}"
          (import ./private/factorio-rcon-flags.nix)
        ];
        WorkingDirectory = workingDir;
        Environment = [ "https_proxy=http://localhost:7890" ];
      };
      Install.WantedBy = [ "default.target" ];
    };

  systemd.user.services.factorio-bot = {
    Unit = {
      Description = "Factorio Telegram Bridge";
      After = [ "factorio.service" ];
      Requires = [ "factorio.service" ];
      PartOf = [ "factorio.service" ];
    };
    Service = {
      ExecStart = "${pkgs.factorio-bot}/bin/midymidy-factorio-webservice";
      Restart = "always";
      Environment = import ./private/factorio-bot-env.nix ++ [
        "https_proxy=http://localhost:7890"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.factorio-saves = {
    Unit = {
      Description = "Auto-archive factorio saves";
      Requisite = [ "factorio.service" ];
    };
    Service.ExecStart = pkgs.writeShellScript "factorio-saves.sh" ''
      dir="${config.home.homeDirectory}/factorio"
      mkdir -p "$dir/old-saves"
      cd "$dir/saves"
      files=($(ls -At))
      [[ ''${#files[@]} -eq 0 ]] && exit
      newest="''${files[0]}"
      cd "$dir/old-saves"
      oldfiles=($(ls -At))
      if [[ ''${#oldfiles[@]} -gt 0 ]]; then
        last="''${oldfiles[0]}"
        newesttime=$(date -r "$dir/saves/$newest" +%s)
        lasttime=$(date -r "$dir/old-saves/$last" +%s)
        [[ $((newesttime - lasttime)) -lt $((55 * 360)) ]] && exit
      fi
      cp "$dir/saves/$newest" "$dir/old-saves/$(mktemp -u "XXXXX-$newest")"
      if [[ "''${#oldfiles[@]}" -ge 100 ]]; then
        rm "''${oldfiles[-1]}"
      fi
    '';
  };

  systemd.user.timers.factorio-saves = {
    Unit.Description = "Timer for factorio save archiver";
    Timer.OnCalendar = "00,06,12,18:00";
    Install.WantedBy = [ "timers.target" ];
  };
}
