{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  # Define the bambam user account (used for the dedicated Bambam session).
  users.users.bambam = {
    isNormalUser = true;
    description = "Bambam session user";
    createHome = true;
    # Minimal groups: only the ones needed for audio/video devices.
    # Removed `wheel` and `networkmanager` to tighten security for this
    # passwordless account.
    extraGroups = [
      "audio"
      "video"
    ];
    # Leave the account with an empty password so the greeter can log in
    # without a password when allowed by PAM (gdm-password service).
    password = "";
    # Explicitly ensure no SSH keys are installed for this account so it
    # cannot be used to SSH in even if other services change. SSH logins
    # with an empty password are disabled by default for the SSH PAM
    # service; this makes the intent explicit.
    openssh.authorizedKeys.keys = [ ];

    packages = with pkgs; [ ];
  };

}
