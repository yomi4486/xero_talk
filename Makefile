.PHONY: android, release, ios, clean
android:
	cd android \
	&& flutter build appbundle

release:
	&& flutter run --release \

ios:
	cd ios \
	&& arch -x86_64 pod install --repo-update \
	&& cd ..

clean:
	@cd ios \
	&& rm -rf Pods \
	&& rm -f Podfile.lock \
	&& pod deintegrate \
	&& cd .. \
	&& rm -rf ~/Library/Developer/Xcode/DerivedData/* \
	&& flutter clean \
	&& flutter pub get \
	&& cd ios \
	&& pod install --repo-update \
	&& cd ..