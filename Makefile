NAMES = *
android:
	cd android
	flutter build appbundle

release:
	flutter run --release

push %:
	git add .
	git commit -m "${@:push-%=%}"
	git push

ios:
	cd ios
	arch -x86_64 pod install --repo-update
	cd ..