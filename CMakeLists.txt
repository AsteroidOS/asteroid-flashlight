cmake_minimum_required(VERSION 3.6.0)

project(asteroid-flashlight
	VERSION 0.0.1
	DESCRIPTION "Default flashlight app for AsteroidOS")

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp REQUIRED)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ASTEROID_MODULE_PATH})

include(FeatureSummary)
include(GNUInstallDirs)
include(ECMFindQmlModule)
include(AsteroidCMakeSettings)
include(AsteroidTranslations)

ecm_find_qmlmodule(Nemo.KeepAlive 1.1)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/asteroid-flashlight.in
	${CMAKE_BINARY_DIR}/asteroid-flashlight
	@ONLY)

install(PROGRAMS ${CMAKE_BINARY_DIR}/asteroid-flashlight
	DESTINATION ${CMAKE_INSTALL_BINDIR})

build_translations(i18n)
add_subdirectory(src)

generate_desktop(${CMAKE_SOURCE_DIR} asteroid-flashlight)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
