.PHONY: build run app install clean

# Compile a debug binary.
build:
	swift build

# Build the release .app bundle into ./build.
app:
	@bash Scripts/build-app.sh release

# Build and launch the app.
run: app
	@open build/Ditto.app

# Copy the app into /Applications.
install: app
	@rm -rf /Applications/Ditto.app
	@cp -R build/Ditto.app /Applications/Ditto.app
	@echo "✓ Installed to /Applications/Ditto.app"

clean:
	swift package clean
	rm -rf build .build
