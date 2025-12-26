{
  description = "Nix Flake: Build Overwitch ( JACK client for Overbridge devices)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        overwitch = pkgs.stdenv.mkDerivation rec {
          pname = "overwitch";
          version = "2.2";

          # ------------- Fetch sources -------------------------------------
          src = pkgs.fetchFromGitHub {
            owner = "dagargo";
            repo = "overwitch";
            rev = "refs/tags/${version}";
            sha256 = "sha256-EYT5m4N9kzeYaOcm1furGGxw1k+Bw+m+FvONVZN9ohk=";
          };

          # ------------- Build inputs --------------------------------------
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

          # ------------- Post‑install --------------------------------------
          postInstall = ''
            mkdir -p $out/etc/udev/rules.d
            mkdir -p $out/etc/udev/hwdb.d
            cp ${src}/udev/*.hwdb     $out/etc/udev/hwdb.d
            cp ${src}/udev/*.rules    $out/etc/udev/rules.d
          '';

          # ------------- Metadata ------------------------------------------------
          # meta = with pkgs.lib; {
          #   description = "Overwitch: JACK client for Overbridge devices";
          #   homepage = "https://github.com/dagargo/overwitch";
          #   license = licenses.gpl3Plus;
          #   maintainers = with maintainers; [ Are10 ];
          #   platforms = platforms.linux;
          # };
        };
      in
      {
        packages = {
          default = overwitch;
          overwitch = overwitch; # also exposed as `default`
        };

        # Development shell for this package
        devShells.default = pkgs.mkShell {
          # Bring in all build inputs of the package
          inputsFrom = [ pkgs ];
        };

        # Optionally, expose a per‑system defaultPackage
        defaultPackage = overwitch;
      }
    )
    // {
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
            enable = lib.mkEnableOption "Enable Overwitch";

            udev = lib.mkEnableOption "Install udev rules for Overwitch";

            dbus = lib.mkEnableOption "Enable D‑Bus activation for Overwitch";
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ self.packages.${pkgs.system}.overwitch ];

            services.udev.packages = lib.mkIf cfg.udev [
              self.packages.${pkgs.system}.overwitch
            ];

            services.dbus.packages = lib.mkIf cfg.dbus [
              self.packages.${pkgs.system}.overwitch
            ];
          };

          # meta = {
          #   description = "NixOS module to enable Overwitch";
          #   homepage = self.outputs.self.meta.homepage;
          # };
        };

      # A top‑level `defaultPackage` is optional.  If you supply one it
      # must not reference `${system}`.  One common pattern is to let each
      # system expose its own default via the per‑system `defaultPackage`
      # above, in which case you can simply omit a top‑level
      # `defaultPackage` altogether.
      #
      # If you really want a single default package regardless of the
      # system you build on, choose one explicitly, e.g.:
      #
      #   defaultPackage = self.packages.x86_64-linux.overwitch;
      #
      # (Replace `x86_64-linux` with the system that you want as the
      # default.)

      # Expose a default NixOS module
      nixosModule = self.nixosModules.default;
    };
}
