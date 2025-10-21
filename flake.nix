{
  description = "A flake for building Overwitch";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = rec {
        overwitch = pkgs.stdenv.mkDerivation {

          name = "overwitch";

          src = pkgs.fetchzip {
            url = "https://github.com/dagargo/overwitch/releases/download/2.1/overwitch-2.1.tar.gz";
            hash = "sha256-LBDlfMEBuEZAROpou2tCQ4hDcGDVmxU5AUveKPORIYc=";
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            autoreconfHook
            wrapGAppsHook
          ];

          buildInputs = with pkgs; [
            libtool
            libusb1
            libjack2
            libsamplerate
            libsndfile
            gettext
            json-glib
            gtk4
          ];

          postInstall = ''
            # install udev/hwdb rules
            mkdir -p $out/etc/udev/rules.d/
            mkdir -p $out/etc/udev/hwdb.d/
            cp ./udev/*.hwdb $out/etc/udev/hwdb.d/
            cp ./udev/*.rules $out/etc/udev/rules.d/
          '';
        };
        default = overwitch;
      };

      #### Dev shell (for `nix develop`)
      devShells.default = pkgs.mkShell {
        inputsFrom = [ self.packages ];
      };

  }) // 
  {
      #### NixOS module (`programs.overwitch`)
      nixosModules.default = { config, lib, pkgs, ...}:
      let cfg = config.services.overwitch;
      in {
          options.services.overwitch = {
              enable = lib.mkEnableOption "Enables Overwitch";

	      dbus.enable = lib.mkOption {
	        type = lib.types.bool;
		default = true;
	        description = "Enables dbus service";
	      };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ self.packages.${pkgs.system}.overwitch ];
            services.udev.packages = [ self.packages.${pkgs.system}.overwitch ];
            services.dbus.packages = [ self.packages.${pkgs.system}.overwitch ];

	    systemd.services = {
	      overwitch-dbus = lib.mkIf cfg.dbus.enable {
	        description = "Overwitch D-Bus Service";
		serviceConfig = {
		  Type = "dbus";
		  BusName = "io.github.dagargo.OverwitchService";
		  ExecStart = "${cfg.package}/bin/overwitch-service";
		  Restart = "on-failure";
		};

		aliases = [ "io.github.dagargo.OverwitchService.service" ];
	      };
	    };

          };
        };
      };
}
