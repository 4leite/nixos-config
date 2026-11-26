{ pkgs, ... }:
{
  users.users."4leite-bot" = {
    isNormalUser = true;
    hashedPassword = "!";
    packages = [ pkgs.codex ];
  };
}
