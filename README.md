# KiCad automation

Windows utilities and shared assets for automating common KiCad project tasks.
The tools are designed for hardware projects and run locally with Windows PowerShell;
they do not require downloaded PowerShell modules.

## Included tools

### Project file renamer

Rename all files in a KiCad project set to the same base name, with a preview,
validation, confirmation, and rollback handling.

- [Project renamer documentation](project-file-renamer/README.md)
- Interactive launcher: `project-file-renamer/Rename-PCB-Files.cmd`

### Schematic styling

Install KiCad schematic defaults and apply the company drawing sheet, title block,
and logo to existing projects.

- [Schematic styling documentation](schematic-style/README.md)
- Install defaults: `schematic-style/Install-KiCadSchematicDefaults.ps1`
- Apply a project style: `schematic-style/Set-KiCadProjectSchematicStyle.ps1`
- Interactive launcher: `project-file-renamer/Apply-CompanySchematicStyle.cmd`

### Custom footprint library

The repository includes a consolidated `Custom-Footprints.pretty` library and a
builder for recreating it from source hardware projects.

- [Custom footprint library documentation](custom-footprint-library/README.md)
- Builder: `custom-footprint-library/Build-Custom-Footprint-Library.ps1`

## Quick start

1. Close KiCad before changing project files or KiCad configuration.
2. Use the interactive `.cmd` launchers for guided file selection and confirmation,
   or run the PowerShell scripts directly from PowerShell.
3. Review the preview before confirming an operation. Existing files are backed up
   or protected from overwrite where applicable.

For command-specific options and safety details, see the README in the relevant
subdirectory.

## Requirements

- Windows
- Windows PowerShell
- KiCad for the projects being modified

The custom footprint library can be added in KiCad through **Preferences > Manage
Footprint Libraries**. Company artwork is supplied locally and is intentionally not
committed to this repository.
