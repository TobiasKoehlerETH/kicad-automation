# CFS-LF Combined Footprint Library

This directory combines every KiCad footprint source found under `CFS-LF/Hardware` into one library:

```text
CFS-LF.pretty/
```

The current build scanned 122 `.kicad_mod` source files across 15 source libraries. Exact duplicates were collapsed, resulting in 16 unique footprints. No same-name footprints with different contents were found.

## Add to KiCad

1. Open **Preferences > Manage Footprint Libraries**.
2. Select the **Project Specific Libraries** or **Global Libraries** tab.
3. Click **Add existing library to table**.
4. Select the `CFS-LF.pretty` directory.

KiCad will expose the library as `CFS-LF` by default.

The original footprint data is preserved byte-for-byte. Existing 3D-model references are therefore unchanged; footprints that use project-relative or KiCad-version-specific model paths may require those paths to be configured separately.

## Source manifest

`SOURCES.csv` records every original footprint path and SHA-256 digest. Paths are relative to the source `Hardware` directory so the manifest contains no machine-specific locations.

## Rebuild

Run the included builder from PowerShell and pass the source repository's `Hardware` directory:

```powershell
.\Build-Combined-Footprint-Library.ps1 -HardwareRoot C:\path\to\CFS-LF\Hardware
```

The builder:

- searches recursively for `.kicad_mod` files;
- collapses byte-identical copies sharing the same filename;
- stops if a filename maps to different footprint contents;
- recreates the combined library and source manifest.
