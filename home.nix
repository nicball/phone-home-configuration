{ config, pkgs, npkgs, transfersh, ... }@args:

{
  home = {
    username = "phablet";
    homeDirectory = "/home/phablet";
    stateVersion = "21.11";

    packages = with pkgs; [
      nix htop curl wget npkgs.kakoune neofetch unar tmux aria2 file
      kitty.terminfo
    ];
  };

  programs.home-manager.enable = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" "https://cache.nixos.org/" ];
    };
    package = pkgs.nix;
  };

  programs.git = {
    enable = true;
    userName = "Nick Ballard";
    userEmail = "znhihgiasy@gmail.com";
  };

  systemd.user.services.clash = {
    Unit.Description = "Clash Daemon";
    Service.ExecStart = "${pkgs.clash}/bin/clash -f ${./private/clash-tag.yaml} -d ${config.home.homeDirectory}/.local/var/clash";
    Install.WantedBy = [ "default.target" ];
  };

  programs.fish = {
    enable = true;
    shellInit = "source ${config.home.profileDirectory}/etc/profile.d/nix.fish";
  };

  systemd.user.services.minecraft = {
    Unit.Description = "Minecraft Server";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "${config.home.homeDirectory + "/mc"}";
      ExecStart = "${pkgs.tmux}/bin/tmux new -s minecraft -d '${pkgs.jre_headless}/bin/java -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=7890 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=7890 -Xmx3576M -jar ./fabric*.jar nogui'";
      ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t minecraft";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.frpc = {
    Unit.Description = "Fast Reverse Proxy Client";
    Service.ExecStart = "${pkgs.frp}/bin/frpc -c ${./private/frpc.ini}";
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Argo Tunnel";
    Service.ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token ${builtins.readFile ./private/cloudflared-token}";
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.caddy =
    let configFile = pkgs.writeText "caddy-config" ''
      :8080
      file_server browse
      root * ${config.home.homeDirectory + "/www"}
    '';
    in {
      Unit.Description = "Caddy HTTP Server";
      Service.ExecStart = "${pkgs.caddy}/bin/caddy run --adapter caddyfile --config ${configFile}";
      Install.WantedBy = [ "default.target" ];
    };

  systemd.user.services.fvckbot = {
    Unit.Description = "Yet another telegram bot";
    Service = {
      ExecStart = "${args.fvckbot.defaultPackage.${args.system}}/bin/fvckbot";
      WorkingDirectory = "${config.home.homeDirectory + "/fvckbot"}";
      Environment = [
        "TG_BOT_TOKEN=${builtins.readFile ./private/fvckbot-token}"
        "https_proxy=http://localhost:7890"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.transfersh = {
    Unit.Description = "Easy and fast file sharing from the command-line";
    Service = {
      ExecStart =
        let pkg = with pkgs; buildGoModule {
          src = transfersh;
          pname = "transfer.sh";
          version = "1.4.0";
          vendorSha256 = "sha256-d7EMXCtDGp9k6acVg/FiLqoO1AsRzoCMkBb0zen9IGc=";
        }; in
        "${pkg}/bin/transfer.sh";
      Environment = [
        "LISTENER=:8081"
        "TEMP_PATH=/tmp/"
        "PROVIDER=local"
        "BASEDIR=${config.home.homeDirectory + "/transfersh"}"
        "LOG=${config.home.homeDirectory + "/transfersh/.log"}"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
