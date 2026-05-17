# file: Makefile
override ANDROID_SDK_ROOT := $(HOME)/Android/Sdk

.PHONY: help
help:
	@echo "Project Development Commands"
	@echo "============================"
	@echo ""
	@echo "Development Setup:"
	@echo "  pre-commit-setup    Set up pre-commit hooks for the project"
	@echo ""
	@echo "Android Deployment:"
	@echo "  build-apk           Build debug APK"
	@echo "  build-apk-release   Build release APK"
	@echo "  push-apk            Build and push debug APK to device"
	@echo "  push-apk-release    Build and push release APK to device"

.PHONY: pre-commit-setup
pre-commit-setup:
	@echo "Setting up pre-commit hooks..."
	@echo "consider running <pre-commit autoupdate> to get the latest versions"
	pre-commit install
	pre-commit install --install-hooks
	pre-commit run --all-files

.PHONY: build-apk
build-apk:
	export ANDROID_SDK_ROOT=$(ANDROID_SDK_ROOT) ANDROID_HOME=$(ANDROID_SDK_ROOT) && flutter build apk --debug

.PHONY: build-apk-release
build-apk-release:
	export ANDROID_SDK_ROOT=$(ANDROID_SDK_ROOT) ANDROID_HOME=$(ANDROID_SDK_ROOT) && flutter build apk --release

.PHONY: push-apk
push-apk: build-apk
	adb install -r build/app/outputs/flutter-apk/app-debug.apk

.PHONY: push-apk-release
push-apk-release: build-apk-release
	adb install -r build/app/outputs/flutter-apk/app-release.apk
