# AI Contribution Guidelines

This repository has a rigid structure based on Fedora Atomic and containerized builds. Any AI agent interacting with this codebase **must** adhere to these rules to avoid breaking the build pipeline.

## Mandatory Operational Rules
1. **Verify Documentation:** Before taking any action, read this file and the "Historical Errors & Prevention" table.
2. **Self-Update:** If you commit an error, you **must** update the table in this file. If the error belongs to an existing class, refine the "Preventive Action" with the new technical insights. The table is a **living library of architectural patterns**, not a chronological log of instances.
3. **Technical Abstraction:** Errors must be documented in a **general and abstract form**. Describe the underlying technical logic (e.g., "Flatpak remote metadata caching") so the solution acts as a reusable pattern for any similar scenario in the project.
4. **Live Session Validation:** For any changes affecting graphical sessions, portals, or user-level services, the agent **must** perform live validation (e.g., using `busctl`, `systemctl --user`, or `gsettings`) to confirm the backend is active and exposing the correct interfaces *before* committing.

## Historical Errors & Prevention

| Error Class / Technical Challenge | Root Cause (Abstract) | Preventive Action / Architectural Pattern |
| :--- | :--- | :--- |
| **Vital Directory Persistence** | Git does not track empty directories; deleting the last file in a mapped directory breaks `COPY` instructions. | Always maintain a `.keep` file in directories that must persist in the repository structure. |
| **Package Source & Namespace Integrity** | Assuming package availability, naming, or external installer flags without verification. | 1. Verify exact package names. 2. For GitHub releases, check actual asset names. 3. When switching from RPM to standalone binaries, **always** manually provide missing systemd units (`.service`, `.timer`) and config files previously included in the package. |
| **Application ID Mismatch** | Linking services using assumed IDs instead of verified Flatpak IDs causes MIME and Portal failures. | **Always** align symlinks and MIME integrations with the official ID. Use shadow `.desktop` files for internal app checks if needed. |
| **Flatpak Remote Persistence & Indexing** | In atomic systems, simply adding a remote configuration file may not trigger metadata indexing. | Use a hybrid approach: add the `.flatpakrepo` file to `etc/` **and** run `remote-add` + `update --appstream` during the build to warm the cache. |
| **Third-Party Repository Validation** | Relying on unverified URLs or corrupted GPG keys for external repositories causes build failures. | Always verify raw repository configuration files and check URL accessibility (e.g., via `curl -I`) before integration. |
| **Plugin Dependency Resolution** | Software plugins often depend on low-level CLI utilities that are not included in base images. | Audit plugin source code or documentation to identify and explicitly install all required system-level CLI dependencies in the build manifest. |
| **Configuration Include Integrity** | Modular configuration files using `include` statements will fail if any referenced path is missing. | Ensure all included configuration fragments exist in the repository, using empty placeholders if necessary. |
| **Atomic System GPG Keyring Constraints** | Initializing a remote via URL during build may fail if the GPG key is not yet trusted. | Point the initialization command to a local `.flatpakrepo` file that already contains the GPG key to ensure atomic import and trust. |
| **Missing Remote Desktop Backend (wlroots)** | Remote control (Valent) fails on Niri if the portal does not export the `RemoteDesktop` interface. | **Use** `xdg-desktop-portal-hyprland` for full `RemoteDesktop` support on wlroots and ensure `/dev/uinput` permissions via `tmpfiles.d`. |
| **Immutable Path Conflict** | Attempting to create a directory where a symlink exists (or vice versa) on an atomic system causes failures. | Use `tmpfiles.d` for path redirection or ensure the build stage correctly handles the target distribution's symlink structure. |
| **Transition Package Naming** | Assuming package names based on previous versions (e.g., KF5 vs KF6) leads to non-existent package errors. | Always verify exact package names on the target host or official repositories, especially for toolkit-specific libraries. |
| **Build Environment Leakage** | Failing to isolate build caches (like `CARGO_HOME`) in multi-stage builds leads to permission errors or bloated layers. | Explicitly define and isolate build environment variables and cache directories within the `builder` stage. |
| **Sandboxed App Discovery** | Placing `.desktop` files in non-standard paths prevents detection of sandboxed applications (Flatpaks). | Ensure all application entries are placed in or linked to standard XDG paths verified by the desktop environment. |
| **Duplicate Flatpak Icons** | Creating manual symlinks for Flatpak `.desktop` files in `XDG_DATA_DIRS` causes duplicate launcher entries. | **Do not** manually link Flatpak-exported desktop files; rely on standard export paths or use `flatpak override`. |
| **Persistent Home Overrides** | System-wide MIME associations in `/etc/skel` are ignored if the user has a pre-existing `~/.config/mimeapps.list`. | Use systemd setup services to explicitly patch existing user configuration files in `/var/home` if a default must be enforced. |

## Package Verification (Recommended Workflow)
Before modifying the `Containerfile`, the agent should simulate or verify package names:
- Check if the package is available for the target Fedora version.
- Verify if it requires specific COPR repositories that are already present or need to be added.
