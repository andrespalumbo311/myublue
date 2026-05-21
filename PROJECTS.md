# Progetti Futuri e Roadmap

Questo file tiene traccia delle evoluzioni pianificate per l'immagine OS, con l'obiettivo di aumentare la sovranità tecnologica, la sicurezza e l'automazione.

## 1. Sovranità dei Pacchetti (Source Sovereignty)
L'obiettivo è ridurre drasticamente la dipendenza da repository COPR personali o di terze parti, preferendo l'acquisizione diretta dalle fonti ufficiali.

- [ ] **Utility Rust nello Stage Builder**: Spostare l'acquisizione di `sudo-rs`, `uutils-coreutils`, `niri` e `dms` dai COPR direttamente ai repository GitHub ufficiali.
    - Utilizzare lo stage `builder` per scaricare i binari dalle "Releases" o compilarli.
    - Implementare la verifica dei checksum (SHA256) per ogni binario scaricato.
- [ ] **Migrazione Kernel CachyOS**: Passare dai COPR personali al repository ufficiale gestito dal team di CachyOS (se disponibile per Fedora) o automatizzare il monitoraggio delle versioni ufficiali.

## 2. Automazione e Aggiornamenti
- [ ] **Integrazione Renovate Avanzata**: Configurare Renovate per monitorare non solo i container, ma anche le versioni dei binari GitHub definiti nello stage builder.
- [ ] **Build Condizionali**: Implementare controlli che triggerano la build solo se ci sono nuovi rilasci "upstream" (kernel o utility critiche), ottimizzando l'uso delle risorse GitHub Actions.

## 3. Ottimizzazioni e Sicurezza
- [ ] **Minimal Image**: Analizzare ulteriormente i pacchetti installati per rimuovere dipendenze legacy ereditate dall'immagine base Fedora, puntando a un'immagine ancora più snella e performante.

## 4. Evoluzione Scheduler eBPF (sched-ext)
L'obiettivo è standardizzare la gestione degli scheduler eBPF e fornire un'interfaccia utente per il controllo granulare delle performance.

- [ ] **Transizione a `scx_loader`**: Sostituire lo script personalizzato `scx-launcher.sh` con `scx_loader`.
    - `scx_loader` è il modo standard e raccomandato per caricare e gestire gli scheduler eBPF.
    - Semplifica la gestione delle configurazioni e permette l'integrazione nativa con tool esterni.
- [ ] **Integrazione SCX Manager**: Implementare l'interfaccia grafica di CachyOS per la gestione degli scheduler.
    - Aggiungere le dipendenze Python/Qt necessarie (`python3-pyqt6`, `python3-setuptools`).
    - Configurare le regole Polkit per permettere l'attivazione/disattivazione degli scheduler senza password (opzionale).
    - Creare la Desktop Entry per l'integrazione nel launcher di Niri.
