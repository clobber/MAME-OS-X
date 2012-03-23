#!/bin/sh -x

java -jar "${SRCROOT}/vendor/smc/Smc.jar" -objc -d "${DERIVED_FILES_DIR}" "${INPUT_FILE_PATH}"