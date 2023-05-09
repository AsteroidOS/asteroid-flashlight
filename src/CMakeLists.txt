add_library(asteroid-flashlight main.cpp resources.qrc)
set_target_properties(asteroid-flashlight PROPERTIES PREFIX "")

target_link_libraries(asteroid-flashlight PUBLIC
	AsteroidApp)

install(TARGETS asteroid-flashlight
	DESTINATION ${CMAKE_INSTALL_LIBDIR})
