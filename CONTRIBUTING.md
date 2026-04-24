# AI Contribution Guidelines

This repository has a rigid structure based on Fedora Atomic and containerized builds. Any AI agent interacting with this codebase **must** adhere to these rules to avoid breaking the build pipeline.

## Mandatory Operational Rules
1. **Verify Documentation:** Before taking any action, read this file and the "Historical Errors & Prevention" table.
2. **Self-Update:** If you commit an error (whether it causes a build failure or a runtime issue), after applying the fix, you **must** update the table in this file with the error description and how to avoid it in the future.
3. **Technical Abstraction:** Errors must be documented in a **general and abstract form**. Do not limit the description to the specific instance (e.g., "Error with Valent"); instead, describe the underlying technical logic (e.g., "Flatpak remote metadata caching on atomic systems") so the solution acts as a reusable architectural pattern for similar scenarios.
4. **Live Session Validation:** For any changes affecting graphical sessions, portals, or user-level services, the agent **must** perform live validation (e.g., using `busctl`, `systemctl --user`, or `gsettings`) to confirm the backend is active and exposing the correct interfaces *before* committing.

## Historical Errors & Prevention

| Error Class / Technical Challenge | Root Cause (Abstract) | Preventive Action / Architectural Pattern |
| :--- | :--- | :--- |
| **Vital Directory Persistence** | Git does not track empty directories; deleting the last file in a mapped directory (like `usr/` or `etc/`) breaks `COPY` instructions in build files. | Always maintain a `.keep` file in directories that must persist in the repository structure. |
| **Package Namespace Validation** | Using incorrect or non-existent package names in the build manifest causes pipeline failure. | Verify package existence in the target distribution's official repositories or enabled COPRs before modification. |
| **Application ID Mismatch** | Linking or configuring services using assumed Application IDs or generic names (e.g., `helium.desktop`) instead of verified Flatpak IDs (e.g., `net.imput.helium.desktop`) causes identity crises in MimeType handlers and Portals. | **Always** align symlinks, `mimeapps.list` entries, and desktop integrations with the official Flatpak ID to ensure proper application discovery. |
| **Flatpak Remote Persistence & Indexing** | In atomic systems, simply adding a remote configuration file may not trigger metadata indexing, leaving the repository "empty" in the UI. | Use a hybrid approach: add the `.flatpakrepo` file to `etc/` **and** run `remote-add` + `update --appstream` during the build to warm the cache. |
| **Third-Party Repository Validation** | Relying on unverified URLs or corrupted GPG keys for external repositories causes build-time or synchronization failures. | Always verify raw repository configuration files and check URL accessibility (e.g., via `curl -I`) before integration. |
| **Plugin Dependency Resolution** | Software plugins often depend on low-level CLI utilities that are not included in minimal base images. | Audit plugin source code or documentation to identify and explicitly install all required system-level CLI dependencies in the build manifest. |
| **Configuration Include Integrity** | Modular configuration files (e.g., KDL, YAML) that use `include` statements will fail to load if any referenced path is missing. | Ensure all included configuration fragments exist in the repository, using empty placeholder files if necessary to maintain structural integrity. |
| **Atomic System GPG Keyring Constraints** | Initializing a remote via URL during build may fail if the GPG key is not yet trusted by the transient build-time keyring. | Point the initialization command to a local `.flatpakrepo` file that already contains the GPG key to ensure atomic import and trust. |
| **Missing Remote Desktop Backend** | Il controllo remoto (Valent) fallisce su Niri se si tenta di usare il backend di GNOME (Mutter), che è incompatibile con i compositori wlroots. | **Sempre** usare `xdg-desktop-portal-wlr` per `RemoteDesktop` e `ScreenCast` su Niri, assicurando che l'app Flatpak abbia i permessi necessari. |
| **Immutable Path Conflict** | Attempting to create a directory where a symlink exists (or vice versa) on an atomic system (e.g., `/opt` vs `/var/opt`) causes RPM or build failures. | Use `tmpfiles.d` for path redirection or ensure the build stage correctly handles the target distribution's symlink structure. |
| **Transition Package Naming** | Assuming package names based on previous versions (e.g., KF5 vs KF6) leads to non-existent package errors during build. | Always verify exact package names on the target host or official repositories, especially for toolkit-specific libraries (Qt, KDE Frameworks). |
| **Build Environment Leakage** | Failing to isolate build caches (like `CARGO_HOME`) in multi-stage builds leads to permission errors or bloated container layers. | Explicitly define and isolate build environment variables and cache directories within the `builder` stage. |
| **Sandboxed App Discovery** | Placing `.desktop` files in non-standard paths prevents the host system or desktop environment from detecting sandboxed applications (Flatpaks). | Ensure all application entries are placed in or linked to standard XDG paths (e.g., `/usr/share/applications`) verified by the desktop environment. |
| **Duplicate Flatpak Icons** | Creating manual symlinks for Flatpak `.desktop` files in directories already in `XDG_DATA_DIRS` (like `.local/share/applications`) causes launchers to display duplicate entries. | **Do not** manually link Flatpak-exported desktop files; rely on the standard `/var/lib/flatpak/exports/share` path or use `flatpak override` if path adjustments are needed. |
| **Persistent Home Overrides** | System-wide MIME associations (in `/etc/skel`) are ignored if the user has a pre-existing `~/.config/mimeapps.list` that points to a different application. | Use systemd setup services to explicitly patch existing user configuration files in `/var/home` if a specific default application must be enforced. |

## Package Verification (Recommended Workflow)
Before modifying the `Containerfile`, the agent should simulate or verify package names:
- Check if the package is available for the target Fedora version.
- Verify if it requires specific COPR repositories that are already present or need to be added.
