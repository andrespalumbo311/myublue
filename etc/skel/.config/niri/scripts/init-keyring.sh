#!/bin/bash
# Inizializza GNOME Keyring e esporta le variabili alla sessione D-Bus e Systemd

# Avvia il daemon o recupera i dati da quello esistente
# Usiamo --replace per assicurarci di avere un'istanza pulita sotto il nostro controllo
# se PAM ha fallito o ha lasciato uno stato inconsistente.
eval $(gnome-keyring-daemon --start --components=secrets,ssh)

# Esporta le variabili all'ambiente della sessione
export GNOME_KEYRING_CONTROL SSH_AUTH_SOCK

# Aggiorna D-Bus e Systemd
if command -v dbus-update-activation-environment >/dev/null; then
    dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GNOME_KEYRING_CONTROL SSH_AUTH_SOCK
fi

# Fallback per systemd se dbus-update fallisce parzialmente
systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GNOME_KEYRING_CONTROL SSH_AUTH_SOCK
