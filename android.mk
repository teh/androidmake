# Expects the following parameters before inclusion:
#APP = ship2
#NS = com.binarycloud.ship2
#SDK = /home/tom/src/android-sdk-linux_86

MANIFEST = AndroidManifest.xml
ANDROID_JAR = $(SDK)/platforms/android-$(VERSION)/android.jar
RESOURCE_FILE = gen/resources
CLASSPATH = $(ANDROID_JAR):.:/home/tom/src/scala-2.8.0.final/lib/scala-library.jar:gen
FSC = /home/tom/src/scala-2.8.0.final/bin/fsc

AAPT = $(SDK)/platforms/android-$(VERSION)/tools/aapt
DEX = $(SDK)/platforms/android-$(VERSION)/tools/dx
APKBUILDER = $(SDK)/tools/apkbuilder
PACKAGE_PATH = $(subst .,/,$(NS))

default: debug
clean:
	rm -rf gen


gen/$(PACKAGE_PATH)/R.java: res/layout/* res/values/* res/raw/* $(MANIFEST)
	mkdir -p gen
	$(AAPT) package -f -M $(MANIFEST) -F $(RESOURCE_FILE) -I $(ANDROID_JAR) -S res -m -J gen

gen/$(PACKAGE_PATH)/R.class: gen/$(PACKAGE_PATH)/R.java
	javac -classpath $(CLASSPATH) gen/$(PACKAGE_PATH)/R.java

gen/min.jar: gen/$(PACKAGE_PATH)/R.class src/$(PACKAGE_PATH)/*scala
	$(FSC) -classpath $(CLASSPATH) -optimise -deprecation -d gen src/$(PACKAGE_PATH)/*scala
	rm -f gen/min.jar
	proguard -injars ./gen\(\!min.jar\):/home/tom/src/scala-2.8.0.final/lib/scala-library.jar \
	         -outjars gen/min.jar \
	         -libraryjars $(ANDROID_JAR) \
                 -dontoptimize \
	         -dontobfuscate \
                 -keep "public class * extends android.app.Activity" \
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

installemu: debug
	adb -e install -r gen/$(APP).apk

uninstallemu:
	adb -e uninstall $(NS)

debugkey:
	keytool -genkey -keypass android -keystore debug.keystore -alias androiddebugkey -storepass android \
            -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
