#!/bin/bash
ROOT=$WORKSPACE/Root
WOPROJECT=woproject.jar
JOB_ROOT=${WORKSPACE}/../..
FRAMEWORKS_REPOSITORY=${HUDSON_HOME}/WOFrameworksRepository

WONDER_SUB_PATH=${WONDER_BRANCH}
echo "WOnder Revision Directory: ${WONDER_SUB_PATH}"

if [ "$WONDER_SUB_PATH" == "" ]; then
	echo "You must provide a WONDER_BRANCH."
	exit 1
elif [ "$WONDER_SUB_PATH" == "Wonder_5_0_0_Legacy" ]; then
	WO_ALT_VERSION=53
	WO_VERSION=5.3.3
else 
	WO_ALT_VERSION=54
	WO_VERSION=5.4.3
fi

echo "WO Version: ${WO_VERSION}"


#
# Configure the launch environment based on the platform information.
#
# Expected uname values:
#   Darwin
#   Mac OS
#   Rhapsody  (this is for things like JavaConverter, which need to run on Mac OS X Server 1.2)
#   *Windows* (this prints out an error message)
#   *winnt*   (ditto)
#
# Everything else is treated as "UNIX", the default.
#
PLATFORM_NAME="`uname -s`"

if [ "${PLATFORM_NAME}" = "" ]; then
    echo ${SCRIPT_NAME}: Unable to access uname executable!  Terminating.
    echo If running on Windows, Quit it.
    exit 1
fi

case "${PLATFORM_NAME}" in
    "Darwin")   PLATFORM_DESCRIPTOR=MacOS
                PLATFORM_TYPE=Darwin
                ;;
    "Mac OS")   PLATFORM_DESCRIPTOR=MacOS
                PLATFORM_TYPE=Darwin
                ;;
    "Rhapsody") PLATFORM_DESCRIPTOR=MacOS
                PLATFORM_TYPE=Rhapsody
                ;;
    *Windows*)  echo Windows?! Really?!! Shesh. This script only works with Linux/UNIX. Terminating.
                exit 1
                ;;
    *winnt*)    echo Windows?! Really?!! Shesh. This script only works with Linux/UNIX. Terminating.
                exit 1
                ;;
    *)          PLATFORM_DESCRIPTOR=UNIX
                PLATFORM_TYPE=Other
                ;;
esac

#
# Depending upon the platform, provide default values for the path
# abstractions (we call these values "shorthands").
#
if [ "${PLATFORM_TYPE}" = "Rhapsody" ]; then
    LOCAL_PATH_PREFIX=/Local
    SYSTEM_PATH_PREFIX=/System
elif [ "$PLATFORM_TYPE" = "Darwin" ]; then
    LOCAL_PATH_PREFIX=
    SYSTEM_PATH_PREFIX=/System
else
    LOCAL_PATH_PREFIX=/Local
    SYSTEM_PATH_PREFIX=
fi

# Make sure the Libraries folder exists
mkdir -p ${WORKSPACE}/Libraries

# Setup Root
rm -rf ${ROOT}
echo "mkdir -p ${ROOT}${LOCAL_PATH_PREFIX}"
mkdir -p ${ROOT}${LOCAL_PATH_PREFIX}
echo "mkdir -p ${ROOT}${SYSTEM_PATH_PREFIX}"
mkdir -p ${ROOT}${SYSTEM_PATH_PREFIX}

# Look for and link to WebObjects
echo "Look for: ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library"
if [ -e "${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library" ]; then
	echo "ln -sfn ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library ${ROOT}${SYSTEM_PATH_PREFIX}"
	(ln -sfn ${FRAMEWORKS_REPOSITORY}/WebObjects/${WO_VERSION}${SYSTEM_PATH_PREFIX}/Library ${ROOT}${SYSTEM_PATH_PREFIX})
else
	echo "WebObjects Version ${WO_VERSION} NOT FOUND!"
	echo "This build cannot run without it. Verify that the installWebObjects.sh script is being run and is using ${FRAMEWORKS_REPOSITORY} for its FRAMEWORKS_REPOSITORY variable."
	exit 1
fi

# Setup and link to Wonder frameworks repository directory
echo "Look for: ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_SUB_PATH}/Library"
if [ -e "${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_SUB_PATH}/Library" ]; then
	echo "This version of Wonder has already been built. Skip creating it."
else
	mkdir -p ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_SUB_PATH}/Library
fi
echo "ln -sfn ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_SUB_PATH}/Library ${ROOT}${LOCAL_PATH_PREFIX}"
(ln -sfn ${FRAMEWORKS_REPOSITORY}/ProjectWOnder/${WONDER_SUB_PATH}/Library ${ROOT}${LOCAL_PATH_PREFIX})

# Link to the woproject.jar so Ant can use it for building
mkdir -p ${ROOT}/lib
ln -sf ${FRAMEWORKS_REPOSITORY}/WOProject/${WOPROJECT} ${ROOT}/lib/${WOPROJECT}

# Setup wolips.properties for Ant to use for building
cat > ${ROOT}/jenkins.build.properties << END
build.root=${ROOT}/Roots
wonder.patch=${WO_ALT_VERSION}
include.source=true

wonder.framework.install.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks
web.framework.install.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebServer/Documents/WebObjects/Frameworks

wonder.application.install.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Applications
web.application.install.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebServer/Documents/WebObjects

wo.local.root=${ROOT}${LOCAL_PATH_PREFIX}
wo.local.frameworks=${ROOT}${LOCAL_PATH_PREFIX}/Library/Frameworks

wo.system.root=${ROOT}${SYSTEM_PATH_PREFIX}
wo.system.frameworks=${ROOT}${SYSTEM_PATH_PREFIX}/Library/Frameworks

wo.extensions=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Extensions

wo.bootstrapjar=${ROOT}${SYSTEM_PATH_PREFIX}/Library/WebObjects/JavaApplications/wotaskd.woa/WOBootstrap.jar
wo.apps.root=${ROOT}${LOCAL_PATH_PREFIX}/Library/WebObjects/Applications
END

# Backward Compatibility!
echo "Create link for backward compatibility with old build.properties file name since old build jobs will still be pointing to it."
echo "ln -sfn ${ROOT}/jenkins.build.properties ${ROOT}/build.properties"
(ln -sfn ${ROOT}/jenkins.build.properties ${ROOT}/build.properties)
