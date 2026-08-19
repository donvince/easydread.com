ARG CHROMIUM_IMAGE_VERSION=1.62.0
FROM mcr.microsoft.com/playwright:v${CHROMIUM_IMAGE_VERSION}-noble

WORKDIR /app

COPY scripts/generate-pdf.cjs ./scripts/generate-pdf.cjs

ENTRYPOINT ["node", "/app/scripts/generate-pdf.cjs"]
