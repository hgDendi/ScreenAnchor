.PHONY: build release bundle install clean

build:
	swift build

release:
	swift build -c release

bundle: release
	bash Scripts/bundle.sh

install: bundle
	bash Scripts/install.sh

clean:
	swift package clean
	rm -rf ScreenAnchor.app

run: build
	.build/debug/ScreenAnchor
