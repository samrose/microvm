{
  description = "NixOS in MicroVMs";

  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, microvm }:
    let
      system = "x86_64-linux";
    in {
      packages.${system} = {
        default = self.packages.${system}.my-microvm;
        my-microvm = self.nixosConfigurations.my-microvm.config.microvm.declaredRunner;
      };

      nixosConfigurations = {
        my-microvm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            microvm.nixosModules.microvm
            ({ pkgs, ... }: {
              networking.hostName = "my-microvm";
              users.users.root.password = "";

              # MediaWiki configuration
              services.mediawiki = {
                enable = true;
                name = "Sample_MediaWiki";
                httpd.virtualHost = {
                  hostName = "example.com";
                  adminAddr = "admin@example.com";
                };
                passwordFile = pkgs.writeText "password" "cardbotnine";
                extraConfig = ''
                  # Disable anonymous editing
                  $wgGroupPermissions['*']['edit'] = false;
                '';

                extensions = {
                  VisualEditor = null;

                  TemplateStyles = pkgs.fetchzip {
                    url = "https://extdist.wmflabs.org/dist/extensions/TemplateStyles-REL1_40-c639c7a.tar.gz";
                    hash = "sha256-YBL0Cs4hDSJBdLsv9zFWVkzo7m5osph8QiY=";
                  };
                };
              };

              microvm = {
                volumes = [ {
                  mountPoint = "/var";
                  image = "var.img";
                  size = 256;
                } ];
                shares = [ {
                  proto = "9p";
                  tag = "ro-store";
                  source = "/nix/store";
                  mountPoint = "/nix/.ro-store";
                } ];

                hypervisor = "qemu";
                socket = "control.socket";
              };
            })
          ];
        };
      };
    };
}
