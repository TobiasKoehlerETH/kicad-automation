# KiCad Project File Renamer

A Windows terminal interface for renaming every file in one KiCad project set together.

## Supported files

- `.kicad_pcb`
- `.kicad_prl`
- `.kicad_pro`
- `.kicad_sch`

## Usage

1. Close the project in KiCad.
2. Double-click `Rename-PCB-Files.cmd`.
3. Choose the project folder with the keyboard file browser. The launcher's folder is selected initially.
4. Enter the new project name, review the live preview, and confirm.

Use the arrow keys and Enter to navigate; the browser exposes a `[Select this folder]` row whenever the folder contains a valid KiCad project. Esc backs out, and `G` opens a text prompt where typing, pasting, or dragging a path is confirmed with Enter. The menu validates the folder and name immediately and disables the rename action while KiCad is open or a destination would be overwritten.

For example, entering `control_board` renames `main.kicad_pcb` to `control_board.kicad_pcb` and applies the same base name to the other supported project files.

## Apply the company schematic style

Double-click `Apply-CompanySchematicStyle.cmd`. This single self-contained package can be copied into a project folder without the repository's PowerShell scripts or worksheet template. Its terminal menu lets you choose a schematic project folder (or a specific `.kicad_pro` file), PNG logo, author name, and team name. Review the complete title-block setup and confirm before it applies:

- the company drawing sheet;
- Company: Angst+Pfister;
- Author: Tobias Köhler;
- Sensing Materials Team;
- Group Engineering;
- the embedded company logo at the bottom right of every schematic sheet.

The dark-red menu starts with the launcher's folder as the project choice and automatically uses `APlogo_black.png` beside the launcher when present. Its keyboard file browser uses arrow keys and Enter to browse or select the highlighted row; Esc backs out, Backspace moves up, `D` chooses a drive, and `G` opens a text prompt for a path. Close KiCad before applying the style. The command creates a timestamped backup of the project file and worksheet before changing them.

You can also pass a project folder or `.kicad_pro` file as the first command-line argument and a PNG logo as the second.

## Safety

- The style tool changes only the selected project and its generated drawing sheet; subfolders are untouched.
- Existing destination files are never overwritten.
- The operation stops if multiple source files share a supported extension.
- Renames are staged first, with rollback attempted if an operation fails.
- A preview and confirmation are shown before any changes are made.

## Requirements

Windows with Windows PowerShell. No installation or downloaded modules are required. `Apply-CompanySchematicStyle.cmd` is portable; the project renamer launcher must remain beside `Invoke-KiCadProjectRenamerTui.ps1`.
