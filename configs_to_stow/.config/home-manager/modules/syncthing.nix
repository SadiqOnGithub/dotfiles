{ ... }:

{
  # Pair the Android app and share folders in http://127.0.0.1:8384.
  # Keep GUI-added devices/folders across home-manager rebuilds.
  services.syncthing = {
    enable = true;
    overrideDevices = false;
    overrideFolders = false;
    guiAddress = "127.0.0.1:8384";
    settings.options.urAccepted = -1;
  };
}
