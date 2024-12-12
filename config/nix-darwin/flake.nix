{
  description = "Khangal nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nixpkgs }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.tmux pkgs.eza pkgs.bat pkgs.jq pkgs.lazydocker pkgs.aerospace pkgs.mkalias pkgs.k9s 
          pkgs.mise pkgs.fzf pkgs.ripgrep pkgs.htop pkgs.rcm pkgs.yazi
        ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
    homeconfig = { config, pkgs, ... }:
	{
	  # Home Manager needs a bit of information about you and the paths it should
	  # manage.

	  # This value determines the Home Manager release that your configuration is
	  # compatible with. This helps avoid breakage when a new Home Manager release
	  # introduces backwards incompatible changes.
	  #
	  # You should not change this value, even if you update Home Manager. If you do
	  # want to update the value, then make sure to first check the Home Manager
	  # release notes.
	  home.stateVersion = "23.05"; # Please read the comment before changing.

	  # The home.packages option allows you to install Nix packages into your
	  # environment.
	  home.packages = [
	    # # Adds the 'hello' command to your environment. It prints a friendly
	    # # "Hello, world!" when run.
	    # pkgs.hello

	    # # It is sometimes useful to fine-tune packages, for example, by applying
	    # # overrides. You can do that directly here, just don't forget the
	    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
	    # # fonts?
	    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

	    # # You can also create simple shell scripts directly inside your
	    # # configuration. For example, this adds a command 'my-hello' to your
	    # # environment:
	    # (pkgs.writeShellScriptBin "my-hello" ''
	    #   echo "Hello, ${config.home.username}!"
	    # '')
	  ];

	  # Home Manager is pretty good at managing dotfiles. The primary way to manage
	  # plain files is through 'home.file'.
	  home.file = {
	    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
	    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
	    # # symlink to the Nix store copy.
	    # ".screenrc".source = dotfiles/screenrc;

	    # # You can also set the file content immediately.
	    # ".gradle/gradle.properties".text = ''
	    #   org.gradle.console=verbose
	    #   org.gradle.daemon.idletimeout=3600000
	    # '';
	  };

	  # You can also manage environment variables but you will have to manually
	  # source
	  #
	  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
	  #
	  # or
	  #
	  #  /etc/profiles/per-user/davish/etc/profile.d/hm-session-vars.sh
	  #
	  # if you don't want to manage your shell through Home Manager.
	  home.sessionVariables = {
	    TEST_ENV = "emacs";
	  };

	  # Let Home Manager install and manage itself.
	  programs.home-manager.enable = true;
	};
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#appurunoMac-mini
    darwinConfigurations."appurunoMac-mini" = nix-darwin.lib.darwinSystem {
      modules = [ configuration home-manager.darwinModules.home-manager {
        users.users.khangal.home = "/Users/khangal";
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.khangal = homeconfig;
      } ];
    };
  };
}
