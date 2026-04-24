# AI Contribution Guidelines

This repository has a rigid structure based on Fedora Atomic and containerized builds. Any AI agent interacting with this codebase **must** adhere to these rules to avoid breaking the build pipeline.

## Mandatory Operational Rules
1. **Verify Documentation:** Before taking any action, read this file and the "Historical Errors & Prevention" table.
2. **Self-Update:** If you commit an error (whether it causes a build failure or a runtime issue), after applying the fix, you **must** update the table in this file with the error description and how to avoid it in the future.

## Historical Errors & Prevention

| Error Committed | Technical Cause | Preventive Action / Solution |
| :--- | :--- | :--- |
| **Vital Directory Removal** | Deleting the last file in a directory (like `usr/` or `etc/`) causes it to vanish from Git, breaking `COPY` commands in the Containerfile. | If a directory must remain in the repo but is empty, always add a `.keep` file. |
| **Non-existent Packages** | Attempting to install packages in the Containerfile using incorrect names or packages not present in Fedora repos. | **Before** adding a package to the Containerfile, verify its existence using `dnf search` or official Fedora repository search tools. |
| **Browser Identity Mismatch** | Helium could not set itself as default due to an ID mismatch (`net.imput.helium` vs `com.github.ShyVortex.Helium`). | Always verify the actual Flatpak ID using `flatpak list` before creating symlinks or desktop entries. |
| **Non-persistent Flatpak Remote** | Using `flatpak remote-add` in the Containerfile doesn't persist the *config* after reboots in some cases. | Use the file-based approach in `etc/flatpak/remotes.d/` **AND** run `flatpak remote-add` + `update --appstream` in the Containerfile to cache metadata. |
| **Broken URL in Containerfile** | Using an incorrect/non-existent URL for a repository (e.g., Valent Flatpak repo) causes the build to fail at the `RUN` step. | **Always** verify URLs (especially for third-party repos) using `curl -I` or a browser before adding them to the build process. |
| **GPG Verification Error** | Providing a corrupted or incomplete GPG key and incorrect repository URL in a `.flatpakrepo` file prevents remote synchronization. | **Always** fetch the raw `.flatpakrepo` content from the source to ensure the GPG key and URL are correct. |
| **Missing Plugin Dependencies** | Installing a DMS plugin (like usbManager) without adding its CLI dependencies (parted, mkfs, etc.) to the Containerfile makes it non-functional. | **Verify** the `README.md` or source code of any plugin to identify and include all required system-level dependencies. |
| **Broken Config Includes** | Using `include` statements in KDL configs (like Niri) for files that don't exist in the repository prevents proper loading. | **Always** ensure that all included files are present in the repository, even if they are empty placeholders. |
| **Flatpak GPG Import Failure** | Running `flatpak remote-add` with a URL in the Containerfile fails if the GPG key is not yet in the system keyring. | **Always** point `flatpak remote-add` to the local `.flatpakrepo` file (after it's been copied to /etc) to ensure the key is imported correctly. |

## Package Verification (Recommended Workflow)
Before modifying the `Containerfile`, the agent should simulate or verify package names:
- Check if the package is available for the target Fedora version.
- Verify if it requires specific COPR repositories that are already present or need to be added.
