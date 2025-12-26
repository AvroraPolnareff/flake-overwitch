# Nixos Flake for Dagargo's Overwitch

For more information about Overwitch:
- https://github.com/dagargo/overwitch

This Nixos Flake fetches the (hopefully) latest release of Dagargo's repo.
Compiles from source, adds the udev rules for the Elektron machines, and registers a dbus service.

For more information on the dbus service, see https://github.com/dagargo/overwitch/issues/78

A devShell is also provided.


Based on the nixpkgs work done by https://github.com/dag-h

# Usage:
Include this flake in your `flake.nix` inputs: 
```
  inputs.overwitch = {
    url = "github:Are10/flake-overwitch/dbus";
    inputs.nixpkgs.follows = "nixpkgs";
  };
```
add the nixos module to your modules:
```
  modules = [
    inputs.overwitch.nixosModules.default
  ];
```
And then enable it in (for example) `configuration.nix`
```   
services.overwitch = {
  enable = true;
  dbus = true;
  udev = true;
}; 
```

