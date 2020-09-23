#!/bin/sh

# a full list of all possible defaultscommands can be found here
# https://ss64.com/osx/syntax-defaults.html
# for a full list of all options run 'defaults read | less'

# disable app verification
sudo spctl --master-disable

# change hostname and sharing name
sudo scutil --set ComputerName "bawzmbp"
sudo scutil --set HostName "bawzmbp"
sudo scutil --set LocalHostName "bawzmbp"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "bawzmbp"

# close any open system preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

# ask for the administrator password upfront
sudo -v

# keep-alive: update existing `sudo` time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# set the timezone; see `sudo systemsetup -listtimezones` for other values
sudo systemsetup -settimezone "Europe/Berlin" > /dev/null

# disable notification center and remove the menu bar icon
launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

# disable annoying apple spell correction and cloud save features
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# set fn state to enable usage of F1,..,FX keys without hitting fn first
defaults write com.apple.keyboard.fnState -bool true

# increase sound quality for bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# do not automatically pair with bluetoot audio devices
sudo defaults write /Library/Preferences/com.apple.Bluetooth.plist DontPageAudioDevices 1
# this is for specific bluetooth devices
#sudo defaults write /Library/Preferences/com.apple.Bluetooth.plist IgnoredDevices -array-add '<MAC ADDRESS>'
# you can get the mac address via device cache
#sudo defaults read /Library/Preferences/com.apple.Bluetooth.plist DeviceCache

# disable font smoothing (use only for non hidpi displays)
defaults write -g CGFontRenderingFontSmoothingDisabled -bool NO

# adjust font smoothing (possible values: 1=medium,2=medium,3=strong)
#defaults -currentHost write -globalDomain AppleFontSmoothing -int 1

# disable transparency in the menu bar and elsewhere
defaults write com.apple.universalaccess reduceTransparency -bool true

# reduce motion to speed up space switching
defaults write com.apple.universalaccess reduceMotionEnabled -bool true
defaults write com.apple.Accessibility ReduceMotionEnabled -bool true

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

# enable hidpi display modes (requires restart)
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

# finder: allow quitting via ⌘ + q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# hide desktop icons (still accessible via ~/Desktop folder)
defaults write com.apple.finder CreateDesktop -bool false

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

# change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "scale"

# minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# wipe all (default) app icons from the dock
# This is only really useful when setting up a new Mac, or if you don’t use
# the dock to launch apps.
defaults write com.apple.dock persistent-apps -array

# speed up mission control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# don’t show dashboard as a space
defaults write com.apple.dock dashboard-in-overlay -bool true

# don’t automatically rearrange spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# remove the auto-hiding dock delay
defaults write com.apple.dock autohide-delay -float 0
# remove the animation when hiding/showing the dock
defaults write com.apple.dock autohide-time-modifier -float 0

# automatically hide and show the dock
defaults write com.apple.dock autohide -bool true

# make dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# privacy: don’t send search queries to apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# show the full url in the address bar (note: this still hides the scheme)
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# set safari’s home page to `about:blank` for faster loading
defaults write com.apple.Safari HomePage -string "about:blank"

# prevent safari from opening ‘safe’ files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# allow hitting the backspace key to go to the previous page in history
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

# hide safari’s bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool false

# hide safari’s sidebar in top sites
defaults write com.apple.Safari ShowSidebarInTopSites -bool false

# disable safari’s thumbnail cache for history and top sites
defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

# enable safari’s debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# make safari’s search banners default to contains instead of starts with
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

# remove useless icons from safari’s bookmarks bar
defaults write com.apple.Safari ProxiesInBookmarksBar "()"

# enable the develop menu and the web inspector in safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# add a context menu item for showing the web inspector in web views
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# disable continuous spellchecking
defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool false
# disable auto-correct
defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false

# update extensions automatically
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

# warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# disable plug-ins
defaults write com.apple.Safari WebKitPluginsEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled -bool false

# disable java
defaults write com.apple.Safari WebKitJavaEnabled -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false

# block pop-up windows
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false

# disable auto-playing video
defaults write com.apple.Safari WebKitMediaPlaybackAllowsInline -bool false
defaults write com.apple.SafariTechnologyPreview WebKitMediaPlaybackAllowsInline -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2AllowsInlineMediaPlayback -bool false
defaults write com.apple.SafariTechnologyPreview com.apple.Safari.ContentPageGroupIdentifier.WebKit2AllowsInlineMediaPlayback -bool false

# disable mail inline attachments (just show the icons)
defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

# disable mail automatic spell checking
defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

# spotlight: only search in applications and system preferences
defaults write com.apple.spotlight orderedItems -array \
  '{"enabled" = 1;"name" = "APPLICATIONS";}' \
  '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
  '{"enabled" = 0;"name" = "DIRECTORIES";}' \
  '{"enabled" = 0;"name" = "PDF";}' \
  '{"enabled" = 0;"name" = "FONTS";}' \
  '{"enabled" = 0;"name" = "DOCUMENTS";}' \
  '{"enabled" = 0;"name" = "MESSAGES";}' \
  '{"enabled" = 0;"name" = "CONTACT";}' \
  '{"enabled" = 0;"name" = "EVENT_TODO";}' \
  '{"enabled" = 0;"name" = "IMAGES";}' \
  '{"enabled" = 0;"name" = "BOOKMARKS";}' \
  '{"enabled" = 0;"name" = "MUSIC";}' \
  '{"enabled" = 0;"name" = "MOVIES";}' \
  '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
  '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
  '{"enabled" = 0;"name" = "SOURCE";}' \
  '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
  '{"enabled" = 0;"name" = "MENU_OTHER";}' \
  '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
  '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
  '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
  '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'
# Load new settings before rebuilding the index
killall mds > /dev/null 2>&1
# Make sure indexing is enabled for the main volume
sudo mdutil -i on / > /dev/null
# rebuild the index from scratch
sudo mdutil -E / > /dev/null

# iterm don’t display the annoying prompt when quitting iterm
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# prevent time machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# disable time machine backups
hash tmutil &> /dev/null && sudo tmutil disable

# show the main window when launching activity monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# visualize cpu usage in the activity monitor dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# show all processes in activity monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# sort activity monitor results by cpu usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# open and save files as utf-8 in textedit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# enable the debug menu in disk utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# always show ~/Library folder
chflags nohidden ~/Library/

# keyboard shortcuts
#addEntries() {
    ## check if universal access / custom menu key exists
    #if defaults read com.apple.universalaccess com.apple.custommenu.apps > /dev/null 2>&1; then
        #defaults delete com.apple.universalaccess com.apple.custommenu.apps
    #fi
    #defaults write com.apple.universalaccess com.apple.custommenu.apps -array

    ## write all apps to custommenu
    #defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add $(echo -e "$appList")
    #echo "All apps with custom shortcuts:"
    #defaults read com.apple.universalaccess com.apple.custommenu.apps
#}

# get the bundleid for each app
#get_BundleId(){
    #mdls -raw -name kMDItemCFBundleIdentifier "$1"
#}

## keyboard shortcuts
# TODO: find list with all system shortcuts to modify
# TODO: change outlook hotkeys to enable movement by h,j,k,l
#createKeyboardShortcuts(){
    ## improve readability
    #app=""
    #appList=""
    #CMD="@"
    #CTRL="^"
    #OPT="~"
    #SHIFT="$"
    #UP='\U2191'
    #DOWN='\U2193'
    #LEFT='\U2190'
    #RIGHT='\U2192'
    #TAB='\U21e5'

    ## Global
    #defaults write NSGlobalDomain NSUserKeyEquivalents "{
        #'About This Mac' = '${CMD}${SHIFT}${OPT}A';
    #}"

    # Finder
    #app=/System/Library/CoreServices/Finder.app
    #if [ -a "$app" ]; then
        #bundleid=$(get_BundleId "$app")
        #echo "Adding: $app $bundleid"
        #appList+="$bundleid\n"
        #defaults write "$bundleid" NSUserKeyEquivalents "{
            #'Show Package Contents' = '${CMD}${SHIFT}O';
            #'Show Next Tab' = '${CMD}${RIGHT}';
            #'Show Previous Tab' = '${CMD}${LEFT}';
            #'Screenshots' = '${CMD}${SHIFT}S';
            #'Downloads' = '${CMD}${SHIFT}D';
        #}"
        #defaults read "$bundleid" NSUserKeyEquivalents
        #echo
    #fi

    # iTerm2
    #app=$HOME/Applications/iTerm.app
    #if [ -a "$app" ]; then
        #bundleid=$(get_BundleId "$app")
        #echo "Adding: $app"
        #appList+="$bundleid\n"
        #defaults write "$bundleid" NSUserKeyEquivalents "{
            #'Copy with Styles' = '${CMD}C';
            #'Find Cursor' = '${CMD}${OPT}/';
            #'Select Previous Tab' = '${CMD}${LEFT}';
            #'Select Next Tab' = '${CMD}${RIGHT}';
            #'Move Tab Left' = '${CMD}${SHIFT}${LEFT}';
            #'Move Tab Right' = '${CMD}${SHIFT}${RIGHT}';
            #'Look Up in Dash' = '${CMD}L';
        #}"
        #defaults read "$bundleid" NSUserKeyEquivalents
        #echo
    #fi
#}

# finally add those shortcuts
#createKeyboardShortcuts
#addEntries

# restart all changed applications
for app in "Activity Monitor" \
  "Address Book" \
  "Calendar" \
  "cfprefsd" \
  "Contacts" \
  "Dock" \
  "Finder" \
  "Mail" \
  "Messages" \
  "Photos" \
  "Safari" \
  "SystemUIServer" \
  "Terminal" \
  "iCal"; do
  killall "${app}" &> /dev/null
done
