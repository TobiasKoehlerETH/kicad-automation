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

## Safety

- The style tool changes only the selected project and its generated drawing sheet; subfolders are untouched.
- Existing destination files are never overwritten.
- The operation stops if multiple source files share a supported extension.
- Renames are staged first, with rollback attempted if an operation fails.
- A preview and confirmation are shown before any changes are made.

## Requirements

Windows with Windows PowerShell. No installation or downloaded modules are required. The project renamer launcher must remain beside `Invoke-KiCadProjectRenamerTui.ps1`.
