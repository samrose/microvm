{
  description = "NixOS in MicroVMs";

  inputs.microvm.url = "github:astro/microvm.nix";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, microvm }:
    let
      system = "x86_64-linux";
    in
    {
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
              networking = {
                hostName = "my-microvm";
                firewall = {
                  enable = true;
                  allowedTCPPorts = [ 8011 ]; # Changed to 8011
                };
              };

              users.users.root.password = "";

              # Basic Apache config
              services.httpd = {
                enable = true;
                enablePHP = true;
                adminAddr = "admin@example.com";
              };

              # MediaWiki configuration
              services.mediawiki = {
                enable = true;
                name = "Sample_MediaWiki";
                database = {
                  type = "postgres";
                  createLocally = true;
                  name = "mediawiki";
                  user = "mediawiki";
                };
                httpd.virtualHost = {
                  hostName = "_";
                  serverAliases = [ "localhost" "127.0.0.1" "10.0.2.15" ];
                  adminAddr = "admin@example.com";
                  listen = [{
                    ip = "0.0.0.0";
                    port = 8011; # Changed to 8011
                  }];
                };
                passwordFile = pkgs.writeText "password" "cardbotnine";
                extraConfig = ''
                  # Disable anonymous editing
                  $wgGroupPermissions['*']['edit'] = false;
                  # Set the server URLs
                  $wgServer = "http://127.0.0.1:8011";
                  $wgCanonicalServer = "http://127.0.0.1:8011";
                '';

                extensions = {
                  VisualEditor = null;
                };
              };

              microvm = {
                mem = 2048;
                volumes = [{
                  mountPoint = "/var";
                  image = "var.img";
                  size = 2048;
                }];
                shares = [{
                  proto = "9p";
                  tag = "ro-store";
                  source = "/nix/store";
                  mountPoint = "/nix/.ro-store";
                }];

                hypervisor = "qemu";
                socket = "control.socket";
                interfaces = [
                  {
                    type = "user";
                    id = "default";
                    mac = "02:00:00:00:00:01";
                  }
                ];

                forwardPorts = [
                  {
                    from = "host";
                    guest.address = "10.0.2.15";
                    guest.port = 8011; # Changed to 8011
                    host.address = "127.0.0.1";
                    host.port = 8011;
                  }
                ];
              };

              # Set state version to avoid warning
              system.stateVersion = "23.11";
            })
          ];
        };
      };
    };
}
