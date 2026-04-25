#!/bin/bash
# Inizializza GNOME Keyring e assicura l'esportazione delle variabili

# Se il daemon è già stato avviato da PAM (comune su Fedora), 
# dobbiamo recuperare le variabili dall'ambiente o forzarne il rilevamento.
if [ -z "$GNOME_KEYRING_CONTROL" ]; then
    # Prova a recuperare le variabili da un'istanza esistente
    eval $(gnome-keyring-daemon --start --components=secrets,ssh)
fi

# Esporta le variabili per i processi figli dello script
export GNOME_KEYRING_CONTROL SSH_AUTH_SOCK

# CRUCIALE: Esporta le variabili al bus di sessione D-Bus e a Systemd User
# Senza questo, niri e le app (specie Flatpak) non troveranno il keyring.
if command -v dbus-update-activation-environment >/dev/null; then
    dbus-update-activation-environment --systemd GNOME_KEYRING_CONTROL SSH_AUTH_SOCK DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
fi

# Fallback aggiuntivo per systemd
systemctl --user import-environment GNOME_KEYRING_CONTROL SSH_AUTH_SOCK DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
