# Expects the following parameters before inclusion:
#APP = ship2
#NS = com.binarycloud.ship2
#SDK = /home/tom/src/android-sdk-linux_86

VERSION = 1.6
MANIFEST = AndroidManifest.xml
ANDROID_JAR = $(SDK)/platforms/android-$(VERSION)/android.jar
RESOURCE_FILE = gen/resources
CLASSPATH = $(ANDROID_JAR):.:/usr/share/java/scala-library.jar

AAPT = $(SDK)/platforms/android-$(VERSION)/tools/aapt
DEX = $(SDK)/platforms/android-$(VERSION)/tools/dx
APKBUILDER = $(SDK)/tools/apkbuilder
PACKAGE_PATH = $(subst .,/,$(NS))

default: debug
clean:
	rm -rf gen

gen/scalamake.mk:
	mkdir -p gen
	python androidmake/dependencies.py $(PWD) > gen/scalamake.mk

include gen/scalamake.mk

gen/$(PACKAGE_PATH)/R.java:
	mkdir -p gen
	$(AAPT) package -f -M $(MANIFEST) -F $(RESOURCE_FILE) -I $(ANDROID_JAR) -S res -m -J gen

gen/$(PACKAGE_PATH)/R.class: gen/$(PACKAGE_PATH)/R.java
	javac -classpath $(CLASSPATH) gen/$(PACKAGE_PATH)/R.java

gen/min.jar: gen/$(PACKAGE_PATH)/R.class $(addprefix gen/$(PACKAGE_PATH)/, $(CLASSES))
	rm -f gen/min.jar
	proguard -injars ./gen\(\!min.jar\):/usr/share/java/scala-library.jar\
	         -outjars gen/min.jar\
	         -libraryjars $(ANDROID_JAR)\
                 -dontoptimize\
	         -dontobfuscate\
                 -keep "public class * extends android.app.Activity"\
                 -dontwarn

gen/classes.dex: gen/min.jar
	$(DEX) --dex --output=gen/classes.dex gen/min.jar

gen/$(APP).ap_: gen/classes.dex $(RESOURCE_FILE)
	$(APKBUILDER) gen/$(APP).ap_ -u -z $(RESOURCE_FILE) -f gen/classes.dex

gen/$(APP).apk: gen/$(APP).ap_
	jarsigner -signedjar gen/$(APP).apk -storepass ketyer gen/$(APP).ap_ mykey

debug: gen/$(APP).apk

install: debug
	adb -d install -r gen/$(APP).apk

uninstall:
	adb -d uninstall $(NS)
