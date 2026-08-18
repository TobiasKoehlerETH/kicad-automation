# KiCad schematic style

This package standardizes KiCad schematics with:

- **Segoe UI** as the Schematic Editor's default font;
- **black** schematic text, labels, references, values, pin text, and worksheet text;
- a reusable drawing sheet containing:
  - Company: Angst+Pfister
  - Author: Tobias Köhler
  - Sensing Materials Team
  - Group Engineering
  - the black company logo at the bottom right of every schematic sheet.

The scripts target KiCad's current JSON project/configuration format and were verified with KiCad 10 on Windows.

## 1. Install the global font and color defaults

Close KiCad, then run:

```powershell
cd C:\Code\kicad-automation\schematic-style
.\Install-KiCadSchematicDefaults.ps1
```

By default, the newest KiCad profile below `%APPDATA%\kicad` is changed. To update every installed profile, use:

```powershell
.\Install-KiCadSchematicDefaults.ps1 -AllVersions
```

The installer creates and selects a dedicated `segoe-ui-black` color theme. It leaves wire, junction, and component-body colors intact while making text-related schematic items black. It also enables monochrome schematic printing.

## 2. Apply the drawing sheet to a project

For an interactive terminal interface, double-click `project-file-renamer\Apply-CompanySchematicStyle.cmd`. The dark-red menu includes a keyboard file browser for choosing the schematic project folder (or `.kicad_pro` file) and PNG logo. Use the arrow keys and Enter to browse or select the highlighted row; Esc backs out, Backspace moves up, `D` opens the drive list, and `G` opens a text prompt for a typed or pasted path. The menu validates every selection, checks that KiCad is closed, and shows a final review before applying the style.

The TUI includes a short startup reveal and progress spinners during the final worksheet update; redirected or scripted input automatically uses plain prompts.

For direct command-line use, close KiCad and pass either the project directory or its `.kicad_pro` file:

```powershell
.\Set-KiCadProjectSchematicStyle.ps1 C:\path\to\board.kicad_pro
```

Multiple projects can be styled in one call:

```powershell
.\Set-KiCadProjectSchematicStyle.ps1 C:\project-a\a.kicad_pro, C:\project-b\b.kicad_pro
```

The script embeds a locally supplied PNG into `Company-Schematic.kicad_wks`, places that worksheet beside the project, and points the project's schematic settings to it using `${KIPRJMOD}`. KiCad uses that worksheet on every page in the schematic hierarchy. The company logo is intentionally excluded from GitHub; provide it with `-LogoPath`.

To use another copy of the logo:

```powershell
.\Set-KiCadProjectSchematicStyle.ps1 C:\path\to\board.kicad_pro -LogoPath C:\path\to\APlogo_black.png
```

The author and team default to `Tobias Köhler` and `Sensing Materials Team`. Override them in direct command-line use with `-AuthorName` and `-TeamName`.

## Safety and scope

- Both scripts stop if KiCad is running, preventing the application from overwriting the changes.
- Timestamped `.bak` files are created before existing settings, projects, or worksheets are changed.
- Every generated worksheet includes the date it was applied in `YYYY-MM-DD` format.
- The global setting supplies Segoe UI wherever schematic text inherits KiCad's default font. Text items that explicitly store a different font face retain that explicit choice.
- KiCad has no global preference for a custom project drawing sheet. Run the project script once for each existing project, and use a styled project as the starting point for new projects.
