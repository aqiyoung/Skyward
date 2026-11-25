// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ja';

  static String m0(count) => "${count} 件選択済み";

  static String m1(name) => "${name} をローカルプロキシに追加しました";

  static String m2(name) => "${name} はすでにローカルプロキシにあります";

  static String m3(count, skipped) => "${count}件を追加、${skipped}件は既存のためスキップ";

  static String m4(detail) => "データを消去できませんでした：${detail}";

  static String m5(count) => "${count} 件の接続";

  static String m6(code) =>
      "Windows が SkywardCore.exe の実行を拒否しました（エラー ${code}）。スマート アプリ コントロールや AppLocker などのアプリ制御ポリシーは未署名のプログラムをブロックします。ポリシーで Skyward を許可するか、ポリシーを無効にしてから再試行してください。";

  static String m7(name) =>
      "アプリの起動が2回連続で完了しませんでした。クラッシュループを断ち切るため、プロファイル ${name} の選択を解除し、今回の自動セットアップをスキップしました。いつでも選択し直せます。";

  static String m8(url) => "${url} からプロファイルを作成しますか？";

  static String m9(count, label) =>
      "${Intl.plural(count, other: 'カスタム設定はサブルールに対応していないため、SUB-RULE ルール ${label} 件を破棄しました')}";

  static String m10(message) => "コアがこのプロキシを解析できません：${message}";

  static String m11(proxy, target) =>
      "${proxy} は ${target} 経由で接続しますが、${target} から再び ${proxy} に戻るため、ループになります";

  static String m12(name) => "名前 ${name} は他のプロキシまたはプロキシグループで使用されています";

  static String m13(path) => "プロキシグループが循環参照しています：${path}";

  static String m14(name) =>
      "空グループのフォールバックはプロキシである必要がありますが、${name} は存在しないかプロキシグループです";

  static String m15(name, message) => "${name}は有効な正規表現ではありません：${message}";

  static String m16(name) => "ダイヤラープロキシ ${name} が存在しません";

  static String m17(names) => "次のプロキシプロバイダーは存在しません：${names}";

  static String m18(names) => "次のプロキシまたはポリシーは存在しません：${names}";

  static String m19(name) => "${name} は組み込みポリシー名のため使用できません";

  static String m20(count) => "${count} 件に問題があり、プロファイルの適用に失敗する可能性があります";

  static String m21(count) => "${count} 日前";

  static String m22(count) => "${count} 日前";

  static String m23(label) => "選択した${label}を削除してもよろしいですか？";

  static String m24(label) => "この${label}を削除してもよろしいですか？";

  static String m25(label) => "${label}の詳細";

  static String m26(name) => "${name} 経由の接続が使用元のプロキシに戻るため、接続を中止しました";

  static String m27(value, percent) => "直結 ${value} · ${percent}";

  static String m28(days, hours) => "${days}日 ${hours}時間";

  static String m29(hours, minutes) => "${hours}時間 ${minutes}分";

  static String m30(count) => "${count}分";

  static String m31(label) => "${label}は空にできません";

  static String m32(label) => "${label}はすでに存在します";

  static String m33(count) => "${count} 件が失敗しました";

  static String m34(label, message) => "${label}：${message}";

  static String m35(name) => "${name} はすでに最新です";

  static String m36(name) => "${name} を更新しました";

  static String m37(count) => "${count} 個";

  static String m38(count) => "${count} 件タイムアウト";

  static String m39(action) => "「${action}」で使用中です。保存するとこちらに移動します。";

  static String m40(modifiers) => "${modifiers} のいずれかを含めてください";

  static String m41(count) => "${count} 時間前";

  static String m42(count) => "${count} 時間前";

  static String m43(target) => "${target} は無効なポリシーです";

  static String m44(proxyName) => "${proxyName} は無効なプロキシです";

  static String m45(providerName) => "${providerName} は無効なプロキシプロバイダーです";

  static String m46(ruleSet) => "${ruleSet} は無効なルールセットです";

  static String m47(subRule) => "${subRule} は無効な SUB_RULE です";

  static String m48(count) => "${count} 件";

  static String m49(line, message) => "${line}行目：${message}";

  static String m50(appName) =>
      "1. システム設定 > プライバシーとセキュリティ を開く\n2. 位置情報サービス を選択\n3. リストで ${appName} を見つけてチェックを入れる\n\n設定が完了したらアプリに戻ると、通常どおり使用できます。ご協力ありがとうございます。";

  static String m51(label, max) => "${label}は最大${max}文字です";

  static String m52(size) => "${size} を解放しました";

  static String m53(count) => "${count} 分前";

  static String m54(count) => "${count} 分前";

  static String m55(count) => "${count} か月前";

  static String m56(count) => "${count} か月前";

  static String m57(code) =>
      "サーバーがアクセスを拒否しました（HTTP ${code}）。リンクの期限切れか、認証情報が誤っている可能性があります";

  static String m58(code) => "サーバーがリクエストを拒否しました（HTTP ${code}）";

  static String m59(code) =>
      "このアドレスには何も見つかりませんでした（HTTP ${code}）。URL が正しいか確認してください";

  static String m60(detail) => "ネットワークリクエストに失敗しました：${detail}";

  static String m61(code) => "サーバーで問題が発生しました（HTTP ${code}）。しばらくしてから再試行してください";

  static String m62(label) => "${label}はまだありません";

  static String m63(label, min, max) => "${label}は${min}から${max}の範囲で指定してください";

  static String m64(label) => "${label}は数値である必要があります";

  static String m65(label) => "${label} は 1024〜49151 の範囲で指定してください";

  static String m66(port) => "ポート ${port}";

  static String m67(days) => "残り ${days} 日";

  static String m68(date, days) => "${date} に期限切れ、残り ${days} 日";

  static String m69(time) => "${time}に更新";

  static String m70(label, profiles) =>
      "${label} は ${profiles} でまだ使用されており、削除するとそれらが正常に動作しなくなります。削除してもよろしいですか？";

  static String m71(count, label) =>
      "${Intl.plural(count, other: 'プロキシ ${label} 件')}";

  static String m72(name, count) => "${name} など${count}件のプロキシ";

  static String m73(removed) =>
      "次のプロキシが削除されます：${removed}。名前を変えた行は新しいプロキシとして扱われ、削除されたプロキシを参照するカスタムプロファイルでは見つからないと表示されます。適用しますか？";

  static String m74(removed, added) =>
      "次のプロキシが削除されます：${removed}。次のプロキシが追加されます：${added}。名前を変えた行は新しいプロキシとして扱われ、削除されたプロキシを参照するカスタムプロファイルでは見つからないと表示されます。適用しますか？";

  static String m75(label) =>
      "${label} はこのプロファイルのルール、プロキシグループ、ダイヤラープロキシ、DNS または NTP からまだ参照されており、削除するとそれらの参照は無効になります。削除してもよろしいですか？";

  static String m76(count, label) =>
      "${Intl.plural(count, other: 'プロキシグループ ${label} 件')}";

  static String m77(value, percent) => "プロキシ ${value} · ${percent}";

  static String m78(percent, upload, download) =>
      "${percent} · ↑ ${upload} ↓ ${download}";

  static String m79(pick, now) => "${now} ではなく ${pick} を選びます";

  static String m80(group) => "${group} で選ばれるサーバー";

  static String m81(pick) => "${pick} を維持します";

  static String m82(number) => "条件 ${number}";

  static String m83(profile) => "「${profile}」がこれらのサイトを確認しようとしています";

  static String m84(count) => "${Intl.plural(count, other: '${count} 台のサーバー')}";

  static String m85(profile) => "「${profile}」を削除しますか？";

  static String m86(requests, used, cap) =>
      "本日のチェック: ${requests} · ${cap} 中 ${used}";

  static String m87(condition) => "${condition} を除く";

  static String m88(country) => "出口 ${country}";

  static String m89(member) => "${member} 経由";

  static String m90(scenario) => "シナリオ「${scenario}」から";

  static String m91(title) =>
      "「${title}」は変更できません。編集はコピーに保存され、そのコピーが実行中のシナリオになります。";

  static String m92(mode) => "ルートはルールモードで適用されます。現在の接続は${mode}モードです。";

  static String m93(profile) => "「${profile}」を追加しました";

  static String m94(node) => "${node} が停止しました";

  static String m95(from, to) => "モード ${from} → ${to}";

  static String m96(count) =>
      "${Intl.plural(count, other: '現在 ${count} 台が該当')}";

  static String m97(ms) => "${ms} ms 未満";

  static String m98(text) => "名前に ${text}";

  static String m99(what) => "${what} 以外";

  static String m100(provider) => "${provider} から";

  static String m101(number) => "ステップ ${number}";

  static String m102(tag) => "タグ ${tag}";

  static String m103(line, text) => "${line} 行目: ${text}";

  static String m104(check) => "チェック ${check} はどこでも使われていないため、実行されません";

  static String m105(hosts) => "サードパーティのサイトに接続します: ${hosts}";

  static String m106(group) => "この設定にはグループ ${group} がありません";

  static String m107(group) => "${group} のサーバーはフィルターを通過しません";

  static String m108(tag) => "タグ ${tag} は使われていません";

  static String m109(group, tier) => "現在、${group} のサーバーは「${tier}」にありません";

  static String m110(tier, after) => "「${tier}」は「${after}」と同じ条件のため、何も振り分けられません";

  static String m111(name, count) => "${name} ほか ${count} 件";

  static String m112(keys) => "取り込みました。次の項目は自分でも変更していたため、自分の内容を残しました: ${keys}";

  static String m113(mode) => "モード: ${mode}";

  static String m114(node) => "${node} を使い続けます。障害時のみ離れ、復旧すると戻ります。";

  static String m115(kind) => "ネットワーク: ${kind}";

  static String m116(condition) => "${condition} のみ";

  static String m117(tier) => "チェック後に「${tier}」に入る可能性があります";

  static String m118(node) => "固定: ${node}";

  static String m119(error) => "動作のエラー: ${error}";

  static String m120(profile) => "動作 ${profile} が見つからないため既定を使用";

  static String m121(error) => "ルーティング状態を保存できませんでした: ${error}";

  static String m122(tier) => "「${tier}」のサーバーへ移動";

  static String m123(from) => "サーバーを変更し、${from} は 15 分間除外";

  static String m124(from) => "${from} が停止したため最適な予備に切り替え";

  static String m125(from, gain) => "${from} から切り替え: ${gain} ms 高速";

  static String m126(node) => "シナリオが ${node} を維持しています";

  static String m127(node) => "${node} はこのグループにありません";

  static String m128(limit) => "切り替え上限に達しました (1 時間に ${limit} 回)";

  static String m129(mode) => "未使用: モード ${mode}";

  static String m130(from) => "${from} は候補から外れました";

  static String m131(kind) => "ネットワークが「${kind}」の間は一時停止中: チェックも切り替えも行いません";

  static String m132(route, error) => "ルート「${route}」を適用できません: ${error}";

  static String m133(route) => "ルート「${route}」はスキップされました。同じ名前のグループが既にあります。";

  static String m134(route, to) => "ルート「${route}」の送信先「${to}」はプロファイルにありません。";

  static String m135(node) => "シナリオが ${node} に切り替えます";

  static String m136(node) => "固定したサーバー ${node} に切り替え";

  static String m137(node) => "動作するサーバーがないため ${node} にフォールバック";

  static String m138(scenario) =>
      "このグループはシナリオ「${scenario}」のルートが作成しました。編集や削除はそちらで行います。";

  static String m139(scenario) => "現在、このグループはシナリオ「${scenario}」が制御しています。";

  static String m140(count, total) => "${total} 件中 ${count} 件が一致";

  static String m141(node) => "チェックで確認でき次第 ${node} に切り替えます";

  static String m142(node, gain) => "${gain} ms 速い状態が続けば ${node} に切り替えます";

  static String m143(node, minutes) => "${minutes} 分後に ${node} へ切り替える可能性があります";

  static String m144(name) => "チェック ${name}";

  static String m145(name) => "ネットワーク診断 ${name}";

  static String m146(count) =>
      "${Intl.plural(count, other: 'このグループの ${count} 台のサーバーから選びます。')}";

  static String m147(count) => "${count} 件のルールにヒット";

  static String m148(count, upload, download) =>
      "${count} · ↑ ${upload} ↓ ${download}";

  static String m149(percent, count) => "ヒット流量の ${percent} · ${count}";

  static String m150(count, label) =>
      "${Intl.plural(count, other: 'ルール ${label} 件')}";

  static String m151(appName) => "${appName}（セーフモード）";

  static String m152(count) => "${count} 秒";

  static String m153(count) => "${count} 件が有効";

  static String m154(count) => "${count} 件に問題";

  static String m155(time) => "${time} に検査";

  static String m156(count) => "設定 ${count} 件";

  static String m157(link) => "${link} からプロキシを読み取れませんでした";

  static String m158(label) => "${label}は1項目のみ指定できます";

  static String m159(value) => "ピーク ${value}";

  static String m160(hour, value) => "ピーク ${hour}:00 · ${value}";

  static String m161(value) => "累計 ${value}";

  static String m162(transport) => "${transport} リクエストヘッダー";

  static String m163(label) => "${label}はURLである必要があります";

  static String m164(month, day) => "${month}/${day} の週";

  static String m165(count) => "${count} 年前";

  static String m166(count) => "${count} 年前";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("アプリについて"),
    "accessControl": MessageLookupByLibrary.simpleMessage("アクセス制御"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選択したアプリのみVPNを経由します",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "アクセス制御では、プロキシを利用するアプリを選びます。",
    ),
    "accessControlDisabledDesc": MessageLookupByLibrary.simpleMessage(
      "アプリアクセス制御は無効です",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選択したアプリはVPNから除外されます",
    ),
    "accessControlSelectedCount": m0,
    "account": MessageLookupByLibrary.simpleMessage("アカウント"),
    "acknowledgments": MessageLookupByLibrary.simpleMessage("謝辞"),
    "acknowledgmentsDesc": MessageLookupByLibrary.simpleMessage(
      "Skyward は chen08209 氏の FlClash から派生し、MetaCubeX の mihomo (Clash.Meta) カーネルを基に構築されています。両者は GPL-3.0 の下で公開されています。",
    ),
    "action": MessageLookupByLibrary.simpleMessage("アクション"),
    "actionDelayTest": MessageLookupByLibrary.simpleMessage("すべての遅延をテスト"),
    "actionDirectMode": MessageLookupByLibrary.simpleMessage("ダイレクトモード"),
    "actionGlobalMode": MessageLookupByLibrary.simpleMessage("グローバルモード"),
    "actionMode": MessageLookupByLibrary.simpleMessage("モード切替"),
    "actionProxy": MessageLookupByLibrary.simpleMessage("システムプロキシ"),
    "actionRuleMode": MessageLookupByLibrary.simpleMessage("ルールモード"),
    "actionStart": MessageLookupByLibrary.simpleMessage("開始/停止"),
    "actionTun": MessageLookupByLibrary.simpleMessage("TUN"),
    "actionUpdateProfiles": MessageLookupByLibrary.simpleMessage("プロファイルを更新"),
    "actionView": MessageLookupByLibrary.simpleMessage("表示/非表示"),
    "adBlockDescription": MessageLookupByLibrary.simpleMessage(
      "一般的な広告・追跡ドメインを遮断します。ルールは購読のルールより先に適用されます。",
    ),
    "add": MessageLookupByLibrary.simpleMessage("追加"),
    "addCustomProxy": MessageLookupByLibrary.simpleMessage("プロキシを追加"),
    "addFilters": MessageLookupByLibrary.simpleMessage("フィルターを追加"),
    "addNodes": MessageLookupByLibrary.simpleMessage("ノードを追加"),
    "addOverrideEntry": MessageLookupByLibrary.simpleMessage("上書き項目を追加"),
    "addProfile": MessageLookupByLibrary.simpleMessage("プロファイルを追加"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループを追加"),
    "addRule": MessageLookupByLibrary.simpleMessage("ルールを追加"),
    "addSettingEntry": MessageLookupByLibrary.simpleMessage("設定項目を追加"),
    "addSsid": MessageLookupByLibrary.simpleMessage("SSIDを追加"),
    "addToLocalProxies": MessageLookupByLibrary.simpleMessage("ローカルプロキシに追加"),
    "addedRules": MessageLookupByLibrary.simpleMessage("追加ルール"),
    "addedToLocalProxies": m1,
    "additionalParameters": MessageLookupByLibrary.simpleMessage("追加パラメータ"),
    "additionalPrefix": MessageLookupByLibrary.simpleMessage("名前のプレフィックス"),
    "additionalSuffix": MessageLookupByLibrary.simpleMessage("名前のサフィックス"),
    "address": MessageLookupByLibrary.simpleMessage("アドレス"),
    "addressHelp": MessageLookupByLibrary.simpleMessage("WebDAVサーバーのアドレス"),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "有効なWebDAVアドレスを入力してください",
    ),
    "advancedConfig": MessageLookupByLibrary.simpleMessage("詳細設定"),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "詳細設定には、DNS、追加ルール、スクリプトがあります。",
    ),
    "ageEncryptedProfile": MessageLookupByLibrary.simpleMessage("暗号化されたプロファイル"),
    "ageSecretKey": MessageLookupByLibrary.simpleMessage("age 秘密鍵"),
    "ageSecretKeyRequiredTip": MessageLookupByLibrary.simpleMessage(
      "このプロファイルは age で暗号化されており、復号には age 秘密鍵が必要です",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("同意する"),
    "allReferencedProxies": MessageLookupByLibrary.simpleMessage(
      "参照されているすべてのプロキシ",
    ),
    "allReferencedProxyProviders": MessageLookupByLibrary.simpleMessage(
      "参照されているすべてのプロキシプロバイダー",
    ),
    "allowBypass": MessageLookupByLibrary.simpleMessage("アプリによるVPNバイパスを許可"),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "アプリが独自の VPN を確立して、この VPN を迂回できるようにします。",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("LAN 接続を許可"),
    "allowedIps": MessageLookupByLibrary.simpleMessage("許可する IP"),
    "alreadyInLocalProxies": m2,
    "answers": MessageLookupByLibrary.simpleMessage("応答"),
    "app": MessageLookupByLibrary.simpleMessage("アプリ"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage("アプリアクセス制御"),
    "appIconDesign": MessageLookupByLibrary.simpleMessage("アプリアイコンのデザイン"),
    "appProxiesEmpty": MessageLookupByLibrary.simpleMessage("ローカルプロキシがありません"),
    "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage("システムDNSを追加"),
    "authentication": MessageLookupByLibrary.simpleMessage("認証"),
    "authenticationDesc": MessageLookupByLibrary.simpleMessage(
      "認証を有効にすると、ローカルプロキシポートの利用にユーザー名とパスワードが必要になります。",
    ),
    "authenticationSystemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "認証が有効な間、システムプロキシは適用されません。",
    ),
    "authorize": MessageLookupByLibrary.simpleMessage("許可"),
    "authorized": MessageLookupByLibrary.simpleMessage("許可済み"),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage("更新の自動チェック"),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage("接続を自動的に閉じる"),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "プロキシを切り替えると、既存の接続を自動的に閉じます。",
    ),
    "autoInclude": MessageLookupByLibrary.simpleMessage("自動で含める"),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("自動起動"),
    "autoRun": MessageLookupByLibrary.simpleMessage("自動実行"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "自動実行はアプリを開いたときにプロキシを開始します。",
    ),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage("システムDNSを自動設定"),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("自動更新"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔"),
    "back": MessageLookupByLibrary.simpleMessage("戻る"),
    "backgroundBlur": MessageLookupByLibrary.simpleMessage("背景のぼかし"),
    "backup": MessageLookupByLibrary.simpleMessage("バックアップ"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage("バックアップと復元"),
    "backupFromNewerVersion": MessageLookupByLibrary.simpleMessage(
      "このバックアップは新しいバージョンのアプリで作成されています。アプリを更新してから復元してください",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("バックアップが完了しました"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("基本情報"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("基本ポリシー"),
    "batchAdd": MessageLookupByLibrary.simpleMessage("一括追加"),
    "batchImport": MessageLookupByLibrary.simpleMessage("一括インポート"),
    "batchLinkInputTip": MessageLookupByLibrary.simpleMessage(
      "1行に1つのリンクを入力してください",
    ),
    "batchListInputTip": MessageLookupByLibrary.simpleMessage(
      "1行に1項目、またはカンマ区切りで入力してください",
    ),
    "batchMapInputTip": MessageLookupByLibrary.simpleMessage(
      "1行に1件、キーと値はスペースで区切ってください",
    ),
    "batchPreviewTip": m3,
    "batchUrlInputTip": MessageLookupByLibrary.simpleMessage(
      "1行に1つのURLを入力してください",
    ),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "電池の最適化を無視すると、アプリがバックグラウンドで動作し続けます。",
    ),
    "bind": MessageLookupByLibrary.simpleMessage("連携"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("ブラックリストモード"),
    "blockConnection": MessageLookupByLibrary.simpleMessage("接続をブロック"),
    "brightness": MessageLookupByLibrary.simpleMessage("明度"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("除外ドメイン"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "除外ドメインはシステムプロキシが有効な場合のみ適用されます。",
    ),
    "bypassPrivateRoute": MessageLookupByLibrary.simpleMessage(
      "プライベートアドレスをバイパス",
    ),
    "bypassPrivateRouteDesc": MessageLookupByLibrary.simpleMessage(
      "プライベートアドレスをバイパスすると、LAN・ループバック・マルチキャストのアドレスは TUN を通りません。",
    ),
    "cache": MessageLookupByLibrary.simpleMessage("キャッシュ"),
    "cacheAlgorithm": MessageLookupByLibrary.simpleMessage("キャッシュアルゴリズム"),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "キャッシュが破損しています。クリアしますか？",
    ),
    "cacheMaxSize": MessageLookupByLibrary.simpleMessage("キャッシュサイズ"),
    "cameraPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "QRコードをスキャンするには、システム設定でカメラへのアクセスを許可するか、アルバムからQRコード画像を選択してください。",
    ),
    "cameraPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "カメラの権限が必要です",
    ),
    "cameraUnavailable": MessageLookupByLibrary.simpleMessage("カメラを使用できません"),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("すべて選択解除"),
    "cannotSave": MessageLookupByLibrary.simpleMessage("保存できません"),
    "capsule": MessageLookupByLibrary.simpleMessage("カプセル"),
    "changeProxyFailedTip": MessageLookupByLibrary.simpleMessage(
      "プロキシの切り替えに失敗したため、前回の選択に戻しました",
    ),
    "changelogBreaking": MessageLookupByLibrary.simpleMessage("破壊的変更"),
    "changelogFeatures": MessageLookupByLibrary.simpleMessage("新機能"),
    "changelogFixes": MessageLookupByLibrary.simpleMessage("不具合修正"),
    "changelogPerformance": MessageLookupByLibrary.simpleMessage("パフォーマンス"),
    "changelogReverts": MessageLookupByLibrary.simpleMessage("取り消し"),
    "checkCertificate": MessageLookupByLibrary.simpleMessage("TLS証明書を検証"),
    "checkCertificateDesc": MessageLookupByLibrary.simpleMessage(
      "TLS 証明書の検証を無効にすると、サブスクリプションとバックアップが中間者攻撃にさらされます。",
    ),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("更新を確認"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage("すでに最新バージョンです"),
    "cipher": MessageLookupByLibrary.simpleMessage("暗号方式"),
    "clearCache": MessageLookupByLibrary.simpleMessage("キャッシュを削除"),
    "clearData": MessageLookupByLibrary.simpleMessage("データを消去"),
    "clearDataAndExitTip": MessageLookupByLibrary.simpleMessage(
      "すべてのプロファイル、設定、ローカルデータを削除してアプリを終了します。もう一度開くと最初から始められます。",
    ),
    "clearDataFailed": m4,
    "clearDnsCache": MessageLookupByLibrary.simpleMessage("DNSキャッシュをクリア"),
    "clearDnsCacheFailed": MessageLookupByLibrary.simpleMessage(
      "DNSキャッシュのクリアに失敗しました",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("検索をクリア"),
    "clientFingerprint": MessageLookupByLibrary.simpleMessage(
      "クライアントフィンガープリント",
    ),
    "clipboardExport": MessageLookupByLibrary.simpleMessage("クリップボードへエクスポート"),
    "clipboardImport": MessageLookupByLibrary.simpleMessage("クリップボードからインポート"),
    "clipboardWriteFailed": MessageLookupByLibrary.simpleMessage(
      "クリップボードにコピーできませんでした。選択範囲が大きすぎる可能性があります",
    ),
    "close": MessageLookupByLibrary.simpleMessage("閉じる"),
    "closeConnections": MessageLookupByLibrary.simpleMessage("接続を閉じる"),
    "color": MessageLookupByLibrary.simpleMessage("カラー"),
    "colorStyle": MessageLookupByLibrary.simpleMessage("配色スタイル"),
    "colorsSection": MessageLookupByLibrary.simpleMessage("配色"),
    "columns": MessageLookupByLibrary.simpleMessage("列数"),
    "compact": MessageLookupByLibrary.simpleMessage("コンパクト"),
    "compatible": MessageLookupByLibrary.simpleMessage("互換モード"),
    "configuration": MessageLookupByLibrary.simpleMessage("Configuration"),
    "confirm": MessageLookupByLibrary.simpleMessage("OK"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "すべてのデータを消去してもよろしいですか？",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "このプロキシグループを削除してもよろしいですか？",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "現在のウィンドウを閉じてもよろしいですか？",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "コアを強制クラッシュさせてもよろしいですか？",
    ),
    "congestionControl": MessageLookupByLibrary.simpleMessage("輻輳制御"),
    "congestionController": MessageLookupByLibrary.simpleMessage("TCP 輻輳制御"),
    "congestionControllerDesc": MessageLookupByLibrary.simpleMessage(
      "TCP 輻輳制御は mips スタックでのみ有効です。",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("接続済み"),
    "connecting": MessageLookupByLibrary.simpleMessage("接続中…"),
    "connection": MessageLookupByLibrary.simpleMessage("接続"),
    "connectionCount": m5,
    "connectionStats": MessageLookupByLibrary.simpleMessage("接続統計"),
    "connectionStatsDesc": MessageLookupByLibrary.simpleMessage(
      "ライブ接続、最近のリクエスト、DNS クエリ",
    ),
    "connections": MessageLookupByLibrary.simpleMessage("接続"),
    "connectivity": MessageLookupByLibrary.simpleMessage("接続状態："),
    "content": MessageLookupByLibrary.simpleMessage("内容"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage("内容は空にできません"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "グローバル追加ルールを管理",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("コピー"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage("環境変数をコピー"),
    "copyLink": MessageLookupByLibrary.simpleMessage("リンクをコピー"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("コピーしました"),
    "core": MessageLookupByLibrary.simpleMessage("コア"),
    "coreBlockedByPolicyTip": m6,
    "coreBlockedBySmartAppControlTip": MessageLookupByLibrary.simpleMessage(
      "Windows のスマート アプリ コントロールが、署名されていない SkywardCore.exe をブロックしました。Windows セキュリティ → アプリとブラウザーの制御 → スマート アプリ コントロールの設定で「オフ」を選び、Skyward を再起動してください。一度オフにすると、Windows を再インストールしない限り再度オンにはできません。",
    ),
    "coreStatus": MessageLookupByLibrary.simpleMessage("コアの状態"),
    "coreVersion": MessageLookupByLibrary.simpleMessage("コアのバージョン"),
    "country": MessageLookupByLibrary.simpleMessage("地域"),
    "crashDetected": MessageLookupByLibrary.simpleMessage("クラッシュを検出しました"),
    "crashDetectedTip": m7,
    "crashTest": MessageLookupByLibrary.simpleMessage("クラッシュテスト"),
    "create": MessageLookupByLibrary.simpleMessage("作成"),
    "createProfileFromUrlTip": m8,
    "creationTime": MessageLookupByLibrary.simpleMessage("作成日時"),
    "currentOutboundDesc": MessageLookupByLibrary.simpleMessage(
      "起動ボタンがあるため削除できません",
    ),
    "currentVersion": MessageLookupByLibrary.simpleMessage("現在のバージョン"),
    "custom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "customColor": MessageLookupByLibrary.simpleMessage("カスタムカラー"),
    "customImportDroppedSubRules": m9,
    "customIssueCoreRejected": m10,
    "customIssueDialerLoop": m11,
    "customIssueDuplicateName": m12,
    "customIssueEmptyName": MessageLookupByLibrary.simpleMessage("名前が空です"),
    "customIssueGroupLoop": m13,
    "customIssueInvalidEmptyFallback": m14,
    "customIssueInvalidFilter": m15,
    "customIssueMissingDialer": m16,
    "customIssueMissingProviders": m17,
    "customIssueMissingProxies": m18,
    "customIssueNoProxySource": MessageLookupByLibrary.simpleMessage(
      "プロキシもプロキシプロバイダーも選択されていないため、コアはこのグループを拒否します",
    ),
    "customIssueReservedName": m19,
    "customIssuesSummary": m20,
    "customProfile": MessageLookupByLibrary.simpleMessage("カスタム"),
    "customProfileDesc": MessageLookupByLibrary.simpleMessage(
      "アプリのプロキシと他のプロファイルからプロキシグループとルールを組み立てます",
    ),
    "customProfileResources": MessageLookupByLibrary.simpleMessage(
      "カスタムプロファイルのリソース",
    ),
    "customProfileResourcesDesc": MessageLookupByLibrary.simpleMessage(
      "カスタムプロファイルのリソースは、自分で追加してカスタムプロファイルから使うプロキシ、ルールプロバイダー、フィルター、アイコンセットです。",
    ),
    "cut": MessageLookupByLibrary.simpleMessage("切り取り"),
    "dark": MessageLookupByLibrary.simpleMessage("ダーク"),
    "dashboard": MessageLookupByLibrary.simpleMessage("ダッシュボード"),
    "dashboardAddableSection": MessageLookupByLibrary.simpleMessage("追加できるカード"),
    "dashboardSplitStack": MessageLookupByLibrary.simpleMessage("スタックを分解"),
    "data": MessageLookupByLibrary.simpleMessage("Data"),
    "database": MessageLookupByLibrary.simpleMessage("データベース"),
    "databaseWriteFailedTip": MessageLookupByLibrary.simpleMessage(
      "変更の保存に失敗したため、元に戻しました",
    ),
    "day": MessageLookupByLibrary.simpleMessage("日"),
    "daysAgo": m21,
    "daysAgoShort": m22,
    "defaultSelected": MessageLookupByLibrary.simpleMessage("デフォルトの選択"),
    "defaultText": MessageLookupByLibrary.simpleMessage("デフォルト"),
    "definitionNotMap": MessageLookupByLibrary.simpleMessage(
      "設定は name と type を含む YAML マッピングである必要があります",
    ),
    "delay": MessageLookupByLibrary.simpleMessage("遅延"),
    "delayFailed": MessageLookupByLibrary.simpleMessage("失敗"),
    "delayTest": MessageLookupByLibrary.simpleMessage("遅延テスト"),
    "delayTestTimeout": MessageLookupByLibrary.simpleMessage("遅延テストのタイムアウト"),
    "delete": MessageLookupByLibrary.simpleMessage("削除"),
    "deleteMultipTip": m23,
    "deleteTip": m24,
    "desc": MessageLookupByLibrary.simpleMessage(
      "ClashMetaベースのマルチプラットフォーム対応プロキシクライアント。シンプルで使いやすく、オープンソースで広告もありません。",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("宛先"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage("宛先GeoIP"),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage("宛先IP ASN"),
    "details": m25,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "サードパーティAPIに依存しているため、参考値です",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("開発者モード"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "開発者モードが有効になりました。",
    ),
    "diagnostics": MessageLookupByLibrary.simpleMessage("診断"),
    "dialerProxy": MessageLookupByLibrary.simpleMessage("ダイヤラープロキシ"),
    "dialerProxyDesc": MessageLookupByLibrary.simpleMessage(
      "ダイヤラープロキシは NTP サーバーへの接続に使用するアウトバウンドです。",
    ),
    "dialerProxyLoopStopped": m26,
    "direct": MessageLookupByLibrary.simpleMessage("ダイレクト"),
    "directShare": m27,
    "disableIcmpForwarding": MessageLookupByLibrary.simpleMessage(
      "ICMP 転送を無効化",
    ),
    "disableIcmpForwardingDesc": MessageLookupByLibrary.simpleMessage(
      "ICMP 転送を無効にすると TUN が ping に直接応答するため、ping に実際の遅延が表示されなくなります。",
    ),
    "disableKeepAlive": MessageLookupByLibrary.simpleMessage("TCP キープアライブを無効化"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("UDPを無効化"),
    "disabled": MessageLookupByLibrary.simpleMessage("無効"),
    "discardChanges": MessageLookupByLibrary.simpleMessage("変更を破棄しますか？"),
    "disclaimer": MessageLookupByLibrary.simpleMessage("免責事項"),
    "disclaimerAcceptContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアをインストール、複製または使用した時点で、本声明のすべての内容を読み、同意したものとみなされます。いずれかの条項に同意いただけない場合は、直ちに使用を中止し、本ソフトウェアをアンインストールしてください。",
    ),
    "disclaimerAcceptTitle": MessageLookupByLibrary.simpleMessage("声明への同意"),
    "disclaimerAcknowledgeLabel": MessageLookupByLibrary.simpleMessage(
      "この声明を読み、理解しました",
    ),
    "disclaimerAcknowledgeTip": MessageLookupByLibrary.simpleMessage(
      "内容を理解したことを確認するため、以下の声明を読み、下のチェックボックスをオンにしてください：",
    ),
    "disclaimerAcknowledgeTitle": MessageLookupByLibrary.simpleMessage("声明の確認"),
    "disclaimerChangesContent": MessageLookupByLibrary.simpleMessage(
      "開発者はバージョンの更新に伴い本声明を変更することがあり、変更内容は新しいバージョンの公開とともに効力を生じます。更新後も本ソフトウェアを引き続き使用した場合、変更後の声明に同意したものとみなされます。",
    ),
    "disclaimerChangesTitle": MessageLookupByLibrary.simpleMessage("本声明の変更"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "Skyward（以下「本ソフトウェア」）をご利用になる前に、本声明の内容をよくお読みになり、十分にご理解ください。「同意する」をタップすると、以下のすべての条項を読み、理解し、承諾したものとみなされます。同意いただけない場合は「終了」をタップし、本ソフトウェアの使用を中止してください。",
    ),
    "disclaimerLiabilityContent": MessageLookupByLibrary.simpleMessage(
      "適用法で認められる最大限の範囲において、開発者およびすべての貢献者は、本ソフトウェアの使用または使用不能に起因する直接的、間接的、偶発的、特別、懲罰的または結果的な損害（データの消失、機器の損傷、ネットワーク障害、業務の中断、逸失利益、およびそれに起因する法的紛争を含むがこれらに限らない）について、その可能性を知らされていた場合であっても、一切責任を負いません。",
    ),
    "disclaimerLiabilityTitle": MessageLookupByLibrary.simpleMessage("責任の制限"),
    "disclaimerLicenseContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは GPL-3.0 ライセンスのもとでオープンソースとして公開されています。同ライセンスを遵守する限り、自由に使用、改変、再配布できますが、派生物も GPL-3.0 で公開し、原著作者の著作権表示を保持する必要があります。\n\n本ソフトウェアに含まれるサードパーティのコンポーネント（Clash.Meta コアを含む）は、それぞれのライセンスに従います。改変版や再配布版に起因する問題について、原著作者は責任を負いません。",
    ),
    "disclaimerLicenseTitle": MessageLookupByLibrary.simpleMessage(
      "オープンソースライセンス",
    ),
    "disclaimerNoServiceStatement": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェア自体は、プロキシサーバー、ノード、サブスクリプション、ネットワーク接続サービスを一切提供しておらず、それらのサービス提供者と提携、代理、保証の関係はありません。",
    ),
    "disclaimerPrivacyContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは、サブスクリプション URL、ノード情報、設定内容、閲覧したウェブサイト、接続記録、通信内容、ログを収集またはアップロードしません。これらのデータは端末内にのみ保存され、開発者がアクセスすることはできません。\n\n本ソフトウェアが外部ネットワークにアクセスするのは、プロファイル更新時に指定されたサブスクリプション URL へアクセスする場合や、アップデート確認時に GitHub へアクセスする場合など、該当する機能を使用したときのみです。\n\n本ソフトウェアには、どのプラットフォームでも統計やクラッシュレポートのサービスは一切組み込まれていません。",
    ),
    "disclaimerPrivacyTitle": MessageLookupByLibrary.simpleMessage(
      "データ収集とプライバシー",
    ),
    "disclaimerResponsibilityContent": MessageLookupByLibrary.simpleMessage(
      "お住まいの国または地域で本ソフトウェアの使用が合法であることはご自身で確認する必要があり、本ソフトウェアを使用したすべての行為とその結果について、ご自身が単独で法的責任を負います。\n\nインポートするサブスクリプション、ノード、設定はご自身の判断で選択したものです。その出所の適法性、内容の安全性、サービスの安定性については、利用者と各提供者の間で解決してください。",
    ),
    "disclaimerResponsibilityTitle": MessageLookupByLibrary.simpleMessage(
      "利用者の責任",
    ),
    "disclaimerRestateHint": MessageLookupByLibrary.simpleMessage("上記の声明を入力"),
    "disclaimerRestateMismatch": MessageLookupByLibrary.simpleMessage(
      "声明の内容と一致しません",
    ),
    "disclaimerRestateTip": MessageLookupByLibrary.simpleMessage(
      "内容を理解したことを確認するため、以下の声明を下の入力欄に正確に入力してください：",
    ),
    "disclaimerRestateTitle": MessageLookupByLibrary.simpleMessage("声明の復唱"),
    "disclaimerSoftwareContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは Clash.Meta（mihomo）コアをベースとしたオープンソースのネットワークプロキシクライアントであり、設定管理、ルールによる振り分け、トラフィック転送などのローカルツール機能のみを提供します。",
    ),
    "disclaimerSoftwareTitle": MessageLookupByLibrary.simpleMessage(
      "ソフトウェアの性質",
    ),
    "disclaimerThirdPartyContent": MessageLookupByLibrary.simpleMessage(
      "サブスクリプションリンク、設定ファイル、ルールセット、スクリプト、外部リソース、外部リンクはすべて第三者が提供するものであり、開発者はその適法性、正確性、安全性、可用性を審査または保証することはできず、また行いません。\n\nサードパーティのコンテンツの使用に起因する情報漏えい、財産上の損失、アカウント停止その他の損失は、利用者と第三者の間で解決するものとし、開発者は一切責任を負いません。",
    ),
    "disclaimerThirdPartyTitle": MessageLookupByLibrary.simpleMessage(
      "サードパーティのコンテンツ",
    ),
    "disclaimerUsageContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは学習、交流、技術研究などの非商用目的でのみ使用できます。有償配布、抱き合わせ販売、商用サービスの一部としての利用、本ソフトウェアの名義での事業活動など、あらゆる商用目的での使用を固く禁じます。いかなる商業行為も本ソフトウェアおよび開発者とは一切関係ありません。\n\nお住まいの国または地域の法令に違反する目的での使用を固く禁じます。これには、法に基づくネットワークアクセス制限の回避、違法情報の拡散、サイバー攻撃、他者の権利の侵害などが含まれますが、これらに限りません。",
    ),
    "disclaimerUsageTitle": MessageLookupByLibrary.simpleMessage("使用の制限"),
    "disclaimerWarrantyContent": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは「現状のまま」かつ「提供可能な範囲で」提供され、商品性、特定目的への適合性、非侵害、継続的な可用性、エラーやセキュリティ上の脆弱性がないことの保証を含め、明示または黙示を問わずいかなる保証も伴いません。\n\n開発者は、本ソフトウェアが利用者の要件を満たすこと、また中断やエラーなく動作することを保証しません。",
    ),
    "disclaimerWarrantyTitle": MessageLookupByLibrary.simpleMessage("無保証"),
    "disconnected": MessageLookupByLibrary.simpleMessage("切断済み"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "新しいバージョンが見つかりました",
    ),
    "dnsCacheCleared": MessageLookupByLibrary.simpleMessage("DNSキャッシュをクリアしました"),
    "dnsHijackDesc": MessageLookupByLibrary.simpleMessage(
      "追加しない場合、ポート 53 宛てのすべての DNS 問い合わせをハイジャックします（any:53）。",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNSハイジャック"),
    "dnsLeakAdvice": MessageLookupByLibrary.simpleMessage(
      "不合格の項目は「詳細設定 → ネットワーク」で VPN と DNS ハイジャックを有効にし、システム設定のプライベート DNS を無効にしてください。DNS 上書きでは平文の上流を DoH に置き換えてください。",
    ),
    "dnsLeakCheck": MessageLookupByLibrary.simpleMessage("DNS リーク診断"),
    "dnsLeakDirect": MessageLookupByLibrary.simpleMessage("53 番ポートの直通"),
    "dnsLeakDirectBad": MessageLookupByLibrary.simpleMessage(
      "223.5.5.5 への直接問い合わせで実アドレスが返り、平文 DNS がそのまま出ています",
    ),
    "dnsLeakEncrypted": MessageLookupByLibrary.simpleMessage("暗号化された解決"),
    "dnsLeakEncryptedBad": MessageLookupByLibrary.simpleMessage(
      "上流が平文 DNS のため、問い合わせ内容がそのまま出ていきます",
    ),
    "dnsLeakExternal": MessageLookupByLibrary.simpleMessage("ブラウザーで確認"),
    "dnsLeakFail": MessageLookupByLibrary.simpleMessage("不合格"),
    "dnsLeakFakeIp": MessageLookupByLibrary.simpleMessage("偽のアドレス"),
    "dnsLeakFakeIpBad": MessageLookupByLibrary.simpleMessage(
      "応答が 198.18.x.x ではないため、この問い合わせは Fake-IP が処理していません",
    ),
    "dnsLeakHijack": MessageLookupByLibrary.simpleMessage("DNS ハイジャック"),
    "dnsLeakHijackBad": MessageLookupByLibrary.simpleMessage(
      "any:53 が未設定のため、他のリゾルバーへの問い合わせは取り込まれません",
    ),
    "dnsLeakIpv6": MessageLookupByLibrary.simpleMessage("IPv6"),
    "dnsLeakIpv6Bad": MessageLookupByLibrary.simpleMessage(
      "グローバル IPv6 アドレスがあり、v6 通信が IPv4 のみの取り込みを迂回できます",
    ),
    "dnsLeakPass": MessageLookupByLibrary.simpleMessage("合格"),
    "dnsLeakRerun": MessageLookupByLibrary.simpleMessage("再診断"),
    "dnsLeakRunning": MessageLookupByLibrary.simpleMessage("診断中"),
    "dnsLeakTunnel": MessageLookupByLibrary.simpleMessage("通信の取り込み"),
    "dnsLeakTunnelBad": MessageLookupByLibrary.simpleMessage(
      "コアが停止中か VPN が未接続のため、アプリが独自に名前を解決します",
    ),
    "dnsLeakUnknown": MessageLookupByLibrary.simpleMessage("判定不可"),
    "dnsLeakWarn": MessageLookupByLibrary.simpleMessage("注意"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNSモード"),
    "dnsOverride": MessageLookupByLibrary.simpleMessage("DNS の上書き"),
    "dnsOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "ここで追加した項目は、すべての URL・ファイルプロファイルの DNS を上書きします。追加していない項目はプロファイル自身の設定のままです。カスタムプロファイルの DNS はその内容で設定します。",
    ),
    "dnsPolicyReplaced": MessageLookupByLibrary.simpleMessage(
      "このプロファイルは独自の DNS ポリシーを持っています。ここの項目はそれを丸ごと置き換えるため、ここにないルールは適用されなくなります。",
    ),
    "dnsQueries": MessageLookupByLibrary.simpleMessage("DNSクエリ"),
    "dockScale": MessageLookupByLibrary.simpleMessage("ボトムバーのサイズ"),
    "docked": MessageLookupByLibrary.simpleMessage("固定"),
    "domain": MessageLookupByLibrary.simpleMessage("ドメイン"),
    "done": MessageLookupByLibrary.simpleMessage("完了"),
    "download": MessageLookupByLibrary.simpleMessage("ダウンロード"),
    "downloadBandwidth": MessageLookupByLibrary.simpleMessage("ダウンロード帯域幅"),
    "duration": MessageLookupByLibrary.simpleMessage("経過時間"),
    "durationDays": m28,
    "durationHours": m29,
    "durationMinutes": m30,
    "edit": MessageLookupByLibrary.simpleMessage("編集"),
    "editDashboard": MessageLookupByLibrary.simpleMessage("ダッシュボードを編集"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage("グローバルルールを編集"),
    "editProxy": MessageLookupByLibrary.simpleMessage("プロキシを編集"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループを編集"),
    "editRule": MessageLookupByLibrary.simpleMessage("ルールを編集"),
    "editSsid": MessageLookupByLibrary.simpleMessage("SSIDを編集"),
    "editorUnavailable": MessageLookupByLibrary.simpleMessage("エディターを利用できません"),
    "elapsed": MessageLookupByLibrary.simpleMessage("所要時間"),
    "emptyFallback": MessageLookupByLibrary.simpleMessage("空グループのフォールバック"),
    "emptyTip": m31,
    "en": MessageLookupByLibrary.simpleMessage("英語"),
    "enabled": MessageLookupByLibrary.simpleMessage("有効"),
    "entries": MessageLookupByLibrary.simpleMessage(" 件"),
    "error": MessageLookupByLibrary.simpleMessage("エラー"),
    "errorDetails": MessageLookupByLibrary.simpleMessage("エラーの詳細"),
    "es": MessageLookupByLibrary.simpleMessage("スペイン語"),
    "exclude": MessageLookupByLibrary.simpleMessage("最近のタスクから隠す"),
    "excludeDstPort": MessageLookupByLibrary.simpleMessage("除外宛先ポート"),
    "excludeDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "除外宛先ポートへの通信は TUN を通りません。",
    ),
    "excludeFilter": MessageLookupByLibrary.simpleMessage("除外フィルター"),
    "excludeInterface": MessageLookupByLibrary.simpleMessage("除外インターフェース"),
    "excludeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "docker0 などの除外インターフェースから入る通信は TUN を通りません。",
    ),
    "excludeSrcPort": MessageLookupByLibrary.simpleMessage("除外送信元ポート"),
    "excludeSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "除外送信元ポートからの通信は TUN を通りません。",
    ),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("除外SSID"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "除外した SSID の Wi-Fi に接続すると、アプリの実行状態が自動的に切り替わります。",
    ),
    "excludeUid": MessageLookupByLibrary.simpleMessage("除外ユーザー ID"),
    "excludeUidDesc": MessageLookupByLibrary.simpleMessage(
      "除外ユーザー ID のプロセスの通信は TUN を通りません。",
    ),
    "existsTip": m32,
    "exit": MessageLookupByLibrary.simpleMessage("終了"),
    "exitFullScreen": MessageLookupByLibrary.simpleMessage("全画面表示を終了"),
    "exitNodes": MessageLookupByLibrary.simpleMessage("出口ノード"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("期待するステータス"),
    "expireTime": MessageLookupByLibrary.simpleMessage("有効期限"),
    "exportFile": MessageLookupByLibrary.simpleMessage("ファイルをエクスポート"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("ログをエクスポート"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("エクスポートが完了しました"),
    "extend": MessageLookupByLibrary.simpleMessage("拡張"),
    "extendMode": MessageLookupByLibrary.simpleMessage("拡張モード"),
    "extendScript": MessageLookupByLibrary.simpleMessage("拡張スクリプト"),
    "externalController": MessageLookupByLibrary.simpleMessage("外部コントローラー"),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "外部コントローラーを有効にすると、ポート 9090 でコアを制御できます。",
    ),
    "externalControllerSecret": MessageLookupByLibrary.simpleMessage(
      "外部コントローラーのシークレット",
    ),
    "externalLink": MessageLookupByLibrary.simpleMessage("外部リンク"),
    "extraLarge": MessageLookupByLibrary.simpleMessage("特大"),
    "fade": MessageLookupByLibrary.simpleMessage("フェード"),
    "failedCount": m33,
    "failedItem": m34,
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fake-IPフィルター"),
    "fakeipFilterMode": MessageLookupByLibrary.simpleMessage("Fake-IPフィルターモード"),
    "fakeipFilterModeDesc": MessageLookupByLibrary.simpleMessage(
      "Fake-IP フィルターモードでは、blacklist は一致を除外、whitelist は一致のみ、rule はルールで判定します。",
    ),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fake-IP範囲"),
    "fakeipRange6": MessageLookupByLibrary.simpleMessage("Fake-IP範囲（IPv6）"),
    "fakeipTtl": MessageLookupByLibrary.simpleMessage("Fake-IP TTL"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("フォールバックフィルター"),
    "file": MessageLookupByLibrary.simpleMessage("ファイル"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("プロファイルファイルを直接アップロードします"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "ファイルが変更されています。変更を保存しますか？",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("フィルター"),
    "filters": MessageLookupByLibrary.simpleMessage("フィルター"),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("プロセス検出"),
    "floating": MessageLookupByLibrary.simpleMessage("フローティング"),
    "followProfile": MessageLookupByLibrary.simpleMessage("プロファイルに従う"),
    "followSystem": MessageLookupByLibrary.simpleMessage("システムに従う"),
    "fontFamily": MessageLookupByLibrary.simpleMessage("フォント"),
    "fontSize": MessageLookupByLibrary.simpleMessage("サイズ"),
    "forceDnsMapping": MessageLookupByLibrary.simpleMessage("DNSマッピングを強制"),
    "forceDnsMappingDesc": MessageLookupByLibrary.simpleMessage(
      "DNS マッピングを強制すると、DNS マッピングでドメインを得た接続もスニッフィングします。",
    ),
    "forceDomain": MessageLookupByLibrary.simpleMessage("強制するドメイン"),
    "forceDomainDesc": MessageLookupByLibrary.simpleMessage(
      "強制するドメインもスニッフィングします。ドメインを持つその他の接続は対象外です。",
    ),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "コアを強制再起動してもよろしいですか？",
    ),
    "fr": MessageLookupByLibrary.simpleMessage("フランス語"),
    "general": MessageLookupByLibrary.simpleMessage("一般"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geo"),
    "geoSkipped": m35,
    "geoUpdated": m36,
    "geodataLoader": MessageLookupByLibrary.simpleMessage("Geo低メモリモード"),
    "global": MessageLookupByLibrary.simpleMessage("グローバル"),
    "go": MessageLookupByLibrary.simpleMessage("開く"),
    "goDownload": MessageLookupByLibrary.simpleMessage("ダウンロードへ"),
    "goToConfigureAddedRules": MessageLookupByLibrary.simpleMessage(
      "追加ルール設定へ移動",
    ),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage("スクリプト設定へ移動"),
    "grid": MessageLookupByLibrary.simpleMessage("グリッド"),
    "groupCount": m37,
    "groupCountUnit": MessageLookupByLibrary.simpleMessage("個"),
    "groupTimeoutCount": m38,
    "hapticFeedback": MessageLookupByLibrary.simpleMessage("触覚フィードバック"),
    "hapticFeedbackDesc": MessageLookupByLibrary.simpleMessage(
      "アプリ内のタップで軽く振動します。",
    ),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage("変更をキャッシュしますか？"),
    "hashByInUser": MessageLookupByLibrary.simpleMessage("インバウンドユーザーでハッシュ"),
    "healthCheck": MessageLookupByLibrary.simpleMessage("ヘルスチェック"),
    "helperCorruptTip": MessageLookupByLibrary.simpleMessage(
      "Helper サービスが利用できないため、TUN モードを有効にできません。Skyward を再インストールしてください。",
    ),
    "hex": MessageLookupByLibrary.simpleMessage("16進数"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("リストから隠す"),
    "hideIp": MessageLookupByLibrary.simpleMessage("IP を隠す"),
    "hideLabelOnScroll": MessageLookupByLibrary.simpleMessage("スクロール中にラベルを隠す"),
    "hideLabelOnScrollDesc": MessageLookupByLibrary.simpleMessage(
      "ページをスクロールしている間、ボトムバーはアイコンだけを表示します",
    ),
    "hideNotification": MessageLookupByLibrary.simpleMessage("常駐通知を隠す"),
    "hideNotificationTip": MessageLookupByLibrary.simpleMessage(
      "プロキシはそのまま動作します。Android はフォアグラウンド サービスの通知を必須とするため、通知をサイレントにしてロック画面に出さないようにします。システム設定で完全にオフにできます",
    ),
    "hidePassword": MessageLookupByLibrary.simpleMessage("パスワードを隠す"),
    "hideTimeoutProxies": MessageLookupByLibrary.simpleMessage(
      "タイムアウトしたプロキシを隠す",
    ),
    "hitsUnit": MessageLookupByLibrary.simpleMessage("ヒット"),
    "hopInterval": MessageLookupByLibrary.simpleMessage("ホップ間隔"),
    "host": MessageLookupByLibrary.simpleMessage("ホスト"),
    "hostname": MessageLookupByLibrary.simpleMessage("ホスト名"),
    "hotkeyConflictWith": m39,
    "hotkeyDesc": MessageLookupByLibrary.simpleMessage(
      "グローバルホットキーはウィンドウが非表示でも有効です。アクションをタップしてキーの組み合わせを記録します。",
    ),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage("ホットキー管理"),
    "hotkeyNeedsModifier": m40,
    "hotkeyNotSet": MessageLookupByLibrary.simpleMessage("未設定"),
    "hotkeyUnavailable": MessageLookupByLibrary.simpleMessage(
      "登録できませんでした。他のアプリが使用している可能性があります",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("時間"),
    "hoursAgo": m41,
    "hoursAgoShort": m42,
    "hue": MessageLookupByLibrary.simpleMessage("色相"),
    "icon": MessageLookupByLibrary.simpleMessage("アイコン"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("アイコン履歴"),
    "iconSets": MessageLookupByLibrary.simpleMessage("アイコンセット"),
    "iconSetsEmptyTip": MessageLookupByLibrary.simpleMessage(
      "アイコンセットはまだありません。「カスタムプロファイルのリソース → アイコンセット」で追加できます",
    ),
    "iconStyle": MessageLookupByLibrary.simpleMessage("アイコンスタイル"),
    "iconStyleFilled": MessageLookupByLibrary.simpleMessage("背景あり"),
    "iconStyleHidden": MessageLookupByLibrary.simpleMessage("非表示"),
    "iconStylePlain": MessageLookupByLibrary.simpleMessage("背景なし"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("アイコンURL"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "電池の最適化を無視",
    ),
    "import": MessageLookupByLibrary.simpleMessage("インポート"),
    "importConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "このファイルはインポートできる設定ではありません",
    ),
    "importConfigReplaceTip": MessageLookupByLibrary.simpleMessage(
      "インポートすると、このプロファイルの現在のプロキシグループ、ルール、設定が置き換えられます",
    ),
    "importFile": MessageLookupByLibrary.simpleMessage("ファイルからインポート"),
    "importFromLink": MessageLookupByLibrary.simpleMessage("リンクからインポート"),
    "importUrl": MessageLookupByLibrary.simpleMessage("URLからインポート"),
    "inbound": MessageLookupByLibrary.simpleMessage("インバウンド"),
    "includeInterface": MessageLookupByLibrary.simpleMessage("対象インターフェース"),
    "includeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "対象インターフェースから入る通信だけが TUN を通り、除外インターフェースは無効になります。",
    ),
    "includeUid": MessageLookupByLibrary.simpleMessage("対象ユーザー ID"),
    "includeUidDesc": MessageLookupByLibrary.simpleMessage(
      "対象ユーザー ID のプロセスの通信だけが TUN を通ります。",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("無期限"),
    "init": MessageLookupByLibrary.simpleMessage("初期化"),
    "initFailed": MessageLookupByLibrary.simpleMessage("起動に失敗しました"),
    "initFailedTip": MessageLookupByLibrary.simpleMessage(
      "Skyward の起動中にエラーが発生したため、続行できません。詳細をコピーして問題を報告できます。繰り返し発生する場合は、データを消去すると起動できるようになることがあります。",
    ),
    "initiator": MessageLookupByLibrary.simpleMessage("発信元"),
    "initiatorShort": MessageLookupByLibrary.simpleMessage("発信元"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage(
      "プロキシグループ名を入力してください",
    ),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage("ルールの内容を入力してください"),
    "installedAppsPermissionDeniedMessage":
        MessageLookupByLibrary.simpleMessage(
          "アプリ一覧の権限が拒否されたため、インストール済みアプリを取得できません。システム設定から手動で許可してください。",
        ),
    "installedAppsPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "このシステムでは、許可するまでインストール済みアプリの一覧が提供されません。許可すると、アプリごとのプロキシを設定できます。",
    ),
    "installedAppsPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "アプリ一覧の権限が必要です",
    ),
    "installedFonts": MessageLookupByLibrary.simpleMessage("インストール済みのフォント"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage("スマート選択"),
    "interfaceName": MessageLookupByLibrary.simpleMessage("インターフェース名"),
    "interfaceNameDesc": MessageLookupByLibrary.simpleMessage(
      "インターフェース名は、アウトバウンド接続に使用するネットワークインターフェースです。",
    ),
    "interfaceNameMode": MessageLookupByLibrary.simpleMessage(
      "アウトバウンドインターフェース",
    ),
    "interfaceNameModeClear": MessageLookupByLibrary.simpleMessage("クリア"),
    "interfaceNameModeCustom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "interfaceNameModeFollow": MessageLookupByLibrary.simpleMessage("設定に従う"),
    "internet": MessageLookupByLibrary.simpleMessage("インターネット"),
    "interval": MessageLookupByLibrary.simpleMessage("間隔"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("イントラネットIP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage("無効なバックアップファイル"),
    "invalidCidrContent": MessageLookupByLibrary.simpleMessage(
      "192.168.0.0/16 のような CIDR 形式の IP 範囲を入力してください",
    ),
    "invalidDscpContent": MessageLookupByLibrary.simpleMessage(
      "DSCP マークは 63 を超えられません",
    ),
    "invalidHostContent": MessageLookupByLibrary.simpleMessage(
      "ドメインまたは IP アドレスを入力してください",
    ),
    "invalidIconSet": MessageLookupByLibrary.simpleMessage("有効なアイコンセットではありません"),
    "invalidLinkTip": MessageLookupByLibrary.simpleMessage(
      "サブスクリプションリンクまたはプロキシの共有リンクではありません",
    ),
    "invalidListenContent": MessageLookupByLibrary.simpleMessage(
      "0.0.0.0:1053 のようなアドレスとポートを入力してください",
    ),
    "invalidNetworkContent": MessageLookupByLibrary.simpleMessage(
      "tcp または udp のみ対応しています",
    ),
    "invalidPolicy": m43,
    "invalidPortRangeContent": MessageLookupByLibrary.simpleMessage(
      "443 や 8000-9000 のようなポートまたは範囲を入力してください",
    ),
    "invalidProfileQrcode": MessageLookupByLibrary.simpleMessage(
      "このQRコードにはプロファイルのリンクが含まれていません",
    ),
    "invalidProxy": m44,
    "invalidProxyProvider": m45,
    "invalidRangeContent": MessageLookupByLibrary.simpleMessage(
      "80 や 8000-9000 のような数値または範囲を / 区切りで入力してください",
    ),
    "invalidRuleSet": m46,
    "invalidSubRule": m47,
    "ipAddress": MessageLookupByLibrary.simpleMessage("IP アドレス"),
    "ipAsn": MessageLookupByLibrary.simpleMessage("ASN"),
    "ipFlagAbuser": MessageLookupByLibrary.simpleMessage("不正利用の履歴"),
    "ipFlagProxy": MessageLookupByLibrary.simpleMessage("プロキシ"),
    "ipFlagTor": MessageLookupByLibrary.simpleMessage("Tor"),
    "ipFlagVpn": MessageLookupByLibrary.simpleMessage("VPN"),
    "ipFlags": MessageLookupByLibrary.simpleMessage("検出"),
    "ipOrganization": MessageLookupByLibrary.simpleMessage("組織"),
    "ipQualityFailed": MessageLookupByLibrary.simpleMessage(
      "IP タイプを判定できませんでした",
    ),
    "ipQualityGood": MessageLookupByLibrary.simpleMessage("良好"),
    "ipQualityLevel": MessageLookupByLibrary.simpleMessage("レベル"),
    "ipQualityNormal": MessageLookupByLibrary.simpleMessage("普通"),
    "ipQualityRetry": MessageLookupByLibrary.simpleMessage("再確認"),
    "ipQualityRisky": MessageLookupByLibrary.simpleMessage("リスクあり"),
    "ipQualityShort": MessageLookupByLibrary.simpleMessage("品質"),
    "ipQualitySource": MessageLookupByLibrary.simpleMessage("採用したソース"),
    "ipQualitySources": MessageLookupByLibrary.simpleMessage("各ソース"),
    "ipSourceIpMismatch": MessageLookupByLibrary.simpleMessage(
      "アウトバウンド IP が不一致",
    ),
    "ipSourceNoType": MessageLookupByLibrary.simpleMessage("判定不可"),
    "ipSourceRateLimited": MessageLookupByLibrary.simpleMessage("レート制限"),
    "ipType": MessageLookupByLibrary.simpleMessage("タイプ"),
    "ipTypeBusiness": MessageLookupByLibrary.simpleMessage("ビジネス"),
    "ipTypeHosting": MessageLookupByLibrary.simpleMessage("データセンター"),
    "ipTypeMobile": MessageLookupByLibrary.simpleMessage("モバイル回線"),
    "ipTypeResidential": MessageLookupByLibrary.simpleMessage("住宅"),
    "ipTypeUnknown": MessageLookupByLibrary.simpleMessage("タイプ不明"),
    "ipVersion": MessageLookupByLibrary.simpleMessage("IP バージョン"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "IPv6 トラフィックは IPv6 が有効なときだけ受信します。",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage(
      "IPv6 を有効にすると、VPN で IPv6 インバウンドを許可します。",
    ),
    "ipv6Timeout": MessageLookupByLibrary.simpleMessage("IPv6タイムアウト（ms）"),
    "itemsCount": m48,
    "ja": MessageLookupByLibrary.simpleMessage("日本語"),
    "justNow": MessageLookupByLibrary.simpleMessage("たった今"),
    "keepAliveIdle": MessageLookupByLibrary.simpleMessage("TCP キープアライブ待機時間"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "TCPキープアライブ間隔",
    ),
    "key": MessageLookupByLibrary.simpleMessage("キー"),
    "ko": MessageLookupByLibrary.simpleMessage("韓国語"),
    "label": MessageLookupByLibrary.simpleMessage("ラベル"),
    "language": MessageLookupByLibrary.simpleMessage("言語"),
    "large": MessageLookupByLibrary.simpleMessage("大"),
    "last7Days": MessageLookupByLibrary.simpleMessage("過去 7 日間"),
    "lastUpdated": MessageLookupByLibrary.simpleMessage("最終更新"),
    "launchInterrupted": MessageLookupByLibrary.simpleMessage("起動が完了しませんでした"),
    "launchInterruptedTip": MessageLookupByLibrary.simpleMessage(
      "前回、アプリは起動中に予期せず終了しました。今回の自動セットアップはスキップしました。手動で起動して再試行できます。",
    ),
    "layout": MessageLookupByLibrary.simpleMessage("レイアウト"),
    "leakCheck": MessageLookupByLibrary.simpleMessage("リークチェック"),
    "light": MessageLookupByLibrary.simpleMessage("ライト"),
    "lineIssueTip": m49,
    "lineWrap": MessageLookupByLibrary.simpleMessage("折り返し"),
    "link": MessageLookupByLibrary.simpleMessage("リンク"),
    "linkDesc": MessageLookupByLibrary.simpleMessage(
      "サブスクリプションリンクまたはプロキシの共有リンクからプロファイルを取得します",
    ),
    "liquidGlass": MessageLookupByLibrary.simpleMessage("リキッドグラス"),
    "list": MessageLookupByLibrary.simpleMessage("リスト"),
    "listen": MessageLookupByLibrary.simpleMessage("リッスン"),
    "listenRoutingMark": MessageLookupByLibrary.simpleMessage("リッスンのルーティングマーク"),
    "listenRoutingMarkDesc": MessageLookupByLibrary.simpleMessage(
      "リッスンのルーティングマークは Linux でのみ有効です。",
    ),
    "liveConnections": MessageLookupByLibrary.simpleMessage("リアルタイム接続"),
    "loading": MessageLookupByLibrary.simpleMessage("読み込み中…"),
    "local": MessageLookupByLibrary.simpleMessage("ローカル"),
    "localImage": MessageLookupByLibrary.simpleMessage("ローカル画像"),
    "localNetwork": MessageLookupByLibrary.simpleMessage("LAN プロキシ"),
    "localNetworkDeniedTip": MessageLookupByLibrary.simpleMessage(
      "ローカルネットワークの権限が拒否されたため gvisor スタックを使用します。LAN にはアクセスできません。",
    ),
    "localNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "オフにすると、LAN・ループバック・マルチキャストのアドレスは仮想インターフェースを通りません。",
    ),
    "localProxies": MessageLookupByLibrary.simpleMessage("ローカルプロキシ"),
    "locationPermission": MessageLookupByLibrary.simpleMessage("位置情報の権限"),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "位置情報の権限が拒否されたため、現在の Wi-Fi 名を取得できません。システム設定で位置情報の権限を手動で有効にしてください。",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "システムの要件により、Wi-Fi 名の取得には位置情報の権限が必要です。Android では「常に許可」を選択してください。そうしないと、アプリがバックグラウンドにあるときに Wi-Fi 名を取得できません。",
    ),
    "locationPermissionGuide": m50,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "位置情報の権限が必要です",
    ),
    "log": MessageLookupByLibrary.simpleMessage("ログ"),
    "logLevel": MessageLookupByLibrary.simpleMessage("ログレベル"),
    "logcat": MessageLookupByLibrary.simpleMessage("ログキャプチャ"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "ログキャプチャを無効にすると、ログの入り口が非表示になります。",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("ログ"),
    "logsAndDiagnostics": MessageLookupByLibrary.simpleMessage("ログと診断"),
    "logsTest": MessageLookupByLibrary.simpleMessage("ログテスト"),
    "loopback": MessageLookupByLibrary.simpleMessage("UWP ループバック解除"),
    "loose": MessageLookupByLibrary.simpleMessage("ゆったり"),
    "matchCase": MessageLookupByLibrary.simpleMessage("大文字と小文字を区別"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("送信元IPにマッチ"),
    "matchTarget": MessageLookupByLibrary.simpleMessage("MATCH-TARGET"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("最大失敗回数"),
    "maxLengthTip": m51,
    "maximize": MessageLookupByLibrary.simpleMessage("最大化"),
    "memoryAppResident": MessageLookupByLibrary.simpleMessage("常駐メモリ"),
    "memoryAppShared": MessageLookupByLibrary.simpleMessage("アプリと共有"),
    "memoryCoreBudget": MessageLookupByLibrary.simpleMessage("コアの上限"),
    "memoryCoreHeapIdle": MessageLookupByLibrary.simpleMessage("未使用のヒープ"),
    "memoryCoreHeapInuse": MessageLookupByLibrary.simpleMessage("使用中のヒープ"),
    "memoryCoreNotRunning": MessageLookupByLibrary.simpleMessage(
      "コアは実行されていません",
    ),
    "memoryCoreRuntime": MessageLookupByLibrary.simpleMessage("ランタイムのオーバーヘッド"),
    "memoryCoreStack": MessageLookupByLibrary.simpleMessage("ゴルーチンスタック"),
    "memoryEstimateDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスの常駐メモリからの推定値で、システムの表示とは異なる場合があります。",
    ),
    "memoryEstimateSharedDesc": MessageLookupByLibrary.simpleMessage(
      "コアはアプリと同じプロセスで動作します。コア分はランタイム統計から推定し、残りはアプリと共有メモリとして計上します。",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("メモリ情報"),
    "memoryInfoDesc": MessageLookupByLibrary.simpleMessage("アプリとコアが使用するメモリ"),
    "memoryReleased": MessageLookupByLibrary.simpleMessage("メモリを解放しました"),
    "memoryReleasedSize": m52,
    "messageTest": MessageLookupByLibrary.simpleMessage("メッセージテスト"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage("これはメッセージです。"),
    "mine": MessageLookupByLibrary.simpleMessage("マイページ"),
    "minimize": MessageLookupByLibrary.simpleMessage("最小化"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("終了時に最小化"),
    "minutes": MessageLookupByLibrary.simpleMessage("分"),
    "minutesAgo": m53,
    "minutesAgoShort": m54,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Mixedポート"),
    "mode": MessageLookupByLibrary.simpleMessage("モード"),
    "monochromeIcon": MessageLookupByLibrary.simpleMessage("モノクロームアイコン"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("モノクローム"),
    "month": MessageLookupByLibrary.simpleMessage("月"),
    "monthsAgo": m55,
    "monthsAgoShort": m56,
    "more": MessageLookupByLibrary.simpleMessage("その他"),
    "moreThemeSettings": MessageLookupByLibrary.simpleMessage("テーマの詳細設定"),
    "motionSection": MessageLookupByLibrary.simpleMessage("モーション"),
    "name": MessageLookupByLibrary.simpleMessage("名前"),
    "navigationBarStyle": MessageLookupByLibrary.simpleMessage("ボトムバー"),
    "navigationSection": MessageLookupByLibrary.simpleMessage("ナビゲーションバー"),
    "network": MessageLookupByLibrary.simpleMessage("ネットワーク"),
    "networkAccessDeniedError": m57,
    "networkBadResponseError": m58,
    "networkCancelledError": MessageLookupByLibrary.simpleMessage(
      "リクエストはキャンセルされました",
    ),
    "networkConnectionError": MessageLookupByLibrary.simpleMessage(
      "サーバーに接続できませんでした。ネットワーク接続またはプロキシ設定を確認してください",
    ),
    "networkControl": MessageLookupByLibrary.simpleMessage("ネットワーク制御"),
    "networkHostLookupError": MessageLookupByLibrary.simpleMessage(
      "サーバーのアドレスを解決できませんでした。URL が正しいこと、DNS が使えることを確認してください",
    ),
    "networkName": MessageLookupByLibrary.simpleMessage("ネットワーク名"),
    "networkNotFoundError": m59,
    "networkOverview": MessageLookupByLibrary.simpleMessage("ネットワーク概要"),
    "networkRateLimitedError": MessageLookupByLibrary.simpleMessage(
      "リクエストが多すぎます（HTTP 429）。しばらく待ってから再試行してください",
    ),
    "networkRequestFailed": m60,
    "networkSecret": MessageLookupByLibrary.simpleMessage("ネットワークシークレット"),
    "networkServerError": m61,
    "networkSpeed": MessageLookupByLibrary.simpleMessage("ネットワーク速度"),
    "networkTakeover": MessageLookupByLibrary.simpleMessage("トラフィックの引き継ぎ"),
    "networkTimeoutError": MessageLookupByLibrary.simpleMessage(
      "リクエストがタイムアウトしました。ネットワークまたはプロキシを確認してから再試行してください",
    ),
    "networkTlsError": MessageLookupByLibrary.simpleMessage(
      "安全な接続に失敗しました。サーバー証明書が無効か、接続が傍受されている可能性があります",
    ),
    "networkType": MessageLookupByLibrary.simpleMessage("ネットワーク種別"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("次の一致"),
    "nextPeriod": MessageLookupByLibrary.simpleMessage("次へ"),
    "no": MessageLookupByLibrary.simpleMessage("いいえ"),
    "noData": MessageLookupByLibrary.simpleMessage("データがありません"),
    "noInfo": MessageLookupByLibrary.simpleMessage("情報がありません"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage("今後表示しない"),
    "noNetwork": MessageLookupByLibrary.simpleMessage("ネットワークがありません"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("ネットワーク不使用アプリ"),
    "noResolve": MessageLookupByLibrary.simpleMessage("IPを解決しない"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage("ホスト名を解決しない"),
    "noSearchResults": MessageLookupByLibrary.simpleMessage("一致する結果はありません"),
    "nodes": MessageLookupByLibrary.simpleMessage("ノード"),
    "nonTextProviderFile": MessageLookupByLibrary.simpleMessage(
      "この外部リソースはテキストファイルではありません",
    ),
    "none": MessageLookupByLibrary.simpleMessage("なし"),
    "notRunning": MessageLookupByLibrary.simpleMessage("停止中"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "現在のプロキシグループは選択できません",
    ),
    "ntpInterval": MessageLookupByLibrary.simpleMessage("同期間隔（分）"),
    "ntpStatusDesc": MessageLookupByLibrary.simpleMessage(
      "NTP を有効にすると、システムクロックではなく NTP サーバーから時刻を取得します。",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイルを追加して始めましょう",
    ),
    "nullTip": m62,
    "numberRangeTip": m63,
    "numberTip": m64,
    "obfs": MessageLookupByLibrary.simpleMessage("難読化"),
    "obfsHost": MessageLookupByLibrary.simpleMessage("難読化ホスト"),
    "obfsMode": MessageLookupByLibrary.simpleMessage("難読化モード"),
    "obfsParam": MessageLookupByLibrary.simpleMessage("難読化パラメータ"),
    "obfsPassword": MessageLookupByLibrary.simpleMessage("難読化パスワード"),
    "onDemand": MessageLookupByLibrary.simpleMessage("オンデマンド"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "オンデマンドは、除外した Wi-Fi に接続している間プロキシを一時停止します。",
    ),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "プロキシトラフィックのみ集計",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("任意"),
    "options": MessageLookupByLibrary.simpleMessage("オプション"),
    "other": MessageLookupByLibrary.simpleMessage("その他"),
    "otherContributors": MessageLookupByLibrary.simpleMessage("その他の貢献者"),
    "outbound": MessageLookupByLibrary.simpleMessage("アウトバウンド"),
    "outboundExit": MessageLookupByLibrary.simpleMessage("出口"),
    "outboundIp": MessageLookupByLibrary.simpleMessage("アウトバウンド IP"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("アウトバウンドモード"),
    "overrideDestination": MessageLookupByLibrary.simpleMessage("宛先を上書き"),
    "overrideDestinationDesc": MessageLookupByLibrary.simpleMessage(
      "宛先を上書きすると、元のアドレスではなく検出したドメインに接続します。",
    ),
    "overrideEntries": MessageLookupByLibrary.simpleMessage("上書き項目"),
    "pagesLabel": MessageLookupByLibrary.simpleMessage("ページ"),
    "parsePureIp": MessageLookupByLibrary.simpleMessage("純粋なIPを解析"),
    "parsePureIpDesc": MessageLookupByLibrary.simpleMessage(
      "純粋な IP を解析すると、IP アドレスしかない接続をスニッフィングします。",
    ),
    "password": MessageLookupByLibrary.simpleMessage("パスワード"),
    "paste": MessageLookupByLibrary.simpleMessage("貼り付け"),
    "pasteDesc": MessageLookupByLibrary.simpleMessage("クリップボードから購読リンクを貼り付け"),
    "peers": MessageLookupByLibrary.simpleMessage("ピア"),
    "perApp": MessageLookupByLibrary.simpleMessage("アプリごと"),
    "perAppDesc": MessageLookupByLibrary.simpleMessage("どのアプリをプロキシ経由にするか選びます。"),
    "pickFromAlbum": MessageLookupByLibrary.simpleMessage("アルバムから選択"),
    "pinWindow": MessageLookupByLibrary.simpleMessage("最前面に固定"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage("WebDAVを連携してください"),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "スクリプト名を入力してください",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "有効なQRコードをアップロードしてください",
    ),
    "plugin": MessageLookupByLibrary.simpleMessage("プラグイン"),
    "pluginCipher": MessageLookupByLibrary.simpleMessage("プラグイン暗号方式"),
    "pluginHost": MessageLookupByLibrary.simpleMessage("プラグインホスト"),
    "pluginMode": MessageLookupByLibrary.simpleMessage("プラグインモード"),
    "pluginPassword": MessageLookupByLibrary.simpleMessage("プラグインパスワード"),
    "pluginPath": MessageLookupByLibrary.simpleMessage("プラグインパス"),
    "pluginUsername": MessageLookupByLibrary.simpleMessage("プラグインユーザー名"),
    "port": MessageLookupByLibrary.simpleMessage("ポート"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage("別のポートを入力してください"),
    "portHopping": MessageLookupByLibrary.simpleMessage("ポートホッピング"),
    "portTip": m65,
    "portValue": m66,
    "ports": MessageLookupByLibrary.simpleMessage("ポート"),
    "preSharedKey": MessageLookupByLibrary.simpleMessage("事前共有鍵"),
    "preferences": MessageLookupByLibrary.simpleMessage("環境設定"),
    "preferred": MessageLookupByLibrary.simpleMessage("優先"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("前提条件"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage("キーの組み合わせを押してください"),
    "preview": MessageLookupByLibrary.simpleMessage("プレビュー"),
    "previousMatch": MessageLookupByLibrary.simpleMessage("前の一致"),
    "previousPeriod": MessageLookupByLibrary.simpleMessage("前へ"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "privacyPolicyContactContent": MessageLookupByLibrary.simpleMessage(
      "If you have questions about this privacy policy, please open an issue at https://github.com/aqiyoung/Skyward.",
    ),
    "privacyPolicyContactTitle": MessageLookupByLibrary.simpleMessage(
      "Contact",
    ),
    "privacyPolicyDataCollectionContent": MessageLookupByLibrary.simpleMessage(
      "Skyward does not collect or upload your subscription URLs, node information, configuration content, visited websites, connection records, traffic content, or logs. All such data is stored only on your device and is never transmitted to the developer.\n\nThe app only accesses the network when you use features that require it, such as updating subscriptions (accessing the subscription URL you provided) or checking for updates (accessing GitHub).",
    ),
    "privacyPolicyDataCollectionTitle": MessageLookupByLibrary.simpleMessage(
      "Data Collection",
    ),
    "privacyPolicyDataRetentionContent": MessageLookupByLibrary.simpleMessage(
      "Data remains on your device until you delete it. Uninstalling the app removes all app data. We retain nothing on any server because we operate no servers that receive your data.",
    ),
    "privacyPolicyDataRetentionTitle": MessageLookupByLibrary.simpleMessage(
      "Data Retention",
    ),
    "privacyPolicyDataSecurityContent": MessageLookupByLibrary.simpleMessage(
      "Your configuration and subscription data is stored in the app\'s private storage on your device, protected by the operating system\'s sandbox. Sensitive items such as the controller secret are stored in the system keystore where available.",
    ),
    "privacyPolicyDataSecurityTitle": MessageLookupByLibrary.simpleMessage(
      "Data Security",
    ),
    "privacyPolicyDataSharingContent": MessageLookupByLibrary.simpleMessage(
      "We do not share, sell, or disclose your data to any third party. There are no analytics SDKs, crash reporting services, or advertising frameworks integrated into the app.",
    ),
    "privacyPolicyDataSharingTitle": MessageLookupByLibrary.simpleMessage(
      "Data Sharing",
    ),
    "privacyPolicyDataUseContent": MessageLookupByLibrary.simpleMessage(
      "All data stays on your device. We use it solely to provide the app\'s functionality: managing your proxy configurations, establishing VPN connections, and displaying network statistics. We do not use your data for advertising, analytics, or any other purpose.",
    ),
    "privacyPolicyDataUseTitle": MessageLookupByLibrary.simpleMessage(
      "How We Use Data",
    ),
    "privateKey": MessageLookupByLibrary.simpleMessage("秘密鍵"),
    "privateKeyPassphrase": MessageLookupByLibrary.simpleMessage("秘密鍵のパスフレーズ"),
    "process": MessageLookupByLibrary.simpleMessage("プロセス"),
    "profile": MessageLookupByLibrary.simpleMessage("プロファイル"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("有効な間隔を入力してください"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage("自動更新間隔を入力してください"),
    "profileDaysLeft": m67,
    "profileDnsSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "このプロファイルにのみ適用され、ネットワーク設定の DNS 上書き項目より優先されます。",
    ),
    "profileExpiresIn": m68,
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "プロファイルが変更されています。自動更新を無効にしますか？",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイル名を入力してください",
    ),
    "profileSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "このプロファイルにのみ適用されます。追加していない項目はデフォルト値を使用します。",
    ),
    "profileTunSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "このプロファイルにのみ適用され、ネットワーク設定の TUN 上書き項目より優先されます。",
    ),
    "profileUpdatedAt": m69,
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "有効なプロファイルURLを入力してください",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイルのURLを入力してください",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("プロファイル"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("プロファイルの並べ替え"),
    "project": MessageLookupByLibrary.simpleMessage("プロジェクト"),
    "protocol": MessageLookupByLibrary.simpleMessage("プロトコル"),
    "protocolParam": MessageLookupByLibrary.simpleMessage("プロトコルパラメータ"),
    "protocolVersion": MessageLookupByLibrary.simpleMessage("プロトコルバージョン"),
    "providerInUse": m70,
    "providerUrlTip": MessageLookupByLibrary.simpleMessage("リモートリソースのみ対応しています"),
    "providers": MessageLookupByLibrary.simpleMessage("外部リソース"),
    "proxies": MessageLookupByLibrary.simpleMessage("プロキシ"),
    "proxiesCount": m71,
    "proxiesProfileLabel": m72,
    "proxiesRemovedTip": m73,
    "proxiesReplacedTip": m74,
    "proxyChains": MessageLookupByLibrary.simpleMessage("プロキシチェーン"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループ"),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage("プロキシグループが空です"),
    "proxyGroupInUse": m75,
    "proxyGroupsAfterStart": MessageLookupByLibrary.simpleMessage(
      "起動するとここにグループが表示されます",
    ),
    "proxyGroupsCount": m76,
    "proxyProviders": MessageLookupByLibrary.simpleMessage("プロキシプロバイダー"),
    "proxyShare": m77,
    "proxyType": MessageLookupByLibrary.simpleMessage("プロキシタイプ"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("キャッシュを整理"),
    "publicKey": MessageLookupByLibrary.simpleMessage("公開鍵"),
    "pureBlack": MessageLookupByLibrary.simpleMessage("ピュアブラック"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("ピュアブラックモード"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QRコード"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "QRコードをスキャンしてプロファイルを取得します",
    ),
    "qrcodeTooLongTip": MessageLookupByLibrary.simpleMessage(
      "このリンクは長すぎて QR コードにできません。「リンクをコピー」を使ってください。",
    ),
    "quickActions": MessageLookupByLibrary.simpleMessage("クイック操作"),
    "quickEdit": MessageLookupByLibrary.simpleMessage("クイック編集"),
    "rankDetail": m78,
    "rcxActiveScriptedGroups": MessageLookupByLibrary.simpleMessage(
      "動作中のスクリプト制御グループ",
    ),
    "rcxAddGroup": MessageLookupByLibrary.simpleMessage("グループを追加"),
    "rcxAddKind": MessageLookupByLibrary.simpleMessage("ネットワーク種別を追加"),
    "rcxAddTag": MessageLookupByLibrary.simpleMessage("タグを追加"),
    "rcxAdvanced": MessageLookupByLibrary.simpleMessage("詳細"),
    "rcxAllGroups": MessageLookupByLibrary.simpleMessage("すべてのグループ"),
    "rcxAnyServer": MessageLookupByLibrary.simpleMessage("すべて"),
    "rcxBackToAuto": MessageLookupByLibrary.simpleMessage("自動に戻す"),
    "rcxBalanced": MessageLookupByLibrary.simpleMessage("バランス"),
    "rcxBasedOn": MessageLookupByLibrary.simpleMessage("ベース"),
    "rcxBehaviour": MessageLookupByLibrary.simpleMessage("動作"),
    "rcxBringChanges": MessageLookupByLibrary.simpleMessage("変更を取り込む"),
    "rcxBringChangesHint": MessageLookupByLibrary.simpleMessage(
      "自分の編集内容はそのまま残ります",
    ),
    "rcxChangeServer": MessageLookupByLibrary.simpleMessage("サーバーを変更"),
    "rcxChangeTo": MessageLookupByLibrary.simpleMessage("選択対象"),
    "rcxCheckDifferent": m79,
    "rcxCheckGroup": MessageLookupByLibrary.simpleMessage("グループ"),
    "rcxCheckNone": MessageLookupByLibrary.simpleMessage("サーバーが見つかりません"),
    "rcxCheckOn": m80,
    "rcxCheckOpen": MessageLookupByLibrary.simpleMessage("ブロックされたサイトが開く"),
    "rcxCheckSame": m81,
    "rcxChecks": MessageLookupByLibrary.simpleMessage("チェック頻度"),
    "rcxCondAdd": MessageLookupByLibrary.simpleMessage("条件を追加"),
    "rcxCondAll": MessageLookupByLibrary.simpleMessage("すべての条件"),
    "rcxCondAlways": MessageLookupByLibrary.simpleMessage("常に"),
    "rcxCondAny": MessageLookupByLibrary.simpleMessage("いずれかの条件"),
    "rcxCondAnyServer": MessageLookupByLibrary.simpleMessage("すべてのサーバー"),
    "rcxCondAtLeast": MessageLookupByLibrary.simpleMessage("以上"),
    "rcxCondAtMost": MessageLookupByLibrary.simpleMessage("以下"),
    "rcxCondClause": m82,
    "rcxCondCountry": MessageLookupByLibrary.simpleMessage("国"),
    "rcxCondField": MessageLookupByLibrary.simpleMessage("項目"),
    "rcxCondIgnoreCase": MessageLookupByLibrary.simpleMessage("大文字小文字を区別しない"),
    "rcxCondLess": MessageLookupByLibrary.simpleMessage("未満"),
    "rcxCondMatch": MessageLookupByLibrary.simpleMessage("一致条件"),
    "rcxCondMore": MessageLookupByLibrary.simpleMessage("超"),
    "rcxCondNoNames": MessageLookupByLibrary.simpleMessage("未定義"),
    "rcxCondNotPrefix": MessageLookupByLibrary.simpleMessage("非"),
    "rcxCondOp": MessageLookupByLibrary.simpleMessage("演算子"),
    "rcxCondPattern": MessageLookupByLibrary.simpleMessage("パターン"),
    "rcxCondText": MessageLookupByLibrary.simpleMessage("テキストで表示"),
    "rcxCondTooComplex": MessageLookupByLibrary.simpleMessage(
      "この条件にはグループが入れ子になっているため、テキストで編集します。",
    ),
    "rcxCondValue": MessageLookupByLibrary.simpleMessage("値"),
    "rcxCondValues": MessageLookupByLibrary.simpleMessage("値（カンマ区切り）"),
    "rcxConsentAllow": MessageLookupByLibrary.simpleMessage("許可"),
    "rcxConsentAsk": m83,
    "rcxConsentHint": MessageLookupByLibrary.simpleMessage(
      "許可するまで、グループは「シンプル」の動作を使います。サイトへの接続は、お使いのサーバー経由か、ネットワークのテスト時のみです。",
    ),
    "rcxConsentTitle": MessageLookupByLibrary.simpleMessage("許可が必要"),
    "rcxContacts": MessageLookupByLibrary.simpleMessage("接続したサイト"),
    "rcxContactsHint": MessageLookupByLibrary.simpleMessage(
      "サードパーティのサイトは、プロバイダーにも組み込みの動作にも属していません。",
    ),
    "rcxControl": MessageLookupByLibrary.simpleMessage("制御"),
    "rcxCountryAll": MessageLookupByLibrary.simpleMessage("すべての国"),
    "rcxCountryOnServers": MessageLookupByLibrary.simpleMessage("サーバーにある国"),
    "rcxCountryPickMany": MessageLookupByLibrary.simpleMessage("国を選択"),
    "rcxCountryPickOne": MessageLookupByLibrary.simpleMessage("国を1つ選択"),
    "rcxCountryServers": m84,
    "rcxCountryVerified": MessageLookupByLibrary.simpleMessage("確認済み"),
    "rcxDeleteProfile": m85,
    "rcxDetails": MessageLookupByLibrary.simpleMessage("詳細"),
    "rcxDirectSplit": MessageLookupByLibrary.simpleMessage(
      "直接接続のサイトをこのグループ経由に",
    ),
    "rcxDirectSplitActive": MessageLookupByLibrary.simpleMessage("現在オン"),
    "rcxDirectSplitHint": MessageLookupByLibrary.simpleMessage(
      "ルールで直接接続にしているサイトが開かなくなったら、このグループを経由させます。ローカルアドレスは常に直接接続のままです。",
    ),
    "rcxDirectSplitStandby": MessageLookupByLibrary.simpleMessage(
      "待機中: 直接接続のサイトはまだ開けます",
    ),
    "rcxDuplicate": MessageLookupByLibrary.simpleMessage("コピーを編集"),
    "rcxEnergyEco": MessageLookupByLibrary.simpleMessage("省電力"),
    "rcxEnergyPrecise": MessageLookupByLibrary.simpleMessage("精密"),
    "rcxEnergyToday": m86,
    "rcxExcept": m87,
    "rcxExcludedByProfile": MessageLookupByLibrary.simpleMessage("動作で除外"),
    "rcxExcludedCooldown": MessageLookupByLibrary.simpleMessage(
      "「サーバーを変更」により除外中",
    ),
    "rcxExcludedNoMatch": MessageLookupByLibrary.simpleMessage("候補外"),
    "rcxExcludedNoTier": MessageLookupByLibrary.simpleMessage("どの優先条件にも一致しません"),
    "rcxExcludedPending": MessageLookupByLibrary.simpleMessage("未チェック"),
    "rcxExcludedUnroutable": MessageLookupByLibrary.simpleMessage(
      "サーバーではありません",
    ),
    "rcxExit": m88,
    "rcxExport": MessageLookupByLibrary.simpleMessage("エクスポート"),
    "rcxFeelCalm": MessageLookupByLibrary.simpleMessage("まれに"),
    "rcxFeelEager": MessageLookupByLibrary.simpleMessage("頻繁に"),
    "rcxFieldAlive": MessageLookupByLibrary.simpleMessage("動作中"),
    "rcxFieldCurrent": MessageLookupByLibrary.simpleMessage("使用中"),
    "rcxFieldDead": MessageLookupByLibrary.simpleMessage("停止中"),
    "rcxFieldDiag": MessageLookupByLibrary.simpleMessage("ネットワーク診断"),
    "rcxFieldEntry": MessageLookupByLibrary.simpleMessage("入口国"),
    "rcxFieldExit": MessageLookupByLibrary.simpleMessage("出口国"),
    "rcxFieldFails": MessageLookupByLibrary.simpleMessage("チェックに失敗"),
    "rcxFieldKind": MessageLookupByLibrary.simpleMessage("ネットワークの種類"),
    "rcxFieldLatency": MessageLookupByLibrary.simpleMessage("遅延 (ms)"),
    "rcxFieldMeasured": MessageLookupByLibrary.simpleMessage("測定済み"),
    "rcxFieldMetered": MessageLookupByLibrary.simpleMessage("従量制ネットワーク"),
    "rcxFieldName": MessageLookupByLibrary.simpleMessage("名前"),
    "rcxFieldPasses": MessageLookupByLibrary.simpleMessage("チェックに成功"),
    "rcxFieldPortal": MessageLookupByLibrary.simpleMessage("ログインページ"),
    "rcxFieldProvider": MessageLookupByLibrary.simpleMessage("プロバイダー"),
    "rcxFieldServer": MessageLookupByLibrary.simpleMessage("サーバーアドレス"),
    "rcxFieldTag": MessageLookupByLibrary.simpleMessage("タグ"),
    "rcxFieldTransport": MessageLookupByLibrary.simpleMessage("接続の種類"),
    "rcxFieldType": MessageLookupByLibrary.simpleMessage("プロトコル"),
    "rcxFieldUdp": MessageLookupByLibrary.simpleMessage("UDP対応"),
    "rcxFixedHint": MessageLookupByLibrary.simpleMessage(
      "グループ全体がこのメンバー経由になり、サーバー探索は行いません。ロードバランサーや入れ子のグループを選ぶと、すべてを任せられます。",
    ),
    "rcxFixedOn": m89,
    "rcxFromScenario": m90,
    "rcxFromYours": MessageLookupByLibrary.simpleMessage("このグループ用の設定"),
    "rcxGroupProfiles": MessageLookupByLibrary.simpleMessage("動作"),
    "rcxGroupProfilesHint": MessageLookupByLibrary.simpleMessage(
      "グループがサーバーを選ぶ方法です。自分のものはタップで編集、それ以外はコピーを編集します。",
    ),
    "rcxHealthAlive": MessageLookupByLibrary.simpleMessage("動作中"),
    "rcxHealthDead": MessageLookupByLibrary.simpleMessage("停止中"),
    "rcxHealthStale": MessageLookupByLibrary.simpleMessage("以前は動作"),
    "rcxHealthUnknown": MessageLookupByLibrary.simpleMessage("未確認"),
    "rcxHistory": MessageLookupByLibrary.simpleMessage("履歴"),
    "rcxHistoryVersions": MessageLookupByLibrary.simpleMessage("以前のバージョン"),
    "rcxHowToChoose": MessageLookupByLibrary.simpleMessage("サーバーの選び方"),
    "rcxHubAuto": MessageLookupByLibrary.simpleMessage("シナリオを使う"),
    "rcxHubBundle": MessageLookupByLibrary.simpleMessage("このファイルの内容"),
    "rcxHubChange": MessageLookupByLibrary.simpleMessage("シナリオを選ぶ"),
    "rcxHubCopyConfirm": MessageLookupByLibrary.simpleMessage("コピーを編集"),
    "rcxHubCopyMessage": m91,
    "rcxHubCopyTitle": MessageLookupByLibrary.simpleMessage("コピーを編集しますか？"),
    "rcxHubDescriptionHint": MessageLookupByLibrary.simpleMessage("このシナリオの内容"),
    "rcxHubEverythingElse": MessageLookupByLibrary.simpleMessage("その他の通信"),
    "rcxHubGroupsEmpty": MessageLookupByLibrary.simpleMessage(
      "このサブスクリプションには動作中のスクリプト制御グループがありません。",
    ),
    "rcxHubLibrary": MessageLookupByLibrary.simpleMessage("シナリオライブラリ"),
    "rcxHubNeedsCore": MessageLookupByLibrary.simpleMessage(
      "自動ルーティングを表示するには接続を開始してください",
    ),
    "rcxHubNetworks": MessageLookupByLibrary.simpleMessage("ネットワークの種類"),
    "rcxHubNoProfile": MessageLookupByLibrary.simpleMessage("サブスクリプションがありません"),
    "rcxHubNoProfileHint": MessageLookupByLibrary.simpleMessage(
      "先にサブスクリプションを追加してください。自動ルーティングはそのグループを使います。",
    ),
    "rcxHubOffHint": MessageLookupByLibrary.simpleMessage(
      "シナリオは、このサブスクリプションのルート、プロキシグループ、トンネルモードを制御できます。",
    ),
    "rcxHubOtherGroups": MessageLookupByLibrary.simpleMessage("このシナリオのグループ"),
    "rcxHubOtherGroupsHint": MessageLookupByLibrary.simpleMessage(
      "このシナリオが個別のサブスクリプショングループに対して行うことです。",
    ),
    "rcxHubRoutes": MessageLookupByLibrary.simpleMessage("ルート"),
    "rcxHubRoutesHint": MessageLookupByLibrary.simpleMessage(
      "通信は上から順に、最初に一致したルートを通ります。残りは「その他の通信」を通ります。",
    ),
    "rcxHubRoutesRuleOnly": m92,
    "rcxImportAdd": MessageLookupByLibrary.simpleMessage("マイライブラリに追加"),
    "rcxImportNeedsCore": MessageLookupByLibrary.simpleMessage(
      "このファイルを確認するには、アプリのコアを起動してください。",
    ),
    "rcxImportTitle": MessageLookupByLibrary.simpleMessage("自動ルーティングをインポート"),
    "rcxImported": m93,
    "rcxJournalFailure": m94,
    "rcxJournalMode": m95,
    "rcxKindChecking": MessageLookupByLibrary.simpleMessage("確認中"),
    "rcxKindGroupsHint": MessageLookupByLibrary.simpleMessage(
      "このネットワークでは、シナリオ内の同名グループを置き換えます。それ以外は他のネットワークと同じ動作です。",
    ),
    "rcxKindName": MessageLookupByLibrary.simpleMessage("名前"),
    "rcxKindNameInvalid": MessageLookupByLibrary.simpleMessage(
      "半角小文字のアルファベット、数字、ハイフン、24文字まで",
    ),
    "rcxKindOpen": MessageLookupByLibrary.simpleMessage("制限なしのインターネット"),
    "rcxKindPortal": MessageLookupByLibrary.simpleMessage("ログインページ"),
    "rcxKindWhen": MessageLookupByLibrary.simpleMessage("判定条件"),
    "rcxKindWhenHint": MessageLookupByLibrary.simpleMessage(
      "種別は上から順に判定され、最初に一致したものがネットワークに適用されます。",
    ),
    "rcxKindWhitelist": MessageLookupByLibrary.simpleMessage("ホワイトリストのみ"),
    "rcxLadderAdd": MessageLookupByLibrary.simpleMessage("ステップを追加"),
    "rcxLadderAdvanced": MessageLookupByLibrary.simpleMessage("詳細な条件…"),
    "rcxLadderAnyWorking": MessageLookupByLibrary.simpleMessage("使える任意のサーバー"),
    "rcxLadderCountry": MessageLookupByLibrary.simpleMessage("国"),
    "rcxLadderEmptyHint": MessageLookupByLibrary.simpleMessage(
      "ステップを追加すると特定のサーバーを優先できます",
    ),
    "rcxLadderExceptCountries": MessageLookupByLibrary.simpleMessage("これらの国以外"),
    "rcxLadderFallThrough": MessageLookupByLibrary.simpleMessage("どれも使えなければ"),
    "rcxLadderFits": m96,
    "rcxLadderInherited": MessageLookupByLibrary.simpleMessage(
      "動作の設定です。ステップを編集すると独自の順序になります",
    ),
    "rcxLadderLastResortHint": MessageLookupByLibrary.simpleMessage(
      "最終手段のステップのサーバーは、下にあるステップも含め、他のどのステップにも使えるサーバーがないときだけ使われます。",
    ),
    "rcxLadderLatency": m97,
    "rcxLadderLatencyUnder": MessageLookupByLibrary.simpleMessage("遅延の上限 (ms)"),
    "rcxLadderNameContains": MessageLookupByLibrary.simpleMessage("名前に含む"),
    "rcxLadderNameHas": m98,
    "rcxLadderNot": m99,
    "rcxLadderOther": MessageLookupByLibrary.simpleMessage("その他の条件"),
    "rcxLadderProvider": m100,
    "rcxLadderServersIn": MessageLookupByLibrary.simpleMessage("このステップのサーバー"),
    "rcxLadderStep": m101,
    "rcxLadderTag": m102,
    "rcxLadderTitle": MessageLookupByLibrary.simpleMessage("サーバーの順序"),
    "rcxLadderUdp": MessageLookupByLibrary.simpleMessage("UDP"),
    "rcxLastResort": MessageLookupByLibrary.simpleMessage("最終手段"),
    "rcxLevel": MessageLookupByLibrary.simpleMessage("複雑さ"),
    "rcxLevelAdvanced": MessageLookupByLibrary.simpleMessage("詳細"),
    "rcxLevelSimple": MessageLookupByLibrary.simpleMessage("シンプル"),
    "rcxLine": m103,
    "rcxLintCheckUnused": m104,
    "rcxLintConsent": m105,
    "rcxLintGroupMissing": m106,
    "rcxLintPoolEmpty": m107,
    "rcxLintTagUnused": m108,
    "rcxLintTierEmpty": m109,
    "rcxLintTierUnreachable": m110,
    "rcxMainGroup": MessageLookupByLibrary.simpleMessage("その他の通信"),
    "rcxMakeSmart": MessageLookupByLibrary.simpleMessage("スクリプトで選択する"),
    "rcxMakeSmartHint": MessageLookupByLibrary.simpleMessage(
      "選んだ動作によって、このグループのサーバー選択方法が決まります。",
    ),
    "rcxManageHint": MessageLookupByLibrary.simpleMessage(
      "ツール → 詳細設定 → スクリプト制御グループで動作を管理できます。",
    ),
    "rcxMatchAdd": MessageLookupByLibrary.simpleMessage("項目を追加"),
    "rcxMatchAllServices": MessageLookupByLibrary.simpleMessage("すべてのサービス"),
    "rcxMatchCidr": MessageLookupByLibrary.simpleMessage("IP 範囲"),
    "rcxMatchCustom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "rcxMatchDomain": MessageLookupByLibrary.simpleMessage("ドメイン"),
    "rcxMatchGeoip": MessageLookupByLibrary.simpleMessage("IP カテゴリ"),
    "rcxMatchGeosite": MessageLookupByLibrary.simpleMessage("サイトカテゴリ"),
    "rcxMatchHint": MessageLookupByLibrary.simpleMessage(
      "このルートが追加で扱うドメイン、IP範囲、アプリ、ルールセットです。",
    ),
    "rcxMatchInvalid": MessageLookupByLibrary.simpleMessage("無効な値です"),
    "rcxMatchKeyword": MessageLookupByLibrary.simpleMessage("ドメインキーワード"),
    "rcxMatchMore": m111,
    "rcxMatchNoResolve": MessageLookupByLibrary.simpleMessage("ドメインを解決しない"),
    "rcxMatchNone": MessageLookupByLibrary.simpleMessage("通信が選ばれていません"),
    "rcxMatchProcess": MessageLookupByLibrary.simpleMessage("アプリ"),
    "rcxMatchRuleSet": MessageLookupByLibrary.simpleMessage("ルールセット"),
    "rcxMatchServices": MessageLookupByLibrary.simpleMessage("サービス"),
    "rcxMatchSuffix": MessageLookupByLibrary.simpleMessage("ドメインとサブドメイン"),
    "rcxMatchType": MessageLookupByLibrary.simpleMessage("種類"),
    "rcxMatchTypeHint": MessageLookupByLibrary.simpleMessage(
      "ドメインサフィックスはすべてのサブドメインも含みます。",
    ),
    "rcxMatchValue": MessageLookupByLibrary.simpleMessage("値"),
    "rcxMergeFailed": MessageLookupByLibrary.simpleMessage("変更を取り込めませんでした"),
    "rcxMerged": MessageLookupByLibrary.simpleMessage("変更を取り込みました"),
    "rcxMergedConflicts": m112,
    "rcxModeAuto": MessageLookupByLibrary.simpleMessage("自動"),
    "rcxModeAutoHint": MessageLookupByLibrary.simpleMessage(
      "サーバーの順序に沿って動作中の最適なサーバーを選び、障害時に切り替えます。",
    ),
    "rcxModeBackToAuto": MessageLookupByLibrary.simpleMessage("モードをシナリオに戻す"),
    "rcxModeByScenario": MessageLookupByLibrary.simpleMessage(
      "このネットワークのモードはシナリオが決めます",
    ),
    "rcxModeIs": m113,
    "rcxModeKeep": MessageLookupByLibrary.simpleMessage("変更しない"),
    "rcxModeManual": MessageLookupByLibrary.simpleMessage("手動"),
    "rcxModeManualHint": MessageLookupByLibrary.simpleMessage(
      "プロキシ画面で選んだサーバーを使い続けます。",
    ),
    "rcxModeManualNow": MessageLookupByLibrary.simpleMessage(
      "モードを手動で選択しました。「シナリオ連動」 を選ぶまでシナリオは待機します",
    ),
    "rcxModePinnedHint": m114,
    "rcxModeScenario": MessageLookupByLibrary.simpleMessage("シナリオ連動"),
    "rcxModeYours": MessageLookupByLibrary.simpleMessage(
      "このネットワークではモードを手動で管理します",
    ),
    "rcxNeedsConsent": MessageLookupByLibrary.simpleMessage("許可が必要です"),
    "rcxNetwork": m115,
    "rcxNewProfile": MessageLookupByLibrary.simpleMessage("新しい動作"),
    "rcxNewScenario": MessageLookupByLibrary.simpleMessage("新しいシナリオ"),
    "rcxOnThisNetwork": MessageLookupByLibrary.simpleMessage("このネットワークでは"),
    "rcxOnly": m116,
    "rcxOpFail": MessageLookupByLibrary.simpleMessage("失敗する"),
    "rcxOpIn": MessageLookupByLibrary.simpleMessage("のいずれか"),
    "rcxOpIs": MessageLookupByLibrary.simpleMessage("が次と等しい"),
    "rcxOpIsNot": MessageLookupByLibrary.simpleMessage("が次と異なる"),
    "rcxOpMatches": MessageLookupByLibrary.simpleMessage("に一致する"),
    "rcxOpOk": MessageLookupByLibrary.simpleMessage("成功する"),
    "rcxOwnProfile": MessageLookupByLibrary.simpleMessage("グループでの設定どおり"),
    "rcxOwnProfileHint": MessageLookupByLibrary.simpleMessage(
      "グループは自身の設定の動作を使います。",
    ),
    "rcxPatternInvalid": MessageLookupByLibrary.simpleMessage(
      "パターンが正しい正規表現ではありません",
    ),
    "rcxPendingTier": m117,
    "rcxPinned": m118,
    "rcxPinnedLabel": MessageLookupByLibrary.simpleMessage("固定"),
    "rcxPoolExclude": MessageLookupByLibrary.simpleMessage("サーバーを除外"),
    "rcxPoolInclude": MessageLookupByLibrary.simpleMessage("サーバーのみ"),
    "rcxProblemGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "このグループにはサーバーがありません",
    ),
    "rcxProblemGroupUnavailable": MessageLookupByLibrary.simpleMessage(
      "現在の設定ではこのグループはセレクターではありません",
    ),
    "rcxProblemProfileInvalid": m119,
    "rcxProblemProfileMissing": m120,
    "rcxProblemStoreFailed": m121,
    "rcxProfile": MessageLookupByLibrary.simpleMessage("動作"),
    "rcxProfileDescriptionHint": MessageLookupByLibrary.simpleMessage(
      "この動作の内容",
    ),
    "rcxProfileName": MessageLookupByLibrary.simpleMessage("名前"),
    "rcxProgramMember": MessageLookupByLibrary.simpleMessage("メンバー"),
    "rcxReasonBest": MessageLookupByLibrary.simpleMessage("最適なサーバーです"),
    "rcxReasonBetterTier": m122,
    "rcxReasonChangeServer": m123,
    "rcxReasonChecking": MessageLookupByLibrary.simpleMessage("より良い候補を確認中"),
    "rcxReasonConfirming": MessageLookupByLibrary.simpleMessage(
      "より高速なサーバーの再計測が必要です",
    ),
    "rcxReasonDwell": MessageLookupByLibrary.simpleMessage("最近切り替えたため次の変更まで待機"),
    "rcxReasonFailover": m124,
    "rcxReasonFaster": m125,
    "rcxReasonFixed": m126,
    "rcxReasonFixedMissing": m127,
    "rcxReasonFlapLimit": m128,
    "rcxReasonHoldPinned": MessageLookupByLibrary.simpleMessage("固定したサーバーを維持"),
    "rcxReasonIdle": m129,
    "rcxReasonInitial": MessageLookupByLibrary.simpleMessage("利用可能な最適なサーバーを選択"),
    "rcxReasonManual": MessageLookupByLibrary.simpleMessage("手動で制御中"),
    "rcxReasonNetworkChanged": MessageLookupByLibrary.simpleMessage(
      "ネットワークが変わりました",
    ),
    "rcxReasonNetworkSuspect": MessageLookupByLibrary.simpleMessage(
      "ネットワークがダウンしているようです。サーバーは原因と見なしません",
    ),
    "rcxReasonNoAlternative": MessageLookupByLibrary.simpleMessage(
      "切り替え先の動作するサーバーがありません",
    ),
    "rcxReasonOutOfPool": m130,
    "rcxReasonPaused": m131,
    "rcxReasonRouteInvalid": m132,
    "rcxReasonRouteNameTaken": m133,
    "rcxReasonRouteToMissing": m134,
    "rcxReasonSelectFailed": MessageLookupByLibrary.simpleMessage(
      "サーバーを選択できませんでした",
    ),
    "rcxReasonSplitOff": MessageLookupByLibrary.simpleMessage(
      "直接接続のサイトが再び直接接続になりました",
    ),
    "rcxReasonSplitOn": MessageLookupByLibrary.simpleMessage(
      "直接接続のサイトがこのグループ経由になりました",
    ),
    "rcxReasonStranded": MessageLookupByLibrary.simpleMessage(
      "動作するサーバーがないため現在のものを維持",
    ),
    "rcxReasonSwitchFixed": m135,
    "rcxReasonSwitchPinned": m136,
    "rcxReasonSwitchStranded": m137,
    "rcxReasonWorking": MessageLookupByLibrary.simpleMessage("動作中。障害が起きるまで維持"),
    "rcxRouteAdd": MessageLookupByLibrary.simpleMessage("ルートを追加"),
    "rcxRouteChoose": MessageLookupByLibrary.simpleMessage("選択"),
    "rcxRouteEdit": MessageLookupByLibrary.simpleMessage("ルートを編集"),
    "rcxRouteGroup": MessageLookupByLibrary.simpleMessage("ルートで作成"),
    "rcxRouteGroupHint": m138,
    "rcxRouteName": MessageLookupByLibrary.simpleMessage("名前"),
    "rcxRouteNameLong": MessageLookupByLibrary.simpleMessage("名前が長すぎます"),
    "rcxRouteNameReserved": MessageLookupByLibrary.simpleMessage(
      "この名前は予約されています",
    ),
    "rcxRouteNew": MessageLookupByLibrary.simpleMessage("新しいルート"),
    "rcxRouteSendAutoHint": MessageLookupByLibrary.simpleMessage(
      "動作するサーバーの中から最適なものを自動で選びます。",
    ),
    "rcxRouteSendDirectHint": MessageLookupByLibrary.simpleMessage(
      "この通信はプロキシを経由しません。",
    ),
    "rcxRouteSendFixed": MessageLookupByLibrary.simpleMessage("1台のサーバー"),
    "rcxRouteSendFixedHint": MessageLookupByLibrary.simpleMessage(
      "この通信は常に選んだサーバーまたはグループを通ります。",
    ),
    "rcxRouteTarget": MessageLookupByLibrary.simpleMessage("サーバー"),
    "rcxRouteWhere": MessageLookupByLibrary.simpleMessage("送信先"),
    "rcxScenario": MessageLookupByLibrary.simpleMessage("シナリオ"),
    "rcxScenarioDrives": m139,
    "rcxScenarioGroups": MessageLookupByLibrary.simpleMessage("グループ"),
    "rcxScenarioKindsHint": MessageLookupByLibrary.simpleMessage(
      "直接診断でネットワークを判別し、それぞれのモードとグループを変更します。",
    ),
    "rcxScenarioMode": MessageLookupByLibrary.simpleMessage("接続モード"),
    "rcxScenarios": MessageLookupByLibrary.simpleMessage("シナリオ"),
    "rcxScenariosHint": MessageLookupByLibrary.simpleMessage(
      "シナリオをタップして編集できます。組み込みやプロバイダーのシナリオはコピーとして開きます。",
    ),
    "rcxSendBest": MessageLookupByLibrary.simpleMessage("最適なサーバー"),
    "rcxSendDirect": MessageLookupByLibrary.simpleMessage("直接接続"),
    "rcxServers": MessageLookupByLibrary.simpleMessage("サーバー"),
    "rcxServersMatch": m140,
    "rcxServersPattern": MessageLookupByLibrary.simpleMessage("名前のパターン"),
    "rcxSmartGroups": MessageLookupByLibrary.simpleMessage("スクリプト制御グループ"),
    "rcxSourceBuiltin": MessageLookupByLibrary.simpleMessage("組み込み"),
    "rcxSourceChanged": MessageLookupByLibrary.simpleMessage("元の内容が変更されました"),
    "rcxSourceChanges": MessageLookupByLibrary.simpleMessage("変更内容"),
    "rcxSourceProvider": MessageLookupByLibrary.simpleMessage("プロバイダー提供"),
    "rcxSourceUser": MessageLookupByLibrary.simpleMessage("マイ"),
    "rcxStranded": MessageLookupByLibrary.simpleMessage("使えるサーバーがないとき"),
    "rcxStrandedDirect": MessageLookupByLibrary.simpleMessage("直接接続"),
    "rcxStrandedHold": MessageLookupByLibrary.simpleMessage("現在のまま"),
    "rcxStrategyAllServers": MessageLookupByLibrary.simpleMessage(
      "プロファイルのすべてのサーバーを使う",
    ),
    "rcxStrategyAuto": MessageLookupByLibrary.simpleMessage("サーバーを自動選択"),
    "rcxStrategyCoreUnavailable": MessageLookupByLibrary.simpleMessage(
      "戦略を利用できません。グループは標準の動作を使用できます。",
    ),
    "rcxStrategyEdit": MessageLookupByLibrary.simpleMessage("選択戦略を編集"),
    "rcxStrategyHold": MessageLookupByLibrary.simpleMessage("動作中のサーバーを維持"),
    "rcxStrategyLines": MessageLookupByLibrary.simpleMessage(
      "既存のサーバー、グループ、プロバイダーの名前を対応する欄に1行ずつ入力してください。",
    ),
    "rcxStrategyLowestLatency": MessageLookupByLibrary.simpleMessage(
      "計測した遅延が小さいサーバーを優先",
    ),
    "rcxStrategyNotApplied": MessageLookupByLibrary.simpleMessage(
      "戦略を適用できませんでした",
    ),
    "rcxStrategyPreferNames": MessageLookupByLibrary.simpleMessage(
      "この文字を含む名前を優先",
    ),
    "rcxStrategyProfileChanged": MessageLookupByLibrary.simpleMessage(
      "使用中のプロファイルが変わりました。保存するにはエディターを開き直してください。",
    ),
    "rcxStrategyYaml": MessageLookupByLibrary.simpleMessage("YAML を編集"),
    "rcxStudioCharacter": MessageLookupByLibrary.simpleMessage("特性"),
    "rcxStudioCharacterHint": MessageLookupByLibrary.simpleMessage(
      "切り替えは、より速いサーバーへどれだけ素早く移るかです。チェックは精度とバッテリー消費のトレードオフです。",
    ),
    "rcxStudioPreview": MessageLookupByLibrary.simpleMessage("今選ばれるサーバー"),
    "rcxStudioPreviewHint": MessageLookupByLibrary.simpleMessage(
      "グループを選ぶと、この動作がそのグループで選ぶサーバーが表示されます。",
    ),
    "rcxStudioRanking": MessageLookupByLibrary.simpleMessage("すべての候補"),
    "rcxStudioServersHint": MessageLookupByLibrary.simpleMessage(
      "これらの条件に合わないサーバーは選ばれることがありません。",
    ),
    "rcxSwitching": MessageLookupByLibrary.simpleMessage("切り替え"),
    "rcxTagName": MessageLookupByLibrary.simpleMessage("タグ名"),
    "rcxTagNameInvalid": MessageLookupByLibrary.simpleMessage(
      "ラテン文字、数字、-、_ のみ、24文字まで",
    ),
    "rcxTags": MessageLookupByLibrary.simpleMessage("タグ"),
    "rcxTagsHint": MessageLookupByLibrary.simpleMessage(
      "タグは一度サーバーの集合に名前を付け、優先条件で tag(name) として使えるようにします。",
    ),
    "rcxThirdParty": MessageLookupByLibrary.simpleMessage("サードパーティ"),
    "rcxTierLabel": MessageLookupByLibrary.simpleMessage("ラベル"),
    "rcxTitle": MessageLookupByLibrary.simpleMessage("自動ルーティング"),
    "rcxTurnOff": MessageLookupByLibrary.simpleMessage("スクリプトによる選択を解除"),
    "rcxUntilCheck": m141,
    "rcxUntilConfirm": m142,
    "rcxUntilDwell": m143,
    "rcxUseCheck": m144,
    "rcxUseDiagnostic": m145,
    "rcxUseEcho": MessageLookupByLibrary.simpleMessage("出口国チェック"),
    "rcxWarnings": MessageLookupByLibrary.simpleMessage("警告"),
    "rcxWhy": MessageLookupByLibrary.simpleMessage("このサーバーの理由"),
    "rcxWouldDo": MessageLookupByLibrary.simpleMessage("既定の動作"),
    "rcxWouldServers": m146,
    "rcxYaml": MessageLookupByLibrary.simpleMessage("YAML"),
    "recentRequests": MessageLookupByLibrary.simpleMessage("最近のリクエスト"),
    "recommendedIcons": MessageLookupByLibrary.simpleMessage("おすすめ"),
    "recordType": MessageLookupByLibrary.simpleMessage("レコードタイプ"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redirポート"),
    "redo": MessageLookupByLibrary.simpleMessage("やり直す"),
    "refresh": MessageLookupByLibrary.simpleMessage("更新"),
    "regex": MessageLookupByLibrary.simpleMessage("正規表現"),
    "releaseMemory": MessageLookupByLibrary.simpleMessage("メモリを解放"),
    "releaseMemoryFailed": MessageLookupByLibrary.simpleMessage(
      "メモリの解放に失敗しました",
    ),
    "remote": MessageLookupByLibrary.simpleMessage("リモート"),
    "remoteDestination": MessageLookupByLibrary.simpleMessage("リモート宛先"),
    "remoteDnsResolve": MessageLookupByLibrary.simpleMessage("リモート DNS 解決"),
    "remove": MessageLookupByLibrary.simpleMessage("削除"),
    "rename": MessageLookupByLibrary.simpleMessage("名前を変更"),
    "replace": MessageLookupByLibrary.simpleMessage("置換"),
    "replaceAll": MessageLookupByLibrary.simpleMessage("すべて置換"),
    "request": MessageLookupByLibrary.simpleMessage("リクエスト"),
    "requestHeaders": MessageLookupByLibrary.simpleMessage("リクエストヘッダー"),
    "requests": MessageLookupByLibrary.simpleMessage("リクエスト"),
    "requestsAndUpdates": MessageLookupByLibrary.simpleMessage("リクエストと更新"),
    "required": MessageLookupByLibrary.simpleMessage("必須"),
    "reset": MessageLookupByLibrary.simpleMessage("リセット"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "このページには変更があります。リセットしてもよろしいですか？",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage("リセットしてもよろしいですか？"),
    "resourceUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔"),
    "resourceUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "自動更新間隔は0より大きくしてください",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("リソース"),
    "respectRules": MessageLookupByLibrary.simpleMessage("ルールに従う"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "ルールに従うを有効にすると DNS 接続がルールに従います。Proxy Server Nameserver の設定が必要です。",
    ),
    "responseCode": MessageLookupByLibrary.simpleMessage("応答コード"),
    "restart": MessageLookupByLibrary.simpleMessage("再起動"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage("コアを再起動してもよろしいですか？"),
    "restore": MessageLookupByLibrary.simpleMessage("復元"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("すべてのデータを復元"),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage("プロファイルのみ復元"),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("復元方式"),
    "restoreStrategyCompatible": MessageLookupByLibrary.simpleMessage("互換"),
    "restoreStrategyOverride": MessageLookupByLibrary.simpleMessage("上書き"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage("復元が完了しました"),
    "result": MessageLookupByLibrary.simpleMessage("結果"),
    "retry": MessageLookupByLibrary.simpleMessage("再試行"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("ルートアドレス"),
    "routeBoard": MessageLookupByLibrary.simpleMessage("ルート"),
    "routeBoardDesc": MessageLookupByLibrary.simpleMessage("この端末から目的地までの経路"),
    "routeCarrier": MessageLookupByLibrary.simpleMessage("回線事業者"),
    "routeExcludeAddress": MessageLookupByLibrary.simpleMessage("ルート除外アドレス"),
    "routeFrom": MessageLookupByLibrary.simpleMessage("端末"),
    "routeMapFlat": MessageLookupByLibrary.simpleMessage("平面マップ"),
    "routeMapGlobe": MessageLookupByLibrary.simpleMessage("3D 地球儀"),
    "routeTo": MessageLookupByLibrary.simpleMessage("宛先"),
    "routeVia": MessageLookupByLibrary.simpleMessage("ノード"),
    "routingMark": MessageLookupByLibrary.simpleMessage("ルーティングマーク"),
    "ru": MessageLookupByLibrary.simpleMessage("ロシア語"),
    "rule": MessageLookupByLibrary.simpleMessage("ルール"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage("論理ルール AND"),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage("完全なドメインにマッチ"),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "ドメインキーワードにマッチ",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "ドメインの正規表現でマッチ",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "ドメインサフィックスにマッチ",
    ),
    "ruleActionDomainWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "ワイルドカードでマッチ（* と ? のみ対応）",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "DSCPマークにマッチ（tproxy udpインバウンドのみ）",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "宛先ポート範囲にマッチ",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage("IPの国コードにマッチ"),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Geosite 内のドメインにマッチ",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage("インバウンド名にマッチ"),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドポートにマッチ",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドタイプにマッチ",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドユーザー名にマッチ（/ で複数指定可）",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "IPが属するASNにマッチ",
    ),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "IPアドレス範囲にマッチ（IP-CIDR6 は別名です）",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "IPアドレス範囲にマッチ",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "IPサフィックス範囲にマッチ",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "すべてのリクエストにマッチ（条件不要）",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "TCPまたはUDPにマッチ",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage("論理ルール NOT"),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("論理ルール OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名でマッチ（Androidではパッケージ名にマッチ）",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名の正規表現でマッチ（Androidではパッケージ名にマッチ）",
    ),
    "ruleActionProcessNameWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名のワイルドカードでマッチ（* と ? のみ対応）",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスのフルパスでマッチ",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスパスの正規表現でマッチ",
    ),
    "ruleActionProcessPathWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスパスのワイルドカードでマッチ（* と ? のみ対応）",
    ),
    "ruleActionRematchNameDesc": MessageLookupByLibrary.simpleMessage(
      "再マッチ名にマッチ（複数は / で区切る）",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "ルールセットを参照します。rule-providersの設定が必要です",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPの国コードにマッチ",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPが属するASNにマッチ",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPアドレス範囲にマッチ",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPサフィックス範囲にマッチ",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "送信元ポート範囲にマッチ",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "サブルールへマッチします。括弧の使い方に注意してください",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "LinuxのユーザーIDにマッチ",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("ルールが空です"),
    "ruleHitCount": m147,
    "ruleHitDetail": m148,
    "ruleHitShare": m149,
    "ruleHits": MessageLookupByLibrary.simpleMessage("ルールヒット"),
    "ruleListInvalid": MessageLookupByLibrary.simpleMessage(
      "ルールは 1 項目に 1 つのルールを書いた YAML リストにしてください。例：- DOMAIN,example.com,DIRECT",
    ),
    "rulePresetAdBlock": MessageLookupByLibrary.simpleMessage("Block Ads"),
    "rulePresetBittorrentDirect": MessageLookupByLibrary.simpleMessage(
      "BitTorrent を直接接続",
    ),
    "rulePresetBlockDot": MessageLookupByLibrary.simpleMessage(
      "DNS over TLS をブロック",
    ),
    "rulePresetBlockLoopback": MessageLookupByLibrary.simpleMessage(
      "プロキシのループバックを防止",
    ),
    "rulePresetBlockQuic": MessageLookupByLibrary.simpleMessage("QUIC をブロック"),
    "rulePresetBlockStun": MessageLookupByLibrary.simpleMessage("STUN をブロック"),
    "rulePresetLanDirect": MessageLookupByLibrary.simpleMessage("LAN 直接接続"),
    "rulePresetSystemServicesDirect": MessageLookupByLibrary.simpleMessage(
      "Apple と Microsoft に直接接続",
    ),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("ルールプロバイダー"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("ルールセット"),
    "ruleSetEmptyTip": MessageLookupByLibrary.simpleMessage(
      "ルールセットに使用できるエントリがありません",
    ),
    "ruleSetInvalidTip": MessageLookupByLibrary.simpleMessage(
      "この mrs ファイルを読み込めません",
    ),
    "ruleSetMixedTip": MessageLookupByLibrary.simpleMessage(
      "ルールセットにドメインと IP 範囲が混在しているため、種類を判別できません",
    ),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("ルールターゲット"),
    "ruleTextInvalid": MessageLookupByLibrary.simpleMessage(
      "ルールは対応する種類で始めてください。例：DOMAIN,example.com,DIRECT",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("ルール"),
    "rulesCount": m150,
    "runTime": MessageLookupByLibrary.simpleMessage("稼働時間"),
    "running": MessageLookupByLibrary.simpleMessage("実行中"),
    "runtimeConfig": MessageLookupByLibrary.simpleMessage("ランタイム設定"),
    "safeMode": MessageLookupByLibrary.simpleMessage("セーフモード"),
    "safeModeAppTitle": m151,
    "saturation": MessageLookupByLibrary.simpleMessage("彩度"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("変更を保存しますか？"),
    "script": MessageLookupByLibrary.simpleMessage("スクリプト"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "スクリプトモード：拡張スクリプトでプロファイル全体を書き換えます",
    ),
    "scrollToSelected": MessageLookupByLibrary.simpleMessage("選択項目へスクロール"),
    "search": MessageLookupByLibrary.simpleMessage("検索"),
    "searchHint": MessageLookupByLibrary.simpleMessage("ページ、ノード、ツール、設定を検索"),
    "seconds": MessageLookupByLibrary.simpleMessage("秒"),
    "secondsCount": m152,
    "secretKey": MessageLookupByLibrary.simpleMessage("キー"),
    "sectionsInEffect": m153,
    "select": MessageLookupByLibrary.simpleMessage("選択"),
    "selectAll": MessageLookupByLibrary.simpleMessage("すべて選択"),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage("ルールセットを選択してください"),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "振り分け戦略を選択してください",
    ),
    "send": MessageLookupByLibrary.simpleMessage("送信"),
    "sendFromPhone": MessageLookupByLibrary.simpleMessage("スマートフォンから送信"),
    "sendFromPhoneConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "スマートフォンから届いたリンクをインポートしますか？",
    ),
    "sendFromPhoneDesc": MessageLookupByLibrary.simpleMessage(
      "スマートフォンでスキャンして、このデバイスにリンクを送信します",
    ),
    "sendFromPhoneNoNetwork": MessageLookupByLibrary.simpleMessage(
      "このデバイスはローカルネットワークに接続されていません",
    ),
    "sendFromPhonePageHint": MessageLookupByLibrary.simpleMessage(
      "サブスクリプションリンクまたはプロキシ共有リンク",
    ),
    "sendFromPhonePageSent": MessageLookupByLibrary.simpleMessage(
      "送信しました。もう一方のデバイスでインポートを確認してください。",
    ),
    "sendFromPhonePageTitle": MessageLookupByLibrary.simpleMessage(
      "Skyward にリンクを送信",
    ),
    "sendFromPhonePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "スマートフォンからリンクを受け取るには、Skyward がローカルネットワークにアクセスするための「付近のデバイス」権限が必要です。アプリの設定でオンにしてください。",
    ),
    "sendFromPhoneTip": MessageLookupByLibrary.simpleMessage(
      "スマートフォンのカメラでコードをスキャンし、開いたページにリンクを貼り付けてください。両方のデバイスを同じネットワークに接続する必要があります。",
    ),
    "server": MessageLookupByLibrary.simpleMessage("サーバー"),
    "serviceAbnormalCount": m154,
    "serviceAllAvailable": MessageLookupByLibrary.simpleMessage("すべて利用可能"),
    "serviceAvailable": MessageLookupByLibrary.simpleMessage("利用可能"),
    "serviceBlocked": MessageLookupByLibrary.simpleMessage("ブロック済み"),
    "serviceCheck": MessageLookupByLibrary.simpleMessage("検査"),
    "serviceCheckAll": MessageLookupByLibrary.simpleMessage("すべて検査"),
    "serviceCheckedAt": m155,
    "serviceComingSoon": MessageLookupByLibrary.simpleMessage("近日提供予定"),
    "serviceDisallowedIsp": MessageLookupByLibrary.simpleMessage(
      "許可されていない ISP",
    ),
    "serviceFailed": MessageLookupByLibrary.simpleMessage("検出に失敗しました"),
    "serviceManage": MessageLookupByLibrary.simpleMessage("サービスを管理"),
    "serviceOriginalsOnly": MessageLookupByLibrary.simpleMessage("オリジナル作品のみ"),
    "servicePending": MessageLookupByLibrary.simpleMessage("未検査"),
    "serviceRestricted": MessageLookupByLibrary.simpleMessage("アクセス制限"),
    "serviceShownOnDashboard": MessageLookupByLibrary.simpleMessage(
      "ダッシュボードに表示",
    ),
    "serviceStatus": MessageLookupByLibrary.simpleMessage("サービスの状態"),
    "serviceUnavailable": MessageLookupByLibrary.simpleMessage("利用不可"),
    "serviceUnsupportedRegion": MessageLookupByLibrary.simpleMessage("対象外の地域"),
    "settingEntries": MessageLookupByLibrary.simpleMessage("設定項目"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "settingsCount": m156,
    "shareLinkUnreadable": m157,
    "shareLinksInvalid": MessageLookupByLibrary.simpleMessage(
      "リンクからプロキシを読み取れませんでした",
    ),
    "shareQrcodeTip": MessageLookupByLibrary.simpleMessage(
      "別のデバイスの Skyward でスキャンすると、このプロファイルをインポートできます。",
    ),
    "show": MessageLookupByLibrary.simpleMessage("表示"),
    "showLess": MessageLookupByLibrary.simpleMessage("折りたたむ"),
    "showMore": MessageLookupByLibrary.simpleMessage("展開"),
    "showNotificationStopAction": MessageLookupByLibrary.simpleMessage(
      "通知に停止ボタンを表示",
    ),
    "showPassword": MessageLookupByLibrary.simpleMessage("パスワードを表示"),
    "sidebar": MessageLookupByLibrary.simpleMessage("サイドバー"),
    "sidebarBlurDesc": MessageLookupByLibrary.simpleMessage(
      "背景のぼかしでは、ウィンドウの背後のデスクトップがサイドバー越しに見えます。",
    ),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("サイレント起動"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "サイレント起動ではウィンドウを表示しません。",
    ),
    "singleAdd": MessageLookupByLibrary.simpleMessage("個別追加"),
    "singleImport": MessageLookupByLibrary.simpleMessage("個別インポート"),
    "singleShareLinkOnly": MessageLookupByLibrary.simpleMessage(
      "ここにはリンクを 1 つだけ入力してください。複数の場合は一覧のクイック編集を使ってください",
    ),
    "singleValueTip": m158,
    "size": MessageLookupByLibrary.simpleMessage("サイズ"),
    "skipCertVerify": MessageLookupByLibrary.simpleMessage("証明書の検証をスキップ"),
    "skipDomain": MessageLookupByLibrary.simpleMessage("スキップするドメイン"),
    "skipDomainDesc": MessageLookupByLibrary.simpleMessage(
      "スキップするドメインにあるドメインを検出しても使用しません。",
    ),
    "skipDstAddress": MessageLookupByLibrary.simpleMessage("スキップする宛先アドレス"),
    "skipSrcAddress": MessageLookupByLibrary.simpleMessage("スキップする送信元アドレス"),
    "slide": MessageLookupByLibrary.simpleMessage("スライド"),
    "sliders": MessageLookupByLibrary.simpleMessage("スライダ"),
    "sniffProtocols": MessageLookupByLibrary.simpleMessage("プロトコル"),
    "sniffer": MessageLookupByLibrary.simpleMessage("スニッファー"),
    "snifferStatusDesc": MessageLookupByLibrary.simpleMessage(
      "スニッファーは TLS・HTTP・QUIC の通信からドメインを読み取り、ルールで照合できるようにします。",
    ),
    "socksPort": MessageLookupByLibrary.simpleMessage("SOCKSポート"),
    "softStyle": MessageLookupByLibrary.simpleMessage("ソフト"),
    "sort": MessageLookupByLibrary.simpleMessage("並べ替え"),
    "source": MessageLookupByLibrary.simpleMessage("ソース"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("送信元IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("特殊プロキシ"),
    "specialRules": MessageLookupByLibrary.simpleMessage("特殊ルール"),
    "spectrum": MessageLookupByLibrary.simpleMessage("スペクトル"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("速度統計"),
    "speedTest": MessageLookupByLibrary.simpleMessage("接続テスト"),
    "speedTestDownloading": MessageLookupByLibrary.simpleMessage(
      "ダウンロード速度を測定中",
    ),
    "speedTestFailed": MessageLookupByLibrary.simpleMessage("テスト失敗"),
    "speedTestMbps": MessageLookupByLibrary.simpleMessage("Mbps"),
    "speedTestMs": MessageLookupByLibrary.simpleMessage("ミリ秒"),
    "speedTestPinging": MessageLookupByLibrary.simpleMessage("レイテンシを測定中"),
    "speedTestProvider": MessageLookupByLibrary.simpleMessage("プロバイダー"),
    "speedTestReady": MessageLookupByLibrary.simpleMessage("準備完了"),
    "speedTestResult": MessageLookupByLibrary.simpleMessage("結果"),
    "speedTestRoute": MessageLookupByLibrary.simpleMessage("テストルート"),
    "speedTestStart": MessageLookupByLibrary.simpleMessage("テスト開始"),
    "speedTestStop": MessageLookupByLibrary.simpleMessage("停止"),
    "speedTestSystemRoute": MessageLookupByLibrary.simpleMessage("システムルート"),
    "speedTestTesting": MessageLookupByLibrary.simpleMessage("テスト中"),
    "speedTestUploading": MessageLookupByLibrary.simpleMessage("アップロード速度を測定中"),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("振り分け戦略"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "振り分け戦略は空にできません",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDが空です"),
    "stackGvisorDesc": MessageLookupByLibrary.simpleMessage(
      "gVisor のユーザースペーススタック。機能と互換性が最も充実しており、メモリ使用量は比較的多めです。切り替え後は VPN の再起動が必要です。",
    ),
    "stackMipsDesc": MessageLookupByLibrary.simpleMessage(
      "既定値。sing-tun 内蔵の軽量ユーザースペーススタック。TCP 輻輳制御を使えるのはこのスタックだけです。切り替え後は VPN の再起動が必要です。",
    ),
    "stackMixedDesc": MessageLookupByLibrary.simpleMessage(
      "複合スタック。TCP はシステムのカーネルスタック、UDP は gVisor で処理します。切り替え後は VPN の再起動が必要です。",
    ),
    "stackMode": MessageLookupByLibrary.simpleMessage("スタックモード"),
    "stackSystemDesc": MessageLookupByLibrary.simpleMessage(
      "TCP はシステムのカーネルスタック、UDP はカーネル転送で処理します。切り替え後は VPN の再起動が必要です。",
    ),
    "stackTrace": MessageLookupByLibrary.simpleMessage("スタックトレース"),
    "standard": MessageLookupByLibrary.simpleMessage("標準"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "標準モード：プロファイルにルールを追加します",
    ),
    "start": MessageLookupByLibrary.simpleMessage("開始"),
    "startFromScratch": MessageLookupByLibrary.simpleMessage("最初から作成"),
    "startVpn": MessageLookupByLibrary.simpleMessage("VPNを起動しています…"),
    "startupAndBackground": MessageLookupByLibrary.simpleMessage("起動とバックグラウンド"),
    "status": MessageLookupByLibrary.simpleMessage("状態"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "DNS を無効にすると、システム DNS を使用します。",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("VPNを停止しています…"),
    "storage": MessageLookupByLibrary.simpleMessage("ストレージ"),
    "strategy": MessageLookupByLibrary.simpleMessage("戦略"),
    "strictRoute": MessageLookupByLibrary.simpleMessage("厳格なルーティング"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "厳格なルーティングは DNS などの通信が TUN を迂回するのを防ぎます。IPv6 がオフの場合、この端末の IPv6 通信は遮断されます。",
    ),
    "style": MessageLookupByLibrary.simpleMessage("スタイル"),
    "submit": MessageLookupByLibrary.simpleMessage("送信"),
    "subscriptionInfo": MessageLookupByLibrary.simpleMessage("サブスクリプション情報"),
    "sudoPasswordTitle": MessageLookupByLibrary.simpleMessage("sudo のパスワードを入力"),
    "suspended": MessageLookupByLibrary.simpleMessage("一時停止中…"),
    "switchProfile": MessageLookupByLibrary.simpleMessage("プロファイルを切り替え"),
    "sync": MessageLookupByLibrary.simpleMessage("同期"),
    "system": MessageLookupByLibrary.simpleMessage("システム"),
    "systemApp": MessageLookupByLibrary.simpleMessage("システムアプリ"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("システムプロキシ"),
    "tab": MessageLookupByLibrary.simpleMessage("タブ"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("タブアニメーション"),
    "takeoverScope": MessageLookupByLibrary.simpleMessage("適用範囲"),
    "takeoverScopeAlways": MessageLookupByLibrary.simpleMessage("常に有効"),
    "takeoverScopeDesc": MessageLookupByLibrary.simpleMessage(
      "VPN 接続後は 0.0.0.0/0 の経路がシステムに引き継がれるため、専用のスイッチはありません。",
    ),
    "tapIconToRetry": MessageLookupByLibrary.simpleMessage("アイコンをタップして再試行"),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("タップして許可"),
    "target": MessageLookupByLibrary.simpleMessage("宛先"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP同時接続"),
    "temporary": MessageLookupByLibrary.simpleMessage("一時ファイル"),
    "testInterval": MessageLookupByLibrary.simpleMessage("テスト間隔"),
    "testUrl": MessageLookupByLibrary.simpleMessage("テストURL"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("使用時にテスト"),
    "textScale": MessageLookupByLibrary.simpleMessage("テキストの拡大縮小"),
    "textScalePreview": MessageLookupByLibrary.simpleMessage(
      "アプリ内の文字はこの大きさで表示されます",
    ),
    "textSection": MessageLookupByLibrary.simpleMessage("テキスト"),
    "theme": MessageLookupByLibrary.simpleMessage("テーマ"),
    "themeColor": MessageLookupByLibrary.simpleMessage("テーマカラー"),
    "themeMode": MessageLookupByLibrary.simpleMessage("テーマモード"),
    "thisMonth": MessageLookupByLibrary.simpleMessage("今月"),
    "tight": MessageLookupByLibrary.simpleMessage("コンパクト"),
    "time": MessageLookupByLibrary.simpleMessage("時刻"),
    "timeout": MessageLookupByLibrary.simpleMessage("タイムアウト"),
    "tintedStyle": MessageLookupByLibrary.simpleMessage("ティント"),
    "tip": MessageLookupByLibrary.simpleMessage("ヒント"),
    "today": MessageLookupByLibrary.simpleMessage("今日"),
    "toggle": MessageLookupByLibrary.simpleMessage("切り替え"),
    "tolerance": MessageLookupByLibrary.simpleMessage("許容値"),
    "toolEntries": MessageLookupByLibrary.simpleMessage("ツール"),
    "tools": MessageLookupByLibrary.simpleMessage("その他"),
    "torch": MessageLookupByLibrary.simpleMessage("ライト"),
    "total": MessageLookupByLibrary.simpleMessage("合計"),
    "totalDownload": MessageLookupByLibrary.simpleMessage("ダウンロード量"),
    "totalTraffic": MessageLookupByLibrary.simpleMessage("合計トラフィック"),
    "totalUpload": MessageLookupByLibrary.simpleMessage("アップロード量"),
    "totalUptime": MessageLookupByLibrary.simpleMessage("稼働時間"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("TProxyポート"),
    "traffic": MessageLookupByLibrary.simpleMessage("通信量"),
    "trafficOverview": MessageLookupByLibrary.simpleMessage("トラフィック概要"),
    "trafficPeak": m159,
    "trafficPeakLine": m160,
    "trafficRanking": MessageLookupByLibrary.simpleMessage("トラフィックランキング"),
    "trafficTotal": m161,
    "trafficTrend": MessageLookupByLibrary.simpleMessage("トラフィック傾向"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("トラフィック統計"),
    "transport": MessageLookupByLibrary.simpleMessage("トランスポート"),
    "transportHeaders": m162,
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunAuthorizationFailed": MessageLookupByLibrary.simpleMessage(
      "TUN の権限を取得できなかったため、オフにしました。",
    ),
    "tunDesc": MessageLookupByLibrary.simpleMessage("TUN は管理者モードでのみ有効です。"),
    "tunGso": MessageLookupByLibrary.simpleMessage("TUN GSO"),
    "tunGsoDesc": MessageLookupByLibrary.simpleMessage(
      "ネットワーク速度を向上。変更後はVPNの再起動が必要。",
    ),
    "tunOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "ここで追加した項目は、すべてのプロファイルの TUN 設定を上書きします。追加していない項目はプロファイル自身の設定のままです。カスタムプロファイル自身が追加した項目が優先されます。",
    ),
    "tunRouteDesc": MessageLookupByLibrary.simpleMessage(
      "ルートアドレスが空のときは全トラフィックを引き継ぎます。除外アドレスのサブネットは仮想インターフェースを通りません。",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("オフにする"),
    "turnOn": MessageLookupByLibrary.simpleMessage("オンにする"),
    "type": MessageLookupByLibrary.simpleMessage("タイプ"),
    "udpRelayMode": MessageLookupByLibrary.simpleMessage("UDP リレーモード"),
    "udpTimeout": MessageLookupByLibrary.simpleMessage("UDP タイムアウト"),
    "udpTimeoutDesc": MessageLookupByLibrary.simpleMessage(
      "UDP タイムアウトは秒単位で、gvisor・system・mixed スタックでのみ有効です。",
    ),
    "ultra": MessageLookupByLibrary.simpleMessage("最高"),
    "undo": MessageLookupByLibrary.simpleMessage("元に戻す"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("統一遅延"),
    "unknown": MessageLookupByLibrary.simpleMessage("不明"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage("不明なネットワークエラー"),
    "unmaximize": MessageLookupByLibrary.simpleMessage("元に戻す"),
    "unnamed": MessageLookupByLibrary.simpleMessage("名称未設定"),
    "unpinWindow": MessageLookupByLibrary.simpleMessage("固定を解除"),
    "update": MessageLookupByLibrary.simpleMessage("更新"),
    "upload": MessageLookupByLibrary.simpleMessage("アップロード"),
    "uploadBandwidth": MessageLookupByLibrary.simpleMessage("アップロード帯域幅"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlTip": m163,
    "usageDetails": MessageLookupByLibrary.simpleMessage("使用の詳細"),
    "usageStats": MessageLookupByLibrary.simpleMessage("使用状況"),
    "useHosts": MessageLookupByLibrary.simpleMessage("Hostsを使用"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("システムのHostsを使用"),
    "usedShort": MessageLookupByLibrary.simpleMessage("使用済み"),
    "usedTraffic": MessageLookupByLibrary.simpleMessage("使用済みトラフィック"),
    "userAgent": MessageLookupByLibrary.simpleMessage("User-Agent"),
    "username": MessageLookupByLibrary.simpleMessage("ユーザー名"),
    "value": MessageLookupByLibrary.simpleMessage("値"),
    "version": MessageLookupByLibrary.simpleMessage("バージョン"),
    "versionUpdate": MessageLookupByLibrary.simpleMessage("バージョンアップデート"),
    "versionUpdateChecking": MessageLookupByLibrary.simpleMessage("確認中…"),
    "versionUpdateDownloading": MessageLookupByLibrary.simpleMessage(
      "ダウンロード中…",
    ),
    "versionUpdateFailed": MessageLookupByLibrary.simpleMessage("確認に失敗しました"),
    "versionUpdateFound": MessageLookupByLibrary.simpleMessage("新しいバージョンがあります"),
    "versionUpdateLatest": MessageLookupByLibrary.simpleMessage("最新です"),
    "view": MessageLookupByLibrary.simpleMessage("表示"),
    "virtualIpv4": MessageLookupByLibrary.simpleMessage("仮想 IPv4"),
    "vividStyle": MessageLookupByLibrary.simpleMessage("ビビッド"),
    "vpnBehavior": MessageLookupByLibrary.simpleMessage("VPN の動作"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN関連の設定変更を検出しました",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "VPN は VpnService でシステムの全トラフィックを自動的にルーティングします。",
    ),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage("WebDAV設定"),
    "webrtcGuard": MessageLookupByLibrary.simpleMessage("WebRTC"),
    "webrtcGuardBlock": MessageLookupByLibrary.simpleMessage("遮断"),
    "webrtcGuardDesc": MessageLookupByLibrary.simpleMessage(
      "ページや通話は STUN サーバーにこの端末の公開アドレスを問い合わせます。遮断が最も安全ですが、P2P 通信はリレー経由になるか失敗します。プロキシ経由ではノードの出口アドレスが渡され、UDP に対応したノードが必要です。未処理では設定のルールに任せます。",
    ),
    "webrtcGuardOff": MessageLookupByLibrary.simpleMessage("未処理"),
    "webrtcGuardProxy": MessageLookupByLibrary.simpleMessage("プロキシ経由"),
    "webrtcLeakAdvice": MessageLookupByLibrary.simpleMessage(
      "「遮断」では反射アドレスが表示されないのが正常です。実際の漏れを調べるには、「詳細設定 → ネットワーク」で WebRTC を一時的に「そのまま」にし、確認後に戻してください。",
    ),
    "webrtcLeakExternal": MessageLookupByLibrary.simpleMessage(
      "ブラウザーで WebRTC を確認",
    ),
    "webrtcLeakGuard": MessageLookupByLibrary.simpleMessage("保護モード"),
    "webrtcLeakGuardOffBad": MessageLookupByLibrary.simpleMessage(
      "保護がオフなので、ページから本体のグローバルアドレスを読めます",
    ),
    "webrtcLeakGuardProxyBad": MessageLookupByLibrary.simpleMessage(
      "検出はプロキシ経由です。ノードが UDP に対応している必要があります",
    ),
    "webrtcLeakReflected": MessageLookupByLibrary.simpleMessage("反射アドレス"),
    "webrtcLeakStun": MessageLookupByLibrary.simpleMessage("STUN プローブ"),
    "webrtcLeakStunBlocked": MessageLookupByLibrary.simpleMessage(
      "STUN 応答がないため、ブロックは機能しています",
    ),
    "webrtcLeakStunOpen": MessageLookupByLibrary.simpleMessage(
      "STUN サーバーから応答がありました",
    ),
    "webrtcLeakStunSilent": MessageLookupByLibrary.simpleMessage(
      "STUN 応答がなく、判定できません",
    ),
    "webrtcLeakStunUnresolved": MessageLookupByLibrary.simpleMessage(
      "STUN ホストを解決できません。ネットワークが利用できません",
    ),
    "week": MessageLookupByLibrary.simpleMessage("週"),
    "weeklyRange": m164,
    "whitelistMode": MessageLookupByLibrary.simpleMessage("ホワイトリストモード"),
    "writeToSystem": MessageLookupByLibrary.simpleMessage("システムに書き込む"),
    "writeToSystemDesc": MessageLookupByLibrary.simpleMessage(
      "システムに書き込むを有効にするとシステムクロックも設定します。Android では無視されます。",
    ),
    "yearsAgo": m165,
    "yearsAgoShort": m166,
    "yes": MessageLookupByLibrary.simpleMessage("はい"),
    "zhCN": MessageLookupByLibrary.simpleMessage("簡体字中国語"),
  };
}
