#!/bin/bash
# Inizializza GNOME Keyring e esporta le variabili alla sessione D-Bus e Systemd

# Avvia il daemon (se non già avviato da PAM/D-Bus) e cattura le variabili
eval $(gnome-keyring-daemon --start --components=secrets,ssh)

# Esporta le variabili importanti alla sessione utente
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SSH_AUTH_SOCK GNOME_KEYRING_CONTROL GNOME_KEYRING_PASSWORD

# Assicura che Nextcloud e altre app possano vedere le variabili
systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SSH_AUTH_SOCK GNOME_KEYRING_CONTROL
