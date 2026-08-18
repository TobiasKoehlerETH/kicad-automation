# Apply company schematic style

`Apply-CompanySchematicStyle.cmd` is a self-contained Windows launcher for applying the Angst+Pfister drawing sheet and title-block defaults to a KiCad project.

## Usage

Double-click the launcher, or pass a project folder or `.kicad_pro` file as the first argument:

```text
Apply-CompanySchematicStyle.cmd C:\path\to\project
```

An optional second argument supplies the PNG logo:

```text
Apply-CompanySchematicStyle.cmd C:\path\to\project C:\path\to\APlogo_black.png
```

The interactive menu lets you choose the project, logo, author, and team, then shows a review before applying changes. KiCad must be closed. Existing project and worksheet files are backed up with a timestamp before they are changed.

The package contains its PowerShell payload and worksheet template inside the `.cmd` file, so it can be copied into a project folder and used without the rest of this repository. If `APlogo_black.png` is placed beside the launcher, it is selected automatically.

## Requirements

- Windows
- Windows PowerShell
- KiCad project files
