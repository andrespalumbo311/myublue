# AI Contribution Guidelines

This repository has a rigid structure based on Fedora Atomic and containerized builds. Any AI agent interacting with this codebase **must** adhere to these rules to avoid breaking the build pipeline.

## Mandatory Operational Rules
1. **Verify Documentation:** Before taking any action, read this file and the "Historical Errors & Prevention" table.
2. **Self-Update:** If you commit an error that causes a build failure, after applying the fix, you **must** update the table in this file with the error description and how to avoid it in the future.
3. **Filesystem Integrity:** Git does not track empty directories. If you delete the last file from a directory referenced in the `Containerfile` (e.g., `etc/`, `usr/`), you must create a `.keep` file to prevent the directory from disappearing.

## Historical Errors & Prevention

| Error Committed | Technical Cause | Preventive Action / Solution |
| :--- | :--- | :--- |
| **Vital Directory Removal** | Deleting the last file in `usr/` caused the directory to vanish from Git, breaking the `COPY usr /usr` command in the Containerfile. | If a directory must remain in the repo but is empty, add a `.keep` file. |
| **Non-existent Packages** | Attempting to install packages in the Containerfile using incorrect names or packages not present in Fedora repos. | **Before** adding a package to the Containerfile, verify its existence using `dnf search` or official Fedora repository search tools. |
| **Browser Identity Mismatch** | Helium browser could not set itself as default because it looked for a specific `.desktop` filename not present in the sandbox. | Do not create duplicates in `/usr/share/applications`. Use `tmpfiles.d` to create symlinks pointing from expected names to Flatpak-exported files. |

## Package Verification (Recommended Workflow)
Before modifying the `Containerfile`, the agent should simulate or verify package names:
- Check if the package is available for the target Fedora version.
- Verify if it requires specific COPR repositories that are already present or need to be added.
