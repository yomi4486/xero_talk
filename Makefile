.PHONY: android, release, ios, clean, cache_clear, cache_clean
android:
	@cd android \
	&& flutter build appbundle \
	&& cd ..

release:
	@flutter run --release

ios:
	@cd ios \
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

cache_clear:
	@pod cache clean --all \
	&& rm -rf ~/Library/Developer/Xcode/DerivedData/*

cache_clean:
	@make cache_clear