# Custom Footprint Library

This directory combines custom KiCad footprint sources from the hardware projects into one library:

```text
Custom-Footprints.pretty/
```

The current build scanned 122 `.kicad_mod` source files across 15 source libraries. Exact duplicates were collapsed, resulting in 16 unique footprints. No same-name footprints with different contents were found.

## Add to KiCad

1. Open **Preferences > Manage Footprint Libraries**.
2. Select the **Project Specific Libraries** or **Global Libraries** tab.
3. Click **Add existing library to table**.
4. Select the `Custom-Footprints.pretty` directory.

KiCad will expose the library as `Custom-Footprints` by default.

The original footprint data is preserved byte-for-byte. Existing 3D-model references are therefore unchanged; footprints that use project-relative or KiCad-version-specific model paths may require those paths to be configured separately.

## Rebuild

Run the included builder from PowerShell and pass the source repository's `Hardware` directory:

```powershell
.\Build-Custom-Footprint-Library.ps1 -HardwareRoot C:\path\to\hardware
```

The builder:

- searches recursively for `.kicad_mod` files;
- collapses byte-identical copies sharing the same filename;
- stops if a filename maps to different footprint contents;
- recreates the custom footprint library.
