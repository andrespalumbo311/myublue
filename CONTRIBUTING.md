# AI Contribution Guidelines

Questo repository ha una struttura rigida basata su Fedora Atomic e build di container. Ogni agente AI che interagisce con questo codice **deve** seguire queste regole per evitare di rompere la pipeline di build.

## Regole Operative Mandatorie
1. **Verifica Documentazione:** Prima di ogni azione, leggi questo file e la tabella "Errori Storici e Prevenzione".
2. **Auto-Aggiornamento:** Se commetti un errore che causa il fallimento della build, dopo aver applicato il fix, **devi obbligatoriamente** aggiornare la tabella in questo file con la descrizione dell'errore e come evitarlo in futuro.
3. **Integrità del Filesystem:** Git non traccia cartelle vuote. Se elimini l'ultimo file da una cartella presente nel `Containerfile` (es. `etc/`, `usr/`), devi creare un file `.keep` per non far sparire la directory.

## Errori Storici e Prevenzione

| Errore Commesso | Causa Tecnica | Azione Preventiva / Soluzione |
| :--- | :--- | :--- |
| **Rimozione cartelle vitali** | Eliminando l'ultimo file in `usr/`, la cartella è sparita da Git, facendo fallire il comando `COPY usr /usr` nel Containerfile. | Se una cartella deve restare nel repo ma è vuota, aggiungi un file `.keep`. |
| **Pacchetti inesistenti** | Tentativo di installare pacchetti nel Containerfile con nomi errati o non presenti nei repo Fedora. | **Prima** di aggiungere un pacchetto al Containerfile, verifica la sua esistenza tramite `dnf search` o sui repository ufficiali Fedora. |
| **Mancato riconoscimento Browser** | Helium non si impostava come predefinito perché cercava un file `.desktop` con nome specifico non presente nel sandbox. | Non creare duplicati in `/usr/share/applications`. Usa `tmpfiles.d` per creare link simbolici che puntino ai file esportati da Flatpak. |

## Verifica Pacchetti (Workflow consigliato)
Prima di modificare il `Containerfile`, l'agente deve simulare o verificare i nomi dei pacchetti:
- Controllare se il pacchetto è disponibile per la versione di Fedora target.
- Verificare se richiede repository COPR specifici già presenti o da aggiungere.
