#!/bin/sh

# disable verification
sudo spctl --master-disable

# change hostname and sharing name
sudo scutil --set ComputerName "bawzmbp"
sudo scutil --set HostName "bawzmbp"
sudo scutil --set LocalHostName "bawzmbp"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "bawzmbp"

#/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# close any open system preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# disable notification center and remove the menu bar icon
launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

# disable transparency in the menu bar and elsewhere
defaults write com.apple.universalaccess reduceTransparency -bool true

# set highlight color to green
defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

# show scrollbars only when scrolling
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# disable the over-the-top focus ring animation
defaults write NSGlobalDomain NSUseAnimatedFocusRing -bool false

# increase window resize speed for cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# save to disk (not to icloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# disable the “are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# remove duplicates in the “open with” menu (also see `lscleanup` alias)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# disable resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# display ascii control characters using caret notation in standard text views
# try e.g. `cd /tmp; unidecode "\x{0000}" > cc.txt; open -e cc.txt`
defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

# disable smart dashes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# disable automatic period substitution as it’s annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# disable smart quotes as they’re annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# enable subpixel font rendering on non-apple lcds
# reference: https://github.com/kevinsuttle/macos-defaults/issues/17#issuecomment-266633501
defaults write NSGlobalDomain AppleFontSmoothing -int 1

# finder: allow quitting via ⌘ + q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# finder: disable window animations and get info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# when performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# avoid creating .ds_store files on network or usb volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# automatically open a new finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# use list view in all finder windows by default
# four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# disable the warning before emptying the trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# enable airdrop over ethernet and on unsupported macs running lion
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Expand the following File Info panes:
# “General”, “Open with”, and “Sharing & Permissions”
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true




# add font tap to brew cask
brew tap homebrew/cask-fonts

# default packages
brew install \
  tmux \
  neovim \
  asdf \
  ansible \
  awscli \
  go-task/tap/go-task \
  grep \
  jq \
  jd \
  git \
  krew \
  pass \
  neomutt \
  isync \
  notmuch \
  screen \
  ranger \
  htop \
  gpg
# to start isync as service run 'brew services start isync'

# brew cask
brew cask install \
  alacritty \
  brave-browser \
  spotify \
  karabiner-elements \
  discord \
  steermouse \
  vscodium \
  microsoft-teams \
  keepassxc \
  1password \
  docker

# install dmenu port and disable spotlight
brew cask install \
  dmenu-mac
# to turn off spotlight, follow https://www.fireebok.com/resource/how-to-turn-off-and-turn-on-spotlight-on-macos-mojave.html

# fonts
brew cask install \
  font-terminus \
  font-hack

# spotify with terminal client
brew install \
  portaudio \
  spotifyd \
  spotify-tui
# start with brew services start spotifyd
# init gpg key with 'gpg --full-gen-key'
# store password with 'pass insert spotify'

# install wm and hotkey manager
brew install \
    koekeishiya/formulae/skhd \
    koekeishiya/formulae/yabai
brew services start yabai
brew services start skhd
brew update
brew services restart --all

# install k8s tools via asdf
asdf plugin add 1password
asdf plugin add bat
asdf plugin add eksctl
asdf plugin add helm
asdf plugin add helm-cr
asdf plugin add helm-docs
asdf plugin add helmfile
asdf plugin add k3d
asdf plugin add k9s
asdf plugin add kubectl
asdf plugin add kubectx
asdf plugin add kubeseal
asdf plugin add terraform
asdf plugin add terraform-docs
asdf plugin add terraform-lsp
asdf plugin add terraform-validator

# fix insecure directory problem
sudo chmod -R 755 /usr/local/share/zsh
sudo chown -R $(whoami):staff /usr/local/share/zsh
