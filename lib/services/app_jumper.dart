import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 从本应用跳到手机上已安装的第三方 App。
class AppJumper {
    static const MethodChannel _channel = MethodChannel("study_manager/app_jumper");
    static const String bubeiPackage = "cn.com.langeasy.LangEasyLexis";
    static final Uri website = Uri.parse("https://www.bbdc.cn/");
    static final Uri appStore = Uri.parse("https://apps.apple.com/cn/app/id698570469");

    static Future<void> openBubeiDanci(BuildContext context) async {
        var opened = false;

        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
            opened = await _openAndroidPackage(bubeiPackage);
        } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
            opened = await _openUri(website);
            if (!opened) {
                opened = await _openUri(appStore);
            }
        } else {
            opened = await _openUri(website);
        }

        if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("打不开不背单词。请先在手机上安装该 App，或稍后重试。"),
                ),
            );
        }
    }

    static Future<bool> _openAndroidPackage(String packageName) async {
        try {
            final opened = await _channel.invokeMethod<bool>(
                "openPackage",
                <String, String>{"package": packageName},
            );
            return opened == true;
        } catch (_) {
            return false;
        }
    }

    static Future<bool> _openUri(Uri uri) async {
        try {
            return await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
            return false;
        }
    }
}
