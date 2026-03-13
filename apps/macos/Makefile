APP_NAME = QuantWise
BUILD_DIR = .build/release
APP_DIR = $(APP_NAME).app/Contents

.PHONY: build run clean app

build:
	swift build -c release

# Run as .app bundle (required for mic/speech/notifications)
run: app
	open $(APP_NAME).app

# Dev build + run as bundle
dev:
	swift build && \
	mkdir -p $(APP_DIR)/MacOS && \
	cp .build/debug/$(APP_NAME) $(APP_DIR)/MacOS/ && \
	cp Info.plist $(APP_DIR)/ && \
	open $(APP_NAME).app

app: build
	mkdir -p $(APP_DIR)/MacOS
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_DIR)/MacOS/
	cp Info.plist $(APP_DIR)/
	@echo "Built $(APP_NAME).app"

clean:
	swift package clean
	rm -rf $(APP_NAME).app
