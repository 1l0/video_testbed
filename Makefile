.PHONY: build run
build:
	flutter build web --base-href=/video_testbed/ --output=./docs/
run:
	flutter run -d web-server
