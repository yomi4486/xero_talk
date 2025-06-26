# Flutter default keep rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Missing class 対策（必要な分だけ追加）
-dontwarn java.beans.**
-dontwarn org.w3c.dom.bootstrap.**
