NAMES = *
android:
	flutter build appbundle

release:
	flutter run --release

push %:
	git add .
	git commit -m "${@:hello-%=%}"
	git push