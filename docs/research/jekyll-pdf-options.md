# PDF generation options for the GitHub Pages site

Research date: 2026-08-19

## Repository context

This repository does not currently use Jekyll. It publishes committed files from `docs/`, contains `docs/.nojekyll`, and has no `_config.yml` or `Gemfile`. The checked-in GitHub Actions workflow deploys DNS, not the website. The EPK page at `docs/epk/index.html` is already designed for PDF output with A4 `@page` and `@media print` CSS.

GitHub Pages can either publish a branch/folder directly or deploy an artifact from a custom Actions workflow. GitHub recommends an Actions publishing workflow when a custom build is required. Such a workflow checks out the repository, builds static output, uploads it with `actions/upload-pages-artifact`, and deploys it with `actions/deploy-pages` ([GitHub Pages publishing-source documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site), [custom workflow documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)).

## Is PDF built into Jekyll or GitHub Pages?

No. Jekyll generates static site content and has a plugin mechanism, but it has no built-in PDF output. GitHub-hosted Jekyll builds run in safe mode and only permit whitelisted plugins. Arbitrary PDF-generation plugins therefore require building locally or in a custom Actions workflow ([Jekyll plugin installation documentation](https://jekyllrb.com/docs/plugins/installation/)). A Jekyll plugin would only wrap one of the conversion engines below; it would not remove that dependency.

## Ranked options

Scores use 5 = easiest/strongest and 1 = hardest/weakest. “Support” combines active maintenance, documentation, ecosystem, and availability of professional support.

| Rank | Approach | GHA ease | macOS ease | Support | Best use |
|---:|---|:---:|:---:|:---:|---|
| 1 | Chromium through Playwright | 5 | 4 | 5 | Faithful PDF of the existing, browser-oriented pages |
| 2 | WeasyPrint | 4 | 5 | 4 | Print-oriented HTML/CSS with no JavaScript dependency |
| 3 | Prince | 3 | 4 | 5 | Highest-end paged-media and standards requirements, if commercial licensing is acceptable |
| 4 | Paged.js CLI | 3 | 3 | 3 | Books/reports needing advanced paged-media features in a browser engine |
| 5 | Pandoc plus a PDF engine | 3 | 4 | 5 | A future Markdown-first authoring workflow, not faithful conversion of the current visual HTML |
| 6 | Hosted HTML-to-PDF service | 4 | 5 | 3–5 | Outsourcing browser/runtime maintenance; accepts cost, secrets, and vendor dependency |
| 7 | wkhtmltopdf | 3 | 3 | 1 | Legacy compatibility only; avoid for new work |
| 8 | A Jekyll PDF plugin/hook | 2 | 2 | 2 | Ruby-centric orchestration when a custom Jekyll build already exists |

### 1. Chromium through Playwright — recommended

Build or copy the static site, serve it on localhost, visit the target page with Chromium, wait for fonts and page scripts, then call `page.pdf()`. Playwright uses print CSS by default and supports paper size, CSS `@page`, backgrounds, headers/footers, outlines, and tagged PDFs ([Playwright `page.pdf` documentation](https://playwright.dev/docs/api/class-page#page-pdf)). It is actively maintained by Microsoft.

This is the closest match to what visitors see and supports the small script in the EPK page. In Actions, install Node dependencies and the pinned Chromium build (`playwright install --with-deps chromium`). On macOS, install the same package/browser once. The main cost is a relatively large browser download. A raw headless-Chrome command is possible, but Playwright provides a more stable, testable API and explicit waits.

For this site use `printBackground: true`, `preferCSSPageSize: true`, and wait for `document.fonts.ready`. Put the resulting file into the deployment tree, for example `_site/epk/easydread-epk.pdf`.

#### Availability in Docker and GitHub Actions

Yes in both cases; neither requires maintaining a browser installation by hand.

- **Docker:** Microsoft publishes `mcr.microsoft.com/playwright` images containing the Playwright browsers and their Linux system dependencies (the Node Playwright package is installed separately by the project). Pin an exact image tag, including the Playwright and Ubuntu versions, and keep it equal to the project's Playwright package version; mismatches can make the bundled browser executable undiscoverable. The image runs browsers as `root` by default, which disables Chromium's sandbox. That is acceptable for this repository's trusted local page, but untrusted pages should use a non-root user plus Playwright's recommended seccomp profile. Playwright also recommends `--ipc=host` for Chromium ([official Docker documentation](https://playwright.dev/docs/docker)).
- **GitHub-hosted Ubuntu runner:** the simplest workflow is `npm ci` followed by `npx playwright install chromium --with-deps`. This installs the Chromium revision matched to the lockfile's Playwright version plus required OS libraries; Playwright documents this exact Chromium-only optimization and an `ubuntu-latest` Actions setup ([official CI guide](https://playwright.dev/docs/ci), [official best-practices guide](https://playwright.dev/docs/best-practices#optimize-browser-downloads-on-ci)). GitHub's Ubuntu images currently include Google Chrome, but runner software is updated weekly and `ubuntu-latest` can migrate between OS releases, so that copy should not be the reproducibility boundary. Pin the runner OS (for example `ubuntu-24.04`) and let Playwright install its matched Chromium build; the exact runner image and included software remain visible in each job's `Set up job` log ([GitHub-hosted runner documentation](https://docs.github.com/en/actions/concepts/runners/github-hosted-runners), [official Ubuntu runner manifest](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md)).
- **Download/storage trade-off:** Playwright says individual browser installations occupy a few hundred megabytes. Installing only Chromium avoids Firefox and WebKit; for headless-only use, `--only-shell` can reduce the download further. Its CI documentation does not recommend caching browser binaries because restoring the cache is often comparable to downloading them and Linux system packages are not covered by that cache. If caching is nevertheless used, key it to the Playwright version ([browser installation and storage documentation](https://playwright.dev/docs/browsers#managing-browser-binaries), [official CI source documentation](https://github.com/microsoft/playwright/blob/main/docs/src/ci.md#caching-browsers)). A pinned Playwright Docker image trades the per-run browser download for pulling a comparatively substantial container image, which the runner's Docker layer cache may or may not already contain.

For this small Pages build, the native Ubuntu-runner route is the least configuration. Docker is equally viable when identical local/CI Linux rendering or a prebuilt reusable environment matters more than image-pull overhead.

### 2. WeasyPrint

WeasyPrint is an open-source HTML/CSS-to-PDF engine designed for pagination rather than a full browser. It is BSD-licensed, actively maintained, and offers professional support ([official project repository](https://github.com/Kozea/WeasyPrint)). Current macOS installation is a single Homebrew package (`brew install weasyprint`) ([official first-steps documentation](https://doc.courtbouillon.org/weasyprint/stable/first_steps.html)).

It is attractive for document-like layouts and strong print CSS, but is not a browser and does not execute page JavaScript. Browser-specific CSS should be tested, and the EPK's letter-colouring script would need to be moved into generated HTML or CSS.

### 3. Prince

Prince is a mature commercial HTML/CSS print engine with extensive paged-media, tagged-PDF, PDF profile, font, and color-management features ([Prince command-line documentation](https://www.princexml.com/doc/command-line/), [PDF output options](https://www.princexml.com/doc/12/doc-refs/)). It supports macOS and Linux. The free version watermarks output; production use requires a licence ([Prince licensing/install documentation](https://www.princexml.com/doc-install/)).

It is the strongest choice for publishing-grade requirements, but downloading the binary and securely supplying a licence in Actions makes it heavier than this site needs.

### 4. Paged.js CLI

Paged.js polyfills CSS Paged Media and Generated Content features and its CLI renders HTML to PDF using Puppeteer ([official repository](https://github.com/pagedjs/pagedjs), [CLI documentation](https://pagedjs.org/en/documentation/2-getting-started-with-paged.js/)). It is useful for long documents with running matter, counters, and book-style pagination. It adds another layout layer and is unnecessary for the existing one-page A4 EPK.

### 5. Pandoc plus an engine

Pandoc is excellent when Markdown is the source of truth. PDF output still requires an engine: LaTeX by default, or HTML engines including WeasyPrint, Prince, wkhtmltopdf, and Paged.js CLI ([Pandoc PDF documentation](https://pandoc.org/MANUAL.html#creating-a-pdf)). It is therefore an authoring/conversion layer, not a standalone answer. Feeding the current hand-designed HTML through Pandoc would likely lose layout fidelity.

### 6. Hosted conversion API

A hosted API can accept a deployed URL or HTML and return a PDF, making both Actions and Mac usage mechanically easy. Trade-offs are credentials, request cost, network dependence, data disclosure, and vendor-specific rendering. It is reasonable when operational support matters more than keeping the build self-contained, but unnecessary for this public, simple page.

### 7. wkhtmltopdf — do not start here

wkhtmltopdf uses an old Qt WebKit stack. Its repository was archived and made read-only in January 2023 ([official archived repository](https://github.com/wkhtmltopdf/wkhtmltopdf)). It remains common in older systems but is a poor choice for a new pipeline using modern CSS and fonts.

### 8. Jekyll plugin/hook

A custom generator or post-write hook can invoke any converter, but GitHub Pages safe mode will not run arbitrary plugins. A custom Actions build is required anyway ([Jekyll plugin documentation](https://jekyllrb.com/docs/plugins/installation/)). This introduces Ruby/Jekyll coupling into a repository that currently does not use either, so a standalone generation script is simpler.

## Deployment choices

1. **Recommended: custom Pages workflow.** Copy `docs/` to `_site/`, serve `_site/` locally, generate the PDF into `_site/epk/`, then upload and deploy `_site/` as the Pages artifact. Generated binaries stay out of Git, and HTML/PDF are produced atomically.
2. **Smallest initial change: generate and commit the PDF.** Run the generator locally (or in a workflow that opens a pull request), commit `docs/epk/easydread-epk.pdf`, and keep branch publishing. Simple, but binary files can become stale and add repository churn.
3. **Separate workflow artifact/release.** Useful for internal downloads or versioned releases, but the PDF will not naturally live beside the web page at `easydread.com`.

## Recommendation

Use Playwright/Chromium as a post-processing step over a locally served copy of the static site, and move Pages publishing to a custom GitHub Actions artifact workflow. This preserves the current HTML as the source of truth, makes use of the EPK's existing print CSS, handles its script and custom fonts, and gives the closest local/CI parity. Jekyll is not needed.
