{ system, config, pkgs, lib, nicpkgs, transfersh, fvckbot, factorio-bot, ... }:

{
  home = {
    username = "phablet";
    homeDirectory = "/home/phablet";
    stateVersion = "21.11";

    packages = with pkgs; [
      nix htop curl wget nicpkgs.kakoune neofetch
      unar tmux aria2 file jq gnugrep pv less
      gcc
      man-pages man-pages-posix
      kitty.terminfo
      owncast
    ];
  };

  programs.home-manager.enable = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" "https://cache.nixos.org/" ];
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
    Service.ExecStart = "${pkgs.clash}/bin/clash -f ${./private/clash.yaml} -d ${config.home.homeDirectory}/.local/var/clash";
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
  #     ExecStart = "${fvckbot.defaultPackage.${system}}/bin/fvckbot";
  #     WorkingDirectory = "${config.home.homeDirectory + "/fvckbot"}";
  #     Environment = [
  #       "TG_BOT_TOKEN=${import ./private/fvckbot-token.nix}"
  #       "https_proxy=http://localhost:7890"
  #     ];
  #   };
  #   Install.WantedBy = [ "default.target" ];
  # };

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

  services.instaepub = {
    enable = true;
    output-dir = config.home.homeDirectory + "/www/instaepub";
    auto-archive = true;
    interval = "hourly";
    pandoc = nicpkgs.pandoc;
  } // import ./private/instaepub.nix;
  systemd.user.services.instaepub.Service.Environment = lib.mkMerge [ "https_proxy=http://localhost:7890" ];

  services.cloudflare-ddns = {
    enable = true;
    enable-log = true;
    log-path = "/tmp/cloudflare-ddns.log";
  } // import ./private/cloudflare-ddns.nix;

  systemd.user.services.aria2d = {
    Unit.Description = "Aria2 Daemon";
    Service = {
      ExecStart =
        let
          aria2 = nicpkgs.aria2.override ({
            server-mode = true;
            dir = config.home.homeDirectory + "/www/files";
          } // import ./private/aria2d.nix);
        in
        "${aria2}/bin/aria2c";
    };
    Install.WantedBy = [ "default.target" ];
  };

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

  systemd.user.services.matrix-qq = {
    Unit = {
      Description = "Mautrix Telegram Bridge";
      After = [ "synapse.service" ];
      PartOf = [ "synapse.service" ];
      Requires = [ "synapse.service" ];
    };
    Service = {
      ExecStart = "${nicpkgs.matrix-qq}/bin/matrix-qq";
      WorkingDirectory = "${config.home.homeDirectory + "/matrix-qq"}";
    };
    Install.WantedBy = [ "default.target" ];
  };

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

  systemd.user.services.factorio =
    let
      factorio = pkgs.stdenv.mkDerivation rec {
        pname = "factorio-headless";
        version = "1.1.100";
        src = pkgs.fetchurl {
          name = "factorio_headless_x64-${version}.tar.xz";
          url = "https://factorio.com/get-download/${version}/headless/linux64";
          sha256 = "sha256-mFDdFG+T7k2ougYxZZGIiGCkBYyFSECc37XdaTq82DQ=";
        };
        preferLocalBuild = true;
        dontBuild = true;
        installPhase = ''
          mkdir -p $out/{bin,share/factorio}
          cp -a data $out/share/factorio
          cp -a bin/x64/factorio $out/bin/factorio
          # patchelf \
          #   --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
          #   $out/bin/factorio
        '';
      };
      workingDir = config.home.homeDirectory + "/factorio";
      configFile = pkgs.writeText "factorio.conf" ''
        use-system-read-write-data-directories=true
        [path]
        read-data=${factorio}/share/factorio/data
        write-data=${workingDir}
      '';
    in {
      Unit = {
        Description = "Factorio Server";
      };
      Service = {
        ExecStart = toString [
          "${pkgs.box64}/bin/box64"
          "${factorio}/bin/factorio"
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
      ExecStart = "${factorio-bot.packages.${system}.default}/bin/midymidy-factorio-webservice";
      Restart = "always";
      Environment = import ./private/factorio-bot-env.nix ++ [
        "https_proxy=http://localhost:7890"
      ];
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

}
