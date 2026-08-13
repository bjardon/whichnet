APP_NAME := WhichNet
APP := dist/$(APP_NAME).app

.PHONY: build app run kill

build:
	swift build -c release

app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/$(APP_NAME) $(APP)/Contents/MacOS/$(APP_NAME)
	cp Info.plist $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)

run: app
	open $(APP)

kill:
	-killall $(APP_NAME)
