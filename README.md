# xero_talk - ちょっとセキュアなチャットツール

## 使用技術
<img src="https://go-skill-icons.vercel.app/api/icons?i=flutter,dart,firebase,apple" />

## その他メモ

<details>
  <summary>リリースビルド時のエラーの解決方法</summary>

下記エラーが出た場合は`ios/Runner.xcworkspace`を開いてタブの`Product > Build`をタップしてからまたコマンドを実行すれば治る。証明書の問題っぽい
```
Could not build the precompiled application for the device.
Error (Xcode): No profiles for 'com.example.xeroTalk' were found: Xcode couldn't find any iOS App Development provisioning profiles matching 'com.example.xeroTalk'. Automatic signing is disabled and unable to generate a profile. To enable
automatic signing, pass -allowProvisioningUpdates to xcodebuild.
~/xero_talk/ios/Runner.xcodeproj



It appears that there was a problem signing your application prior to installation on the device.

Verify that the Bundle Identifier in your project is your signing id in Xcode
  open ios/Runner.xcworkspace

Also try selecting 'Product > Build' to fix the problem.

Error running application on yomi4486’s iPhone13.
```
</details>
