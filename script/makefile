
TARGET_NAME="Example"

# defalut: write look
# 	

all: write look install

look:
	ldid -e ${TARGET_NAME}.app/${TARGET_NAME}

write:
	ldid -Sad.entitlements ./${TARGET_NAME}.app/${TARGET_NAME}

install:
	ideviceinstaller -i ./${TARGET_NAME}.app

clean: 
	ideviceinstaller -U com.kpappmanager.Example


# brew install ideviceinstaller 脚本安装ipa
#
#
#