# Font Research: Cooper-style FOSS typeface

**Date:** 2026-08-18  
**Recommendation:** Caprasimo

## Recommendation

Use **Caprasimo** for `/epk/`. Google Fonts' upstream metadata identifies it as a display serif by The DocRepair Project, Phaedra Charles, and Flavia Zimbardi, licensed under **SIL Open Font License 1.1**. Its official description says Caprasimo is a DocRepair font "providing fallback for Cooper Black that minimizes text reflow", and that it is based on Fraunces, which was inspired by early 20th-century typefaces including the Cooper Series.

Sources:

- Google Fonts specimen: <https://fonts.google.com/specimen/Caprasimo>
- `google/fonts` metadata: <https://raw.githubusercontent.com/google/fonts/main/ofl/caprasimo/METADATA.pb>
- `google/fonts` description: <https://raw.githubusercontent.com/google/fonts/main/ofl/caprasimo/DESCRIPTION.en_us.html>
- `google/fonts` license file: <https://raw.githubusercontent.com/google/fonts/main/ofl/caprasimo/OFL.txt>

## License and hosting

Caprasimo's `OFL.txt` says the font software is licensed under the SIL Open Font License, Version 1.1. The OFL permits use, copying, embedding, modification, redistribution, and bundling, provided the font is not sold by itself and redistributed copies include the copyright notice and license. For this site, that means committing the WOFF2 file is fine as long as `OFL.txt` is committed alongside it. No rendered on-page attribution is required for unmodified use.

Implemented asset layout:

```text
docs/fonts/caprasimo/
  Caprasimo-Regular-latin.woff2
  OFL.txt
```

## Alternative considered

**Titan One** is also OFL-licensed and its official description says it is "a really fat display type with a happy and cheerful personality" intended mainly for "headers and short texts". It is a good chunky display backup, but Caprasimo is the more direct match because it was explicitly made as a Cooper Black fallback.

**Fraunces** is also OFL-licensed and its official description says it is inspired by early 20th-century typefaces including the Cooper Series, but it reads more like a soft-serif display face than a close Cooper Black substitute.

Sources:

- Titan One metadata: <https://raw.githubusercontent.com/google/fonts/main/ofl/titanone/METADATA.pb>
- Titan One description: <https://raw.githubusercontent.com/google/fonts/main/ofl/titanone/DESCRIPTION.en_us.html>
- Titan One license file: <https://raw.githubusercontent.com/google/fonts/main/ofl/titanone/OFL.txt>
- Fraunces metadata: <https://raw.githubusercontent.com/google/fonts/main/ofl/fraunces/METADATA.pb>
- Fraunces description: <https://raw.githubusercontent.com/google/fonts/main/ofl/fraunces/DESCRIPTION.en_us.html>
- Fraunces license file: <https://raw.githubusercontent.com/google/fonts/main/ofl/fraunces/OFL.txt>
