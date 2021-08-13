
TARGET_NAME="Example"


ln -fhs "${BUILT_PRODUCTS_DIR}" "${PROJECT_DIR}"/LatestBuild
cp ${PROJECT_DIR}/../script/* "${BUILT_PRODUCTS_DIR}"
ldid -Sad.entitlements ./${TARGET_NAME}.app/${TARGET_NAME}
ideviceinstaller -i ./${TARGET_NAME}.app