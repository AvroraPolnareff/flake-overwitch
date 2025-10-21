{
  description = "A flake for building Overwitch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = rec {
          overwitch = pkgs.stdenv.mkDerivation {

            name = "overwitch";

            src = builtins.fetchGit {
	      url = "https://github.com/dagargo/overwitch";
	      ref = "refs/tags/2.1.1";
	      rev = "230a05255adb6c656b432b7a2eb3be899072c56e";
            };

            nativeBuildInputs = with pkgs; [
              pkg-config
              autoreconfHook
              wrapGAppsHook3
            ];

            buildInputs = with pkgs; [
              libtool
              libusb1
              libjack2
              libsamplerate
              libsndfile
              systemd
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

      }
    )
    // {
      #### NixOS module (`programs.overwitch`)
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.services.overwitch;
        in
        {
          options.services.overwitch = {
            enable = lib.mkEnableOption "Enables Overwitch";
          };

          config = lib.mkIf cfg.enable {

            # Actually install the package
            environment.systemPackages = [ self.packages.${pkgs.system}.overwitch ];

            # Install the udev hwdb and rules
            services.udev.packages = [ self.packages.${pkgs.system}.overwitch ];

            # DBus activation has replaced systemd (user) service
            services.dbus.packages = [ self.packages.${pkgs.system}.overwitch ];

          };
        };
    };
}
