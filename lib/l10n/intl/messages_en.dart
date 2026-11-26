// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(count) =>
      "${Intl.plural(count, other: '${count} selected')}";

  static String m1(name) => "Added ${name} to local proxies";

  static String m2(name) => "${name} is already in local proxies";

  static String m3(count, skipped) =>
      "${count} to add, ${skipped} skipped as existing";

  static String m4(detail) => "Couldn\'t clear the data: ${detail}";

  static String m5(count) => "${count} connections";

  static String m6(code) =>
      "Windows refused to run SkywardCore.exe (error ${code}). An app control policy such as Smart App Control or AppLocker blocks unsigned programs; allow Skyward in that policy or turn it off, then try again.";

  static String m7(name) =>
      "The app failed to finish launching twice in a row. To break the loop, the profile ${name} has been deselected and automatic setup was skipped. You can select it again at any time.";

  static String m8(url) => "Do you want to create a profile from ${url}?";

  static String m9(count, label) =>
      "${Intl.plural(count, one: '1 SUB-RULE rule was dropped, since custom profiles do not support sub-rules', other: '${label} SUB-RULE rules were dropped, since custom profiles do not support sub-rules')}";

  static String m10(message) => "The core cannot parse this proxy: ${message}";

  static String m11(proxy, target) =>
      "${proxy} dials through ${target}, which leads back to ${proxy}, so the dial loops";

  static String m12(name) =>
      "The name ${name} is already used by another proxy or proxy group";

  static String m13(path) =>
      "Proxy groups reference each other in a loop: ${path}";

  static String m14(name) =>
      "The empty fallback must be a proxy, but ${name} does not exist or is a proxy group";

  static String m15(name, message) =>
      "${name} is not a valid regex: ${message}";

  static String m16(name) => "The dialer proxy ${name} does not exist";

  static String m17(names) => "These proxy providers do not exist: ${names}";

  static String m18(names) =>
      "These proxies or policies do not exist: ${names}";

  static String m19(name) =>
      "${name} is a built-in policy name and cannot be used here";

  static String m20(count) =>
      "${count} items have problems, and applying this profile may fail";

  static String m21(count) =>
      "${Intl.plural(count, one: '1 day ago', other: '${count} days ago')}";

  static String m22(count) => "${Intl.plural(count, other: '${count}d ago')}";

  static String m23(label) =>
      "Are you sure you want to delete the selected ${label}?";

  static String m24(label) => "Are you sure you want to delete this ${label}?";

  static String m25(label) => "${label} details";

  static String m26(name) =>
      "Dialing through ${name} leads back to the proxy that uses it, so the connection was stopped";

  static String m27(value, percent) => "Direct ${value} · ${percent}";

  static String m28(days, hours) => "${days} d ${hours} h";

  static String m29(hours, minutes) => "${hours} h ${minutes} min";

  static String m30(count) => "${count} min";

  static String m31(label) => "${label} cannot be empty";

  static String m32(label) => "${label} already exists";

  static String m33(count) => "${count} items failed";

  static String m34(label, message) => "${label}: ${message}";

  static String m35(name) => "${name} is already up to date";

  static String m36(name) => "${name} updated";

  static String m37(count) =>
      "${Intl.plural(count, one: '1 group', other: '${count} groups')}";

  static String m38(count) => "${count} timed out";

  static String m39(action) =>
      "Already used by “${action}”. Saving moves it here.";

  static String m40(modifiers) => "Include at least one of ${modifiers}";

  static String m41(count) =>
      "${Intl.plural(count, one: '1 hour ago', other: '${count} hours ago')}";

  static String m42(count) => "${Intl.plural(count, other: '${count}h ago')}";

  static String m43(target) => "${target} is an invalid policy";

  static String m44(proxyName) => "${proxyName} is an invalid proxy";

  static String m45(providerName) =>
      "${providerName} is an invalid proxy provider";

  static String m46(ruleSet) => "${ruleSet} is an invalid rule set";

  static String m47(subRule) => "${subRule} is an invalid SUB_RULE";

  static String m48(count) =>
      "${Intl.plural(count, one: '1 item', other: '${count} items')}";

  static String m49(line, message) => "Line ${line}: ${message}";

  static String m50(appName) =>
      "1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check ${appName} in the list\n\nWhen you are done, return to the app to continue. Thank you for your cooperation.";

  static String m51(label, max) => "${label} must be at most ${max} characters";

  static String m52(size) => "Released ${size}";

  static String m53(count) =>
      "${Intl.plural(count, one: '1 minute ago', other: '${count} minutes ago')}";

  static String m54(count) => "${Intl.plural(count, other: '${count}m ago')}";

  static String m55(count) =>
      "${Intl.plural(count, one: '1 month ago', other: '${count} months ago')}";

  static String m56(count) => "${Intl.plural(count, other: '${count}mo ago')}";

  static String m57(code) =>
      "The server denied access (HTTP ${code}). The link may have expired, or the credentials are wrong";

  static String m58(code) => "The server rejected the request (HTTP ${code})";

  static String m59(code) =>
      "Nothing was found at this address (HTTP ${code}). Check that the URL is correct";

  static String m60(detail) => "Network request failed: ${detail}";

  static String m61(code) =>
      "The server ran into a problem (HTTP ${code}). Try again later";

  static String m62(label) => "No ${label} yet";

  static String m63(label, min, max) =>
      "${label} must be between ${min} and ${max}";

  static String m64(label) => "${label} must be a number";

  static String m65(label) => "${label} must be between 1024 and 49151";

  static String m66(port) => "Port ${port}";

  static String m67(days) =>
      "${Intl.plural(days, one: '1 day left', other: '${days} days left')}";

  static String m68(date, days) =>
      "Expires ${date}, ${Intl.plural(days, one: '1 day', other: '${days} days')} left";

  static String m69(time) => "Updated ${time}";

  static String m70(label, profiles) =>
      "${label} is still used by ${profiles}, which will not work properly once it is deleted. Are you sure you want to delete it?";

  static String m71(count, label) =>
      "${Intl.plural(count, one: '1 proxy', other: '${label} proxies')}";

  static String m72(name, count) => "${name} and others (${count} proxies)";

  static String m73(removed) =>
      "These proxies will be deleted: ${removed}. A line whose name changed counts as a new proxy, and custom profiles naming the deleted ones will flag them as missing. Apply anyway?";

  static String m74(removed, added) =>
      "These proxies will be deleted: ${removed}. These will be added: ${added}. A line whose name changed counts as a new proxy, and custom profiles naming the deleted ones will flag them as missing. Apply anyway?";

  static String m75(label) =>
      "${label} is still named by rules, proxy groups, dialer proxies, DNS or NTP in this profile, which stop working once it is deleted. Are you sure you want to delete it?";

  static String m76(count, label) =>
      "${Intl.plural(count, one: '1 proxy group', other: '${label} proxy groups')}";

  static String m77(value, percent) => "Proxy ${value} · ${percent}";

  static String m78(percent, upload, download) =>
      "${percent} · ↑ ${upload} ↓ ${download}";

  static String m79(pick, now) => "Would pick ${pick} instead of ${now}";

  static String m80(group) => "What it picks in ${group}";

  static String m81(pick) => "Would keep ${pick}";

  static String m82(number) => "Condition ${number}";

  static String m83(profile) => "“${profile}” wants to check these sites";

  static String m84(count) =>
      "${Intl.plural(count, one: '${count} server', other: '${count} servers')}";

  static String m85(profile) => "Delete “${profile}”?";

  static String m86(requests, used, cap) =>
      "Checks today: ${requests} · ${used} of ${cap}";

  static String m87(condition) => "except ${condition}";

  static String m88(country) => "exit ${country}";

  static String m89(member) => "Through ${member}";

  static String m90(scenario) => "From scenario «${scenario}»";

  static String m91(title) =>
      "“${title}” is not yours to change. Your edits go to a copy, and the copy becomes the running scenario.";

  static String m92(mode) =>
      "Routes apply in rule mode; the connection is in ${mode} mode now.";

  static String m93(profile) => "Added “${profile}”";

  static String m94(node) => "${node} stopped working";

  static String m95(from, to) => "Mode ${from} → ${to}";

  static String m96(count) =>
      "${Intl.plural(count, one: '${count} server fits now', other: '${count} servers fit now')}";

  static String m97(ms) => "under ${ms} ms";

  static String m98(text) => "${text} in name";

  static String m99(what) => "not ${what}";

  static String m100(provider) => "from ${provider}";

  static String m101(number) => "Step ${number}";

  static String m102(tag) => "tag ${tag}";

  static String m103(line, text) => "Line ${line}: ${text}";

  static String m104(check) => "Check ${check} is never used, so it never runs";

  static String m105(hosts) => "Contacts third-party sites: ${hosts}";

  static String m106(group) => "This config has no group ${group}";

  static String m107(group) => "No server of ${group} passes the filter";

  static String m108(tag) => "Tag ${tag} is never used";

  static String m109(tier, group) =>
      "No server of ${group} is in “${tier}” right now";

  static String m110(tier, after) =>
      "“${tier}” repeats the condition of “${after}”, so nothing lands in it";

  static String m111(name, count) => "${name} and ${count} more";

  static String m112(keys) =>
      "Brought over; you changed these too, so yours were kept: ${keys}";

  static String m113(mode) => "Mode: ${mode}";

  static String m114(node) =>
      "Stays on ${node}; leaves it only when it fails and comes back when it recovers.";

  static String m115(kind) => "Network: ${kind}";

  static String m116(condition) => "only ${condition}";

  static String m117(tier) => "may reach “${tier}” after a check";

  static String m118(node) => "Pinned: ${node}";

  static String m119(error) => "Behaviour error: ${error}";

  static String m120(profile) =>
      "Behaviour ${profile} was not found; the default is used";

  static String m121(error) => "Routing state could not be saved: ${error}";

  static String m122(tier) => "Moved to a server in “${tier}”";

  static String m123(from) =>
      "Changed server; ${from} is skipped for 15 minutes";

  static String m124(from) =>
      "${from} stopped working; switched to the best standby";

  static String m125(from, gain) => "Switched from ${from}: ${gain} ms faster";

  static String m126(node) => "The scenario holds ${node}";

  static String m127(node) => "${node} is not in this group";

  static String m128(limit) => "Switch limit reached (${limit} per hour)";

  static String m129(mode) => "Not in use: mode ${mode}";

  static String m130(from) => "${from} is no longer in the pool";

  static String m131(kind) =>
      "Paused while the network is “${kind}”: nothing is checked or switched";

  static String m132(route, error) =>
      "The route «${route}» could not be applied: ${error}";

  static String m133(route) =>
      "The route «${route}» was skipped: a group with its name already exists.";

  static String m134(route, to) =>
      "The route «${route}» sends traffic to «${to}», which is not in the profile.";

  static String m135(node) => "The scenario moves to ${node}";

  static String m136(node) => "Switched to the pinned server ${node}";

  static String m137(node) => "No working server; fell back to ${node}";

  static String m138(scenario) =>
      "A route in the scenario «${scenario}» created this group. Edit or remove it there.";

  static String m139(scenario) =>
      "The scenario «${scenario}» drives this group now.";

  static String m140(count, total) => "${count} of ${total} match";

  static String m141(node) => "Will switch to ${node} once a check confirms it";

  static String m142(node, gain) =>
      "Will switch to ${node} if it stays ${gain} ms faster";

  static String m143(node, minutes) =>
      "May switch to ${node} in ${minutes} min";

  static String m144(name) => "check ${name}";

  static String m145(name) => "network diagnostic ${name}";

  static String m146(count) =>
      "${Intl.plural(count, one: 'It chooses from the ${count} server of this group.', other: 'It chooses among the ${count} servers of this group.')}";

  static String m147(count) => "${count} rules hit";

  static String m148(count, upload, download) =>
      "${count} · ↑ ${upload} ↓ ${download}";

  static String m149(percent, count) => "${percent} of hit traffic · ${count}";

  static String m150(count, label) =>
      "${Intl.plural(count, one: '1 rule', other: '${label} rules')}";

  static String m151(appName) => "${appName} (Safe mode)";

  static String m152(count) =>
      "${Intl.plural(count, one: '1 second', other: '${count} seconds')}";

  static String m153(count) => "${count} in effect";

  static String m154(count) =>
      "${Intl.plural(count, one: '1 issue', other: '${count} issues')}";

  static String m155(time) => "Checked at ${time}";

  static String m156(count) =>
      "${Intl.plural(count, one: '1 setting', other: '${count} settings')}";

  static String m157(link) => "No proxy could be read from ${link}";

  static String m158(label) => "${label} must be a single item";

  static String m159(value) => "Peak ${value}";

  static String m160(hour, value) => "Peak ${hour}:00 · ${value}";

  static String m161(value) => "Total ${value}";

  static String m162(transport) => "${transport} Headers";

  static String m163(label) => "${label} must be a URL";

  static String m164(week, year) => "Week ${week} of ${year}";

  static String m165(month, day) => "Week of ${month}/${day}";

  static String m166(count) =>
      "${Intl.plural(count, one: '1 year ago', other: '${count} years ago')}";

  static String m167(count) => "${Intl.plural(count, other: '${count}y ago')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "accessControl": MessageLookupByLibrary.simpleMessage("Access control"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Only selected apps go through the VPN",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "Access control picks which apps use the proxy.",
    ),
    "accessControlDisabledDesc": MessageLookupByLibrary.simpleMessage(
      "App access control is disabled",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Selected apps are excluded from the VPN",
    ),
    "accessControlSelectedCount": m0,
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "acknowledgments": MessageLookupByLibrary.simpleMessage("Acknowledgments"),
    "acknowledgmentsDesc": MessageLookupByLibrary.simpleMessage(
      "Skyward began as a fork of FlClash by chen08209 and is built on the mihomo (Clash.Meta) core by MetaCubeX. Both are released under GPL-3.0.",
    ),
    "action": MessageLookupByLibrary.simpleMessage("Action"),
    "actionDelayTest": MessageLookupByLibrary.simpleMessage("Test all delays"),
    "actionDirectMode": MessageLookupByLibrary.simpleMessage("Direct mode"),
    "actionGlobalMode": MessageLookupByLibrary.simpleMessage("Global mode"),
    "actionMode": MessageLookupByLibrary.simpleMessage("Switch mode"),
    "actionProxy": MessageLookupByLibrary.simpleMessage("System proxy"),
    "actionRuleMode": MessageLookupByLibrary.simpleMessage("Rule mode"),
    "actionStart": MessageLookupByLibrary.simpleMessage("Start/Stop"),
    "actionTun": MessageLookupByLibrary.simpleMessage("TUN"),
    "actionUpdateProfiles": MessageLookupByLibrary.simpleMessage(
      "Update profiles",
    ),
    "actionView": MessageLookupByLibrary.simpleMessage("Show/Hide"),
    "adBlockDescription": MessageLookupByLibrary.simpleMessage(
      "Blocks common ad and tracker domains, ahead of the rules a subscription ships.",
    ),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "addCustomProxy": MessageLookupByLibrary.simpleMessage("Add proxy"),
    "addFilters": MessageLookupByLibrary.simpleMessage("Add filters"),
    "addNodes": MessageLookupByLibrary.simpleMessage("Add nodes"),
    "addOverrideEntry": MessageLookupByLibrary.simpleMessage(
      "Add override entry",
    ),
    "addProfile": MessageLookupByLibrary.simpleMessage("Add profile"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("Add proxy group"),
    "addRule": MessageLookupByLibrary.simpleMessage("Add rule"),
    "addSettingEntry": MessageLookupByLibrary.simpleMessage("Add setting"),
    "addSsid": MessageLookupByLibrary.simpleMessage("Add SSID"),
    "addToLocalProxies": MessageLookupByLibrary.simpleMessage(
      "Add to local proxies",
    ),
    "addedRules": MessageLookupByLibrary.simpleMessage("Added rules"),
    "addedToLocalProxies": m1,
    "additionalParameters": MessageLookupByLibrary.simpleMessage(
      "Additional parameters",
    ),
    "additionalPrefix": MessageLookupByLibrary.simpleMessage("Name prefix"),
    "additionalSuffix": MessageLookupByLibrary.simpleMessage("Name suffix"),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "addressHelp": MessageLookupByLibrary.simpleMessage(
      "WebDAV server address",
    ),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid WebDAV address",
    ),
    "advancedConfig": MessageLookupByLibrary.simpleMessage(
      "Advanced configuration",
    ),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Advanced configuration holds DNS, added rules, and scripts.",
    ),
    "ageEncryptedProfile": MessageLookupByLibrary.simpleMessage(
      "Encrypted profile",
    ),
    "ageSecretKey": MessageLookupByLibrary.simpleMessage("Age secret key"),
    "ageSecretKeyRequiredTip": MessageLookupByLibrary.simpleMessage(
      "This profile is encrypted with age and needs an age secret key to decrypt",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("Agree"),
    "allReferencedProxies": MessageLookupByLibrary.simpleMessage(
      "All referenced proxies",
    ),
    "allReferencedProxyProviders": MessageLookupByLibrary.simpleMessage(
      "All referenced proxy providers",
    ),
    "allowBypass": MessageLookupByLibrary.simpleMessage(
      "Allow apps to bypass VPN",
    ),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "Apps may bring up their own VPN and leave this one.",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("Allow LAN"),
    "allowedIps": MessageLookupByLibrary.simpleMessage("Allowed IPs"),
    "alreadyInLocalProxies": m2,
    "answers": MessageLookupByLibrary.simpleMessage("Answers"),
    "app": MessageLookupByLibrary.simpleMessage("App"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage(
      "App access control",
    ),
    "appIconDesign": MessageLookupByLibrary.simpleMessage("App icon design"),
    "appProxiesEmpty": MessageLookupByLibrary.simpleMessage("No local proxies"),
    "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage(
      "Append system DNS",
    ),
    "authentication": MessageLookupByLibrary.simpleMessage("Authentication"),
    "authenticationDesc": MessageLookupByLibrary.simpleMessage(
      "Authentication asks for a username and password on the local proxy port.",
    ),
    "authenticationSystemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "The system proxy is not applied while authentication is on.",
    ),
    "authorize": MessageLookupByLibrary.simpleMessage("Authorize"),
    "authorized": MessageLookupByLibrary.simpleMessage("Authorized"),
    "auto": MessageLookupByLibrary.simpleMessage("Auto"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage(
      "Auto check for updates",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage(
      "Auto close connections",
    ),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Auto close connections drops open connections when you switch proxies.",
    ),
    "autoInclude": MessageLookupByLibrary.simpleMessage("Auto-include"),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("Auto launch"),
    "autoRun": MessageLookupByLibrary.simpleMessage("Auto run"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "Auto run starts the proxy when the app opens.",
    ),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage(
      "Auto-set system DNS",
    ),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("Auto update"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Auto-update interval",
    ),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "backgroundBlur": MessageLookupByLibrary.simpleMessage("Background blur"),
    "backup": MessageLookupByLibrary.simpleMessage("Backup"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage(
      "Backup and restore",
    ),
    "backupFromNewerVersion": MessageLookupByLibrary.simpleMessage(
      "This backup comes from a newer version of the app. Update the app before restoring it",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("Backup successful"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("Basic info"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("Basic strategies"),
    "batchAdd": MessageLookupByLibrary.simpleMessage("Batch add"),
    "batchImport": MessageLookupByLibrary.simpleMessage("Batch import"),
    "batchLinkInputTip": MessageLookupByLibrary.simpleMessage(
      "One link per line",
    ),
    "batchListInputTip": MessageLookupByLibrary.simpleMessage(
      "One item per line, or separated by commas",
    ),
    "batchMapInputTip": MessageLookupByLibrary.simpleMessage(
      "One entry per line: key, a space, then value",
    ),
    "batchPreviewTip": m3,
    "batchUrlInputTip": MessageLookupByLibrary.simpleMessage(
      "One URL per line",
    ),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "Ignore battery optimization keeps the app running in the background.",
    ),
    "bind": MessageLookupByLibrary.simpleMessage("Bind"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("Blacklist mode"),
    "blockConnection": MessageLookupByLibrary.simpleMessage("Block connection"),
    "brightness": MessageLookupByLibrary.simpleMessage("Brightness"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("Bypass domains"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Bypass domains apply only while the system proxy is on.",
    ),
    "bypassPrivateRoute": MessageLookupByLibrary.simpleMessage(
      "Bypass private addresses",
    ),
    "bypassPrivateRouteDesc": MessageLookupByLibrary.simpleMessage(
      "With Bypass private addresses on, LAN, loopback and multicast addresses skip TUN.",
    ),
    "cache": MessageLookupByLibrary.simpleMessage("Cache"),
    "cacheAlgorithm": MessageLookupByLibrary.simpleMessage("Cache algorithm"),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "The cache is corrupted. Clear it?",
    ),
    "cacheMaxSize": MessageLookupByLibrary.simpleMessage("Cache size"),
    "cameraPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Allow camera access in system settings to scan QR codes, or choose a QR code image from the album.",
    ),
    "cameraPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Camera permission required",
    ),
    "cameraUnavailable": MessageLookupByLibrary.simpleMessage(
      "Camera unavailable",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("Deselect all"),
    "cannotSave": MessageLookupByLibrary.simpleMessage("Can\'t save"),
    "capsule": MessageLookupByLibrary.simpleMessage("Capsule"),
    "changeProxyFailedTip": MessageLookupByLibrary.simpleMessage(
      "Failed to switch proxy; the previous selection has been restored",
    ),
    "changelogBreaking": MessageLookupByLibrary.simpleMessage(
      "Breaking changes",
    ),
    "changelogFeatures": MessageLookupByLibrary.simpleMessage("New features"),
    "changelogFixes": MessageLookupByLibrary.simpleMessage("Bug fixes"),
    "changelogPerformance": MessageLookupByLibrary.simpleMessage("Performance"),
    "changelogReverts": MessageLookupByLibrary.simpleMessage("Reverts"),
    "checkCertificate": MessageLookupByLibrary.simpleMessage(
      "Verify TLS certificates",
    ),
    "checkCertificateDesc": MessageLookupByLibrary.simpleMessage(
      "With TLS verification off, subscriptions and backups are open to man-in-the-middle attacks.",
    ),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("Check for updates"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "The app is already up to date",
    ),
    "cipher": MessageLookupByLibrary.simpleMessage("Cipher"),
    "clearCache": MessageLookupByLibrary.simpleMessage("Clear cache"),
    "clearData": MessageLookupByLibrary.simpleMessage("Clear data"),
    "clearDataAndExitTip": MessageLookupByLibrary.simpleMessage(
      "This deletes all profiles, settings, and local data, then closes the app. Open it again to start fresh.",
    ),
    "clearDataFailed": m4,
    "clearDnsCache": MessageLookupByLibrary.simpleMessage("Clear DNS cache"),
    "clearDnsCacheFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to clear DNS cache",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clientFingerprint": MessageLookupByLibrary.simpleMessage(
      "Client fingerprint",
    ),
    "clipboardExport": MessageLookupByLibrary.simpleMessage(
      "Export to clipboard",
    ),
    "clipboardImport": MessageLookupByLibrary.simpleMessage(
      "Import from clipboard",
    ),
    "clipboardWriteFailed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t copy to the clipboard. The selection may be too large",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "closeConnections": MessageLookupByLibrary.simpleMessage(
      "Close connections",
    ),
    "color": MessageLookupByLibrary.simpleMessage("Color"),
    "colorStyle": MessageLookupByLibrary.simpleMessage("Color style"),
    "colorsSection": MessageLookupByLibrary.simpleMessage("Colors"),
    "columns": MessageLookupByLibrary.simpleMessage("Columns"),
    "compact": MessageLookupByLibrary.simpleMessage("Compact"),
    "compatible": MessageLookupByLibrary.simpleMessage("Compatibility mode"),
    "configuration": MessageLookupByLibrary.simpleMessage("Configuration"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear all data?",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this proxy group?",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to exit the current window?",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to force crash the core?",
    ),
    "congestionControl": MessageLookupByLibrary.simpleMessage(
      "Congestion control",
    ),
    "congestionController": MessageLookupByLibrary.simpleMessage(
      "TCP congestion control",
    ),
    "congestionControllerDesc": MessageLookupByLibrary.simpleMessage(
      "TCP congestion control works only with the mips stack.",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("Connected"),
    "connecting": MessageLookupByLibrary.simpleMessage("Connecting…"),
    "connection": MessageLookupByLibrary.simpleMessage("Connection"),
    "connectionCount": m5,
    "connectionStats": MessageLookupByLibrary.simpleMessage("Connection stats"),
    "connectionStatsDesc": MessageLookupByLibrary.simpleMessage(
      "Live connections, recent requests and DNS queries",
    ),
    "connections": MessageLookupByLibrary.simpleMessage("Connections"),
    "connectivity": MessageLookupByLibrary.simpleMessage("Connectivity: "),
    "content": MessageLookupByLibrary.simpleMessage("Content"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Content cannot be empty",
    ),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "Control global added rules",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage(
      "Copy environment variables",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Copy link"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("Copied successfully"),
    "core": MessageLookupByLibrary.simpleMessage("Core"),
    "coreBlockedByPolicyTip": m6,
    "coreBlockedBySmartAppControlTip": MessageLookupByLibrary.simpleMessage(
      "Windows Smart App Control blocked SkywardCore.exe because it is not signed. Open Windows Security → App & browser control → Smart App Control settings, choose Off, then start Skyward again. Smart App Control cannot be turned back on without reinstalling Windows.",
    ),
    "coreStatus": MessageLookupByLibrary.simpleMessage("Core status"),
    "coreVersion": MessageLookupByLibrary.simpleMessage("Core version"),
    "country": MessageLookupByLibrary.simpleMessage("Region"),
    "crashDetected": MessageLookupByLibrary.simpleMessage("Crash detected"),
    "crashDetectedTip": m7,
    "crashTest": MessageLookupByLibrary.simpleMessage("Crash test"),
    "create": MessageLookupByLibrary.simpleMessage("Create"),
    "createProfileFromUrlTip": m8,
    "creationTime": MessageLookupByLibrary.simpleMessage("Creation time"),
    "currentOutboundDesc": MessageLookupByLibrary.simpleMessage(
      "Holds the start button and can\'t be removed",
    ),
    "currentVersion": MessageLookupByLibrary.simpleMessage("Current version"),
    "custom": MessageLookupByLibrary.simpleMessage("Custom"),
    "customColor": MessageLookupByLibrary.simpleMessage("Custom color"),
    "customImportDroppedSubRules": m9,
    "customIssueCoreRejected": m10,
    "customIssueDialerLoop": m11,
    "customIssueDuplicateName": m12,
    "customIssueEmptyName": MessageLookupByLibrary.simpleMessage(
      "The name is empty",
    ),
    "customIssueGroupLoop": m13,
    "customIssueInvalidEmptyFallback": m14,
    "customIssueInvalidFilter": m15,
    "customIssueMissingDialer": m16,
    "customIssueMissingProviders": m17,
    "customIssueMissingProxies": m18,
    "customIssueNoProxySource": MessageLookupByLibrary.simpleMessage(
      "No proxies or proxy providers are selected, so the core rejects this group",
    ),
    "customIssueReservedName": m19,
    "customIssuesSummary": m20,
    "customProfile": MessageLookupByLibrary.simpleMessage("Custom"),
    "customProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Assemble proxy groups and rules from app proxies and other profiles",
    ),
    "customProfileResources": MessageLookupByLibrary.simpleMessage(
      "Custom profile resources",
    ),
    "customProfileResourcesDesc": MessageLookupByLibrary.simpleMessage(
      "Custom profile resources are the proxies, rule providers, filters, and icon sets you add yourself for custom profiles to use.",
    ),
    "cut": MessageLookupByLibrary.simpleMessage("Cut"),
    "dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "dashboardAddableSection": MessageLookupByLibrary.simpleMessage(
      "Available to add",
    ),
    "dashboardSplitStack": MessageLookupByLibrary.simpleMessage("Split stack"),
    "data": MessageLookupByLibrary.simpleMessage("Data"),
    "database": MessageLookupByLibrary.simpleMessage("Database"),
    "databaseWriteFailedTip": MessageLookupByLibrary.simpleMessage(
      "Failed to save the change; it has been rolled back",
    ),
    "day": MessageLookupByLibrary.simpleMessage("Day"),
    "daysAgo": m21,
    "daysAgoShort": m22,
    "defaultSelected": MessageLookupByLibrary.simpleMessage(
      "Default selection",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("Default"),
    "definitionNotMap": MessageLookupByLibrary.simpleMessage(
      "The configuration must be a YAML mapping with a name and a type",
    ),
    "delay": MessageLookupByLibrary.simpleMessage("Delay"),
    "delayFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "delayTest": MessageLookupByLibrary.simpleMessage("Delay test"),
    "delayTestTimeout": MessageLookupByLibrary.simpleMessage(
      "Delay test timeout",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteMultipTip": m23,
    "deleteTip": m24,
    "desc": MessageLookupByLibrary.simpleMessage(
      "A multi-platform proxy client based on ClashMeta, simple and easy to use, open-source and ad-free.",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("Destination"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage(
      "Destination GeoIP",
    ),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage(
      "Destination IP ASN",
    ),
    "details": m25,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "Relies on a third-party API; for reference only",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("Developer mode"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "Developer mode is enabled.",
    ),
    "diagnostics": MessageLookupByLibrary.simpleMessage("Diagnostics"),
    "dialerProxy": MessageLookupByLibrary.simpleMessage("Dialer proxy"),
    "dialerProxyDesc": MessageLookupByLibrary.simpleMessage(
      "Dialer proxy is the outbound used to reach the NTP server.",
    ),
    "dialerProxyLoopStopped": m26,
    "direct": MessageLookupByLibrary.simpleMessage("Direct"),
    "directShare": m27,
    "disableIcmpForwarding": MessageLookupByLibrary.simpleMessage(
      "Disable ICMP forwarding",
    ),
    "disableIcmpForwardingDesc": MessageLookupByLibrary.simpleMessage(
      "With ICMP forwarding disabled, TUN answers ping itself, so ping no longer shows the real latency.",
    ),
    "disableKeepAlive": MessageLookupByLibrary.simpleMessage(
      "Disable TCP keep-alive",
    ),
    "disableUDP": MessageLookupByLibrary.simpleMessage("Disable UDP"),
    "disabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "discardChanges": MessageLookupByLibrary.simpleMessage(
      "Discard the changes?",
    ),
    "disclaimer": MessageLookupByLibrary.simpleMessage("Disclaimer"),
    "disclaimerAcceptContent": MessageLookupByLibrary.simpleMessage(
      "By installing, copying, or using the Software, you are deemed to have read and agreed to this entire statement. If you disagree with any of its terms, stop using and uninstall the Software immediately.",
    ),
    "disclaimerAcceptTitle": MessageLookupByLibrary.simpleMessage("Acceptance"),
    "disclaimerAcknowledgeLabel": MessageLookupByLibrary.simpleMessage(
      "I have read and understand this statement",
    ),
    "disclaimerAcknowledgeTip": MessageLookupByLibrary.simpleMessage(
      "To confirm you understand, read the following statement and check the box below:",
    ),
    "disclaimerAcknowledgeTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm the statement",
    ),
    "disclaimerChangesContent": MessageLookupByLibrary.simpleMessage(
      "The developers may revise this statement with any release, and the revision takes effect when that release is published. Continuing to use the Software after updating means you accept the revised statement.",
    ),
    "disclaimerChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Changes to this statement",
    ),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "Before using Skyward (\"the Software\"), please read this statement carefully and make sure you understand all of it. Tapping \"Agree\" means you have read, understood, and accept every term below. If you do not agree, tap \"Exit\" and stop using the Software.",
    ),
    "disclaimerLiabilityContent": MessageLookupByLibrary.simpleMessage(
      "To the maximum extent permitted by applicable law, neither the developers nor any contributor shall be liable for any direct, indirect, incidental, special, punitive, or consequential damages arising from the use of or inability to use the Software, including but not limited to data loss, device damage, network failures, business interruption, lost profits, or any resulting legal dispute, even if advised of the possibility of such damages.",
    ),
    "disclaimerLiabilityTitle": MessageLookupByLibrary.simpleMessage(
      "Limitation of liability",
    ),
    "disclaimerLicenseContent": MessageLookupByLibrary.simpleMessage(
      "The Software is open source under the GPL-3.0 license. You may use, modify, and distribute it freely as long as you comply with that license, which requires derivative works to be released under GPL-3.0 as well and the original copyright notices to be kept.\n\nThird-party components in the Software, including the Clash.Meta core, follow their own licenses. The original authors are not responsible for any issue arising from modified or redistributed versions.",
    ),
    "disclaimerLicenseTitle": MessageLookupByLibrary.simpleMessage(
      "Open-source license",
    ),
    "disclaimerNoServiceStatement": MessageLookupByLibrary.simpleMessage(
      "The Software itself does not provide any proxy server, node, subscription, or network access service, and has no partnership, agency, or guarantee relationship with any provider of such services.",
    ),
    "disclaimerPrivacyContent": MessageLookupByLibrary.simpleMessage(
      "The Software does not collect or upload your subscription URLs, node details, configuration content, visited websites, connection records, traffic content, or logs. This data stays on your device and the developers have no access to it.\n\nThe Software only reaches the network when you use a feature that needs it, such as fetching the subscription URL you provided when updating a profile, or contacting GitHub when checking for updates.\n\nThe Software includes no analytics or crash reporting service on any platform.",
    ),
    "disclaimerPrivacyTitle": MessageLookupByLibrary.simpleMessage(
      "Data collection and privacy",
    ),
    "disclaimerResponsibilityContent": MessageLookupByLibrary.simpleMessage(
      "You are responsible for making sure that using the Software is lawful where you live, and you alone bear the legal responsibility for everything you do with it and its consequences.\n\nThe subscriptions, nodes, and configurations you import are your own choice. Whether their source is lawful, their content is safe, and their service is reliable is a matter between you and their providers.",
    ),
    "disclaimerResponsibilityTitle": MessageLookupByLibrary.simpleMessage(
      "Your responsibility",
    ),
    "disclaimerRestateHint": MessageLookupByLibrary.simpleMessage(
      "Enter the statement above",
    ),
    "disclaimerRestateMismatch": MessageLookupByLibrary.simpleMessage(
      "Does not match the statement",
    ),
    "disclaimerRestateTip": MessageLookupByLibrary.simpleMessage(
      "To confirm you understand, enter the following statement in full in the field below:",
    ),
    "disclaimerRestateTitle": MessageLookupByLibrary.simpleMessage(
      "Restate the statement",
    ),
    "disclaimerSoftwareContent": MessageLookupByLibrary.simpleMessage(
      "The Software is an open-source network proxy client built on the Clash.Meta (mihomo) core. It only provides local tooling such as configuration management, rule-based routing, and traffic forwarding.",
    ),
    "disclaimerSoftwareTitle": MessageLookupByLibrary.simpleMessage(
      "Nature of the software",
    ),
    "disclaimerThirdPartyContent": MessageLookupByLibrary.simpleMessage(
      "Subscription links, configuration files, rule sets, scripts, external resources, and external links are all provided by third parties. The developers cannot and do not review or guarantee their legality, accuracy, security, or availability.\n\nAny data leak, financial loss, account ban, or other loss caused by third-party content is to be settled between you and the third party; the developers bear no responsibility for it.",
    ),
    "disclaimerThirdPartyTitle": MessageLookupByLibrary.simpleMessage(
      "Third-party content",
    ),
    "disclaimerUsageContent": MessageLookupByLibrary.simpleMessage(
      "The Software is intended only for non-commercial uses such as learning, exchange, and technical research. Using it for any commercial purpose is strictly prohibited, including but not limited to paid distribution, bundled sales, use as part of a commercial service, or doing business in the name of the Software. Any commercial activity is unrelated to the Software and its developers.\n\nUsing the Software for anything that violates the laws and regulations of your country or region is strictly prohibited, including but not limited to bypassing lawfully imposed network access restrictions, spreading illegal content, launching network attacks, or infringing the lawful rights of others.",
    ),
    "disclaimerUsageTitle": MessageLookupByLibrary.simpleMessage(
      "Restrictions on use",
    ),
    "disclaimerWarrantyContent": MessageLookupByLibrary.simpleMessage(
      "The Software is provided \"as is\" and \"as available\", without warranty of any kind, express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, non-infringement, uninterrupted availability, freedom from errors, or freedom from security vulnerabilities.\n\nThe developers do not guarantee that the Software will meet your needs or that it will run without interruption or error.",
    ),
    "disclaimerWarrantyTitle": MessageLookupByLibrary.simpleMessage(
      "No warranty",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("Disconnected"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "New version found",
    ),
    "dnsCacheCleared": MessageLookupByLibrary.simpleMessage(
      "DNS cache cleared",
    ),
    "dnsHijackDesc": MessageLookupByLibrary.simpleMessage(
      "Without this entry, TUN hijacks every DNS query to port 53 (any:53).",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNS hijacking"),
    "dnsLeakAdvice": MessageLookupByLibrary.simpleMessage(
      "For anything that failed, open VPN and DNS hijacking in Advanced > Network, turn off Private DNS in the system settings, and replace plain upstreams with DoH under DNS overrides.",
    ),
    "dnsLeakCheck": MessageLookupByLibrary.simpleMessage("DNS leak check"),
    "dnsLeakDirect": MessageLookupByLibrary.simpleMessage("Port 53 leak"),
    "dnsLeakDirectBad": MessageLookupByLibrary.simpleMessage(
      "A direct query to 223.5.5.5 returned a real address, so plain DNS still leaves the device",
    ),
    "dnsLeakEncrypted": MessageLookupByLibrary.simpleMessage(
      "Encrypted resolution",
    ),
    "dnsLeakEncryptedBad": MessageLookupByLibrary.simpleMessage(
      "The upstream is plain DNS, so every query is readable on the way out",
    ),
    "dnsLeakExternal": MessageLookupByLibrary.simpleMessage(
      "Verify in a browser",
    ),
    "dnsLeakFail": MessageLookupByLibrary.simpleMessage("Fail"),
    "dnsLeakFakeIp": MessageLookupByLibrary.simpleMessage("Fake address"),
    "dnsLeakFakeIpBad": MessageLookupByLibrary.simpleMessage(
      "The answer is not 198.18.x.x, so fake-IP did not answer this query",
    ),
    "dnsLeakHijack": MessageLookupByLibrary.simpleMessage("DNS hijack"),
    "dnsLeakHijackBad": MessageLookupByLibrary.simpleMessage(
      "any:53 is not set, so queries to other resolvers are not captured",
    ),
    "dnsLeakIpv6": MessageLookupByLibrary.simpleMessage("IPv6"),
    "dnsLeakIpv6Bad": MessageLookupByLibrary.simpleMessage(
      "This device holds a global IPv6 address, and v6 traffic can bypass an IPv4-only capture",
    ),
    "dnsLeakPass": MessageLookupByLibrary.simpleMessage("Pass"),
    "dnsLeakRerun": MessageLookupByLibrary.simpleMessage("Check again"),
    "dnsLeakRunning": MessageLookupByLibrary.simpleMessage("Checking"),
    "dnsLeakTunnel": MessageLookupByLibrary.simpleMessage("Traffic capture"),
    "dnsLeakTunnelBad": MessageLookupByLibrary.simpleMessage(
      "The core is stopped or the VPN is off, so apps resolve names themselves",
    ),
    "dnsLeakUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "dnsLeakWarn": MessageLookupByLibrary.simpleMessage("Warn"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNS mode"),
    "dnsOverride": MessageLookupByLibrary.simpleMessage("DNS override"),
    "dnsOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Entries added here replace the DNS of every URL and file profile; anything not added keeps the profile\'s own setting. Custom profiles set their DNS in their content.",
    ),
    "dnsPolicyReplaced": MessageLookupByLibrary.simpleMessage(
      "This profile lists DNS policies of its own; the entries here replace them whole, so every rule they carried that is not set here stops applying.",
    ),
    "dnsQueries": MessageLookupByLibrary.simpleMessage("DNS queries"),
    "dockScale": MessageLookupByLibrary.simpleMessage("Dock size"),
    "docked": MessageLookupByLibrary.simpleMessage("Docked"),
    "domain": MessageLookupByLibrary.simpleMessage("Domain"),
    "done": MessageLookupByLibrary.simpleMessage("Done"),
    "download": MessageLookupByLibrary.simpleMessage("Download"),
    "downloadBandwidth": MessageLookupByLibrary.simpleMessage(
      "Download bandwidth",
    ),
    "duration": MessageLookupByLibrary.simpleMessage("Duration"),
    "durationDays": m28,
    "durationHours": m29,
    "durationMinutes": m30,
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editDashboard": MessageLookupByLibrary.simpleMessage("Edit dashboard"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage(
      "Edit global rules",
    ),
    "editProxy": MessageLookupByLibrary.simpleMessage("Edit proxy"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("Edit proxy group"),
    "editRule": MessageLookupByLibrary.simpleMessage("Edit rule"),
    "editSsid": MessageLookupByLibrary.simpleMessage("Edit SSID"),
    "editorUnavailable": MessageLookupByLibrary.simpleMessage(
      "Editor unavailable",
    ),
    "elapsed": MessageLookupByLibrary.simpleMessage("Took"),
    "emptyFallback": MessageLookupByLibrary.simpleMessage("Empty fallback"),
    "emptyTip": m31,
    "en": MessageLookupByLibrary.simpleMessage("English"),
    "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "entries": MessageLookupByLibrary.simpleMessage(" entries"),
    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "errorDetails": MessageLookupByLibrary.simpleMessage("Error details"),
    "es": MessageLookupByLibrary.simpleMessage("Spanish"),
    "exclude": MessageLookupByLibrary.simpleMessage("Hide from recent tasks"),
    "excludeDstPort": MessageLookupByLibrary.simpleMessage(
      "Excluded destination ports",
    ),
    "excludeDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "Traffic to excluded destination ports skips TUN.",
    ),
    "excludeFilter": MessageLookupByLibrary.simpleMessage("Exclude filter"),
    "excludeInterface": MessageLookupByLibrary.simpleMessage(
      "Excluded interfaces",
    ),
    "excludeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "Traffic arriving on excluded interfaces, such as docker0, skips TUN.",
    ),
    "excludeSrcPort": MessageLookupByLibrary.simpleMessage(
      "Excluded source ports",
    ),
    "excludeSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "Traffic from excluded source ports skips TUN.",
    ),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Exclude SSIDs"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "When connected to Wi-Fi with an excluded SSID, the app\'s running state switches automatically.",
    ),
    "excludeUid": MessageLookupByLibrary.simpleMessage("Excluded user IDs"),
    "excludeUidDesc": MessageLookupByLibrary.simpleMessage(
      "Traffic from processes of excluded user IDs skips TUN.",
    ),
    "existsTip": m32,
    "exit": MessageLookupByLibrary.simpleMessage("Exit"),
    "exitFullScreen": MessageLookupByLibrary.simpleMessage("Exit full screen"),
    "exitNodes": MessageLookupByLibrary.simpleMessage("Exit nodes"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("Expected status"),
    "expireTime": MessageLookupByLibrary.simpleMessage("Expiration time"),
    "exportFile": MessageLookupByLibrary.simpleMessage("Export file"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Export logs"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Export successful"),
    "extend": MessageLookupByLibrary.simpleMessage("Extend"),
    "extendMode": MessageLookupByLibrary.simpleMessage("Extend mode"),
    "extendScript": MessageLookupByLibrary.simpleMessage("Extend script"),
    "externalController": MessageLookupByLibrary.simpleMessage(
      "External controller",
    ),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "The external controller lets you control the core on port 9090.",
    ),
    "externalControllerSecret": MessageLookupByLibrary.simpleMessage(
      "External controller secret",
    ),
    "externalLink": MessageLookupByLibrary.simpleMessage("External link"),
    "extraLarge": MessageLookupByLibrary.simpleMessage("Extra large"),
    "fade": MessageLookupByLibrary.simpleMessage("Fade"),
    "failedCount": m33,
    "failedItem": m34,
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fake-IP filter"),
    "fakeipFilterMode": MessageLookupByLibrary.simpleMessage(
      "Fake-IP filter mode",
    ),
    "fakeipFilterModeDesc": MessageLookupByLibrary.simpleMessage(
      "In Fake-IP filter mode, blacklist excludes matches, whitelist fakes only matches, and rule matches as rules.",
    ),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fake-IP range"),
    "fakeipRange6": MessageLookupByLibrary.simpleMessage(
      "Fake-IP range (IPv6)",
    ),
    "fakeipTtl": MessageLookupByLibrary.simpleMessage("Fake-IP TTL"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("Fallback filter"),
    "file": MessageLookupByLibrary.simpleMessage("File"),
    "fileDesc": MessageLookupByLibrary.simpleMessage(
      "Upload a profile file directly",
    ),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "The file has been modified. Save the changes?",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "filters": MessageLookupByLibrary.simpleMessage("Filters"),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("Find process"),
    "floating": MessageLookupByLibrary.simpleMessage("Floating"),
    "followProfile": MessageLookupByLibrary.simpleMessage("Follow profile"),
    "followSystem": MessageLookupByLibrary.simpleMessage("Follow system"),
    "fontFamily": MessageLookupByLibrary.simpleMessage("Font family"),
    "fontSize": MessageLookupByLibrary.simpleMessage("Size"),
    "forceDnsMapping": MessageLookupByLibrary.simpleMessage(
      "Force DNS mapping",
    ),
    "forceDnsMappingDesc": MessageLookupByLibrary.simpleMessage(
      "Force DNS mapping also sniffs connections whose domain came from a DNS mapping.",
    ),
    "forceDomain": MessageLookupByLibrary.simpleMessage("Force domains"),
    "forceDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Force domains are sniffed too; other connections that already have a domain are left alone.",
    ),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to force restart the core?",
    ),
    "fr": MessageLookupByLibrary.simpleMessage("French"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geo"),
    "geoSkipped": m35,
    "geoUpdated": m36,
    "geodataLoader": MessageLookupByLibrary.simpleMessage(
      "Geo low-memory mode",
    ),
    "global": MessageLookupByLibrary.simpleMessage("Global"),
    "go": MessageLookupByLibrary.simpleMessage("Go"),
    "goDownload": MessageLookupByLibrary.simpleMessage("Download"),
    "goToConfigureAddedRules": MessageLookupByLibrary.simpleMessage(
      "Go to added rules configuration",
    ),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage(
      "Go to script configuration",
    ),
    "grid": MessageLookupByLibrary.simpleMessage("Grid"),
    "groupCount": m37,
    "groupCountUnit": MessageLookupByLibrary.simpleMessage("groups"),
    "groupTimeoutCount": m38,
    "hapticFeedback": MessageLookupByLibrary.simpleMessage("Haptic feedback"),
    "hapticFeedbackDesc": MessageLookupByLibrary.simpleMessage(
      "A light vibration on taps across the app.",
    ),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage(
      "Cache the changes?",
    ),
    "hashByInUser": MessageLookupByLibrary.simpleMessage(
      "Hash by inbound user",
    ),
    "healthCheck": MessageLookupByLibrary.simpleMessage("Health check"),
    "helperCorruptTip": MessageLookupByLibrary.simpleMessage(
      "Helper service unavailable; TUN mode cannot be enabled. Reinstall Skyward to restore it.",
    ),
    "hex": MessageLookupByLibrary.simpleMessage("Hex"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("Hide from list"),
    "hideIp": MessageLookupByLibrary.simpleMessage("Hide IP"),
    "hideLabelOnScroll": MessageLookupByLibrary.simpleMessage(
      "Hide labels while scrolling",
    ),
    "hideLabelOnScrollDesc": MessageLookupByLibrary.simpleMessage(
      "The dock keeps its icons while the page moves",
    ),
    "hideNotification": MessageLookupByLibrary.simpleMessage(
      "Hide the ongoing notification",
    ),
    "hideNotificationTip": MessageLookupByLibrary.simpleMessage(
      "The proxy keeps running. Android requires a foreground service to post one, so this makes it silent and keeps it off the lock screen; system settings can turn it off entirely",
    ),
    "hidePassword": MessageLookupByLibrary.simpleMessage("Hide password"),
    "hideTimeoutProxies": MessageLookupByLibrary.simpleMessage(
      "Hide timed-out proxies",
    ),
    "hitsUnit": MessageLookupByLibrary.simpleMessage("hits"),
    "hopInterval": MessageLookupByLibrary.simpleMessage("Hop interval"),
    "host": MessageLookupByLibrary.simpleMessage("Host"),
    "hostname": MessageLookupByLibrary.simpleMessage("Hostname"),
    "hotkeyConflictWith": m39,
    "hotkeyDesc": MessageLookupByLibrary.simpleMessage(
      "Global hotkeys work even while the window is hidden. Tap an action to record its key combination.",
    ),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage(
      "Hotkey management",
    ),
    "hotkeyNeedsModifier": m40,
    "hotkeyNotSet": MessageLookupByLibrary.simpleMessage("Not set"),
    "hotkeyUnavailable": MessageLookupByLibrary.simpleMessage(
      "Not registered, it may be taken by another app",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("hours"),
    "hoursAgo": m41,
    "hoursAgoShort": m42,
    "hue": MessageLookupByLibrary.simpleMessage("Hue"),
    "icon": MessageLookupByLibrary.simpleMessage("Icon"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("Icon records"),
    "iconSets": MessageLookupByLibrary.simpleMessage("Icon sets"),
    "iconSetsEmptyTip": MessageLookupByLibrary.simpleMessage(
      "No icon sets yet. Add them in Custom profile resources → Icon sets",
    ),
    "iconStyle": MessageLookupByLibrary.simpleMessage("Icon style"),
    "iconStyleFilled": MessageLookupByLibrary.simpleMessage("Filled"),
    "iconStyleHidden": MessageLookupByLibrary.simpleMessage("Hidden"),
    "iconStylePlain": MessageLookupByLibrary.simpleMessage("Plain"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("Icon URL"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Ignore battery optimization",
    ),
    "import": MessageLookupByLibrary.simpleMessage("Import"),
    "importConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "This file is not a config that can be imported",
    ),
    "importConfigReplaceTip": MessageLookupByLibrary.simpleMessage(
      "Importing replaces the proxy groups, rules and settings this profile has now",
    ),
    "importFile": MessageLookupByLibrary.simpleMessage("Import from file"),
    "importFromLink": MessageLookupByLibrary.simpleMessage("Import from link"),
    "importUrl": MessageLookupByLibrary.simpleMessage("Import from URL"),
    "inbound": MessageLookupByLibrary.simpleMessage("Inbound"),
    "includeInterface": MessageLookupByLibrary.simpleMessage(
      "Included interfaces",
    ),
    "includeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "Only traffic arriving on included interfaces goes through TUN, and excluded interfaces no longer apply.",
    ),
    "includeUid": MessageLookupByLibrary.simpleMessage("Included user IDs"),
    "includeUidDesc": MessageLookupByLibrary.simpleMessage(
      "Only traffic from processes of included user IDs goes through TUN.",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("Never expires"),
    "init": MessageLookupByLibrary.simpleMessage("Init"),
    "initFailed": MessageLookupByLibrary.simpleMessage("Startup failed"),
    "initFailedTip": MessageLookupByLibrary.simpleMessage(
      "Skyward ran into an error while starting and can\'t continue. Copy the details to report the problem. If it keeps happening, clearing the data usually lets the app start again.",
    ),
    "initiator": MessageLookupByLibrary.simpleMessage("Initiator"),
    "initiatorShort": MessageLookupByLibrary.simpleMessage("From"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage(
      "Enter the proxy group name",
    ),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage(
      "Enter the rule content",
    ),
    "installedAppsPermissionDeniedMessage":
        MessageLookupByLibrary.simpleMessage(
          "The app list permission was denied, so installed apps cannot be listed. Please grant it manually in system settings.",
        ),
    "installedAppsPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "This system hides the installed app list until the permission is granted. Authorize it to configure the per-app proxy.",
    ),
    "installedAppsPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "App list permission required",
    ),
    "installedFonts": MessageLookupByLibrary.simpleMessage("Installed fonts"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage(
      "Smart selection",
    ),
    "interfaceName": MessageLookupByLibrary.simpleMessage("Interface name"),
    "interfaceNameDesc": MessageLookupByLibrary.simpleMessage(
      "Interface name is the network interface outbound connections use.",
    ),
    "interfaceNameMode": MessageLookupByLibrary.simpleMessage(
      "Outbound interface",
    ),
    "interfaceNameModeClear": MessageLookupByLibrary.simpleMessage("Clear"),
    "interfaceNameModeCustom": MessageLookupByLibrary.simpleMessage("Custom"),
    "interfaceNameModeFollow": MessageLookupByLibrary.simpleMessage(
      "Follow config",
    ),
    "internet": MessageLookupByLibrary.simpleMessage("Internet"),
    "interval": MessageLookupByLibrary.simpleMessage("Interval"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("Intranet IP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage(
      "Invalid backup file",
    ),
    "invalidCidrContent": MessageLookupByLibrary.simpleMessage(
      "Enter an IP range in CIDR form such as 192.168.0.0/16",
    ),
    "invalidDscpContent": MessageLookupByLibrary.simpleMessage(
      "A DSCP mark cannot exceed 63",
    ),
    "invalidHostContent": MessageLookupByLibrary.simpleMessage(
      "Enter a domain or an IP address",
    ),
    "invalidIconSet": MessageLookupByLibrary.simpleMessage(
      "Not a valid icon set",
    ),
    "invalidLinkTip": MessageLookupByLibrary.simpleMessage(
      "Not a subscription link or a proxy share link",
    ),
    "invalidListenContent": MessageLookupByLibrary.simpleMessage(
      "Enter an address and port such as 0.0.0.0:1053",
    ),
    "invalidNetworkContent": MessageLookupByLibrary.simpleMessage(
      "Only tcp or udp is supported",
    ),
    "invalidPolicy": m43,
    "invalidPortRangeContent": MessageLookupByLibrary.simpleMessage(
      "Enter a port or a range such as 443 or 8000-9000",
    ),
    "invalidProfileQrcode": MessageLookupByLibrary.simpleMessage(
      "This QR code doesn\'t contain a profile link",
    ),
    "invalidProxy": m44,
    "invalidProxyProvider": m45,
    "invalidRangeContent": MessageLookupByLibrary.simpleMessage(
      "Enter numbers or ranges such as 80 or 8000-9000, separated by /",
    ),
    "invalidRuleSet": m46,
    "invalidSubRule": m47,
    "ipAddress": MessageLookupByLibrary.simpleMessage("IP address"),
    "ipAsn": MessageLookupByLibrary.simpleMessage("ASN"),
    "ipFlagAbuser": MessageLookupByLibrary.simpleMessage("Abuse history"),
    "ipFlagProxy": MessageLookupByLibrary.simpleMessage("Proxy"),
    "ipFlagTor": MessageLookupByLibrary.simpleMessage("Tor"),
    "ipFlagVpn": MessageLookupByLibrary.simpleMessage("VPN"),
    "ipFlags": MessageLookupByLibrary.simpleMessage("Flags"),
    "ipOrganization": MessageLookupByLibrary.simpleMessage("Organization"),
    "ipQualityFailed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t determine the IP type",
    ),
    "ipQualityGood": MessageLookupByLibrary.simpleMessage("Good"),
    "ipQualityLevel": MessageLookupByLibrary.simpleMessage("Level"),
    "ipQualityNormal": MessageLookupByLibrary.simpleMessage("Normal"),
    "ipQualityRetry": MessageLookupByLibrary.simpleMessage("Check again"),
    "ipQualityRisky": MessageLookupByLibrary.simpleMessage("Risky"),
    "ipQualityShort": MessageLookupByLibrary.simpleMessage("Quality"),
    "ipQualitySource": MessageLookupByLibrary.simpleMessage("Answered by"),
    "ipQualitySources": MessageLookupByLibrary.simpleMessage("Sources"),
    "ipSourceIpMismatch": MessageLookupByLibrary.simpleMessage(
      "Different outbound IP",
    ),
    "ipSourceNoType": MessageLookupByLibrary.simpleMessage("No type"),
    "ipSourceRateLimited": MessageLookupByLibrary.simpleMessage("Rate limited"),
    "ipType": MessageLookupByLibrary.simpleMessage("Type"),
    "ipTypeBusiness": MessageLookupByLibrary.simpleMessage("Business"),
    "ipTypeHosting": MessageLookupByLibrary.simpleMessage("Data center"),
    "ipTypeMobile": MessageLookupByLibrary.simpleMessage("Mobile network"),
    "ipTypeResidential": MessageLookupByLibrary.simpleMessage("Residential"),
    "ipTypeUnknown": MessageLookupByLibrary.simpleMessage("Unknown type"),
    "ipVersion": MessageLookupByLibrary.simpleMessage("IP version"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "IPv6 traffic is received only while IPv6 is on.",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage(
      "With IPv6 on, the VPN allows IPv6 inbound.",
    ),
    "ipv6Timeout": MessageLookupByLibrary.simpleMessage("IPv6 timeout (ms)"),
    "itemsCount": m48,
    "ja": MessageLookupByLibrary.simpleMessage("Japanese"),
    "justNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "keepAliveIdle": MessageLookupByLibrary.simpleMessage(
      "TCP keep-alive idle",
    ),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "TCP keep-alive interval",
    ),
    "key": MessageLookupByLibrary.simpleMessage("Key"),
    "ko": MessageLookupByLibrary.simpleMessage("Korean"),
    "label": MessageLookupByLibrary.simpleMessage("Label"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "large": MessageLookupByLibrary.simpleMessage("Large"),
    "last7Days": MessageLookupByLibrary.simpleMessage("Last 7 days"),
    "lastUpdated": MessageLookupByLibrary.simpleMessage("Last updated"),
    "launchInterrupted": MessageLookupByLibrary.simpleMessage(
      "Launch did not finish",
    ),
    "launchInterruptedTip": MessageLookupByLibrary.simpleMessage(
      "The app exited unexpectedly while it was starting up last time. Automatic setup was skipped for this launch; you can start it manually to retry.",
    ),
    "layout": MessageLookupByLibrary.simpleMessage("Layout"),
    "leakCheck": MessageLookupByLibrary.simpleMessage("Leak check"),
    "light": MessageLookupByLibrary.simpleMessage("Light"),
    "lineIssueTip": m49,
    "lineWrap": MessageLookupByLibrary.simpleMessage("Word wrap"),
    "link": MessageLookupByLibrary.simpleMessage("Link"),
    "linkDesc": MessageLookupByLibrary.simpleMessage(
      "Obtain a profile from a subscription link or a proxy share link",
    ),
    "liquidGlass": MessageLookupByLibrary.simpleMessage("Liquid Glass"),
    "list": MessageLookupByLibrary.simpleMessage("List"),
    "listen": MessageLookupByLibrary.simpleMessage("Listen"),
    "listenRoutingMark": MessageLookupByLibrary.simpleMessage(
      "Listen routing mark",
    ),
    "listenRoutingMarkDesc": MessageLookupByLibrary.simpleMessage(
      "Listen routing mark works only on Linux.",
    ),
    "liveConnections": MessageLookupByLibrary.simpleMessage("Live connections"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading…"),
    "local": MessageLookupByLibrary.simpleMessage("Local"),
    "localImage": MessageLookupByLibrary.simpleMessage("Local image"),
    "localNetwork": MessageLookupByLibrary.simpleMessage("LAN proxy"),
    "localNetworkDeniedTip": MessageLookupByLibrary.simpleMessage(
      "Local network permission denied: using the gvisor stack, LAN is unreachable.",
    ),
    "localNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "When off, LAN, loopback and multicast addresses bypass the virtual interface.",
    ),
    "localProxies": MessageLookupByLibrary.simpleMessage("Local proxies"),
    "locationPermission": MessageLookupByLibrary.simpleMessage(
      "Location permission",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "Location permission was denied, so the current Wi-Fi name cannot be read. Please enable location permission manually in system settings.",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "The system requires location permission to read the Wi-Fi name. On Android choose \"Allow all the time\", otherwise the Wi-Fi name cannot be read while the app is in the background.",
    ),
    "locationPermissionGuide": m50,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Location permission required",
    ),
    "log": MessageLookupByLibrary.simpleMessage("Log"),
    "logLevel": MessageLookupByLibrary.simpleMessage("Log level"),
    "logcat": MessageLookupByLibrary.simpleMessage("Logcat"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "Turning off Logcat hides the logs entry.",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("Logs"),
    "logsAndDiagnostics": MessageLookupByLibrary.simpleMessage(
      "Logs and diagnostics",
    ),
    "logsTest": MessageLookupByLibrary.simpleMessage("Logs test"),
    "loopback": MessageLookupByLibrary.simpleMessage("UWP loopback exemption"),
    "loose": MessageLookupByLibrary.simpleMessage("Loose"),
    "matchCase": MessageLookupByLibrary.simpleMessage("Match case"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("Match source IP"),
    "matchTarget": MessageLookupByLibrary.simpleMessage("MATCH-TARGET"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("Max failures"),
    "maxLengthTip": m51,
    "maximize": MessageLookupByLibrary.simpleMessage("Maximize"),
    "memoryAppResident": MessageLookupByLibrary.simpleMessage(
      "Resident memory",
    ),
    "memoryAppShared": MessageLookupByLibrary.simpleMessage("App & shared"),
    "memoryCoreBudget": MessageLookupByLibrary.simpleMessage("Core budget"),
    "memoryCoreHeapIdle": MessageLookupByLibrary.simpleMessage("Heap idle"),
    "memoryCoreHeapInuse": MessageLookupByLibrary.simpleMessage("Heap in use"),
    "memoryCoreNotRunning": MessageLookupByLibrary.simpleMessage(
      "Core is not running",
    ),
    "memoryCoreRuntime": MessageLookupByLibrary.simpleMessage(
      "Runtime overhead",
    ),
    "memoryCoreStack": MessageLookupByLibrary.simpleMessage("Goroutine stacks"),
    "memoryEstimateDesc": MessageLookupByLibrary.simpleMessage(
      "Estimated from process resident memory; it may differ from what the system reports.",
    ),
    "memoryEstimateSharedDesc": MessageLookupByLibrary.simpleMessage(
      "The Core runs inside the app process. Its share is estimated from runtime stats, and the rest counts as app and shared memory.",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("Memory info"),
    "memoryInfoDesc": MessageLookupByLibrary.simpleMessage(
      "Memory the app and the core use",
    ),
    "memoryReleased": MessageLookupByLibrary.simpleMessage("Memory released"),
    "memoryReleasedSize": m52,
    "messageTest": MessageLookupByLibrary.simpleMessage("Message test"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage(
      "This is a message.",
    ),
    "mine": MessageLookupByLibrary.simpleMessage("Mine"),
    "minimize": MessageLookupByLibrary.simpleMessage("Minimize"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("Minimize on exit"),
    "minutes": MessageLookupByLibrary.simpleMessage("minutes"),
    "minutesAgo": m53,
    "minutesAgoShort": m54,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Mixed port"),
    "mode": MessageLookupByLibrary.simpleMessage("Mode"),
    "monochromeIcon": MessageLookupByLibrary.simpleMessage("Monochrome icon"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("Monochrome"),
    "month": MessageLookupByLibrary.simpleMessage("Month"),
    "monthsAgo": m55,
    "monthsAgoShort": m56,
    "more": MessageLookupByLibrary.simpleMessage("More"),
    "moreThemeSettings": MessageLookupByLibrary.simpleMessage(
      "More theme settings",
    ),
    "motionSection": MessageLookupByLibrary.simpleMessage("Motion"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "navigationBarStyle": MessageLookupByLibrary.simpleMessage("Bottom bar"),
    "navigationSection": MessageLookupByLibrary.simpleMessage("Navigation"),
    "network": MessageLookupByLibrary.simpleMessage("Network"),
    "networkAccessDeniedError": m57,
    "networkBadResponseError": m58,
    "networkCancelledError": MessageLookupByLibrary.simpleMessage(
      "The request was cancelled",
    ),
    "networkConnectionError": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t connect to the server. Check your network connection or proxy settings",
    ),
    "networkControl": MessageLookupByLibrary.simpleMessage("Network control"),
    "networkHostLookupError": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t resolve the server address. Check that the URL is correct and DNS is working",
    ),
    "networkName": MessageLookupByLibrary.simpleMessage("Network name"),
    "networkNotFoundError": m59,
    "networkOverview": MessageLookupByLibrary.simpleMessage("Network overview"),
    "networkRateLimitedError": MessageLookupByLibrary.simpleMessage(
      "Too many requests (HTTP 429). Wait a moment and try again",
    ),
    "networkRequestFailed": m60,
    "networkSecret": MessageLookupByLibrary.simpleMessage("Network secret"),
    "networkServerError": m61,
    "networkSpeed": MessageLookupByLibrary.simpleMessage("Network speed"),
    "networkTakeover": MessageLookupByLibrary.simpleMessage("Traffic takeover"),
    "networkTimeoutError": MessageLookupByLibrary.simpleMessage(
      "The request timed out. Check your network or proxy, then try again",
    ),
    "networkTlsError": MessageLookupByLibrary.simpleMessage(
      "Secure connection failed. The server\'s certificate may be invalid, or the connection is being intercepted",
    ),
    "networkType": MessageLookupByLibrary.simpleMessage("Network type"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("Next match"),
    "nextPeriod": MessageLookupByLibrary.simpleMessage("Next"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noData": MessageLookupByLibrary.simpleMessage("No data"),
    "noInfo": MessageLookupByLibrary.simpleMessage("No info"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage(
      "Don\'t remind me again",
    ),
    "noNetwork": MessageLookupByLibrary.simpleMessage("No network"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("No-network apps"),
    "noResolve": MessageLookupByLibrary.simpleMessage("Don\'t resolve IP"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage(
      "Don\'t resolve hostname",
    ),
    "noSearchResults": MessageLookupByLibrary.simpleMessage(
      "No matching results",
    ),
    "nodes": MessageLookupByLibrary.simpleMessage("Nodes"),
    "nonTextProviderFile": MessageLookupByLibrary.simpleMessage(
      "This external resource is not a text file",
    ),
    "none": MessageLookupByLibrary.simpleMessage("None"),
    "notRunning": MessageLookupByLibrary.simpleMessage("Not running"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "The current proxy group cannot be selected",
    ),
    "ntpInterval": MessageLookupByLibrary.simpleMessage(
      "Sync interval (minutes)",
    ),
    "ntpStatusDesc": MessageLookupByLibrary.simpleMessage(
      "NTP takes the time from an NTP server instead of the system clock.",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Add a profile to get started",
    ),
    "nullTip": m62,
    "numberRangeTip": m63,
    "numberTip": m64,
    "obfs": MessageLookupByLibrary.simpleMessage("Obfuscation"),
    "obfsHost": MessageLookupByLibrary.simpleMessage("Obfuscation host"),
    "obfsMode": MessageLookupByLibrary.simpleMessage("Obfuscation mode"),
    "obfsParam": MessageLookupByLibrary.simpleMessage("Obfuscation parameter"),
    "obfsPassword": MessageLookupByLibrary.simpleMessage(
      "Obfuscation password",
    ),
    "onDemand": MessageLookupByLibrary.simpleMessage("On demand"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "On demand pauses the proxy on excluded Wi-Fi.",
    ),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "Only count proxy traffic",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("Optional"),
    "options": MessageLookupByLibrary.simpleMessage("Options"),
    "other": MessageLookupByLibrary.simpleMessage("Other"),
    "otherContributors": MessageLookupByLibrary.simpleMessage(
      "Other contributors",
    ),
    "outbound": MessageLookupByLibrary.simpleMessage("Outbound"),
    "outboundExit": MessageLookupByLibrary.simpleMessage("Exit"),
    "outboundIp": MessageLookupByLibrary.simpleMessage("Outbound IP"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("Outbound mode"),
    "overrideDestination": MessageLookupByLibrary.simpleMessage(
      "Override destination",
    ),
    "overrideDestinationDesc": MessageLookupByLibrary.simpleMessage(
      "Override destination connects to the sniffed domain instead of the original address.",
    ),
    "overrideEntries": MessageLookupByLibrary.simpleMessage("Override entries"),
    "pagesLabel": MessageLookupByLibrary.simpleMessage("Pages"),
    "parsePureIp": MessageLookupByLibrary.simpleMessage("Parse pure IP"),
    "parsePureIpDesc": MessageLookupByLibrary.simpleMessage(
      "Parse pure IP sniffs connections that carry only an IP address.",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "paste": MessageLookupByLibrary.simpleMessage("Paste"),
    "pasteDesc": MessageLookupByLibrary.simpleMessage(
      "Paste a subscription link from the clipboard",
    ),
    "peers": MessageLookupByLibrary.simpleMessage("Peers"),
    "perApp": MessageLookupByLibrary.simpleMessage("Per app"),
    "perAppDesc": MessageLookupByLibrary.simpleMessage(
      "Choose which apps use the proxy.",
    ),
    "pickFromAlbum": MessageLookupByLibrary.simpleMessage("Choose from album"),
    "pinWindow": MessageLookupByLibrary.simpleMessage("Pin window"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage(
      "Please bind WebDAV",
    ),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "Please enter a script name",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "Please upload a valid QR code",
    ),
    "plugin": MessageLookupByLibrary.simpleMessage("Plugin"),
    "pluginCipher": MessageLookupByLibrary.simpleMessage("Plugin cipher"),
    "pluginHost": MessageLookupByLibrary.simpleMessage("Plugin host"),
    "pluginMode": MessageLookupByLibrary.simpleMessage("Plugin mode"),
    "pluginPassword": MessageLookupByLibrary.simpleMessage("Plugin password"),
    "pluginPath": MessageLookupByLibrary.simpleMessage("Plugin path"),
    "pluginUsername": MessageLookupByLibrary.simpleMessage("Plugin username"),
    "port": MessageLookupByLibrary.simpleMessage("Port"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage(
      "Please enter a different port",
    ),
    "portHopping": MessageLookupByLibrary.simpleMessage("Port hopping"),
    "portTip": m65,
    "portValue": m66,
    "ports": MessageLookupByLibrary.simpleMessage("Ports"),
    "preSharedKey": MessageLookupByLibrary.simpleMessage("Pre-shared key"),
    "preferences": MessageLookupByLibrary.simpleMessage("Preferences"),
    "preferred": MessageLookupByLibrary.simpleMessage("Preferred"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Prerequisites"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage(
      "Press a key combination",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "previousMatch": MessageLookupByLibrary.simpleMessage("Previous match"),
    "previousPeriod": MessageLookupByLibrary.simpleMessage("Previous"),
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
    "privateKey": MessageLookupByLibrary.simpleMessage("Private key"),
    "privateKeyPassphrase": MessageLookupByLibrary.simpleMessage(
      "Private key passphrase",
    ),
    "process": MessageLookupByLibrary.simpleMessage("Process"),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("Please enter a valid interval"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage(
          "Please enter the auto-update interval",
        ),
    "profileDaysLeft": m67,
    "profileDnsSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Applies to this profile only and takes precedence over the DNS override entries in the network settings.",
    ),
    "profileExpiresIn": m68,
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "The profile has been modified. Turn off auto update?",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter the profile name",
    ),
    "profileSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Applies to this profile only; anything not added uses its default.",
    ),
    "profileTunSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Applies to this profile only and takes precedence over the TUN override entries in the network settings.",
    ),
    "profileUpdatedAt": m69,
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid profile URL",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter the profile URL",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("Profiles"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("Sort profiles"),
    "project": MessageLookupByLibrary.simpleMessage("Project"),
    "protocol": MessageLookupByLibrary.simpleMessage("Protocol"),
    "protocolParam": MessageLookupByLibrary.simpleMessage("Protocol parameter"),
    "protocolVersion": MessageLookupByLibrary.simpleMessage("Protocol version"),
    "providerInUse": m70,
    "providerUrlTip": MessageLookupByLibrary.simpleMessage(
      "Only remote providers are supported",
    ),
    "providers": MessageLookupByLibrary.simpleMessage("External resources"),
    "proxies": MessageLookupByLibrary.simpleMessage("Proxies"),
    "proxiesCount": m71,
    "proxiesProfileLabel": m72,
    "proxiesRemovedTip": m73,
    "proxiesReplacedTip": m74,
    "proxyChains": MessageLookupByLibrary.simpleMessage("Proxy chain"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("Proxy group"),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "Proxy group is empty",
    ),
    "proxyGroupInUse": m75,
    "proxyGroupsAfterStart": MessageLookupByLibrary.simpleMessage(
      "Groups show up here once the core starts",
    ),
    "proxyGroupsCount": m76,
    "proxyProviders": MessageLookupByLibrary.simpleMessage("Proxy providers"),
    "proxyShare": m77,
    "proxyType": MessageLookupByLibrary.simpleMessage("Proxy type"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("Prune cache"),
    "publicKey": MessageLookupByLibrary.simpleMessage("Public key"),
    "pureBlack": MessageLookupByLibrary.simpleMessage("Pure black"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("Pure black mode"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QR code"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "Scan a QR code to obtain a profile",
    ),
    "qrcodeTooLongTip": MessageLookupByLibrary.simpleMessage(
      "This link is too long for a QR code. Use Copy link instead.",
    ),
    "quickActions": MessageLookupByLibrary.simpleMessage("Quick actions"),
    "quickEdit": MessageLookupByLibrary.simpleMessage("Quick edit"),
    "rankDetail": m78,
    "rcxActiveScriptedGroups": MessageLookupByLibrary.simpleMessage(
      "Active scripted groups",
    ),
    "rcxAddGroup": MessageLookupByLibrary.simpleMessage("Add group"),
    "rcxAddKind": MessageLookupByLibrary.simpleMessage("Add network kind"),
    "rcxAddTag": MessageLookupByLibrary.simpleMessage("Add tag"),
    "rcxAdvanced": MessageLookupByLibrary.simpleMessage("Advanced"),
    "rcxAllGroups": MessageLookupByLibrary.simpleMessage("Every group"),
    "rcxAnyServer": MessageLookupByLibrary.simpleMessage("Any"),
    "rcxBackToAuto": MessageLookupByLibrary.simpleMessage("Back to auto"),
    "rcxBalanced": MessageLookupByLibrary.simpleMessage("Balanced"),
    "rcxBasedOn": MessageLookupByLibrary.simpleMessage("Based on"),
    "rcxBehaviour": MessageLookupByLibrary.simpleMessage("Behaviour"),
    "rcxBringChanges": MessageLookupByLibrary.simpleMessage(
      "Bring changes over",
    ),
    "rcxBringChangesHint": MessageLookupByLibrary.simpleMessage(
      "Your own edits stay as they are",
    ),
    "rcxChangeServer": MessageLookupByLibrary.simpleMessage("Change server"),
    "rcxChangeTo": MessageLookupByLibrary.simpleMessage("Choose from"),
    "rcxCheckDifferent": m79,
    "rcxCheckGroup": MessageLookupByLibrary.simpleMessage("Group"),
    "rcxCheckNone": MessageLookupByLibrary.simpleMessage(
      "Would find no server",
    ),
    "rcxCheckOn": m80,
    "rcxCheckOpen": MessageLookupByLibrary.simpleMessage("opens blocked"),
    "rcxCheckSame": m81,
    "rcxChecks": MessageLookupByLibrary.simpleMessage("Check frequency"),
    "rcxCondAdd": MessageLookupByLibrary.simpleMessage("Add condition"),
    "rcxCondAll": MessageLookupByLibrary.simpleMessage("All conditions"),
    "rcxCondAlways": MessageLookupByLibrary.simpleMessage("Always"),
    "rcxCondAny": MessageLookupByLibrary.simpleMessage("Any condition"),
    "rcxCondAnyServer": MessageLookupByLibrary.simpleMessage("Any server"),
    "rcxCondAtLeast": MessageLookupByLibrary.simpleMessage("is at least"),
    "rcxCondAtMost": MessageLookupByLibrary.simpleMessage("is at most"),
    "rcxCondClause": m82,
    "rcxCondCountry": MessageLookupByLibrary.simpleMessage("Country"),
    "rcxCondField": MessageLookupByLibrary.simpleMessage("Field"),
    "rcxCondIgnoreCase": MessageLookupByLibrary.simpleMessage("Ignore case"),
    "rcxCondLess": MessageLookupByLibrary.simpleMessage("is under"),
    "rcxCondMatch": MessageLookupByLibrary.simpleMessage("Match"),
    "rcxCondMore": MessageLookupByLibrary.simpleMessage("is over"),
    "rcxCondNoNames": MessageLookupByLibrary.simpleMessage("None declared"),
    "rcxCondNotPrefix": MessageLookupByLibrary.simpleMessage("not"),
    "rcxCondOp": MessageLookupByLibrary.simpleMessage("Operator"),
    "rcxCondPattern": MessageLookupByLibrary.simpleMessage("Pattern"),
    "rcxCondText": MessageLookupByLibrary.simpleMessage("As text"),
    "rcxCondTooComplex": MessageLookupByLibrary.simpleMessage(
      "This condition nests groups, so it is edited as text.",
    ),
    "rcxCondValue": MessageLookupByLibrary.simpleMessage("Value"),
    "rcxCondValues": MessageLookupByLibrary.simpleMessage(
      "Values, comma-separated",
    ),
    "rcxConsentAllow": MessageLookupByLibrary.simpleMessage("Allow"),
    "rcxConsentAsk": m83,
    "rcxConsentHint": MessageLookupByLibrary.simpleMessage(
      "Until you allow it, the group runs the Simple behaviour. The sites are contacted only through your servers or to test the network.",
    ),
    "rcxConsentTitle": MessageLookupByLibrary.simpleMessage(
      "Permission needed",
    ),
    "rcxContacts": MessageLookupByLibrary.simpleMessage("Sites contacted"),
    "rcxContactsHint": MessageLookupByLibrary.simpleMessage(
      "Third-party sites belong neither to your provider nor to the built-in behaviours.",
    ),
    "rcxControl": MessageLookupByLibrary.simpleMessage("Control"),
    "rcxCountryAll": MessageLookupByLibrary.simpleMessage("All countries"),
    "rcxCountryOnServers": MessageLookupByLibrary.simpleMessage(
      "On your servers",
    ),
    "rcxCountryPickMany": MessageLookupByLibrary.simpleMessage(
      "Choose countries",
    ),
    "rcxCountryPickOne": MessageLookupByLibrary.simpleMessage(
      "Choose a country",
    ),
    "rcxCountryServers": m84,
    "rcxCountryVerified": MessageLookupByLibrary.simpleMessage("verified"),
    "rcxDeleteProfile": m85,
    "rcxDetails": MessageLookupByLibrary.simpleMessage("Details"),
    "rcxDirectSplit": MessageLookupByLibrary.simpleMessage(
      "Direct sites through this group",
    ),
    "rcxDirectSplitActive": MessageLookupByLibrary.simpleMessage("On now"),
    "rcxDirectSplitHint": MessageLookupByLibrary.simpleMessage(
      "When sites your rules send direct stop opening, they go through this group. Local addresses always stay direct.",
    ),
    "rcxDirectSplitStandby": MessageLookupByLibrary.simpleMessage(
      "Ready: direct sites still open",
    ),
    "rcxDuplicate": MessageLookupByLibrary.simpleMessage("Edit a copy"),
    "rcxEnergyEco": MessageLookupByLibrary.simpleMessage("Economical"),
    "rcxEnergyPrecise": MessageLookupByLibrary.simpleMessage("Precise"),
    "rcxEnergyToday": m86,
    "rcxExcept": m87,
    "rcxExcludedByProfile": MessageLookupByLibrary.simpleMessage(
      "Excluded by the behaviour",
    ),
    "rcxExcludedCooldown": MessageLookupByLibrary.simpleMessage(
      "Skipped after “Change server”",
    ),
    "rcxExcludedNoMatch": MessageLookupByLibrary.simpleMessage(
      "Not in the pool",
    ),
    "rcxExcludedNoTier": MessageLookupByLibrary.simpleMessage(
      "Matches no preference",
    ),
    "rcxExcludedPending": MessageLookupByLibrary.simpleMessage(
      "Not checked yet",
    ),
    "rcxExcludedUnroutable": MessageLookupByLibrary.simpleMessage(
      "Not a server",
    ),
    "rcxExit": m88,
    "rcxExport": MessageLookupByLibrary.simpleMessage("Export"),
    "rcxFeelCalm": MessageLookupByLibrary.simpleMessage("Rarely"),
    "rcxFeelEager": MessageLookupByLibrary.simpleMessage("Often"),
    "rcxFieldAlive": MessageLookupByLibrary.simpleMessage("Working"),
    "rcxFieldCurrent": MessageLookupByLibrary.simpleMessage("In use"),
    "rcxFieldDead": MessageLookupByLibrary.simpleMessage("Not working"),
    "rcxFieldDiag": MessageLookupByLibrary.simpleMessage("Network diagnostic"),
    "rcxFieldEntry": MessageLookupByLibrary.simpleMessage("Entry country"),
    "rcxFieldExit": MessageLookupByLibrary.simpleMessage("Exit country"),
    "rcxFieldFails": MessageLookupByLibrary.simpleMessage("Fails check"),
    "rcxFieldKind": MessageLookupByLibrary.simpleMessage("Network kind"),
    "rcxFieldLatency": MessageLookupByLibrary.simpleMessage("Latency, ms"),
    "rcxFieldMeasured": MessageLookupByLibrary.simpleMessage("Measured"),
    "rcxFieldMetered": MessageLookupByLibrary.simpleMessage("Metered network"),
    "rcxFieldName": MessageLookupByLibrary.simpleMessage("Name"),
    "rcxFieldPasses": MessageLookupByLibrary.simpleMessage("Passes check"),
    "rcxFieldPortal": MessageLookupByLibrary.simpleMessage("Sign-in page"),
    "rcxFieldProvider": MessageLookupByLibrary.simpleMessage("Provider"),
    "rcxFieldServer": MessageLookupByLibrary.simpleMessage("Server address"),
    "rcxFieldTag": MessageLookupByLibrary.simpleMessage("Tag"),
    "rcxFieldTransport": MessageLookupByLibrary.simpleMessage(
      "Connection type",
    ),
    "rcxFieldType": MessageLookupByLibrary.simpleMessage("Protocol"),
    "rcxFieldUdp": MessageLookupByLibrary.simpleMessage("Supports UDP"),
    "rcxFixedHint": MessageLookupByLibrary.simpleMessage(
      "The whole group goes through this member with no server search; pick a load balancer or a nested group to hand it everything.",
    ),
    "rcxFixedOn": m89,
    "rcxFromScenario": m90,
    "rcxFromYours": MessageLookupByLibrary.simpleMessage(
      "Yours for this group",
    ),
    "rcxGroupProfiles": MessageLookupByLibrary.simpleMessage("Behaviours"),
    "rcxGroupProfilesHint": MessageLookupByLibrary.simpleMessage(
      "How a group picks its server. Tap one of yours to edit it, any other to edit a copy.",
    ),
    "rcxHealthAlive": MessageLookupByLibrary.simpleMessage("Working"),
    "rcxHealthDead": MessageLookupByLibrary.simpleMessage("Not working"),
    "rcxHealthStale": MessageLookupByLibrary.simpleMessage("Worked before"),
    "rcxHealthUnknown": MessageLookupByLibrary.simpleMessage("Not checked"),
    "rcxHistory": MessageLookupByLibrary.simpleMessage("History"),
    "rcxHistoryVersions": MessageLookupByLibrary.simpleMessage(
      "Earlier versions",
    ),
    "rcxHowToChoose": MessageLookupByLibrary.simpleMessage(
      "How to pick the server",
    ),
    "rcxHubAuto": MessageLookupByLibrary.simpleMessage("Use a scenario"),
    "rcxHubBundle": MessageLookupByLibrary.simpleMessage("In this file"),
    "rcxHubChange": MessageLookupByLibrary.simpleMessage("Choose a scenario"),
    "rcxHubCopyConfirm": MessageLookupByLibrary.simpleMessage("Edit a copy"),
    "rcxHubCopyMessage": m91,
    "rcxHubCopyTitle": MessageLookupByLibrary.simpleMessage("Edit a copy?"),
    "rcxHubDescriptionHint": MessageLookupByLibrary.simpleMessage(
      "What this scenario does",
    ),
    "rcxHubEverythingElse": MessageLookupByLibrary.simpleMessage(
      "Everything else",
    ),
    "rcxHubGroupsEmpty": MessageLookupByLibrary.simpleMessage(
      "This subscription has no active scripted groups.",
    ),
    "rcxHubLibrary": MessageLookupByLibrary.simpleMessage("Scenario library"),
    "rcxHubNeedsCore": MessageLookupByLibrary.simpleMessage(
      "Start the connection to see auto routing",
    ),
    "rcxHubNetworks": MessageLookupByLibrary.simpleMessage("Network kinds"),
    "rcxHubNoProfile": MessageLookupByLibrary.simpleMessage("No subscription"),
    "rcxHubNoProfileHint": MessageLookupByLibrary.simpleMessage(
      "Add a subscription first; auto routing works with its groups.",
    ),
    "rcxHubOffHint": MessageLookupByLibrary.simpleMessage(
      "A scenario can control routes, proxy groups and the tunnel mode for this subscription.",
    ),
    "rcxHubOtherGroups": MessageLookupByLibrary.simpleMessage(
      "Groups in this scenario",
    ),
    "rcxHubOtherGroupsHint": MessageLookupByLibrary.simpleMessage(
      "What this scenario does with individual subscription groups.",
    ),
    "rcxHubRoutes": MessageLookupByLibrary.simpleMessage("Routes"),
    "rcxHubRoutesHint": MessageLookupByLibrary.simpleMessage(
      "Traffic takes the first route it matches, top to bottom; the rest goes through Everything else.",
    ),
    "rcxHubRoutesRuleOnly": m92,
    "rcxImportAdd": MessageLookupByLibrary.simpleMessage("Add to my library"),
    "rcxImportNeedsCore": MessageLookupByLibrary.simpleMessage(
      "Start the app\'s core to check this file.",
    ),
    "rcxImportTitle": MessageLookupByLibrary.simpleMessage(
      "Import auto routing",
    ),
    "rcxImported": m93,
    "rcxJournalFailure": m94,
    "rcxJournalMode": m95,
    "rcxKindChecking": MessageLookupByLibrary.simpleMessage("checking"),
    "rcxKindGroupsHint": MessageLookupByLibrary.simpleMessage(
      "On this network these replace the scenario\'s groups of the same name; the others work as on every network.",
    ),
    "rcxKindName": MessageLookupByLibrary.simpleMessage("Name"),
    "rcxKindNameInvalid": MessageLookupByLibrary.simpleMessage(
      "Lowercase Latin letters, digits and dashes, up to 24",
    ),
    "rcxKindOpen": MessageLookupByLibrary.simpleMessage("open internet"),
    "rcxKindPortal": MessageLookupByLibrary.simpleMessage("sign-in page"),
    "rcxKindWhen": MessageLookupByLibrary.simpleMessage("Recognized when"),
    "rcxKindWhenHint": MessageLookupByLibrary.simpleMessage(
      "Kinds are tried top to bottom; the network gets the first that holds.",
    ),
    "rcxKindWhitelist": MessageLookupByLibrary.simpleMessage("whitelists only"),
    "rcxLadderAdd": MessageLookupByLibrary.simpleMessage("Add a step"),
    "rcxLadderAdvanced": MessageLookupByLibrary.simpleMessage(
      "Advanced condition…",
    ),
    "rcxLadderAnyWorking": MessageLookupByLibrary.simpleMessage(
      "Any working server",
    ),
    "rcxLadderCountry": MessageLookupByLibrary.simpleMessage("Country"),
    "rcxLadderEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Add steps to prefer some servers over others",
    ),
    "rcxLadderExceptCountries": MessageLookupByLibrary.simpleMessage(
      "All but these countries",
    ),
    "rcxLadderFallThrough": MessageLookupByLibrary.simpleMessage(
      "if none of them works",
    ),
    "rcxLadderFits": m96,
    "rcxLadderInherited": MessageLookupByLibrary.simpleMessage(
      "From the behaviour — edit a step to make the order your own",
    ),
    "rcxLadderLastResortHint": MessageLookupByLibrary.simpleMessage(
      "Servers in a last-resort step are used only when no other step has a working server, even a step below it.",
    ),
    "rcxLadderLatency": m97,
    "rcxLadderLatencyUnder": MessageLookupByLibrary.simpleMessage(
      "Latency under, ms",
    ),
    "rcxLadderNameContains": MessageLookupByLibrary.simpleMessage(
      "Name contains",
    ),
    "rcxLadderNameHas": m98,
    "rcxLadderNot": m99,
    "rcxLadderOther": MessageLookupByLibrary.simpleMessage("Other conditions"),
    "rcxLadderProvider": m100,
    "rcxLadderServersIn": MessageLookupByLibrary.simpleMessage(
      "Servers in this step",
    ),
    "rcxLadderStep": m101,
    "rcxLadderTag": m102,
    "rcxLadderTitle": MessageLookupByLibrary.simpleMessage("Server order"),
    "rcxLadderUdp": MessageLookupByLibrary.simpleMessage("UDP"),
    "rcxLastResort": MessageLookupByLibrary.simpleMessage("Fallback"),
    "rcxLevel": MessageLookupByLibrary.simpleMessage("Complexity"),
    "rcxLevelAdvanced": MessageLookupByLibrary.simpleMessage("Advanced"),
    "rcxLevelSimple": MessageLookupByLibrary.simpleMessage("Simple"),
    "rcxLine": m103,
    "rcxLintCheckUnused": m104,
    "rcxLintConsent": m105,
    "rcxLintGroupMissing": m106,
    "rcxLintPoolEmpty": m107,
    "rcxLintTagUnused": m108,
    "rcxLintTierEmpty": m109,
    "rcxLintTierUnreachable": m110,
    "rcxMainGroup": MessageLookupByLibrary.simpleMessage("Everything else"),
    "rcxMakeSmart": MessageLookupByLibrary.simpleMessage(
      "Use scripted selection",
    ),
    "rcxMakeSmartHint": MessageLookupByLibrary.simpleMessage(
      "The selected behaviour determines how this group picks a server.",
    ),
    "rcxManageHint": MessageLookupByLibrary.simpleMessage(
      "Manage behaviours in Tools → Advanced configuration → Scripted groups.",
    ),
    "rcxMatchAdd": MessageLookupByLibrary.simpleMessage("Add entry"),
    "rcxMatchAllServices": MessageLookupByLibrary.simpleMessage("All services"),
    "rcxMatchCidr": MessageLookupByLibrary.simpleMessage("IP range"),
    "rcxMatchCustom": MessageLookupByLibrary.simpleMessage("Custom"),
    "rcxMatchDomain": MessageLookupByLibrary.simpleMessage("Domain"),
    "rcxMatchGeoip": MessageLookupByLibrary.simpleMessage("IP category"),
    "rcxMatchGeosite": MessageLookupByLibrary.simpleMessage("Site category"),
    "rcxMatchHint": MessageLookupByLibrary.simpleMessage(
      "Domains, IP ranges, apps or rule sets this route also takes.",
    ),
    "rcxMatchInvalid": MessageLookupByLibrary.simpleMessage("Invalid value"),
    "rcxMatchKeyword": MessageLookupByLibrary.simpleMessage("Domain keyword"),
    "rcxMatchMore": m111,
    "rcxMatchNoResolve": MessageLookupByLibrary.simpleMessage(
      "Don’t resolve domains",
    ),
    "rcxMatchNone": MessageLookupByLibrary.simpleMessage("No traffic chosen"),
    "rcxMatchProcess": MessageLookupByLibrary.simpleMessage("App"),
    "rcxMatchRuleSet": MessageLookupByLibrary.simpleMessage("Rule set"),
    "rcxMatchServices": MessageLookupByLibrary.simpleMessage("Services"),
    "rcxMatchSuffix": MessageLookupByLibrary.simpleMessage(
      "Domain and subdomains",
    ),
    "rcxMatchType": MessageLookupByLibrary.simpleMessage("Type"),
    "rcxMatchTypeHint": MessageLookupByLibrary.simpleMessage(
      "A domain suffix also covers every subdomain.",
    ),
    "rcxMatchValue": MessageLookupByLibrary.simpleMessage("Value"),
    "rcxMergeFailed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t bring the changes over",
    ),
    "rcxMerged": MessageLookupByLibrary.simpleMessage("Changes brought over"),
    "rcxMergedConflicts": m112,
    "rcxModeAuto": MessageLookupByLibrary.simpleMessage("Auto"),
    "rcxModeAutoHint": MessageLookupByLibrary.simpleMessage(
      "Picks the best working server in the server order and switches when it fails.",
    ),
    "rcxModeBackToAuto": MessageLookupByLibrary.simpleMessage(
      "Give the mode back to the scenario",
    ),
    "rcxModeByScenario": MessageLookupByLibrary.simpleMessage(
      "The scenario sets the mode on this network",
    ),
    "rcxModeIs": m113,
    "rcxModeKeep": MessageLookupByLibrary.simpleMessage("Don\'t change"),
    "rcxModeManual": MessageLookupByLibrary.simpleMessage("Manual"),
    "rcxModeManualHint": MessageLookupByLibrary.simpleMessage(
      "The group stays on the server you pick in Proxies.",
    ),
    "rcxModeManualNow": MessageLookupByLibrary.simpleMessage(
      "You chose the mode yourself; the scenario waits until you pick By scenario",
    ),
    "rcxModePinnedHint": m114,
    "rcxModeScenario": MessageLookupByLibrary.simpleMessage("By scenario"),
    "rcxModeYours": MessageLookupByLibrary.simpleMessage(
      "The mode is yours on this network",
    ),
    "rcxNeedsConsent": MessageLookupByLibrary.simpleMessage(
      "Needs your permission",
    ),
    "rcxNetwork": m115,
    "rcxNewProfile": MessageLookupByLibrary.simpleMessage("New behaviour"),
    "rcxNewScenario": MessageLookupByLibrary.simpleMessage("New scenario"),
    "rcxOnThisNetwork": MessageLookupByLibrary.simpleMessage("On this network"),
    "rcxOnly": m116,
    "rcxOpFail": MessageLookupByLibrary.simpleMessage("fails"),
    "rcxOpIn": MessageLookupByLibrary.simpleMessage("is one of"),
    "rcxOpIs": MessageLookupByLibrary.simpleMessage("is"),
    "rcxOpIsNot": MessageLookupByLibrary.simpleMessage("is not"),
    "rcxOpMatches": MessageLookupByLibrary.simpleMessage("matches"),
    "rcxOpOk": MessageLookupByLibrary.simpleMessage("succeeds"),
    "rcxOwnProfile": MessageLookupByLibrary.simpleMessage(
      "As set on the group",
    ),
    "rcxOwnProfileHint": MessageLookupByLibrary.simpleMessage(
      "The group keeps the behaviour set in its own settings.",
    ),
    "rcxPatternInvalid": MessageLookupByLibrary.simpleMessage(
      "The pattern is not a valid regular expression",
    ),
    "rcxPendingTier": m117,
    "rcxPinned": m118,
    "rcxPinnedLabel": MessageLookupByLibrary.simpleMessage("Pinned"),
    "rcxPoolExclude": MessageLookupByLibrary.simpleMessage("Leave out servers"),
    "rcxPoolInclude": MessageLookupByLibrary.simpleMessage("Use only servers"),
    "rcxProblemGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "The group has no servers",
    ),
    "rcxProblemGroupUnavailable": MessageLookupByLibrary.simpleMessage(
      "This group is not a selector in the current config",
    ),
    "rcxProblemProfileInvalid": m119,
    "rcxProblemProfileMissing": m120,
    "rcxProblemStoreFailed": m121,
    "rcxProfile": MessageLookupByLibrary.simpleMessage("Behaviour"),
    "rcxProfileDescriptionHint": MessageLookupByLibrary.simpleMessage(
      "What this behaviour does",
    ),
    "rcxProfileName": MessageLookupByLibrary.simpleMessage("Name"),
    "rcxProgramMember": MessageLookupByLibrary.simpleMessage("Member"),
    "rcxReasonBest": MessageLookupByLibrary.simpleMessage(
      "This is the best server",
    ),
    "rcxReasonBetterTier": m122,
    "rcxReasonChangeServer": m123,
    "rcxReasonChecking": MessageLookupByLibrary.simpleMessage(
      "Checking a better candidate",
    ),
    "rcxReasonConfirming": MessageLookupByLibrary.simpleMessage(
      "A faster server needs another measurement",
    ),
    "rcxReasonDwell": MessageLookupByLibrary.simpleMessage(
      "Switched recently; holding before the next change",
    ),
    "rcxReasonFailover": m124,
    "rcxReasonFaster": m125,
    "rcxReasonFixed": m126,
    "rcxReasonFixedMissing": m127,
    "rcxReasonFlapLimit": m128,
    "rcxReasonHoldPinned": MessageLookupByLibrary.simpleMessage(
      "Holding the pinned server",
    ),
    "rcxReasonIdle": m129,
    "rcxReasonInitial": MessageLookupByLibrary.simpleMessage(
      "Selected the best available server",
    ),
    "rcxReasonManual": MessageLookupByLibrary.simpleMessage(
      "Controlled manually",
    ),
    "rcxReasonNetworkChanged": MessageLookupByLibrary.simpleMessage(
      "Network changed",
    ),
    "rcxReasonNetworkSuspect": MessageLookupByLibrary.simpleMessage(
      "The network looks down; no server is blamed",
    ),
    "rcxReasonNoAlternative": MessageLookupByLibrary.simpleMessage(
      "No other working server to change to",
    ),
    "rcxReasonOutOfPool": m130,
    "rcxReasonPaused": m131,
    "rcxReasonRouteInvalid": m132,
    "rcxReasonRouteNameTaken": m133,
    "rcxReasonRouteToMissing": m134,
    "rcxReasonSelectFailed": MessageLookupByLibrary.simpleMessage(
      "Could not select the server",
    ),
    "rcxReasonSplitOff": MessageLookupByLibrary.simpleMessage(
      "Direct sites go direct again",
    ),
    "rcxReasonSplitOn": MessageLookupByLibrary.simpleMessage(
      "Direct sites now go through this group",
    ),
    "rcxReasonStranded": MessageLookupByLibrary.simpleMessage(
      "No working server in the pool; holding the current one",
    ),
    "rcxReasonSwitchFixed": m135,
    "rcxReasonSwitchPinned": m136,
    "rcxReasonSwitchStranded": m137,
    "rcxReasonWorking": MessageLookupByLibrary.simpleMessage(
      "Working; kept until it fails",
    ),
    "rcxRouteAdd": MessageLookupByLibrary.simpleMessage("Add route"),
    "rcxRouteChoose": MessageLookupByLibrary.simpleMessage("Choose"),
    "rcxRouteEdit": MessageLookupByLibrary.simpleMessage("Edit the route"),
    "rcxRouteGroup": MessageLookupByLibrary.simpleMessage("Made by a route"),
    "rcxRouteGroupHint": m138,
    "rcxRouteName": MessageLookupByLibrary.simpleMessage("Name"),
    "rcxRouteNameLong": MessageLookupByLibrary.simpleMessage(
      "The name is too long",
    ),
    "rcxRouteNameReserved": MessageLookupByLibrary.simpleMessage(
      "This name is reserved",
    ),
    "rcxRouteNew": MessageLookupByLibrary.simpleMessage("New route"),
    "rcxRouteSendAutoHint": MessageLookupByLibrary.simpleMessage(
      "Picks the best working server by itself.",
    ),
    "rcxRouteSendDirectHint": MessageLookupByLibrary.simpleMessage(
      "This traffic bypasses the proxy.",
    ),
    "rcxRouteSendFixed": MessageLookupByLibrary.simpleMessage("One server"),
    "rcxRouteSendFixedHint": MessageLookupByLibrary.simpleMessage(
      "This traffic always goes through the chosen server or group.",
    ),
    "rcxRouteTarget": MessageLookupByLibrary.simpleMessage("Server"),
    "rcxRouteWhere": MessageLookupByLibrary.simpleMessage("Where it goes"),
    "rcxScenario": MessageLookupByLibrary.simpleMessage("Scenario"),
    "rcxScenarioDrives": m139,
    "rcxScenarioGroups": MessageLookupByLibrary.simpleMessage("Groups"),
    "rcxScenarioKindsHint": MessageLookupByLibrary.simpleMessage(
      "Recognize networks by direct diagnostics, then change the mode and groups on each.",
    ),
    "rcxScenarioMode": MessageLookupByLibrary.simpleMessage("Connection mode"),
    "rcxScenarios": MessageLookupByLibrary.simpleMessage("Scenarios"),
    "rcxScenariosHint": MessageLookupByLibrary.simpleMessage(
      "Tap a scenario to edit it. Built-in and provider scenarios open as copies.",
    ),
    "rcxSendBest": MessageLookupByLibrary.simpleMessage("Best server"),
    "rcxSendDirect": MessageLookupByLibrary.simpleMessage("Direct"),
    "rcxServers": MessageLookupByLibrary.simpleMessage("Servers"),
    "rcxServersMatch": m140,
    "rcxServersPattern": MessageLookupByLibrary.simpleMessage("Name pattern"),
    "rcxSmartGroups": MessageLookupByLibrary.simpleMessage("Scripted groups"),
    "rcxSourceBuiltin": MessageLookupByLibrary.simpleMessage("Built-in"),
    "rcxSourceChanged": MessageLookupByLibrary.simpleMessage(
      "The original changed",
    ),
    "rcxSourceChanges": MessageLookupByLibrary.simpleMessage("What changed"),
    "rcxSourceProvider": MessageLookupByLibrary.simpleMessage("From provider"),
    "rcxSourceUser": MessageLookupByLibrary.simpleMessage("Mine"),
    "rcxStranded": MessageLookupByLibrary.simpleMessage("When no server works"),
    "rcxStrandedDirect": MessageLookupByLibrary.simpleMessage("Direct"),
    "rcxStrandedHold": MessageLookupByLibrary.simpleMessage("Keep current"),
    "rcxStrategyAllServers": MessageLookupByLibrary.simpleMessage(
      "Use all servers in the profile",
    ),
    "rcxStrategyAuto": MessageLookupByLibrary.simpleMessage(
      "Auto-select server",
    ),
    "rcxStrategyCoreUnavailable": MessageLookupByLibrary.simpleMessage(
      "Strategy unavailable. The group can use its standard behaviour.",
    ),
    "rcxStrategyEdit": MessageLookupByLibrary.simpleMessage("Edit strategy"),
    "rcxStrategyHold": MessageLookupByLibrary.simpleMessage(
      "Keep the working server",
    ),
    "rcxStrategyLines": MessageLookupByLibrary.simpleMessage(
      "Enter one existing server, group or provider name per line in its field.",
    ),
    "rcxStrategyLowestLatency": MessageLookupByLibrary.simpleMessage(
      "Prefer lower measured latency",
    ),
    "rcxStrategyNotApplied": MessageLookupByLibrary.simpleMessage(
      "Could not apply the strategy",
    ),
    "rcxStrategyPreferNames": MessageLookupByLibrary.simpleMessage(
      "Prefer names containing",
    ),
    "rcxStrategyProfileChanged": MessageLookupByLibrary.simpleMessage(
      "The active profile changed. Reopen the editor to save.",
    ),
    "rcxStrategyYaml": MessageLookupByLibrary.simpleMessage("Edit YAML"),
    "rcxStudioCharacter": MessageLookupByLibrary.simpleMessage("Character"),
    "rcxStudioCharacterHint": MessageLookupByLibrary.simpleMessage(
      "Switching is how readily it moves to a faster server; checks trade accuracy for battery.",
    ),
    "rcxStudioPreview": MessageLookupByLibrary.simpleMessage(
      "What it would pick now",
    ),
    "rcxStudioPreviewHint": MessageLookupByLibrary.simpleMessage(
      "Choose a group to see which server this behaviour would pick in it.",
    ),
    "rcxStudioRanking": MessageLookupByLibrary.simpleMessage("All candidates"),
    "rcxStudioServersHint": MessageLookupByLibrary.simpleMessage(
      "Servers outside these conditions are never picked.",
    ),
    "rcxSwitching": MessageLookupByLibrary.simpleMessage("Switching"),
    "rcxTagName": MessageLookupByLibrary.simpleMessage("Tag name"),
    "rcxTagNameInvalid": MessageLookupByLibrary.simpleMessage(
      "Latin letters, digits, - and _ only, up to 24",
    ),
    "rcxTags": MessageLookupByLibrary.simpleMessage("Tags"),
    "rcxTagsHint": MessageLookupByLibrary.simpleMessage(
      "A tag names a set of servers once, for use in tiers as tag(name).",
    ),
    "rcxThirdParty": MessageLookupByLibrary.simpleMessage("third party"),
    "rcxTierLabel": MessageLookupByLibrary.simpleMessage("Label"),
    "rcxTitle": MessageLookupByLibrary.simpleMessage("Auto routing"),
    "rcxTurnOff": MessageLookupByLibrary.simpleMessage(
      "Remove scripted selection",
    ),
    "rcxUntilCheck": m141,
    "rcxUntilConfirm": m142,
    "rcxUntilDwell": m143,
    "rcxUseCheck": m144,
    "rcxUseDiagnostic": m145,
    "rcxUseEcho": MessageLookupByLibrary.simpleMessage("exit-country check"),
    "rcxWarnings": MessageLookupByLibrary.simpleMessage("Warnings"),
    "rcxWhy": MessageLookupByLibrary.simpleMessage("Why this server"),
    "rcxWouldDo": MessageLookupByLibrary.simpleMessage("Default behaviour"),
    "rcxWouldServers": m146,
    "rcxYaml": MessageLookupByLibrary.simpleMessage("YAML"),
    "recentRequests": MessageLookupByLibrary.simpleMessage("Recent requests"),
    "recommendedIcons": MessageLookupByLibrary.simpleMessage("Suggested"),
    "recordType": MessageLookupByLibrary.simpleMessage("Record type"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redir port"),
    "redo": MessageLookupByLibrary.simpleMessage("Redo"),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "regex": MessageLookupByLibrary.simpleMessage("Regex"),
    "releaseMemory": MessageLookupByLibrary.simpleMessage("Release memory"),
    "releaseMemoryFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to release memory",
    ),
    "remote": MessageLookupByLibrary.simpleMessage("Remote"),
    "remoteDestination": MessageLookupByLibrary.simpleMessage(
      "Remote destination",
    ),
    "remoteDnsResolve": MessageLookupByLibrary.simpleMessage(
      "Remote DNS resolution",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "rename": MessageLookupByLibrary.simpleMessage("Rename"),
    "replace": MessageLookupByLibrary.simpleMessage("Replace"),
    "replaceAll": MessageLookupByLibrary.simpleMessage("Replace all"),
    "request": MessageLookupByLibrary.simpleMessage("Request"),
    "requestHeaders": MessageLookupByLibrary.simpleMessage("Request headers"),
    "requests": MessageLookupByLibrary.simpleMessage("Requests"),
    "requestsAndUpdates": MessageLookupByLibrary.simpleMessage(
      "Requests and updates",
    ),
    "required": MessageLookupByLibrary.simpleMessage("Required"),
    "reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "This page has changes. Are you sure you want to reset?",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to reset?",
    ),
    "resourceUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Auto-update interval",
    ),
    "resourceUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "The auto-update interval must be greater than 0",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("Resources"),
    "respectRules": MessageLookupByLibrary.simpleMessage("Respect rules"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "Respect rules routes DNS connections by the rules and needs a Proxy Server Nameserver.",
    ),
    "responseCode": MessageLookupByLibrary.simpleMessage("Response code"),
    "restart": MessageLookupByLibrary.simpleMessage("Restart"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to restart the core?",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("Restore all data"),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage(
      "Restore profiles only",
    ),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("Restore strategy"),
    "restoreStrategyCompatible": MessageLookupByLibrary.simpleMessage(
      "Compatible",
    ),
    "restoreStrategyOverride": MessageLookupByLibrary.simpleMessage("Override"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage(
      "Restore successful",
    ),
    "result": MessageLookupByLibrary.simpleMessage("Result"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("Route addresses"),
    "routeBoard": MessageLookupByLibrary.simpleMessage("Route"),
    "routeBoardDesc": MessageLookupByLibrary.simpleMessage(
      "The hops this device\'s traffic takes",
    ),
    "routeCarrier": MessageLookupByLibrary.simpleMessage("Carrier"),
    "routeExcludeAddress": MessageLookupByLibrary.simpleMessage(
      "Route exclude addresses",
    ),
    "routeFrom": MessageLookupByLibrary.simpleMessage("From"),
    "routeMapFlat": MessageLookupByLibrary.simpleMessage("Flat map"),
    "routeMapGlobe": MessageLookupByLibrary.simpleMessage("3D globe"),
    "routeTo": MessageLookupByLibrary.simpleMessage("To"),
    "routeVia": MessageLookupByLibrary.simpleMessage("Via"),
    "routingMark": MessageLookupByLibrary.simpleMessage("Routing mark"),
    "ru": MessageLookupByLibrary.simpleMessage("Russian"),
    "rule": MessageLookupByLibrary.simpleMessage("Rule"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage(
      "Logical rule AND",
    ),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Match the full domain",
    ),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "Match a domain keyword",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Match a domain regex",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match a domain suffix",
    ),
    "ruleActionDomainWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Wildcard match; only * and ? are supported",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "Match the DSCP mark (tproxy UDP inbound only)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match the destination port range",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Match the IP\'s country code",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Match domains in Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage(
      "Match the inbound name",
    ),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match the inbound port",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "Match the inbound type",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "Match the inbound username; separate multiple usernames with /",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Match the IP\'s ASN",
    ),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "Match an IP address range; IP-CIDR6 is just an alias",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Match an IP address range",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match an IP suffix range",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "Match all requests, no conditions needed",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "Match TCP or UDP",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage(
      "Logical rule NOT",
    ),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("Logical rule OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process name; matches the package name on Android",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process name regex; matches the package name on Android",
    ),
    "ruleActionProcessNameWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process name wildcard; only * and ? are supported",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "Match by the full process path",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process path regex",
    ),
    "ruleActionProcessPathWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process path wildcard; only * and ? are supported",
    ),
    "ruleActionRematchNameDesc": MessageLookupByLibrary.simpleMessage(
      "Match the rematch name; separate multiple names with /",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "Reference a rule set; requires rule-providers",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Match the source IP\'s country code",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Match the source IP\'s ASN",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Match a source IP address range",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match a source IP suffix range",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match the source port range",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "Match into a sub-rule; mind the parentheses",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Match the Linux user ID",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("Rule is empty"),
    "ruleHitCount": m147,
    "ruleHitDetail": m148,
    "ruleHitShare": m149,
    "ruleHits": MessageLookupByLibrary.simpleMessage("Rule hits"),
    "ruleListInvalid": MessageLookupByLibrary.simpleMessage(
      "The rules must be a YAML list with one rule per item, such as - DOMAIN,example.com,DIRECT",
    ),
    "rulePresetAdBlock": MessageLookupByLibrary.simpleMessage("Block Ads"),
    "rulePresetBittorrentDirect": MessageLookupByLibrary.simpleMessage(
      "BitTorrent direct",
    ),
    "rulePresetBlockDot": MessageLookupByLibrary.simpleMessage(
      "Block DNS over TLS",
    ),
    "rulePresetBlockLoopback": MessageLookupByLibrary.simpleMessage(
      "Block proxy loopback",
    ),
    "rulePresetBlockQuic": MessageLookupByLibrary.simpleMessage("Block QUIC"),
    "rulePresetBlockStun": MessageLookupByLibrary.simpleMessage("Block STUN"),
    "rulePresetLanDirect": MessageLookupByLibrary.simpleMessage("LAN direct"),
    "rulePresetSystemServicesDirect": MessageLookupByLibrary.simpleMessage(
      "Apple and Microsoft direct",
    ),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("Rule providers"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("Rule set"),
    "ruleSetEmptyTip": MessageLookupByLibrary.simpleMessage(
      "The rule set has no usable entries",
    ),
    "ruleSetInvalidTip": MessageLookupByLibrary.simpleMessage(
      "This mrs file cannot be read",
    ),
    "ruleSetMixedTip": MessageLookupByLibrary.simpleMessage(
      "The rule set mixes domains and IP ranges, so its type cannot be told",
    ),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("Rule target"),
    "ruleTextInvalid": MessageLookupByLibrary.simpleMessage(
      "The rule must start with a supported type, such as DOMAIN,example.com,DIRECT",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("Rules"),
    "rulesCount": m150,
    "runTime": MessageLookupByLibrary.simpleMessage("Run time"),
    "running": MessageLookupByLibrary.simpleMessage("Running"),
    "runtimeConfig": MessageLookupByLibrary.simpleMessage("Runtime config"),
    "safeMode": MessageLookupByLibrary.simpleMessage("Safe mode"),
    "safeModeAppTitle": m151,
    "saturation": MessageLookupByLibrary.simpleMessage("Saturation"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save the changes?"),
    "script": MessageLookupByLibrary.simpleMessage("Script"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "Script mode: rewrites the whole profile with an extension script",
    ),
    "scrollToSelected": MessageLookupByLibrary.simpleMessage(
      "Scroll to selected",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "searchHint": MessageLookupByLibrary.simpleMessage(
      "Search pages, nodes, tools and settings",
    ),
    "seconds": MessageLookupByLibrary.simpleMessage("seconds"),
    "secondsCount": m152,
    "secretKey": MessageLookupByLibrary.simpleMessage("Key"),
    "sectionsInEffect": m153,
    "select": MessageLookupByLibrary.simpleMessage("Select"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Select all"),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage(
      "Please select a rule set",
    ),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "Please select a split strategy",
    ),
    "send": MessageLookupByLibrary.simpleMessage("Send"),
    "sendFromPhone": MessageLookupByLibrary.simpleMessage("Send from phone"),
    "sendFromPhoneConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Import the link from your phone?",
    ),
    "sendFromPhoneDesc": MessageLookupByLibrary.simpleMessage(
      "Scan with your phone and send a link to this device",
    ),
    "sendFromPhoneNoNetwork": MessageLookupByLibrary.simpleMessage(
      "This device is not connected to a local network",
    ),
    "sendFromPhonePageHint": MessageLookupByLibrary.simpleMessage(
      "Subscription link or proxy share link",
    ),
    "sendFromPhonePageSent": MessageLookupByLibrary.simpleMessage(
      "Sent. Confirm the import on the other device.",
    ),
    "sendFromPhonePageTitle": MessageLookupByLibrary.simpleMessage(
      "Send a link to Skyward",
    ),
    "sendFromPhonePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Receiving a link from your phone needs the Nearby devices permission, which lets Skyward reach the local network. Turn it on in the app\'s settings.",
    ),
    "sendFromPhoneTip": MessageLookupByLibrary.simpleMessage(
      "Scan the code with your phone\'s camera and paste the link on the page that opens. Both devices need to be on the same network.",
    ),
    "server": MessageLookupByLibrary.simpleMessage("Server"),
    "serviceAbnormalCount": m154,
    "serviceAllAvailable": MessageLookupByLibrary.simpleMessage(
      "All available",
    ),
    "serviceAvailable": MessageLookupByLibrary.simpleMessage("Available"),
    "serviceBlocked": MessageLookupByLibrary.simpleMessage("Blocked"),
    "serviceCheck": MessageLookupByLibrary.simpleMessage("Check"),
    "serviceCheckAll": MessageLookupByLibrary.simpleMessage("Check all"),
    "serviceCheckedAt": m155,
    "serviceComingSoon": MessageLookupByLibrary.simpleMessage("Coming soon"),
    "serviceDisallowedIsp": MessageLookupByLibrary.simpleMessage(
      "Disallowed ISP",
    ),
    "serviceFailed": MessageLookupByLibrary.simpleMessage("Check failed"),
    "serviceManage": MessageLookupByLibrary.simpleMessage("Manage services"),
    "serviceOriginalsOnly": MessageLookupByLibrary.simpleMessage(
      "Originals only",
    ),
    "servicePending": MessageLookupByLibrary.simpleMessage("Not checked"),
    "serviceRestricted": MessageLookupByLibrary.simpleMessage(
      "Access restricted",
    ),
    "serviceShownOnDashboard": MessageLookupByLibrary.simpleMessage(
      "Shown on the dashboard",
    ),
    "serviceStatus": MessageLookupByLibrary.simpleMessage("Service status"),
    "serviceUnavailable": MessageLookupByLibrary.simpleMessage("Unavailable"),
    "serviceUnsupportedRegion": MessageLookupByLibrary.simpleMessage(
      "Region not supported",
    ),
    "settingEntries": MessageLookupByLibrary.simpleMessage("settings"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsCount": m156,
    "shareLinkUnreadable": m157,
    "shareLinksInvalid": MessageLookupByLibrary.simpleMessage(
      "No proxy could be read from the links",
    ),
    "shareQrcodeTip": MessageLookupByLibrary.simpleMessage(
      "Scan with Skyward on another device to import this profile.",
    ),
    "show": MessageLookupByLibrary.simpleMessage("Show"),
    "showLess": MessageLookupByLibrary.simpleMessage("Collapse"),
    "showMore": MessageLookupByLibrary.simpleMessage("Expand"),
    "showNotificationStopAction": MessageLookupByLibrary.simpleMessage(
      "Stop button in notification",
    ),
    "showPassword": MessageLookupByLibrary.simpleMessage("Show password"),
    "sidebar": MessageLookupByLibrary.simpleMessage("Sidebar"),
    "sidebarBlurDesc": MessageLookupByLibrary.simpleMessage(
      "Background blur lets the desktop behind the window show through the sidebar.",
    ),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("Silent launch"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Silent launch starts without showing the window.",
    ),
    "singleAdd": MessageLookupByLibrary.simpleMessage("Single add"),
    "singleImport": MessageLookupByLibrary.simpleMessage("Single import"),
    "singleShareLinkOnly": MessageLookupByLibrary.simpleMessage(
      "Enter one link here; edit several from the quick edit of the list",
    ),
    "singleValueTip": m158,
    "size": MessageLookupByLibrary.simpleMessage("Size"),
    "skipCertVerify": MessageLookupByLibrary.simpleMessage(
      "Skip certificate verification",
    ),
    "skipDomain": MessageLookupByLibrary.simpleMessage("Skip domains"),
    "skipDomainDesc": MessageLookupByLibrary.simpleMessage(
      "A sniffed domain on the Skip domains list is not used.",
    ),
    "skipDstAddress": MessageLookupByLibrary.simpleMessage(
      "Skip destination addresses",
    ),
    "skipSrcAddress": MessageLookupByLibrary.simpleMessage(
      "Skip source addresses",
    ),
    "slide": MessageLookupByLibrary.simpleMessage("Slide"),
    "sliders": MessageLookupByLibrary.simpleMessage("Sliders"),
    "sniffProtocols": MessageLookupByLibrary.simpleMessage("Protocols"),
    "sniffer": MessageLookupByLibrary.simpleMessage("Sniffer"),
    "snifferStatusDesc": MessageLookupByLibrary.simpleMessage(
      "The sniffer reads the domain from TLS, HTTP and QUIC traffic so rules can match it.",
    ),
    "socksPort": MessageLookupByLibrary.simpleMessage("SOCKS port"),
    "softStyle": MessageLookupByLibrary.simpleMessage("Soft"),
    "sort": MessageLookupByLibrary.simpleMessage("Sort"),
    "source": MessageLookupByLibrary.simpleMessage("Source"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("Source IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("Special proxy"),
    "specialRules": MessageLookupByLibrary.simpleMessage("Special rules"),
    "spectrum": MessageLookupByLibrary.simpleMessage("Spectrum"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("Speed statistics"),
    "speedTest": MessageLookupByLibrary.simpleMessage("Connection test"),
    "speedTestDownloading": MessageLookupByLibrary.simpleMessage(
      "Testing download",
    ),
    "speedTestFailed": MessageLookupByLibrary.simpleMessage("Test failed"),
    "speedTestMbps": MessageLookupByLibrary.simpleMessage("Mbps"),
    "speedTestMs": MessageLookupByLibrary.simpleMessage("ms"),
    "speedTestPinging": MessageLookupByLibrary.simpleMessage(
      "Measuring latency",
    ),
    "speedTestProvider": MessageLookupByLibrary.simpleMessage("Provider"),
    "speedTestReady": MessageLookupByLibrary.simpleMessage("Ready"),
    "speedTestResult": MessageLookupByLibrary.simpleMessage("Result"),
    "speedTestRoute": MessageLookupByLibrary.simpleMessage("Test route"),
    "speedTestStart": MessageLookupByLibrary.simpleMessage("Start test"),
    "speedTestStop": MessageLookupByLibrary.simpleMessage("Stop"),
    "speedTestSystemRoute": MessageLookupByLibrary.simpleMessage(
      "System route",
    ),
    "speedTestTesting": MessageLookupByLibrary.simpleMessage("Testing"),
    "speedTestUploading": MessageLookupByLibrary.simpleMessage(
      "Testing upload",
    ),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("Split strategy"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Split strategy cannot be empty",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDs are empty"),
    "stackGvisorDesc": MessageLookupByLibrary.simpleMessage(
      "The gVisor userspace stack: the most complete and compatible, with a higher memory footprint. Restart the VPN after switching.",
    ),
    "stackMipsDesc": MessageLookupByLibrary.simpleMessage(
      "Default. A lightweight userspace stack built into sing-tun; only this stack supports TCP congestion control. Restart the VPN after switching.",
    ),
    "stackMixedDesc": MessageLookupByLibrary.simpleMessage(
      "A hybrid: TCP through the system kernel stack and UDP through gVisor. Restart the VPN after switching.",
    ),
    "stackMode": MessageLookupByLibrary.simpleMessage("Stack mode"),
    "stackSystemDesc": MessageLookupByLibrary.simpleMessage(
      "TCP is handled by the system kernel stack while UDP is forwarded by the kernel. Restart the VPN after switching.",
    ),
    "stackTrace": MessageLookupByLibrary.simpleMessage("Stack trace"),
    "standard": MessageLookupByLibrary.simpleMessage("Standard"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "Standard mode: adds rules on top of the profile",
    ),
    "start": MessageLookupByLibrary.simpleMessage("Start"),
    "startFromScratch": MessageLookupByLibrary.simpleMessage(
      "Start from scratch",
    ),
    "startVpn": MessageLookupByLibrary.simpleMessage("Starting VPN…"),
    "startupAndBackground": MessageLookupByLibrary.simpleMessage(
      "Startup and background",
    ),
    "status": MessageLookupByLibrary.simpleMessage("Status"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "With DNS off, the system DNS is used.",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("Stopping VPN…"),
    "storage": MessageLookupByLibrary.simpleMessage("Storage"),
    "strategy": MessageLookupByLibrary.simpleMessage("Strategy"),
    "strictRoute": MessageLookupByLibrary.simpleMessage("Strict route"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "Strict route keeps traffic such as DNS from bypassing TUN, and with IPv6 off it blocks this device\'s IPv6 connections.",
    ),
    "style": MessageLookupByLibrary.simpleMessage("Style"),
    "submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "subscriptionInfo": MessageLookupByLibrary.simpleMessage(
      "Subscription info",
    ),
    "sudoPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Enter your password for sudo",
    ),
    "suspended": MessageLookupByLibrary.simpleMessage("Suspended…"),
    "switchProfile": MessageLookupByLibrary.simpleMessage("Switch profile"),
    "sync": MessageLookupByLibrary.simpleMessage("Sync"),
    "system": MessageLookupByLibrary.simpleMessage("System"),
    "systemApp": MessageLookupByLibrary.simpleMessage("System apps"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("System proxy"),
    "tab": MessageLookupByLibrary.simpleMessage("Tab"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("Tab animation"),
    "takeoverScope": MessageLookupByLibrary.simpleMessage("Traffic scope"),
    "takeoverScopeAlways": MessageLookupByLibrary.simpleMessage("Always on"),
    "takeoverScopeDesc": MessageLookupByLibrary.simpleMessage(
      "Once the VPN is up, Android routes 0.0.0.0/0 through it; there is no separate switch.",
    ),
    "tapIconToRetry": MessageLookupByLibrary.simpleMessage(
      "Tap the icon to retry",
    ),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("Tap to authorize"),
    "target": MessageLookupByLibrary.simpleMessage("Target"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP concurrent"),
    "temporary": MessageLookupByLibrary.simpleMessage("Temporary files"),
    "testInterval": MessageLookupByLibrary.simpleMessage("Test interval"),
    "testUrl": MessageLookupByLibrary.simpleMessage("Test URL"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("Test when used"),
    "textScale": MessageLookupByLibrary.simpleMessage("Text scaling"),
    "textScalePreview": MessageLookupByLibrary.simpleMessage(
      "Text in the app will look like this",
    ),
    "textSection": MessageLookupByLibrary.simpleMessage("Text"),
    "theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "themeColor": MessageLookupByLibrary.simpleMessage("Theme color"),
    "themeMode": MessageLookupByLibrary.simpleMessage("Theme mode"),
    "thisMonth": MessageLookupByLibrary.simpleMessage("This month"),
    "tight": MessageLookupByLibrary.simpleMessage("Tight"),
    "time": MessageLookupByLibrary.simpleMessage("Time"),
    "timeout": MessageLookupByLibrary.simpleMessage("Timeout"),
    "tintedStyle": MessageLookupByLibrary.simpleMessage("Tinted"),
    "tip": MessageLookupByLibrary.simpleMessage("Tip"),
    "today": MessageLookupByLibrary.simpleMessage("Today"),
    "toggle": MessageLookupByLibrary.simpleMessage("Toggle"),
    "tolerance": MessageLookupByLibrary.simpleMessage("Tolerance"),
    "toolEntries": MessageLookupByLibrary.simpleMessage("Tools"),
    "tools": MessageLookupByLibrary.simpleMessage("More"),
    "torch": MessageLookupByLibrary.simpleMessage("Flashlight"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalDownload": MessageLookupByLibrary.simpleMessage("Downloaded"),
    "totalTraffic": MessageLookupByLibrary.simpleMessage("Total traffic"),
    "totalUpload": MessageLookupByLibrary.simpleMessage("Uploaded"),
    "totalUptime": MessageLookupByLibrary.simpleMessage("Running time"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("TProxy port"),
    "traffic": MessageLookupByLibrary.simpleMessage("Traffic"),
    "trafficOverview": MessageLookupByLibrary.simpleMessage("Traffic overview"),
    "trafficPeak": m159,
    "trafficPeakLine": m160,
    "trafficRanking": MessageLookupByLibrary.simpleMessage("Traffic ranking"),
    "trafficTotal": m161,
    "trafficTrend": MessageLookupByLibrary.simpleMessage("Traffic trend"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("Traffic usage"),
    "transport": MessageLookupByLibrary.simpleMessage("Transport"),
    "transportHeaders": m162,
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunAuthorizationFailed": MessageLookupByLibrary.simpleMessage(
      "TUN could not be authorized, so it was turned off.",
    ),
    "tunDesc": MessageLookupByLibrary.simpleMessage(
      "TUN works only in administrator mode.",
    ),
    "tunGso": MessageLookupByLibrary.simpleMessage("TUN GSO"),
    "tunGsoDesc": MessageLookupByLibrary.simpleMessage(
      "Boosts network speed. Takes effect after restarting VPN.",
    ),
    "tunOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Entries added here replace the TUN settings of every profile; anything not added keeps the profile\'s own setting. Entries a custom profile adds itself take precedence.",
    ),
    "tunRouteDesc": MessageLookupByLibrary.simpleMessage(
      "An empty route address takes over all traffic; excluded subnets stay outside the virtual interface.",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("Turn off"),
    "turnOn": MessageLookupByLibrary.simpleMessage("Turn on"),
    "type": MessageLookupByLibrary.simpleMessage("Type"),
    "udpRelayMode": MessageLookupByLibrary.simpleMessage("UDP relay mode"),
    "udpTimeout": MessageLookupByLibrary.simpleMessage("UDP timeout"),
    "udpTimeoutDesc": MessageLookupByLibrary.simpleMessage(
      "The UDP timeout is in seconds and works only with the gvisor, system and mixed stacks.",
    ),
    "ultra": MessageLookupByLibrary.simpleMessage("Ultra"),
    "undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("Unified delay"),
    "unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage(
      "Unknown network error",
    ),
    "unmaximize": MessageLookupByLibrary.simpleMessage("Restore down"),
    "unnamed": MessageLookupByLibrary.simpleMessage("Unnamed"),
    "unpinWindow": MessageLookupByLibrary.simpleMessage("Unpin window"),
    "update": MessageLookupByLibrary.simpleMessage("Update"),
    "upload": MessageLookupByLibrary.simpleMessage("Upload"),
    "uploadBandwidth": MessageLookupByLibrary.simpleMessage("Upload bandwidth"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlTip": m163,
    "usageDetails": MessageLookupByLibrary.simpleMessage("Usage details"),
    "usageStats": MessageLookupByLibrary.simpleMessage("Usage stats"),
    "useHosts": MessageLookupByLibrary.simpleMessage("Use hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("Use system hosts"),
    "usedShort": MessageLookupByLibrary.simpleMessage("used"),
    "usedTraffic": MessageLookupByLibrary.simpleMessage("Used traffic"),
    "userAgent": MessageLookupByLibrary.simpleMessage("User-Agent"),
    "username": MessageLookupByLibrary.simpleMessage("Username"),
    "value": MessageLookupByLibrary.simpleMessage("Value"),
    "version": MessageLookupByLibrary.simpleMessage("Version"),
    "versionUpdate": MessageLookupByLibrary.simpleMessage("Version update"),
    "versionUpdateChecking": MessageLookupByLibrary.simpleMessage("Checking…"),
    "versionUpdateDownloading": MessageLookupByLibrary.simpleMessage(
      "Downloading…",
    ),
    "versionUpdateFailed": MessageLookupByLibrary.simpleMessage("Check failed"),
    "versionUpdateFound": MessageLookupByLibrary.simpleMessage(
      "New version available",
    ),
    "versionUpdateLatest": MessageLookupByLibrary.simpleMessage("Up to date"),
    "view": MessageLookupByLibrary.simpleMessage("View"),
    "virtualIpv4": MessageLookupByLibrary.simpleMessage("Virtual IPv4"),
    "vividStyle": MessageLookupByLibrary.simpleMessage("Vivid"),
    "vpnBehavior": MessageLookupByLibrary.simpleMessage("VPN behaviour"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN-related configuration change detected",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "VPN routes all system traffic through VpnService automatically.",
    ),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage(
      "WebDAV configuration",
    ),
    "webrtcGuard": MessageLookupByLibrary.simpleMessage("WebRTC"),
    "webrtcGuardBlock": MessageLookupByLibrary.simpleMessage("Block"),
    "webrtcGuardDesc": MessageLookupByLibrary.simpleMessage(
      "Pages and calls ask a STUN server for this machine\'s public address. Blocking is safest, but peer-to-peer traffic falls back to a relay or fails. Through proxy hands out the node\'s exit address instead, which needs a node that carries UDP. Leave alone passes discovery to the profile\'s rules.",
    ),
    "webrtcGuardOff": MessageLookupByLibrary.simpleMessage("Leave alone"),
    "webrtcGuardProxy": MessageLookupByLibrary.simpleMessage("Through proxy"),
    "webrtcLeakAdvice": MessageLookupByLibrary.simpleMessage(
      "With Block, seeing no reflected address is expected. To test a real leak, set WebRTC to Leave alone in Advanced > Network, check again, then switch back.",
    ),
    "webrtcLeakExternal": MessageLookupByLibrary.simpleMessage(
      "Verify WebRTC in a browser",
    ),
    "webrtcLeakGuard": MessageLookupByLibrary.simpleMessage("Guard mode"),
    "webrtcLeakGuardOffBad": MessageLookupByLibrary.simpleMessage(
      "Guard is off, so a page can read this device\'s public address",
    ),
    "webrtcLeakGuardProxyBad": MessageLookupByLibrary.simpleMessage(
      "Discovery goes through the proxy; the node must carry UDP",
    ),
    "webrtcLeakReflected": MessageLookupByLibrary.simpleMessage(
      "Reflected address",
    ),
    "webrtcLeakStun": MessageLookupByLibrary.simpleMessage("STUN probe"),
    "webrtcLeakStunBlocked": MessageLookupByLibrary.simpleMessage(
      "No STUN answer came back, so the block is in force",
    ),
    "webrtcLeakStunOpen": MessageLookupByLibrary.simpleMessage(
      "A STUN server answered",
    ),
    "webrtcLeakStunSilent": MessageLookupByLibrary.simpleMessage(
      "No STUN answer came back, so the result is inconclusive",
    ),
    "webrtcLeakStunUnresolved": MessageLookupByLibrary.simpleMessage(
      "No STUN host could be resolved; the network is unavailable",
    ),
    "week": MessageLookupByLibrary.simpleMessage("Week"),
    "weekOfYear": m164,
    "weeklyRange": m165,
    "whitelistMode": MessageLookupByLibrary.simpleMessage("Whitelist mode"),
    "writeToSystem": MessageLookupByLibrary.simpleMessage("Write to system"),
    "writeToSystemDesc": MessageLookupByLibrary.simpleMessage(
      "Write to system also sets the system clock; Android ignores it.",
    ),
    "yearsAgo": m166,
    "yearsAgoShort": m167,
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "zhCN": MessageLookupByLibrary.simpleMessage("Simplified Chinese"),
  };
}
