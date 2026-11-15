.PHONY: build app run clean

build:
	swift build

app:
	./scripts/build-app.sh

run: app
	-pkill -x NotchLocal
	open build/NotchLocal.app

clean:
	rm -rf .build build
