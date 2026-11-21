# SAP GUI for Windows on Linux via Wine

This repository provides an automated Bash script to install and configure **SAP GUI for Windows (7.60)** on Linux using **Wine**.  
It aims to reproduce a working SAP GUI environment by installing required runtimes, COM components, and dependencies inside a dedicated Wine prefix.

> ⚠️ Disclaimer  
> This setup is intended for **educational and experimental purposes only**.  
> SAP GUI on Wine is not officially supported by SAP, and stability may vary depending on system configuration.

---

## 📦 What the script does

The installer automates the following steps:

- Creates a dedicated working directory structure
- Installs Wine (32-bit + 64-bit support)
- Installs Winetricks and required dependencies
- Configures a dedicated Wine prefix (`sapwine`)
- Installs runtime libraries:
  - Visual C++ Redistributables (2008–2019)
  - .NET Framework (4.0–4.8 fallback)
  - MSXML, IE8, and legacy Windows components
- Installs COM / OLE / scripting support:
  - VBScript engine
  - ActiveX / OCX runtime components
- Extracts SAP GUI installer files
- Installs SAP GUI using `SapGuiSetup.exe`
- Registers required OCX/DLL components via `regsvr32`
- Executes VBScript-based validation tests
- Fixes SAP Logon desktop shortcut for Wine integration

---

## 📁 Directory structure

The script creates the following layout:

~/Windows_SAP_GUI_on_Linux/
├── sapwine/ # Wine prefix (Windows environment)
├── helper_files/ # Optional external DLL/OCX dependencies
├── sapgui-extracted/ # SAP GUI installer files


---

## 🧩 Optional helper files

The script optionally supports manually provided Windows system DLLs:

```

helper\_files/
├── vbscript.dll
├── comctl32.dll
├── comdlg32.dll
├── oleaut32.dll


⚠️ Important notes
These files are optional and not strictly required for installation
They are copied into system32 inside the Wine prefix as a fallback compatibility layer
Most functionality is already handled by Wine + Winetricks dependencies
They are included to improve compatibility in edge-case environments
THEY ARE RECOMMENDED TO DOWNLOAD THOUGH, but you will have to include them from third party sources.

The script does not rely on a single official redistribution source for these DLLs, therefore their use is treated as best-effort and optional.

❓ Interactive helper_files confirmation

During execution, the script prompts:
Did you put the following files in the helper_files/ folder?
    vbscript.dll
    comctl32.dll
    comdlg32.dll
    oleaut32.dll

Behavior:
yes → continues installation and testing
no → exits the script safely

This ensures explicit user awareness before using optional system components.

chmod +x install.sh
./install.sh

🧪 Validation tests

The script performs automated runtime checks using VBScript and COM objects:

VBScript engine execution
COM object creation tests
OCX component registration
ActiveX functionality (SAPI, Windows Media components)
SAP-specific OCX registration checks

These tests are used to verify environment readiness, not full SAP compatibility.

🧷 SAP GUI compatibility notes
SAP GUI for Windows is not officially supported on Linux
Wine compatibility may vary between versions
Some components may require manual adjustment depending on system setup
SAP GUI for Java remains the officially supported Linux alternative

⚠️ Disclaimer

This script is provided as-is without warranty.

No guarantee of stability or production use
No official SAP support implied
Use only in testing or educational environments

The author is not responsible for system misconfiguration or software issues resulting from its use.

📜 License

This project is released for educational purposes.
Third-party components remain subject to their respective licenses.



