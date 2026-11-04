import 'package:skyward/models/clash_config.dart';

/// The ad and tracker domains Skyward blocks unless the reader turns the module
/// off in Settings -> Advanced configuration.
///
/// A module rather than one of the quick presets: it is on from the first
/// launch, so the reader never has to find it, and it covers every subscription
/// at once instead of being pasted into one profile's added rules. The rules go
/// in ahead of the profile's own (see `SetupAction.getProfile`), so a
/// subscription that ships its own ad rules cannot take them back out.
///
/// Only names that serve ads or measure visitors belong here. Attribution SDKs
/// (Adjust, AppsFlyer) and push transports are deliberately absent: blocking
/// them breaks first launches and message delivery in apps that expect them,
/// which is not the trade this module is meant to make. The grouping is for
/// whoever edits this list -- it does not reach the config.
const adBlockRules = <String>[
  // Google: ad serving, tag management and app analytics.
  'DOMAIN-SUFFIX,doubleclick.net,REJECT',
  'DOMAIN-SUFFIX,googlesyndication.com,REJECT',
  'DOMAIN-SUFFIX,googleadservices.com,REJECT',
  'DOMAIN-SUFFIX,google-analytics.com,REJECT',
  'DOMAIN-SUFFIX,googletagmanager.com,REJECT',
  'DOMAIN-SUFFIX,googletagservices.com,REJECT',
  // Firebase Analytics. The rest of Firebase stays reachable: messaging and
  // remote config share those names.
  'DOMAIN-SUFFIX,app-measurement.com,REJECT',

  // Ad exchanges and the trackers that ride along with them.
  'DOMAIN-SUFFIX,adnxs.com,REJECT',
  'DOMAIN-SUFFIX,criteo.com,REJECT',
  'DOMAIN-SUFFIX,criteo.net,REJECT',
  'DOMAIN-SUFFIX,outbrain.com,REJECT',
  'DOMAIN-SUFFIX,taboola.com,REJECT',
  'DOMAIN-SUFFIX,pubmatic.com,REJECT',
  'DOMAIN-SUFFIX,rubiconproject.com,REJECT',
  'DOMAIN-SUFFIX,openx.net,REJECT',
  'DOMAIN-SUFFIX,smartadserver.com,REJECT',
  'DOMAIN-SUFFIX,adform.net,REJECT',
  'DOMAIN-SUFFIX,casalemedia.com,REJECT',
  'DOMAIN-SUFFIX,33across.com,REJECT',
  'DOMAIN-SUFFIX,sharethrough.com,REJECT',
  'DOMAIN-SUFFIX,teads.tv,REJECT',
  'DOMAIN-SUFFIX,bidswitch.net,REJECT',
  'DOMAIN-SUFFIX,sovrn.com,REJECT',
  'DOMAIN-SUFFIX,lijit.com,REJECT',
  'DOMAIN-SUFFIX,adroll.com,REJECT',

  // Mobile ad SDKs that ship inside apps.
  'DOMAIN-SUFFIX,applovin.com,REJECT',
  'DOMAIN-SUFFIX,unityads.unity3d.com,REJECT',
  'DOMAIN-SUFFIX,vungle.com,REJECT',
  'DOMAIN-SUFFIX,ironsrc.com,REJECT',
  'DOMAIN-SUFFIX,ironsource.mobi,REJECT',
  'DOMAIN-SUFFIX,mintegral.com,REJECT',
  'DOMAIN-SUFFIX,chartboost.com,REJECT',
  'DOMAIN-SUFFIX,adcolony.com,REJECT',
  'DOMAIN-SUFFIX,tapjoy.com,REJECT',
  'DOMAIN-SUFFIX,inmobi.com,REJECT',
  'DOMAIN-SUFFIX,startapp.com,REJECT',
  'DOMAIN-SUFFIX,startappservice.com,REJECT',
  'DOMAIN-SUFFIX,fyber.com,REJECT',
  'DOMAIN-SUFFIX,smaato.com,REJECT',
  'DOMAIN-SUFFIX,liftoff.io,REJECT',
  'DOMAIN-SUFFIX,moloco.com,REJECT',
  'DOMAIN-SUFFIX,digitalturbine.com,REJECT',

  // Pangle (ByteDance).
  'DOMAIN-SUFFIX,pangle.io,REJECT',
  'DOMAIN-SUFFIX,pangolin-sdk-toutiao.com,REJECT',
  'DOMAIN-SUFFIX,pglstatp-toutiao.com,REJECT',
  'DOMAIN-SUFFIX,gromore.cn,REJECT',
  'DOMAIN,is.snssdk.com,REJECT',

  // GDT / Youlianghui (Tencent).
  'DOMAIN-SUFFIX,gdt.qq.com,REJECT',
  'DOMAIN,pgdt.gtimg.cn,REJECT',
  'DOMAIN,mi.gdt.qq.com,REJECT',

  // Baidu union.
  'DOMAIN-SUFFIX,mobads.baidu.com,REJECT',
  'DOMAIN-SUFFIX,mobads-logs.baidu.com,REJECT',
  'DOMAIN-SUFFIX,pos.baidu.com,REJECT',
  'DOMAIN-SUFFIX,cpro.baidu.com,REJECT',
  'DOMAIN-SUFFIX,cbjs.baidu.com,REJECT',

  // Alimama (Alibaba).
  'DOMAIN-SUFFIX,tanx.com,REJECT',
  'DOMAIN-SUFFIX,alimama.com,REJECT',

  // Vendor ad networks on Android phones.
  'DOMAIN-SUFFIX,ad.xiaomi.com,REJECT',
  'DOMAIN-SUFFIX,ad.mi.com,REJECT',
  'DOMAIN-SUFFIX,ads.oppomobile.com,REJECT',
  'DOMAIN-SUFFIX,adx.oppomobile.com,REJECT',
  'DOMAIN-SUFFIX,adnet.vivo.com.cn,REJECT',

  // Chinese analytics and push vendors. These carry telemetry rather than ads,
  // but an app that cannot reach them only loses its dashboards.
  'DOMAIN-SUFFIX,umeng.com,REJECT',
  'DOMAIN-SUFFIX,umtrack.com,REJECT',
  'DOMAIN-SUFFIX,umengcloud.com,REJECT',
  'DOMAIN-SUFFIX,getui.com,REJECT',
  'DOMAIN-SUFFIX,getui.net,REJECT',
  'DOMAIN-SUFFIX,igexin.com,REJECT',
  'DOMAIN-SUFFIX,jpush.cn,REJECT',
  'DOMAIN-SUFFIX,jiguang.cn,REJECT',
  'DOMAIN-SUFFIX,talkingdata.com,REJECT',
  'DOMAIN-SUFFIX,growingio.com,REJECT',
  'DOMAIN-SUFFIX,sensorsdata.cn,REJECT',
  'DOMAIN-SUFFIX,miaozhen.com,REJECT',
  'DOMAIN-SUFFIX,admaster.com.cn,REJECT',
  'DOMAIN-SUFFIX,adview.cn,REJECT',

  // Session recording and behavioural analytics.
  'DOMAIN-SUFFIX,scorecardresearch.com,REJECT',
  'DOMAIN-SUFFIX,quantserve.com,REJECT',
  'DOMAIN-SUFFIX,hotjar.com,REJECT',
  'DOMAIN-SUFFIX,mixpanel.com,REJECT',
  'DOMAIN-SUFFIX,amplitude.com,REJECT',
  'DOMAIN-SUFFIX,segment.io,REJECT',
  'DOMAIN-SUFFIX,fullstory.com,REJECT',
  'DOMAIN-SUFFIX,mouseflow.com,REJECT',
  'DOMAIN-SUFFIX,crazyegg.com,REJECT',
  'DOMAIN-SUFFIX,luckyorange.com,REJECT',
];

/// [adBlockRules] as parsed rules, for the config builder and the settings
/// page alike.
List<Rule> get adBlockRuleList => adBlockRules.map(Rule.parse).toList();

/// [rules] with the module's rules in front of them.
///
/// In front because the added rules are what a profile's own list cannot
/// override -- that is the whole point of putting them there -- and minus any
/// line [rules] already carries, so a reader who pasted the same names into
/// their added rules before this module existed keeps one copy of each.
List<Rule> withAdBlockRules(List<Rule> rules) {
  final existing = rules.map((rule) => rule.rawValue).toSet();
  return [
    ...adBlockRuleList.where((rule) => !existing.contains(rule.rawValue)),
    ...rules,
  ];
}
