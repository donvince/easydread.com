# easydread.com
Easydread are an seven piece Conscious-Rock-Reggae band from Bedfordshire

They combine sounds drawn from a wide range of influences, from Ska to Rap, soul to Punk.
As they seamlessly blend powerful political imagery with sweet harmonies and heavy grooves easydread will get you thinking as well as skanking.

Have a listen and find out more here: [easydread.com](http://www.easydread.com/)

## Generate the EPK PDF

Docker Desktop is the only local dependency. Generate a preview at
`output/pdf/easydread-epk.pdf` with:

```bash
make pdf
```

The first run downloads the pinned Chromium image. Docker reuses that image and the small
generator layer on later runs, so no local Node or npm registry access is required.

To write the PDF alongside the web page for a Pages deployment, run:

```bash
make pdf-site
```
