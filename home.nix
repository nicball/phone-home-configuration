{ config, pkgs, lib, ... }:

{
  imports = [
    # ./factorio.nix
  ];

  nic.nicpkgs.enable-overlay = true;

  home = {
    username = "phablet";
    homeDirectory = "/home/phablet";
    stateVersion = "21.11";

    packages = with pkgs; [
      nix htop curl wget
      unar tmux aria2 file jq gnugrep pv less
      man-pages man-pages-posix
      kitty.terminfo
      owncast
    ];
  };

  programs.home-manager.enable = true;

  nic.kakoune.enable = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
        "https://nicpkgs.cachix.org"
      ];
      trusted-public-keys = [
        "nicpkgs.cachix.org-1:OTCMJ8lLYwhnDhlkP0huok3hOnxV3u/YVDH9M0kPLqM="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      auto-optimise-store = true;
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
    Service.ExecStart = "${pkgs.clash-meta}/bin/clash-meta -f ${./private/clash.yaml} -d ${config.home.homeDirectory}/.local/var/clash";
    Install.WantedBy = [ "default.target" ];
  };

  programs.fish = {
    enable = true;
    shellInit = "source ${config.home.profileDirectory}/etc/profile.d/nix.fish";
  };

  programs.nix-index.enable = true;

  # systemd.user.services.minecraft = {
  #   Unit.Description = "Minecraft Server";
  #   Service = {
  #     Type = "oneshot";
  #     WorkingDirectory = "${config.home.homeDirectory + "/mc"}";
  #     ExecStart = "${pkgs.tmux}/bin/tmux new -s minecraft -d '${pkgs.jre_headless}/bin/java -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=7890 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=7890 -Xmx3072M -jar ./fabric*.jar nogui'";
  #     ExecStop = "${pkgs.tmux}/bin/tmux kill-session -t minecraft";
  #     RemainAfterExit = true;
  #   };
  #   Install.WantedBy = [ "default.target" ];
  # };

  # systemd.user.services.frpc = {
  #   Unit.Description = "Fast Reverse Proxy Client";
  #   Service.ExecStart = "${pkgs.frp}/bin/frpc -c ${./private/frpc.ini}";
  #   Install.WantedBy = [ "default.target" ];
  # };

  systemd.user.services.cloudflared = {
    Unit.Description = "Cloudflare Argo Tunnel";
    Service.ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token ${import ./private/cloudflared-token.nix}";
    Service.Restart = "always";
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

  # systemd.user.services.fvckbot = {
  #   Unit.Description = "Yet another telegram bot";
  #   Service = {
  #     ExecStart = "${pkgs.fvckbot}/bin/fvckbot";
  #     WorkingDirectory = "${config.home.homeDirectory + "/fvckbot"}";
  #     Environment = [
  #       "TG_BOT_TOKEN=${import ./private/fvckbot-token.nix}"
  #       "https_proxy=http://localhost:7890"
  #     ];
  #   };
  #   Install.WantedBy = [ "default.target" ];
  # };

  # systemd.user.services.transfersh = {
  #   Unit.Description = "Easy and fast file sharing from the command-line";
  #   Service = {
  #     ExecStart = "${pkg.tranfersh}/bin/transfer.sh";
  #     Environment = [
  #       "LISTENER=:8081"
  #       "TEMP_PATH=/tmp/"
  #       "PROVIDER=local"
  #       "BASEDIR=${config.home.homeDirectory + "/transfersh"}"
  #       "LOG=${config.home.homeDirectory + "/transfersh/.log"}"
  #     ];
  #   };
  #   Install.WantedBy = [ "default.target" ];
  # };

  nic.instaepub = {
    enable = true;
    output-dir = config.home.homeDirectory + "/www/instaepub";
    auto-archive = true;
    interval = "hourly";
    pandoc = pkgs.pandoc-static;
  } // import ./private/instaepub.nix;
  systemd.user.services.instaepub.Service.Environment = lib.mkMerge [ "https_proxy=http://localhost:7890" ];

  nic.cloudflare-ddns = {
    enable = true;
    enable-log = true;
    log-path = "/tmp/cloudflare-ddns.log";
  } // import ./private/cloudflare-ddns.nix;

  systemd.user.services.aria2d = {
    Unit.Description = "Aria2 Daemon";
    Service = {
      ExecStart =
        let
          aria2 = pkgs.aria2.override ({
            server-mode = true;
            dir = config.home.homeDirectory + "/www/files";
          } // import ./private/aria2d.nix);
        in
        "${aria2}/bin/aria2c";
    };
    Install.WantedBy = [ "default.target" ];
  };

  nixpkgs.config.permittedInsecurePackages = [ "olm-3.2.16" ];
  systemd.user.services.mautrix-telegram = {
    Unit = {
      Description = "Mautrix Telegram Bridge";
      After = [ "synapse.service" ];
      PartOf = [ "synapse.service" ];
      Requires = [ "synapse.service" ];
    };
    Service = {
      ExecStart =
        let
          py = pkgs.python3.withPackages (p: with p; [ pysocks pkgs.mautrix-telegram ]);
        in
        "${py}/bin/python3 -m mautrix_telegram";
      WorkingDirectory = "${config.home.homeDirectory + "/mautrix-telegram"}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # systemd.user.services.matrix-qq = {
  #   Unit = {
  #     Description = "Mautrix Telegram Bridge";
  #     After = [ "synapse.service" "qsign.service" ];
  #     PartOf = [ "synapse.service" ];
  #     Requires = [ "synapse.service" "qsign.service" ];
  #   };
  #   Service = {
  #     ExecStart = "${pkgs.matrix-qq}/bin/matrix-qq";
  #     WorkingDirectory = "${config.home.homeDirectory + "/matrix-qq"}";
  #   };
  #   Install.WantedBy = [ "default.target" ];
  # };

  # systemd.user.services.qsign = {
  #   Unit = {
  #     Description = "QQ signing server";
  #     PartOf = [ "matrix-qq.service" ];
  #   };
  #   Service = {
  #     ExecStart = "${pkgs.jre}/bin/java -jar ./unidbg-fetch-qsign-1.2.1-all.jar --basePath=./txlib/8.9.63";
  #     WorkingDirectory = config.home.homeDirectory + "/qsign";
  #   };
  # };

  systemd.user.services.synapse = {
    Unit = {
      Description = "Synapse Matrix Home Server";
    };
    Service = {
      ExecStart = "${pkgs.matrix-synapse}/bin/synapse_homeserver -c home_server.yaml";
      WorkingDirectory = "${config.home.homeDirectory + "/synapse"}";
      Environment = [ "https_proxy=http://localhost:7890" ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.crawler = {
    Unit.Description = "Web Crawler";
    Service = {
      ExecStart = "${pkgs.python3.withPackages (p: [ p.requests ])}/bin/python3 bot.py";
      WorkingDirectory = config.home.homeDirectory + "/16k-crawler";
      Environment = [ "https_proxy=http://localhost:7890" ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.timers.crawler = {
    Unit.Description = "Timer for Web Crawler";
    Timer.OnCalendar = "hourly";
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.nodebb = let dir = config.home.homeDirectory + "/nodebb"; in {
    Unit = {
      Description = "NodeBB forum";
      Requires = [ "redis.service" ];
      After = [ "redis.service" ];
    };
    Service = {
      Environment = "PATH=${pkgs.nodejs}/bin";
      ExecStart = "${dir}/nodebb start";
      ExecStop = "${dir}/nodebb stop";
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = dir;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.redis = {
    Unit.Description = "redis";
    Service = {
      ExecStart = "${pkgs.redis}/bin/redis-server ./redis.conf";
      WorkingDirectory = config.home.homeDirectory + "/redis";
    };
    Install.WantedBy = [ "default.target" ];
  };

}
