import { defineConfig } from '@eunjae/dots';

// Array format allows precise ordering of steps
export default defineConfig([
	// First: set global workspacePath and clone repos
	{
		workspacePath: "~/workspace",
		repos: [{ url: "git@github.com:eunjae-lee/dotfiles.git" }],
	},

	// Second: install oh-my-zsh (before symlinks that depend on it)
	{
		shell: [
			{
				name: "Install oh-my-zsh",
				command:
					'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"',
				unless: "test -d ~/.oh-my-zsh",
			},
		],
	},

	// Third: install zsh plugins and themes
	{
		shell: [
			{
				name: "Clone spaceship theme",
				command:
					'git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt"',
				unless: 'test -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt"',
			},
			{
				name: "Symlink spaceship theme",
				command:
					'ln -s "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"',
				unless: 'test -L "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"',
			},
			{
				name: "Clone zsh-z plugin",
				command:
					"git clone https://github.com/agkozak/zsh-z $HOME/.oh-my-zsh/custom/plugins/zsh-z",
				unless: 'test -d "$HOME/.oh-my-zsh/custom/plugins/zsh-z"',
			},
		],
	},

	// Fourth: install packages
	{
		brew: [
			"git",
			"gh",
			"jq",
			"fzf",
			"mise",
			"ast-grep",
			"ripgrep",
			"lazygit",
			"zellij",
			"wget",
			"m-cli",
			"switchaudio-osx",
			"ffmpeg",
			"imagemagick",
			"libheif",
		],
		brewCask: [
			// Editors & Dev tools
			"visual-studio-code",
			"zed",
			"iterm2",
			"ghostty",
			"fork",
			"docker",
			// Browsers
			"firefox",
			"google-chrome",
			"google-chrome@canary",
			// Communication
			"slack",
			"discord",
			"telegram",
			"whatsapp",
			// Productivity
			"1password",
			"raycast",
			"notion",
			"input-source-pro",
			"jordanbaird-ice",
			// Media
			"spotify",
			"iina",
			"handbrake",
			// Fonts
			"font-geist-mono",
			"font-geist-mono-nerd-font",
			"font-jetbrains-mono",
			"font-jetbrains-mono-nerd-font",
			"font-roboto",
			"font-spectral",
			"font-noto-sans-cjk",
			"font-cascadia-code",
			"font-cascadia-code-pl",
			"font-cascadia-mono",
			"font-cascadia-mono-pl",
			"font-monaspace",
			"font-fira-code",
			// Quick Look plugins
			"qlmarkdown",
		],
		mas: [
			904280696, // Things 3
			869223134, // KakaoTalk
			639968404, // Parcel
			1453273600, // Data Jar
			1604176982, // One Thing
			6450279539, // Second Clock
			1607635845, // Velja
			1586435171, // Actions
		],
	},

	// Fifth: symlink config files (after packages are installed)
	{
		symlinks: [
			{ src: "~/workspace/dotfiles/.zshrc", dest: "~/.zshrc", force: true },
			{ src: "~/workspace/dotfiles/.zprofile", dest: "~/.zprofile", force: true },
			{ src: "~/workspace/dotfiles/.gitconfig", dest: "~/.gitconfig" },
			{
				src: "~/workspace/dotfiles/.gitignore_global",
				dest: "~/.gitignore_global",
				force: true,
			},
			{
				src: "~/workspace/dotfiles/app-configs/raycast-scripts",
				dest: "~/workspace/raycast-scripts",
			},
			{
				src: "~/workspace/dotfiles/app-configs/lazygit/config.yml",
				dest: "~/Library/Application Support/lazygit/config.yml",
				force: true,
			},
			{
				src: "~/workspace/dotfiles/app-configs/zed/settings.json",
				dest: "~/.config/zed/settings.json",
				force: true,
			},
			{
				src: "~/workspace/dotfiles/app-configs/zed/tasks.json",
				dest: "~/.config/zed/tasks.json",
				force: true,
			},
			{
				src: "~/workspace/dotfiles/app-configs/zed/keymap.json",
				dest: "~/.config/zed/keymap.json",
				force: true,
			},
			{
				src: "~/workspace/dotfiles/app-configs/zsh/plugins/auto-notify",
				dest: "~/.oh-my-zsh/custom/plugins/auto-notify",
				force: true,
			},
			{
				src: "~/workspace/dotfiles/app-configs/ghostty/config",
				dest: "~/Library/Application Support/com.mitchellh.ghostty/config",
			},
			{
				src: "~/workspace/dotfiles/app-configs/mise.toml",
				dest: "~/.config/mise/config.toml",
				force: true,
			},
		],
	},

	// Sixth: configure mise (after brew installs it)
	{
		shell: [
			{
				name: "Install node via mise",
				command: "mise use --global node@22",
				unless: "mise list node | grep -q 22",
			},
			{
				name: "Install pnpm via mise",
				command: "mise use --global pnpm@9",
				unless: "mise list pnpm | grep -q 9",
			},
			{
				name: "Install python via mise",
				command: "mise use --global python@3.11.3",
				unless: "mise list python | grep -q 3.11.3",
			},
		],
	},

	// Seventh: global npm packages
	{
		shell: [
			{
				name: "Install one-thing CLI",
				command: "npm install -g one-thing",
				unless: "npm list -g one-thing 2>/dev/null | grep -q one-thing",
			},
		],
	},
]);
