# KiCad Project File Renamer

A standalone Windows launcher for renaming the files in a KiCad project set through a simple terminal interface.

## Supported files

- `.kicad_pcb`
- `.kicad_prl`
- `.kicad_pro`
- `.kicad_sch`

## Usage

1. Close the project in KiCad.
2. Copy `Rename-PCB-Files.cmd` into the project folder.
3. Double-click the launcher.
4. Enter the new project name, review the preview, and confirm.

For example, entering `control_board` renames `main.kicad_pcb` to `control_board.kicad_pcb` and applies the same base name to the other supported project files.

## Apply the company schematic style

Copy `Apply-CompanySchematicStyle.cmd` into a KiCad project folder and double-click it. It finds the single `.kicad_pro` file in that folder and applies:

- the company drawing sheet;
- Company: Sensing Materials;
- Author: Tobias Köhler;
- Sensing Materials Team;
- Group Engineering;
- the embedded company logo at the bottom right of every schematic sheet.

Place a local `APlogo_black.png` beside the `.cmd` file, or pass a logo path to the PowerShell script. The image is intentionally not stored in GitHub. Close KiCad before running it. The command creates a timestamped backup of the project file and worksheet before changing them.

## Safety

- Only files in the launcher's own folder are considered; subfolders are untouched.
- Existing destination files are never overwritten.
- The operation stops if multiple source files share a supported extension.
- Renames are staged first, with rollback attempted if an operation fails.
- A preview and confirmation are shown before any changes are made.

## Requirements

Windows with Windows PowerShell. No installation, downloaded modules, or companion files are required.
