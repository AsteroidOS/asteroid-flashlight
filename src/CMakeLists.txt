add_library(asteroid-flashlight main.cpp)
set_target_properties(asteroid-flashlight PROPERTIES PREFIX "")

asteroid_app_qml_module(asteroid-flashlight
	main.qml
)

target_link_libraries(
	asteroid-flashlight
	PUBLIC
		Asteroid::AsteroidApp6
)

install(
	TARGETS asteroid-flashlight
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
