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
- [ ] **MOK Key Rotation**: Definire una procedura per la rotazione periodica delle chiavi MOK per il Secure Boot.
- [ ] **Minimal Image**: Analizzare ulteriormente i pacchetti installati per rimuovere dipendenze legacy ereditate dall'immagine base Fedora, puntando a un'immagine ancora più snella e performante.
