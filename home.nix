{ config, pkgs, npkgs, ... }@args:

{
  home = {
    username = "phablet";
    homeDirectory = "/home/phablet";
    stateVersion = "21.11";

    packages = with pkgs; [
      nix htop curl wget npkgs.kakoune neofetch unar screen aria2
      kitty.terminfo
    ];
  };

  programs.home-manager.enable = true;

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
      WorkingDirectory = "${config.home.homeDirectory + "/mc"}";
      ExecStart="${pkgs.papermc}/bin/minecraft-server -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=7890 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=7890 -Xmx4G";
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
}
