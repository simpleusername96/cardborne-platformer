#!/usr/bin/env python3
"""Guard against restoring the retired raster UI conversion workflow."""


def main() -> None:
    raise SystemExit(
        "This converter is retired. UI chrome is owned by the code-native "
        "Theme and shared component factory."
    )


if __name__ == "__main__":
    main()
