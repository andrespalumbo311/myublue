# AI Contribution Guidelines

This repository has a rigid structure based on Fedora Atomic and containerized builds. Any AI agent interacting with this codebase **must** adhere to these rules to avoid breaking the build pipeline.

## Mandatory Operational Rules
1. **Verify Documentation:** Before taking any action, read this file and the "Historical Errors & Prevention" table.
2. **Self-Update:** If you commit an error that causes a build failure, after applying the fix, you **must** update the table in this file with the error description and how to avoid it in the future.

## Historical Errors & Prevention

| Error Committed | Technical Cause | Preventive Action / Solution |
| :--- | :--- | :--- |
| **Vital Directory Removal** | Deleting the last file in a directory (like `usr/` or `etc/`) causes it to vanish from Git, breaking `COPY` commands in the Containerfile. | If a directory must remain in the repo but is empty, always add a `.keep` file. |
| **Non-existent Packages** | Attempting to install packages in the Containerfile using incorrect names or packages not present in Fedora repos. | **Before** adding a package to the Containerfile, verify its existence using `dnf search` or official Fedora repository search tools. |
| **Browser Identity Mismatch** | Helium could not set itself as default due to an ID mismatch (`net.imput.helium` vs `com.github.ShyVortex.Helium`). | Always verify the actual Flatpak ID using `flatpak list` before creating symlinks or desktop entries. |

## Package Verification (Recommended Workflow)
Before modifying the `Containerfile`, the agent should simulate or verify package names:
- Check if the package is available for the target Fedora version.
- Verify if it requires specific COPR repositories that are already present or need to be added.
