# Defining variables for all scripts
SCRIPTS_DIR := scripts
INIT_APP_SCRIPT := $(SCRIPTS_DIR)/init_app.sh
CLEAN_IOS_SCRIPT := $(SCRIPTS_DIR)/clean_ios.sh
CODEGEN_SCRIPT := $(SCRIPTS_DIR)/build_runner.sh
CHECK_COVERAGE_SCRIPT := $(SCRIPTS_DIR)/check_coverage.sh
SPIDER_BUILD_SCRIPT := $(SCRIPTS_DIR)/spider_build.sh
FORMAT_SCRIPT := $(SCRIPTS_DIR)/format.sh

# Tasks to run each script
init_app:
	sh $(INIT_APP_SCRIPT)

clean_ios:
	sh $(CLEAN_IOS_SCRIPT)

codegen:
	sh $(CODEGEN_SCRIPT)

check_coverage:
	sh $(CHECK_COVERAGE_SCRIPT)

spider_build:
	sh $(SPIDER_BUILD_SCRIPT)

format:
	sh $(FORMAT_SCRIPT)

# By default, we display a message about available tasks
all:
	@echo "Available tasks:"
	@echo " - init_app: flutter clean, clean_ios, pub get, pub run build_runner, dart format"
	@echo " - clean_ios: Clears local dependencies for iOS."
	@echo " - codegen: build_runner build & dart format"
	@echo " - check_coverage: automating the process of testing the coverage."
	@echo " - spider_build: Runs spider build."
	@echo " - format: dart format -l 120 lib test"
