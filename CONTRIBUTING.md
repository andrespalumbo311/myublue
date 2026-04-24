# AI Contribution Guidelines

This repository has a rigid structure based on Fedora Atomic and containerized builds. Any AI agent interacting with this codebase **must** adhere to these rules to avoid breaking the build pipeline.

## Mandatory Operational Rules
1. **Verify Documentation:** Before taking any action, read this file and the "Historical Errors & Prevention" table.
2. **Self-Update:** If you commit an error (whether it causes a build failure or a runtime issue), after applying the fix, you **must** update the table in this file with the error description and how to avoid it in the future.
3. **Technical Abstraction:** Errors must be documented in a **general and abstract form**. Do not limit the description to the specific instance (e.g., "Error with Valent"); instead, describe the underlying technical logic (e.g., "Flatpak remote metadata caching on atomic systems") so the solution acts as a reusable architectural pattern for similar scenarios.

## Historical Errors & Prevention

| Error Class / Technical Challenge | Root Cause (Abstract) | Preventive Action / Architectural Pattern |
| :--- | :--- | :--- |
| **Vital Directory Persistence** | Git does not track empty directories; deleting the last file in a mapped directory (like `usr/` or `etc/`) breaks `COPY` instructions in build files. | Always maintain a `.keep` file in directories that must persist in the repository structure. |
| **Package Namespace Validation** | Using incorrect or non-existent package names in the build manifest causes pipeline failure. | Verify package existence in the target distribution's official repositories or enabled COPRs before modification. |
| **Application ID Mismatch** | Linking or configuring services using assumed Application IDs instead of verified ones leads to integration failure. | Verify the exact Application ID (e.g., via `flatpak list`) before creating symlinks, desktop entries, or service overrides. |
| **Flatpak Remote Persistence & Indexing** | In atomic systems, simply adding a remote configuration file may not trigger metadata indexing, leaving the repository "empty" in the UI. | Use a hybrid approach: add the `.flatpakrepo` file to `etc/` **and** run `remote-add` + `update --appstream` during the build to warm the cache. |
| **Third-Party Repository Validation** | Relying on unverified URLs or corrupted GPG keys for external repositories causes build-time or synchronization failures. | Always verify raw repository configuration files and check URL accessibility (e.g., via `curl -I`) before integration. |
| **Plugin Dependency Resolution** | Software plugins often depend on low-level CLI utilities that are not included in minimal base images. | Audit plugin source code or documentation to identify and explicitly install all required system-level CLI dependencies in the build manifest. |
| **Configuration Include Integrity** | Modular configuration files (e.g., KDL, YAML) that use `include` statements will fail to load if any referenced path is missing. | Ensure all included configuration fragments exist in the repository, using empty placeholder files if necessary to maintain structural integrity. |
| **Atomic System GPG Keyring Constraints** | Initializing a remote via URL during build may fail if the GPG key is not yet trusted by the transient build-time keyring. | Point the initialization command to a local `.flatpakrepo` file that already contains the GPG key to ensure atomic import and trust. |
| **Missing Remote Desktop Backend** | Remote mouse/keyboard input from apps (like Valent) fails on Wayland/Niri if the `gnome-remote-desktop` backend is not installed, even if portals are configured. | **Always** install the required portal backends (e.g., `gnome-remote-desktop`) and grant `org.freedesktop.portal.RemoteDesktop` permissions to the Flatpak. |

## Package Verification (Recommended Workflow)
Before modifying the `Containerfile`, the agent should simulate or verify package names:
- Check if the package is available for the target Fedora version.
- Verify if it requires specific COPR repositories that are already present or need to be added.
