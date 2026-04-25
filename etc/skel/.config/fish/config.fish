if status is-interactive
    # Inizializzazione Starship
    starship init fish | source

    # Inizializzazione Zoxide
    zoxide init fish | source

    # Inizializzazione FZF
    fzf --fish | source

    # Aliases
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -lAh'
    alias ..='cd ..'
    alias ...='cd ../..'

    # Integrazione VTE (per tracking directory nel terminale)
    if test -f /etc/profile.d/vte.sh
        bass source /etc/profile.d/vte.sh
    end
end
