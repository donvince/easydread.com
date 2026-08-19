DOCKER ?= docker
PYTHON ?= python3
PORT ?= 8000
SITE_DIR ?= docs
CHROMIUM_IMAGE_VERSION := 1.62.0
PDF_IMAGE ?= easydread-pdf:chromium-$(CHROMIUM_IMAGE_VERSION)
PDF_OUTPUT ?= output/pdf/easydread-epk.pdf
PDF_PAGE ?= /epk/

.PHONY: serve pdf pdf-site

serve:
	$(PYTHON) -m http.server "$(PORT)" --directory "$(SITE_DIR)"

pdf:
	@mkdir -p "$(dir $(PDF_OUTPUT))"
	$(DOCKER) build \
		--build-arg "CHROMIUM_IMAGE_VERSION=$(CHROMIUM_IMAGE_VERSION)" \
		--tag "$(PDF_IMAGE)" \
		--file Dockerfile.pdf .
	$(DOCKER) run --rm --init --ipc=host \
		--user "$$(id -u):$$(id -g)" \
		--env HOME=/tmp \
		--env SITE_DIRECTORY=/work/docs \
		--env "PDF_OUTPUT=/work/$(PDF_OUTPUT)" \
		--env "PDF_PAGE=$(PDF_PAGE)" \
		--volume "$(CURDIR):/work" \
		"$(PDF_IMAGE)"

pdf-site:
	$(MAKE) pdf PDF_OUTPUT=docs/epk/easydread-epk.pdf
