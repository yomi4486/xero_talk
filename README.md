# xero_talk

ちょっとセキュアなチャットツール

ブログ記事
- [ちょっとセキュアなチャットツール Part1](https://xenfo.org/blog/life/2024-07-24/)

`ios/Runner/Info.plist`に下記を追記してください
```xml
<key>NSCameraUsageDescription</key>
<string>Access to take a photo by camera</string>
<key>NSAppleMusicUsageDescription</key>
<string>Access to pick a photo</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Access to pick a photo</string>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>http</string>
    <string>https</string>
</array>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```