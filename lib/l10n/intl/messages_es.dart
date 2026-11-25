// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es locale. All the
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
  String get localeName => 'es';

  static String m0(count) =>
      "${Intl.plural(count, one: '${count} seleccionada', other: '${count} seleccionadas')}";

  static String m1(name) => "${name} añadido a proxies locales";

  static String m2(name) => "${name} ya está en proxies locales";

  static String m3(count, skipped) =>
      "${count} por añadir, ${skipped} omitidos por ya existir";

  static String m4(detail) => "No se pudieron borrar los datos: ${detail}";

  static String m5(count) => "${count} conexiones";

  static String m6(code) =>
      "Windows se negó a ejecutar SkywardCore.exe (error ${code}). Una directiva de control de aplicaciones, como Smart App Control o AppLocker, bloquea los programas sin firmar; permite Skyward en esa directiva o desactívala e inténtalo de nuevo.";

  static String m7(name) =>
      "La app no pudo terminar de iniciarse dos veces seguidas. Para romper el ciclo, se ha deseleccionado el perfil ${name} y se ha omitido la configuración automática. Puedes volver a seleccionarlo en cualquier momento.";

  static String m8(url) => "¿Quieres crear un perfil a partir de ${url}?";

  static String m9(count, label) =>
      "${Intl.plural(count, one: 'Se descartó 1 regla SUB-RULE, porque los perfiles personalizados no admiten subreglas', other: 'Se descartaron ${label} reglas SUB-RULE, porque los perfiles personalizados no admiten subreglas')}";

  static String m10(message) =>
      "El núcleo no puede interpretar este proxy: ${message}";

  static String m11(proxy, target) =>
      "${proxy} marca a través de ${target}, que lleva de vuelta a ${proxy}, por lo que la marcación entra en bucle";

  static String m12(name) =>
      "El nombre ${name} ya lo usa otro proxy o grupo de proxies";

  static String m13(path) =>
      "Los grupos de proxies se referencian entre sí en bucle: ${path}";

  static String m14(name) =>
      "El respaldo si está vacío debe ser un proxy, pero ${name} no existe o es un grupo de proxies";

  static String m15(name, message) =>
      "${name} no es una expresión regular válida: ${message}";

  static String m16(name) => "El proxy de marcación ${name} no existe";

  static String m17(names) =>
      "Estos proveedores de proxies no existen: ${names}";

  static String m18(names) => "Estos proxies o políticas no existen: ${names}";

  static String m19(name) =>
      "${name} es un nombre de política integrada y no se puede usar aquí";

  static String m20(count) =>
      "${count} elementos tienen problemas, y aplicar este perfil puede fallar";

  static String m21(count) =>
      "${Intl.plural(count, one: 'hace 1 día', other: 'hace ${count} días')}";

  static String m22(count) => "${Intl.plural(count, other: 'hace ${count} d')}";

  static String m23(label) =>
      "¿Seguro que quieres eliminar los elementos seleccionados (${label})?";

  static String m24(label) =>
      "¿Seguro que quieres eliminar este elemento (${label})?";

  static String m25(label) => "Detalles de ${label}";

  static String m26(name) =>
      "La marcación a través de ${name} lleva de vuelta al proxy que lo usa, por lo que se detuvo la conexión";

  static String m27(value, percent) => "Directo ${value} · ${percent}";

  static String m28(days, hours) => "${days} d ${hours} h";

  static String m29(hours, minutes) => "${hours} h ${minutes} min";

  static String m30(count) => "${count} min";

  static String m31(label) => "${label} no puede estar vacío";

  static String m32(label) => "${label} ya existe";

  static String m33(count) => "${count} elementos fallaron";

  static String m34(label, message) => "${label}: ${message}";

  static String m35(name) => "${name} ya está actualizado";

  static String m36(name) => "${name} actualizado";

  static String m37(count) =>
      "${Intl.plural(count, one: '1 grupo', other: '${count} grupos')}";

  static String m38(count) => "${count} sin respuesta";

  static String m39(action) =>
      "Ya lo usa “${action}”. Al guardar, pasará a este.";

  static String m40(modifiers) =>
      "Incluye al menos una de estas teclas: ${modifiers}";

  static String m41(count) =>
      "${Intl.plural(count, one: 'hace 1 hora', other: 'hace ${count} horas')}";

  static String m42(count) => "${Intl.plural(count, other: 'hace ${count} h')}";

  static String m43(target) => "${target} no es una política válida";

  static String m44(proxyName) => "${proxyName} no es un proxy válido";

  static String m45(providerName) =>
      "${providerName} no es un proveedor de proxies válido";

  static String m46(ruleSet) => "${ruleSet} no es un conjunto de reglas válido";

  static String m47(subRule) => "${subRule} no es una SUB_RULE válida";

  static String m48(count) =>
      "${Intl.plural(count, one: '1 elemento', other: '${count} elementos')}";

  static String m49(line, message) => "Línea ${line}: ${message}";

  static String m50(appName) =>
      "1. Abre Ajustes del sistema > Privacidad y seguridad\n2. Elige Servicios de localización\n3. Busca ${appName} en la lista y márcalo\n\nCuando termines, vuelve a la app para continuar. Gracias por tu colaboración.";

  static String m51(label, max) =>
      "${label} debe tener como máximo ${max} caracteres";

  static String m52(size) => "Liberado: ${size}";

  static String m53(count) =>
      "${Intl.plural(count, one: 'hace 1 minuto', other: 'hace ${count} minutos')}";

  static String m54(count) =>
      "${Intl.plural(count, other: 'hace ${count} min')}";

  static String m55(count) =>
      "${Intl.plural(count, one: 'hace 1 mes', other: 'hace ${count} meses')}";

  static String m56(count) => "${Intl.plural(count, other: 'hace ${count} m')}";

  static String m57(code) =>
      "El servidor denegó el acceso (HTTP ${code}). Puede que el enlace haya caducado o que las credenciales sean incorrectas";

  static String m58(code) => "El servidor rechazó la solicitud (HTTP ${code})";

  static String m59(code) =>
      "No se encontró nada en esta dirección (HTTP ${code}). Comprueba que la URL sea correcta";

  static String m60(detail) => "Falló la solicitud de red: ${detail}";

  static String m61(code) =>
      "El servidor tuvo un problema (HTTP ${code}). Inténtalo de nuevo más tarde";

  static String m62(label) => "Aún no hay ningún elemento (${label})";

  static String m63(label, min, max) =>
      "${label} debe estar entre ${min} y ${max}";

  static String m64(label) => "${label} debe ser un número";

  static String m65(label) => "${label} debe estar entre 1024 y 49151";

  static String m66(port) => "Puerto ${port}";

  static String m67(days) =>
      "${Intl.plural(days, one: 'Queda 1 día', other: 'Quedan ${days} días')}";

  static String m68(date, days) =>
      "Vence el ${date}, ${Intl.plural(days, one: 'queda 1 día', other: 'quedan ${days} días')}";

  static String m69(time) => "Actualizado ${time}";

  static String m70(label, profiles) =>
      "${label} sigue en uso en ${profiles}, que dejarán de funcionar correctamente si se elimina. ¿Seguro que quieres eliminarlo?";

  static String m71(count, label) =>
      "${Intl.plural(count, one: '1 proxy', other: '${label} proxies')}";

  static String m72(name, count) => "${name} y otros (${count} proxies)";

  static String m73(removed) =>
      "Se eliminarán estos proxies: ${removed}. Una línea cuyo nombre cambió cuenta como un proxy nuevo, y los perfiles personalizados que mencionen los eliminados los marcarán como ausentes. ¿Aplicar de todos modos?";

  static String m74(removed, added) =>
      "Se eliminarán estos proxies: ${removed}. Se añadirán estos: ${added}. Una línea cuyo nombre cambió cuenta como un proxy nuevo, y los perfiles personalizados que mencionen los eliminados los marcarán como ausentes. ¿Aplicar de todos modos?";

  static String m75(label) =>
      "${label} sigue mencionado por reglas, grupos de proxies, proxies de marcación, DNS o NTP de este perfil, que dejarán de funcionar si se elimina. ¿Seguro que quieres eliminarlo?";

  static String m76(count, label) =>
      "${Intl.plural(count, one: '1 grupo de proxies', other: '${label} grupos de proxies')}";

  static String m77(value, percent) => "Proxy ${value} · ${percent}";

  static String m78(percent, upload, download) =>
      "${percent} · ↑ ${upload} ↓ ${download}";

  static String m79(pick, now) => "Elegiría ${pick} en lugar de ${now}";

  static String m80(group) => "Lo que elegiría en ${group}";

  static String m81(pick) => "Mantendría ${pick}";

  static String m82(number) => "Condición ${number}";

  static String m83(profile) => "«${profile}» quiere comprobar estos sitios";

  static String m84(count) =>
      "${Intl.plural(count, one: '${count} servidor', other: '${count} servidores')}";

  static String m85(profile) => "¿Eliminar «${profile}»?";

  static String m86(requests, used, cap) =>
      "Comprobaciones hoy: ${requests} · ${used} de ${cap}";

  static String m87(condition) => "excepto ${condition}";

  static String m88(country) => "salida ${country}";

  static String m89(member) => "Vía ${member}";

  static String m90(scenario) => "Del escenario «${scenario}»";

  static String m91(title) =>
      "«${title}» no se puede modificar. Tus cambios irán a una copia, y la copia pasará a ser el escenario activo.";

  static String m92(mode) =>
      "Las rutas se aplican en modo regla; ahora la conexión está en modo ${mode}.";

  static String m93(profile) => "Se añadió «${profile}»";

  static String m94(node) => "${node} dejó de funcionar";

  static String m95(from, to) => "Modo ${from} → ${to}";

  static String m96(count) =>
      "${Intl.plural(count, one: '${count} servidor encaja ahora', other: '${count} servidores encajan ahora')}";

  static String m97(ms) => "menos de ${ms} ms";

  static String m98(text) => "${text} en el nombre";

  static String m99(what) => "no ${what}";

  static String m100(provider) => "de ${provider}";

  static String m101(number) => "Paso ${number}";

  static String m102(tag) => "etiqueta ${tag}";

  static String m103(line, text) => "Línea ${line}: ${text}";

  static String m104(check) =>
      "La comprobación ${check} nunca se usa, así que nunca se ejecuta";

  static String m105(hosts) => "Contacta con sitios de terceros: ${hosts}";

  static String m106(group) => "Esta configuración no tiene el grupo ${group}";

  static String m107(group) => "Ningún servidor de ${group} pasa el filtro";

  static String m108(tag) => "La etiqueta ${tag} nunca se usa";

  static String m109(group, tier) =>
      "Ahora ningún servidor de ${group} está en «${tier}»";

  static String m110(tier, after) =>
      "«${tier}» repite la condición de «${after}», así que nada llega a ella";

  static String m111(name, count) => "${name} y ${count} más";

  static String m112(keys) =>
      "Traído; también cambiaste esto, así que se conservaron tus valores: ${keys}";

  static String m113(mode) => "Modo: ${mode}";

  static String m114(node) =>
      "Se queda en ${node}; lo deja solo si falla y vuelve cuando se recupera.";

  static String m115(kind) => "Red: ${kind}";

  static String m116(condition) => "solo ${condition}";

  static String m117(tier) => "puede llegar a «${tier}» tras una comprobación";

  static String m118(node) => "Fijado: ${node}";

  static String m119(error) => "Error de comportamiento: ${error}";

  static String m120(profile) =>
      "No se encontró el comportamiento ${profile}; se usa el predeterminado";

  static String m121(error) =>
      "No se pudo guardar el estado del enrutamiento: ${error}";

  static String m122(tier) => "Cambiado a un servidor de «${tier}»";

  static String m123(from) =>
      "Servidor cambiado; ${from} se omite durante 15 minutos";

  static String m124(from) =>
      "${from} dejó de funcionar; cambiado al mejor de reserva";

  static String m125(from, gain) =>
      "Cambiado desde ${from}: ${gain} ms más rápido";

  static String m126(node) => "El escenario mantiene ${node}";

  static String m127(node) => "${node} no está en este grupo";

  static String m128(limit) =>
      "Límite de cambios alcanzado (${limit} por hora)";

  static String m129(mode) => "No se usa: modo ${mode}";

  static String m130(from) => "${from} ya no está en el grupo de servidores";

  static String m131(kind) =>
      "En pausa mientras la red es «${kind}»: no se comprueba ni se cambia nada";

  static String m132(route, error) =>
      "No se pudo aplicar la ruta «${route}»: ${error}";

  static String m133(route) =>
      "Se omitió la ruta «${route}»: ya existe un grupo con ese nombre.";

  static String m134(route, to) =>
      "La ruta «${route}» envía el tráfico a «${to}», que no está en el perfil.";

  static String m135(node) => "El escenario cambia a ${node}";

  static String m136(node) => "Cambiado al servidor fijado ${node}";

  static String m137(node) => "Ningún servidor funciona; se usa ${node}";

  static String m138(scenario) =>
      "Una ruta del escenario «${scenario}» creó este grupo. Edítala o elimínala allí.";

  static String m139(scenario) =>
      "Ahora el escenario «${scenario}» dirige este grupo.";

  static String m140(count, total) => "${count} de ${total} coinciden";

  static String m141(node) =>
      "Cambiará a ${node} cuando una comprobación lo confirme";

  static String m142(node, gain) =>
      "Cambiará a ${node} si sigue ${gain} ms más rápido";

  static String m143(node, minutes) =>
      "Podrá cambiar a ${node} en ${minutes} min";

  static String m144(name) => "comprobación ${name}";

  static String m145(name) => "diagnóstico de red ${name}";

  static String m146(count) =>
      "${Intl.plural(count, one: 'Elige entre ${count} servidor de este grupo.', other: 'Elige entre los ${count} servidores de este grupo.')}";

  static String m147(count) => "${count} reglas con aciertos";

  static String m148(count, upload, download) =>
      "${count} · ↑ ${upload} ↓ ${download}";

  static String m149(percent, count) =>
      "${percent} del tráfico con aciertos · ${count}";

  static String m150(count, label) =>
      "${Intl.plural(count, one: '1 regla', other: '${label} reglas')}";

  static String m151(appName) => "${appName} (Modo seguro)";

  static String m152(count) =>
      "${Intl.plural(count, one: '1 segundo', other: '${count} segundos')}";

  static String m153(count) => "${count} en vigor";

  static String m154(count) =>
      "${Intl.plural(count, one: '1 problema', other: '${count} problemas')}";

  static String m155(time) => "Comprobado a las ${time}";

  static String m156(count) =>
      "${Intl.plural(count, one: '1 ajuste', other: '${count} ajustes')}";

  static String m157(link) => "No se pudo leer ningún proxy de ${link}";

  static String m158(label) => "${label} debe ser un solo elemento";

  static String m159(value) => "Pico: ${value}";

  static String m160(hour, value) => "Pico ${hour}:00 · ${value}";

  static String m161(value) => "Total: ${value}";

  static String m162(transport) => "Encabezados ${transport}";

  static String m163(label) => "${label} debe ser una URL";

  static String m164(month, day) => "Semana del ${month}/${day}";

  static String m165(count) =>
      "${Intl.plural(count, one: 'hace 1 año', other: 'hace ${count} años')}";

  static String m166(count) =>
      "${Intl.plural(count, other: 'hace ${count} a')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("Acerca de"),
    "accessControl": MessageLookupByLibrary.simpleMessage("Control de acceso"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Solo las apps seleccionadas usan la VPN",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "El control de acceso elige qué apps usan el proxy.",
    ),
    "accessControlDisabledDesc": MessageLookupByLibrary.simpleMessage(
      "El control de acceso de apps está desactivado",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Las apps seleccionadas quedan excluidas de la VPN",
    ),
    "accessControlSelectedCount": m0,
    "account": MessageLookupByLibrary.simpleMessage("Cuenta"),
    "acknowledgments": MessageLookupByLibrary.simpleMessage("Agradecimientos"),
    "acknowledgmentsDesc": MessageLookupByLibrary.simpleMessage(
      "Skyward comenzó como una bifurcación de FlClash de chen08209 y se basa en el núcleo mihomo (Clash.Meta) de MetaCubeX. Ambos se publican bajo GPL-3.0.",
    ),
    "action": MessageLookupByLibrary.simpleMessage("Acción"),
    "actionDelayTest": MessageLookupByLibrary.simpleMessage(
      "Probar la latencia de todos",
    ),
    "actionDirectMode": MessageLookupByLibrary.simpleMessage("Modo directo"),
    "actionGlobalMode": MessageLookupByLibrary.simpleMessage("Modo global"),
    "actionMode": MessageLookupByLibrary.simpleMessage("Cambiar modo"),
    "actionProxy": MessageLookupByLibrary.simpleMessage("Proxy del sistema"),
    "actionRuleMode": MessageLookupByLibrary.simpleMessage("Modo regla"),
    "actionStart": MessageLookupByLibrary.simpleMessage("Iniciar/Detener"),
    "actionTun": MessageLookupByLibrary.simpleMessage("TUN"),
    "actionUpdateProfiles": MessageLookupByLibrary.simpleMessage(
      "Actualizar perfiles",
    ),
    "actionView": MessageLookupByLibrary.simpleMessage("Mostrar/Ocultar"),
    "adBlockDescription": MessageLookupByLibrary.simpleMessage(
      "Bloquea los dominios habituales de publicidad y rastreo, por delante de las reglas de la suscripción.",
    ),
    "add": MessageLookupByLibrary.simpleMessage("Añadir"),
    "addCustomProxy": MessageLookupByLibrary.simpleMessage("Añadir proxy"),
    "addFilters": MessageLookupByLibrary.simpleMessage("Añadir filtros"),
    "addNodes": MessageLookupByLibrary.simpleMessage("Añadir nodos"),
    "addOverrideEntry": MessageLookupByLibrary.simpleMessage(
      "Añadir entrada de sobrescritura",
    ),
    "addProfile": MessageLookupByLibrary.simpleMessage("Añadir perfil"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Añadir grupo de proxies",
    ),
    "addRule": MessageLookupByLibrary.simpleMessage("Añadir regla"),
    "addSettingEntry": MessageLookupByLibrary.simpleMessage("Añadir ajuste"),
    "addSsid": MessageLookupByLibrary.simpleMessage("Añadir SSID"),
    "addToLocalProxies": MessageLookupByLibrary.simpleMessage(
      "Añadir a proxies locales",
    ),
    "addedRules": MessageLookupByLibrary.simpleMessage("Reglas añadidas"),
    "addedToLocalProxies": m1,
    "additionalParameters": MessageLookupByLibrary.simpleMessage(
      "Parámetros adicionales",
    ),
    "additionalPrefix": MessageLookupByLibrary.simpleMessage(
      "Prefijo del nombre",
    ),
    "additionalSuffix": MessageLookupByLibrary.simpleMessage(
      "Sufijo del nombre",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Dirección"),
    "addressHelp": MessageLookupByLibrary.simpleMessage(
      "Dirección del servidor WebDAV",
    ),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "Introduce una dirección WebDAV válida",
    ),
    "advancedConfig": MessageLookupByLibrary.simpleMessage(
      "Configuración avanzada",
    ),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "La configuración avanzada incluye el DNS, las reglas añadidas y los scripts.",
    ),
    "ageEncryptedProfile": MessageLookupByLibrary.simpleMessage(
      "Perfil cifrado",
    ),
    "ageSecretKey": MessageLookupByLibrary.simpleMessage(
      "Clave secreta de age",
    ),
    "ageSecretKeyRequiredTip": MessageLookupByLibrary.simpleMessage(
      "Este perfil está cifrado con age y necesita una clave secreta de age para descifrarse",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("Aceptar"),
    "allReferencedProxies": MessageLookupByLibrary.simpleMessage(
      "Todos los proxies referenciados",
    ),
    "allReferencedProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Todos los proveedores de proxies referenciados",
    ),
    "allowBypass": MessageLookupByLibrary.simpleMessage(
      "Permitir que las apps eludan la VPN",
    ),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "Permite que las aplicaciones levanten su propia VPN y eviten esta.",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("Permitir acceso LAN"),
    "allowedIps": MessageLookupByLibrary.simpleMessage("IP permitidas"),
    "alreadyInLocalProxies": m2,
    "answers": MessageLookupByLibrary.simpleMessage("Respuestas"),
    "app": MessageLookupByLibrary.simpleMessage("App"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage(
      "Control de acceso de apps",
    ),
    "appIconDesign": MessageLookupByLibrary.simpleMessage(
      "Diseño del icono de la app",
    ),
    "appProxiesEmpty": MessageLookupByLibrary.simpleMessage(
      "No hay proxies locales",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage(
      "Añadir DNS del sistema",
    ),
    "authentication": MessageLookupByLibrary.simpleMessage("Autenticación"),
    "authenticationDesc": MessageLookupByLibrary.simpleMessage(
      "La autenticación pide usuario y contraseña en el puerto del proxy local.",
    ),
    "authenticationSystemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "El proxy del sistema no se aplica mientras la autenticación esté activada.",
    ),
    "authorize": MessageLookupByLibrary.simpleMessage("Autorizar"),
    "authorized": MessageLookupByLibrary.simpleMessage("Autorizado"),
    "auto": MessageLookupByLibrary.simpleMessage("Automático"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage(
      "Buscar actualizaciones automáticamente",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage(
      "Cerrar conexiones automáticamente",
    ),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Cerrar conexiones automáticamente corta las conexiones abiertas al cambiar de proxy.",
    ),
    "autoInclude": MessageLookupByLibrary.simpleMessage(
      "Incluir automáticamente",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("Inicio automático"),
    "autoRun": MessageLookupByLibrary.simpleMessage("Ejecución automática"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "La ejecución automática inicia el proxy al abrir la app.",
    ),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage(
      "Configurar DNS del sistema automáticamente",
    ),
    "autoUpdate": MessageLookupByLibrary.simpleMessage(
      "Actualización automática",
    ),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Intervalo de actualización automática",
    ),
    "back": MessageLookupByLibrary.simpleMessage("Atrás"),
    "backgroundBlur": MessageLookupByLibrary.simpleMessage(
      "Desenfoque de fondo",
    ),
    "backup": MessageLookupByLibrary.simpleMessage("Copia de seguridad"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage(
      "Copia de seguridad y restauración",
    ),
    "backupFromNewerVersion": MessageLookupByLibrary.simpleMessage(
      "Esta copia de seguridad procede de una versión más reciente de la app. Actualiza la app antes de restaurarla",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage(
      "Copia de seguridad completada",
    ),
    "basicInfo": MessageLookupByLibrary.simpleMessage("Información básica"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage(
      "Estrategias básicas",
    ),
    "batchAdd": MessageLookupByLibrary.simpleMessage("Añadir en lote"),
    "batchImport": MessageLookupByLibrary.simpleMessage("Importar en lote"),
    "batchLinkInputTip": MessageLookupByLibrary.simpleMessage(
      "Un enlace por línea",
    ),
    "batchListInputTip": MessageLookupByLibrary.simpleMessage(
      "Un elemento por línea, o separados por comas",
    ),
    "batchMapInputTip": MessageLookupByLibrary.simpleMessage(
      "Una entrada por línea: clave, un espacio y el valor",
    ),
    "batchPreviewTip": m3,
    "batchUrlInputTip": MessageLookupByLibrary.simpleMessage(
      "Una URL por línea",
    ),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "Ignorar la optimización de batería mantiene la app en ejecución en segundo plano.",
    ),
    "bind": MessageLookupByLibrary.simpleMessage("Vincular"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("Modo lista negra"),
    "blockConnection": MessageLookupByLibrary.simpleMessage(
      "Bloquear conexión",
    ),
    "brightness": MessageLookupByLibrary.simpleMessage("Brillo"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("Dominios excluidos"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Los dominios excluidos solo se aplican mientras el proxy del sistema esté activado.",
    ),
    "bypassPrivateRoute": MessageLookupByLibrary.simpleMessage(
      "Omitir direcciones privadas",
    ),
    "bypassPrivateRouteDesc": MessageLookupByLibrary.simpleMessage(
      "Con Omitir direcciones privadas activado, las direcciones de LAN, loopback y multidifusión no pasan por TUN.",
    ),
    "cache": MessageLookupByLibrary.simpleMessage("Caché"),
    "cacheAlgorithm": MessageLookupByLibrary.simpleMessage(
      "Algoritmo de caché",
    ),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "La caché está dañada. ¿Borrarla?",
    ),
    "cacheMaxSize": MessageLookupByLibrary.simpleMessage("Tamaño de caché"),
    "cameraPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Permite el acceso a la cámara en los ajustes del sistema para escanear códigos QR, o elige una imagen de código QR del álbum.",
    ),
    "cameraPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Se requiere permiso de cámara",
    ),
    "cameraUnavailable": MessageLookupByLibrary.simpleMessage(
      "Cámara no disponible",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage(
      "Deseleccionar todo",
    ),
    "cannotSave": MessageLookupByLibrary.simpleMessage("No se puede guardar"),
    "capsule": MessageLookupByLibrary.simpleMessage("Cápsula"),
    "changeProxyFailedTip": MessageLookupByLibrary.simpleMessage(
      "No se pudo cambiar de proxy; se ha restaurado la selección anterior",
    ),
    "changelogBreaking": MessageLookupByLibrary.simpleMessage(
      "Cambios incompatibles",
    ),
    "changelogFeatures": MessageLookupByLibrary.simpleMessage("Novedades"),
    "changelogFixes": MessageLookupByLibrary.simpleMessage("Correcciones"),
    "changelogPerformance": MessageLookupByLibrary.simpleMessage("Rendimiento"),
    "changelogReverts": MessageLookupByLibrary.simpleMessage("Reversiones"),
    "checkCertificate": MessageLookupByLibrary.simpleMessage(
      "Verificar certificados TLS",
    ),
    "checkCertificateDesc": MessageLookupByLibrary.simpleMessage(
      "Con la verificación TLS desactivada, las suscripciones y las copias de seguridad quedan expuestas a ataques de intermediario.",
    ),
    "checkUpdate": MessageLookupByLibrary.simpleMessage(
      "Buscar actualizaciones",
    ),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "La app ya está actualizada",
    ),
    "cipher": MessageLookupByLibrary.simpleMessage("Cifrado"),
    "clearCache": MessageLookupByLibrary.simpleMessage("Borrar caché"),
    "clearData": MessageLookupByLibrary.simpleMessage("Borrar datos"),
    "clearDataAndExitTip": MessageLookupByLibrary.simpleMessage(
      "Esto elimina todos los perfiles, ajustes y datos locales, y luego cierra la app. Ábrela de nuevo para empezar de cero.",
    ),
    "clearDataFailed": m4,
    "clearDnsCache": MessageLookupByLibrary.simpleMessage(
      "Borrar la caché DNS",
    ),
    "clearDnsCacheFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo borrar la caché DNS",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Borrar búsqueda"),
    "clientFingerprint": MessageLookupByLibrary.simpleMessage(
      "Huella del cliente",
    ),
    "clipboardExport": MessageLookupByLibrary.simpleMessage(
      "Exportar al portapapeles",
    ),
    "clipboardImport": MessageLookupByLibrary.simpleMessage(
      "Importar desde el portapapeles",
    ),
    "clipboardWriteFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo copiar al portapapeles. Puede que la selección sea demasiado grande",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Cerrar"),
    "closeConnections": MessageLookupByLibrary.simpleMessage(
      "Cerrar conexiones",
    ),
    "color": MessageLookupByLibrary.simpleMessage("Color"),
    "colorStyle": MessageLookupByLibrary.simpleMessage("Estilo de color"),
    "colorsSection": MessageLookupByLibrary.simpleMessage("Colores"),
    "columns": MessageLookupByLibrary.simpleMessage("Columnas"),
    "compact": MessageLookupByLibrary.simpleMessage("Compacto"),
    "compatible": MessageLookupByLibrary.simpleMessage(
      "Modo de compatibilidad",
    ),
    "configuration": MessageLookupByLibrary.simpleMessage("Configuration"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres borrar todos los datos?",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres eliminar este grupo de proxies?",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres salir de la ventana actual?",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres forzar el fallo del núcleo?",
    ),
    "congestionControl": MessageLookupByLibrary.simpleMessage(
      "Control de congestión",
    ),
    "congestionController": MessageLookupByLibrary.simpleMessage(
      "Control de congestión TCP",
    ),
    "congestionControllerDesc": MessageLookupByLibrary.simpleMessage(
      "El control de congestión TCP solo funciona con la pila mips.",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("Conectado"),
    "connecting": MessageLookupByLibrary.simpleMessage("Conectando…"),
    "connection": MessageLookupByLibrary.simpleMessage("Conexión"),
    "connectionCount": m5,
    "connectionStats": MessageLookupByLibrary.simpleMessage(
      "Estadísticas de conexión",
    ),
    "connectionStatsDesc": MessageLookupByLibrary.simpleMessage(
      "Conexiones activas, solicitudes recientes y consultas DNS",
    ),
    "connections": MessageLookupByLibrary.simpleMessage("Conexiones"),
    "connectivity": MessageLookupByLibrary.simpleMessage("Conectividad: "),
    "content": MessageLookupByLibrary.simpleMessage("Contenido"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage(
      "El contenido no puede estar vacío",
    ),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "Controlar las reglas añadidas globales",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("Copiar"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage(
      "Copiar variables de entorno",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Copiar enlace"),
    "copySuccess": MessageLookupByLibrary.simpleMessage(
      "Copiado correctamente",
    ),
    "core": MessageLookupByLibrary.simpleMessage("Núcleo"),
    "coreBlockedByPolicyTip": m6,
    "coreBlockedBySmartAppControlTip": MessageLookupByLibrary.simpleMessage(
      "Smart App Control de Windows bloqueó SkywardCore.exe porque no está firmado. Abre Seguridad de Windows → Control de aplicaciones y navegador → Configuración de Smart App Control, elige Desactivado y vuelve a iniciar Skyward. Smart App Control no se puede volver a activar sin reinstalar Windows.",
    ),
    "coreStatus": MessageLookupByLibrary.simpleMessage("Estado del núcleo"),
    "coreVersion": MessageLookupByLibrary.simpleMessage("Versión del núcleo"),
    "country": MessageLookupByLibrary.simpleMessage("Región"),
    "crashDetected": MessageLookupByLibrary.simpleMessage("Fallo detectado"),
    "crashDetectedTip": m7,
    "crashTest": MessageLookupByLibrary.simpleMessage("Prueba de fallo"),
    "create": MessageLookupByLibrary.simpleMessage("Crear"),
    "createProfileFromUrlTip": m8,
    "creationTime": MessageLookupByLibrary.simpleMessage("Fecha de creación"),
    "currentOutboundDesc": MessageLookupByLibrary.simpleMessage(
      "Contiene el botón de inicio y no se puede quitar",
    ),
    "currentVersion": MessageLookupByLibrary.simpleMessage("Versión actual"),
    "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
    "customColor": MessageLookupByLibrary.simpleMessage("Color personalizado"),
    "customImportDroppedSubRules": m9,
    "customIssueCoreRejected": m10,
    "customIssueDialerLoop": m11,
    "customIssueDuplicateName": m12,
    "customIssueEmptyName": MessageLookupByLibrary.simpleMessage(
      "El nombre está vacío",
    ),
    "customIssueGroupLoop": m13,
    "customIssueInvalidEmptyFallback": m14,
    "customIssueInvalidFilter": m15,
    "customIssueMissingDialer": m16,
    "customIssueMissingProviders": m17,
    "customIssueMissingProxies": m18,
    "customIssueNoProxySource": MessageLookupByLibrary.simpleMessage(
      "No hay proxies ni proveedores de proxies seleccionados, por lo que el núcleo rechaza este grupo",
    ),
    "customIssueReservedName": m19,
    "customIssuesSummary": m20,
    "customProfile": MessageLookupByLibrary.simpleMessage("Personalizado"),
    "customProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Crea grupos de proxies y reglas a partir de los proxies de la app y de otros perfiles",
    ),
    "customProfileResources": MessageLookupByLibrary.simpleMessage(
      "Recursos de perfil personalizado",
    ),
    "customProfileResourcesDesc": MessageLookupByLibrary.simpleMessage(
      "Los recursos de perfil personalizado son los proxies, proveedores de reglas, filtros y conjuntos de iconos que añades tú para usarlos en perfiles personalizados.",
    ),
    "cut": MessageLookupByLibrary.simpleMessage("Cortar"),
    "dark": MessageLookupByLibrary.simpleMessage("Oscuro"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Panel"),
    "dashboardAddableSection": MessageLookupByLibrary.simpleMessage(
      "Disponibles para añadir",
    ),
    "dashboardSplitStack": MessageLookupByLibrary.simpleMessage(
      "Separar la pila",
    ),
    "data": MessageLookupByLibrary.simpleMessage("Data"),
    "database": MessageLookupByLibrary.simpleMessage("Base de datos"),
    "databaseWriteFailedTip": MessageLookupByLibrary.simpleMessage(
      "No se pudo guardar el cambio; se ha revertido",
    ),
    "day": MessageLookupByLibrary.simpleMessage("Día"),
    "daysAgo": m21,
    "daysAgoShort": m22,
    "defaultSelected": MessageLookupByLibrary.simpleMessage(
      "Selección predeterminada",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("Predeterminado"),
    "definitionNotMap": MessageLookupByLibrary.simpleMessage(
      "La configuración debe ser un mapa YAML con un nombre y un tipo",
    ),
    "delay": MessageLookupByLibrary.simpleMessage("Latencia"),
    "delayFailed": MessageLookupByLibrary.simpleMessage("Fallido"),
    "delayTest": MessageLookupByLibrary.simpleMessage("Prueba de latencia"),
    "delayTestTimeout": MessageLookupByLibrary.simpleMessage(
      "Tiempo de espera de la prueba de latencia",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
    "deleteMultipTip": m23,
    "deleteTip": m24,
    "desc": MessageLookupByLibrary.simpleMessage(
      "Un cliente proxy multiplataforma basado en ClashMeta, sencillo de usar, de código abierto y sin anuncios.",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("Destino"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage(
      "GeoIP de destino",
    ),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage(
      "ASN de la IP de destino",
    ),
    "details": m25,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "Depende de una API de terceros; solo con fines informativos",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("Modo desarrollador"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "El modo desarrollador está activado.",
    ),
    "diagnostics": MessageLookupByLibrary.simpleMessage("Diagnóstico"),
    "dialerProxy": MessageLookupByLibrary.simpleMessage("Proxy de marcación"),
    "dialerProxyDesc": MessageLookupByLibrary.simpleMessage(
      "El proxy de marcación es la salida que se usa para llegar al servidor NTP.",
    ),
    "dialerProxyLoopStopped": m26,
    "direct": MessageLookupByLibrary.simpleMessage("Directo"),
    "directShare": m27,
    "disableIcmpForwarding": MessageLookupByLibrary.simpleMessage(
      "Desactivar reenvío ICMP",
    ),
    "disableIcmpForwardingDesc": MessageLookupByLibrary.simpleMessage(
      "Con el reenvío ICMP desactivado, TUN responde él mismo al ping, por lo que ping ya no muestra la latencia real.",
    ),
    "disableKeepAlive": MessageLookupByLibrary.simpleMessage(
      "Desactivar keep-alive TCP",
    ),
    "disableUDP": MessageLookupByLibrary.simpleMessage("Desactivar UDP"),
    "disabled": MessageLookupByLibrary.simpleMessage("Desactivado"),
    "discardChanges": MessageLookupByLibrary.simpleMessage(
      "¿Descartar los cambios?",
    ),
    "disclaimer": MessageLookupByLibrary.simpleMessage("Aviso legal"),
    "disclaimerAcceptContent": MessageLookupByLibrary.simpleMessage(
      "Al instalar, copiar o usar el Software, se considera que has leído y aceptado esta declaración en su totalidad. Si no estás de acuerdo con alguno de sus términos, deja de usar el Software y desinstálalo de inmediato.",
    ),
    "disclaimerAcceptTitle": MessageLookupByLibrary.simpleMessage("Aceptación"),
    "disclaimerAcknowledgeLabel": MessageLookupByLibrary.simpleMessage(
      "He leído y entiendo esta declaración",
    ),
    "disclaimerAcknowledgeTip": MessageLookupByLibrary.simpleMessage(
      "Para confirmar que lo entiendes, lee la siguiente declaración y marca la casilla de abajo:",
    ),
    "disclaimerAcknowledgeTitle": MessageLookupByLibrary.simpleMessage(
      "Confirma la declaración",
    ),
    "disclaimerChangesContent": MessageLookupByLibrary.simpleMessage(
      "Los desarrolladores pueden revisar esta declaración con cualquier versión, y la revisión entra en vigor cuando se publique dicha versión. Seguir usando el Software después de actualizar implica que aceptas la declaración revisada.",
    ),
    "disclaimerChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Cambios en esta declaración",
    ),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "Antes de usar Skyward (“el Software”), lee con atención esta declaración y asegúrate de entenderla por completo. Pulsar “Aceptar” significa que has leído, comprendido y aceptado todos los términos siguientes. Si no estás de acuerdo, pulsa “Salir” y deja de usar el Software.",
    ),
    "disclaimerLiabilityContent": MessageLookupByLibrary.simpleMessage(
      "En la máxima medida permitida por la ley aplicable, ni los desarrolladores ni ningún colaborador serán responsables de ningún daño directo, indirecto, incidental, especial, punitivo o emergente derivado del uso o de la imposibilidad de usar el Software, incluidos, entre otros, la pérdida de datos, los daños al dispositivo, los fallos de red, la interrupción de la actividad, el lucro cesante o cualquier disputa legal resultante, incluso si se les hubiera advertido de la posibilidad de tales daños.",
    ),
    "disclaimerLiabilityTitle": MessageLookupByLibrary.simpleMessage(
      "Limitación de responsabilidad",
    ),
    "disclaimerLicenseContent": MessageLookupByLibrary.simpleMessage(
      "El Software es de código abierto bajo la licencia GPL-3.0. Puedes usarlo, modificarlo y distribuirlo libremente siempre que cumplas dicha licencia, que exige que las obras derivadas se publiquen también bajo GPL-3.0 y que se conserven los avisos de derechos de autor originales.\n\nLos componentes de terceros del Software, incluido el núcleo Clash.Meta, siguen sus propias licencias. Los autores originales no se hacen responsables de ningún problema derivado de versiones modificadas o redistribuidas.",
    ),
    "disclaimerLicenseTitle": MessageLookupByLibrary.simpleMessage(
      "Licencia de código abierto",
    ),
    "disclaimerNoServiceStatement": MessageLookupByLibrary.simpleMessage(
      "El Software en sí no proporciona ningún servidor proxy, nodo, suscripción ni servicio de acceso a la red, y no mantiene ninguna relación de asociación, representación ni garantía con ningún proveedor de dichos servicios.",
    ),
    "disclaimerPrivacyContent": MessageLookupByLibrary.simpleMessage(
      "El Software no recopila ni sube tus URL de suscripción, los detalles de los nodos, el contenido de las configuraciones, los sitios web visitados, los registros de conexión, el contenido del tráfico ni los registros. Estos datos permanecen en tu dispositivo y los desarrolladores no tienen acceso a ellos.\n\nEl Software solo accede a la red cuando usas una función que lo necesita, como obtener la URL de suscripción que indicaste al actualizar un perfil o conectarse a GitHub al buscar actualizaciones.\n\nEl Software no incluye ningún servicio de analítica ni de informes de fallos en ninguna plataforma.",
    ),
    "disclaimerPrivacyTitle": MessageLookupByLibrary.simpleMessage(
      "Recopilación de datos y privacidad",
    ),
    "disclaimerResponsibilityContent": MessageLookupByLibrary.simpleMessage(
      "Eres responsable de asegurarte de que el uso del Software sea legal donde vives, y asumes tú solo la responsabilidad legal de todo lo que hagas con él y de sus consecuencias.\n\nLas suscripciones, los nodos y las configuraciones que importas son decisión tuya. Que su origen sea legal, su contenido seguro y su servicio fiable es un asunto entre tú y sus proveedores.",
    ),
    "disclaimerResponsibilityTitle": MessageLookupByLibrary.simpleMessage(
      "Tu responsabilidad",
    ),
    "disclaimerRestateHint": MessageLookupByLibrary.simpleMessage(
      "Escribe la declaración anterior",
    ),
    "disclaimerRestateMismatch": MessageLookupByLibrary.simpleMessage(
      "No coincide con la declaración",
    ),
    "disclaimerRestateTip": MessageLookupByLibrary.simpleMessage(
      "Para confirmar que lo entiendes, escribe la siguiente declaración completa en el campo de abajo:",
    ),
    "disclaimerRestateTitle": MessageLookupByLibrary.simpleMessage(
      "Repite la declaración",
    ),
    "disclaimerSoftwareContent": MessageLookupByLibrary.simpleMessage(
      "El Software es un cliente proxy de red de código abierto basado en el núcleo Clash.Meta (mihomo). Solo ofrece herramientas locales como la gestión de configuración, el enrutamiento basado en reglas y el reenvío de tráfico.",
    ),
    "disclaimerSoftwareTitle": MessageLookupByLibrary.simpleMessage(
      "Naturaleza del software",
    ),
    "disclaimerThirdPartyContent": MessageLookupByLibrary.simpleMessage(
      "Los enlaces de suscripción, los archivos de configuración, los conjuntos de reglas, los scripts, los recursos externos y los enlaces externos los proporcionan terceros. Los desarrolladores no pueden revisar ni garantizar, ni lo hacen, su legalidad, exactitud, seguridad o disponibilidad.\n\nCualquier fuga de datos, pérdida económica, bloqueo de cuenta u otra pérdida causada por contenido de terceros debe resolverse entre tú y el tercero; los desarrolladores no asumen ninguna responsabilidad por ello.",
    ),
    "disclaimerThirdPartyTitle": MessageLookupByLibrary.simpleMessage(
      "Contenido de terceros",
    ),
    "disclaimerUsageContent": MessageLookupByLibrary.simpleMessage(
      "El Software está destinado únicamente a usos no comerciales, como el aprendizaje, el intercambio y la investigación técnica. Queda estrictamente prohibido usarlo con cualquier fin comercial, incluidos, entre otros, la distribución de pago, la venta en paquete, su uso como parte de un servicio comercial o hacer negocio en nombre del Software. Cualquier actividad comercial no guarda relación con el Software ni con sus desarrolladores.\n\nQueda estrictamente prohibido usar el Software para cualquier fin que infrinja las leyes y normativas de tu país o región, incluidos, entre otros, eludir restricciones de acceso a la red impuestas legalmente, difundir contenido ilegal, lanzar ataques a la red o vulnerar los derechos legítimos de otras personas.",
    ),
    "disclaimerUsageTitle": MessageLookupByLibrary.simpleMessage(
      "Restricciones de uso",
    ),
    "disclaimerWarrantyContent": MessageLookupByLibrary.simpleMessage(
      "El Software se proporciona “tal cual” y “según disponibilidad”, sin garantía de ningún tipo, expresa o implícita, incluidas, entre otras, las garantías de comerciabilidad, idoneidad para un fin concreto, no infracción, disponibilidad ininterrumpida, ausencia de errores o ausencia de vulnerabilidades de seguridad.\n\nLos desarrolladores no garantizan que el Software satisfaga tus necesidades ni que funcione sin interrupciones ni errores.",
    ),
    "disclaimerWarrantyTitle": MessageLookupByLibrary.simpleMessage(
      "Sin garantía",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("Desconectado"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "Nueva versión disponible",
    ),
    "dnsCacheCleared": MessageLookupByLibrary.simpleMessage(
      "Caché DNS borrada",
    ),
    "dnsHijackDesc": MessageLookupByLibrary.simpleMessage(
      "Sin esta entrada, TUN secuestra todas las consultas DNS al puerto 53 (any:53).",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("Secuestro de DNS"),
    "dnsLeakAdvice": MessageLookupByLibrary.simpleMessage(
      "Para lo que falle, active la VPN y el secuestro de DNS en «Avanzado → Red», desactive el DNS privado en los ajustes del sistema y sustituya los servidores en claro por DoH en las sustituciones de DNS.",
    ),
    "dnsLeakCheck": MessageLookupByLibrary.simpleMessage(
      "Comprobación de fugas DNS",
    ),
    "dnsLeakDirect": MessageLookupByLibrary.simpleMessage(
      "Fuga por el puerto 53",
    ),
    "dnsLeakDirectBad": MessageLookupByLibrary.simpleMessage(
      "Una consulta directa a 223.5.5.5 devolvió una dirección real, así que el DNS en claro sigue saliendo",
    ),
    "dnsLeakEncrypted": MessageLookupByLibrary.simpleMessage(
      "Resolución cifrada",
    ),
    "dnsLeakEncryptedBad": MessageLookupByLibrary.simpleMessage(
      "El servidor superior es DNS en claro, así que cada consulta se puede leer de camino",
    ),
    "dnsLeakExternal": MessageLookupByLibrary.simpleMessage(
      "Verificar en el navegador",
    ),
    "dnsLeakFail": MessageLookupByLibrary.simpleMessage("Fallo"),
    "dnsLeakFakeIp": MessageLookupByLibrary.simpleMessage("Dirección falsa"),
    "dnsLeakFakeIpBad": MessageLookupByLibrary.simpleMessage(
      "La respuesta no es 198.18.x.x, así que esta consulta no la atendió el fake-IP",
    ),
    "dnsLeakHijack": MessageLookupByLibrary.simpleMessage("Secuestro de DNS"),
    "dnsLeakHijackBad": MessageLookupByLibrary.simpleMessage(
      "any:53 no está definido, así que las consultas a otros resolutores no se capturan",
    ),
    "dnsLeakIpv6": MessageLookupByLibrary.simpleMessage("IPv6"),
    "dnsLeakIpv6Bad": MessageLookupByLibrary.simpleMessage(
      "Este equipo tiene una dirección IPv6 global y el tráfico v6 puede saltarse una captura solo IPv4",
    ),
    "dnsLeakPass": MessageLookupByLibrary.simpleMessage("Correcto"),
    "dnsLeakRerun": MessageLookupByLibrary.simpleMessage("Comprobar de nuevo"),
    "dnsLeakRunning": MessageLookupByLibrary.simpleMessage("Comprobando"),
    "dnsLeakTunnel": MessageLookupByLibrary.simpleMessage(
      "Captura del tráfico",
    ),
    "dnsLeakTunnelBad": MessageLookupByLibrary.simpleMessage(
      "El núcleo está detenido o la VPN está apagada, así que las apps resuelven los nombres por su cuenta",
    ),
    "dnsLeakUnknown": MessageLookupByLibrary.simpleMessage("Sin determinar"),
    "dnsLeakWarn": MessageLookupByLibrary.simpleMessage("Atención"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("Modo DNS"),
    "dnsOverride": MessageLookupByLibrary.simpleMessage("Sobrescritura de DNS"),
    "dnsOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Las entradas añadidas aquí sustituyen el DNS de todos los perfiles de URL y de archivo; lo que no añadas conserva el ajuste del propio perfil. Los perfiles personalizados definen su DNS en su contenido.",
    ),
    "dnsPolicyReplaced": MessageLookupByLibrary.simpleMessage(
      "Este perfil tiene sus propias políticas de DNS; las entradas de aquí las reemplazan por completo, así que las reglas que no estén aquí dejan de aplicarse.",
    ),
    "dnsQueries": MessageLookupByLibrary.simpleMessage("Consultas DNS"),
    "dockScale": MessageLookupByLibrary.simpleMessage(
      "Tamaño de la barra inferior",
    ),
    "docked": MessageLookupByLibrary.simpleMessage("Fija"),
    "domain": MessageLookupByLibrary.simpleMessage("Dominio"),
    "done": MessageLookupByLibrary.simpleMessage("Hecho"),
    "download": MessageLookupByLibrary.simpleMessage("Descarga"),
    "downloadBandwidth": MessageLookupByLibrary.simpleMessage(
      "Ancho de banda de descarga",
    ),
    "duration": MessageLookupByLibrary.simpleMessage("Duración"),
    "durationDays": m28,
    "durationHours": m29,
    "durationMinutes": m30,
    "edit": MessageLookupByLibrary.simpleMessage("Editar"),
    "editDashboard": MessageLookupByLibrary.simpleMessage("Editar panel"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage(
      "Editar reglas globales",
    ),
    "editProxy": MessageLookupByLibrary.simpleMessage("Editar proxy"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Editar grupo de proxies",
    ),
    "editRule": MessageLookupByLibrary.simpleMessage("Editar regla"),
    "editSsid": MessageLookupByLibrary.simpleMessage("Editar SSID"),
    "editorUnavailable": MessageLookupByLibrary.simpleMessage(
      "Editor no disponible",
    ),
    "elapsed": MessageLookupByLibrary.simpleMessage("Tardó"),
    "emptyFallback": MessageLookupByLibrary.simpleMessage(
      "Respaldo si está vacío",
    ),
    "emptyTip": m31,
    "en": MessageLookupByLibrary.simpleMessage("Inglés"),
    "enabled": MessageLookupByLibrary.simpleMessage("Activado"),
    "entries": MessageLookupByLibrary.simpleMessage(" entradas"),
    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "errorDetails": MessageLookupByLibrary.simpleMessage("Detalles del error"),
    "es": MessageLookupByLibrary.simpleMessage("Español"),
    "exclude": MessageLookupByLibrary.simpleMessage(
      "Ocultar de aplicaciones recientes",
    ),
    "excludeDstPort": MessageLookupByLibrary.simpleMessage(
      "Puertos de destino excluidos",
    ),
    "excludeDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "El tráfico hacia los puertos de destino excluidos no pasa por TUN.",
    ),
    "excludeFilter": MessageLookupByLibrary.simpleMessage(
      "Filtro de exclusión",
    ),
    "excludeInterface": MessageLookupByLibrary.simpleMessage(
      "Interfaces excluidas",
    ),
    "excludeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "El tráfico que llega por las interfaces excluidas, como docker0, no pasa por TUN.",
    ),
    "excludeSrcPort": MessageLookupByLibrary.simpleMessage(
      "Puertos de origen excluidos",
    ),
    "excludeSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "El tráfico desde los puertos de origen excluidos no pasa por TUN.",
    ),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Excluir SSID"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "Al conectarte a una red Wi-Fi con un SSID excluido, el estado de ejecución de la app cambia automáticamente.",
    ),
    "excludeUid": MessageLookupByLibrary.simpleMessage(
      "ID de usuario excluidos",
    ),
    "excludeUidDesc": MessageLookupByLibrary.simpleMessage(
      "El tráfico de los procesos de los ID de usuario excluidos no pasa por TUN.",
    ),
    "existsTip": m32,
    "exit": MessageLookupByLibrary.simpleMessage("Salir"),
    "exitFullScreen": MessageLookupByLibrary.simpleMessage(
      "Salir de pantalla completa",
    ),
    "exitNodes": MessageLookupByLibrary.simpleMessage("Nodos de salida"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("Estado esperado"),
    "expireTime": MessageLookupByLibrary.simpleMessage("Fecha de vencimiento"),
    "exportFile": MessageLookupByLibrary.simpleMessage("Exportar archivo"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Exportar registros"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage(
      "Exportación completada",
    ),
    "extend": MessageLookupByLibrary.simpleMessage("Extensión"),
    "extendMode": MessageLookupByLibrary.simpleMessage("Modo de extensión"),
    "extendScript": MessageLookupByLibrary.simpleMessage("Script de extensión"),
    "externalController": MessageLookupByLibrary.simpleMessage(
      "Controlador externo",
    ),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "El controlador externo permite controlar el núcleo en el puerto 9090.",
    ),
    "externalControllerSecret": MessageLookupByLibrary.simpleMessage(
      "Clave del controlador externo",
    ),
    "externalLink": MessageLookupByLibrary.simpleMessage("Enlace externo"),
    "extraLarge": MessageLookupByLibrary.simpleMessage("Muy grande"),
    "fade": MessageLookupByLibrary.simpleMessage("Fundido"),
    "failedCount": m33,
    "failedItem": m34,
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Filtro Fake-IP"),
    "fakeipFilterMode": MessageLookupByLibrary.simpleMessage(
      "Modo de filtro Fake-IP",
    ),
    "fakeipFilterModeDesc": MessageLookupByLibrary.simpleMessage(
      "En el modo de filtro Fake-IP, la lista negra excluye las coincidencias, la lista blanca aplica Fake-IP solo a las coincidencias y rule coincide según las reglas.",
    ),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Rango Fake-IP"),
    "fakeipRange6": MessageLookupByLibrary.simpleMessage(
      "Rango Fake-IP (IPv6)",
    ),
    "fakeipTtl": MessageLookupByLibrary.simpleMessage("TTL de Fake-IP"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage(
      "Filtro de respaldo",
    ),
    "file": MessageLookupByLibrary.simpleMessage("Archivo"),
    "fileDesc": MessageLookupByLibrary.simpleMessage(
      "Sube un archivo de perfil directamente",
    ),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "El archivo se ha modificado. ¿Guardar los cambios?",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("Filtro"),
    "filters": MessageLookupByLibrary.simpleMessage("Filtros"),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("Buscar proceso"),
    "floating": MessageLookupByLibrary.simpleMessage("Flotante"),
    "followProfile": MessageLookupByLibrary.simpleMessage("Seguir perfil"),
    "followSystem": MessageLookupByLibrary.simpleMessage("Seguir el sistema"),
    "fontFamily": MessageLookupByLibrary.simpleMessage("Familia de fuente"),
    "fontSize": MessageLookupByLibrary.simpleMessage("Tamaño"),
    "forceDnsMapping": MessageLookupByLibrary.simpleMessage("Forzar mapeo DNS"),
    "forceDnsMappingDesc": MessageLookupByLibrary.simpleMessage(
      "Forzar mapeo DNS también analiza las conexiones cuyo dominio provino de un mapeo DNS.",
    ),
    "forceDomain": MessageLookupByLibrary.simpleMessage("Forzar dominios"),
    "forceDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Los dominios forzados también se analizan; las demás conexiones que ya tienen dominio se dejan como están.",
    ),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres forzar el reinicio del núcleo?",
    ),
    "fr": MessageLookupByLibrary.simpleMessage("Francés"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geo"),
    "geoSkipped": m35,
    "geoUpdated": m36,
    "geodataLoader": MessageLookupByLibrary.simpleMessage(
      "Modo geo de poca memoria",
    ),
    "global": MessageLookupByLibrary.simpleMessage("Global"),
    "go": MessageLookupByLibrary.simpleMessage("Ir"),
    "goDownload": MessageLookupByLibrary.simpleMessage("Descargar"),
    "goToConfigureAddedRules": MessageLookupByLibrary.simpleMessage(
      "Ir a la configuración de las reglas añadidas",
    ),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage(
      "Ir a la configuración del script",
    ),
    "grid": MessageLookupByLibrary.simpleMessage("Cuadrícula"),
    "groupCount": m37,
    "groupCountUnit": MessageLookupByLibrary.simpleMessage("grupos"),
    "groupTimeoutCount": m38,
    "hapticFeedback": MessageLookupByLibrary.simpleMessage("Respuesta háptica"),
    "hapticFeedbackDesc": MessageLookupByLibrary.simpleMessage(
      "Vibración leve al pulsar en la aplicación.",
    ),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage(
      "¿Guardar los cambios en la caché?",
    ),
    "hashByInUser": MessageLookupByLibrary.simpleMessage(
      "Hash por usuario de entrada",
    ),
    "healthCheck": MessageLookupByLibrary.simpleMessage(
      "Comprobación de estado",
    ),
    "helperCorruptTip": MessageLookupByLibrary.simpleMessage(
      "El servicio auxiliar (Helper) no está disponible; no se puede activar el modo TUN. Reinstala Skyward para restaurarlo.",
    ),
    "hex": MessageLookupByLibrary.simpleMessage("Hex"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("Ocultar de la lista"),
    "hideIp": MessageLookupByLibrary.simpleMessage("Ocultar IP"),
    "hideLabelOnScroll": MessageLookupByLibrary.simpleMessage(
      "Ocultar las etiquetas al desplazarse",
    ),
    "hideLabelOnScrollDesc": MessageLookupByLibrary.simpleMessage(
      "Al desplazarse por la página, la barra inferior conserva solo sus iconos",
    ),
    "hideNotification": MessageLookupByLibrary.simpleMessage(
      "Ocultar la notificación permanente",
    ),
    "hideNotificationTip": MessageLookupByLibrary.simpleMessage(
      "El proxy sigue funcionando. Android exige una notificación de servicio en primer plano, así que esta pasa a ser silenciosa y no aparece en la pantalla de bloqueo; los ajustes del sistema pueden desactivarla del todo",
    ),
    "hidePassword": MessageLookupByLibrary.simpleMessage("Ocultar contraseña"),
    "hideTimeoutProxies": MessageLookupByLibrary.simpleMessage(
      "Ocultar proxies sin respuesta",
    ),
    "hitsUnit": MessageLookupByLibrary.simpleMessage("aciertos"),
    "hopInterval": MessageLookupByLibrary.simpleMessage("Intervalo de salto"),
    "host": MessageLookupByLibrary.simpleMessage("Host"),
    "hostname": MessageLookupByLibrary.simpleMessage("Nombre de host"),
    "hotkeyConflictWith": m39,
    "hotkeyDesc": MessageLookupByLibrary.simpleMessage(
      "Los atajos globales funcionan incluso con la ventana oculta. Toca una acción para grabar su combinación de teclas.",
    ),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage(
      "Gestión de atajos",
    ),
    "hotkeyNeedsModifier": m40,
    "hotkeyNotSet": MessageLookupByLibrary.simpleMessage("Sin asignar"),
    "hotkeyUnavailable": MessageLookupByLibrary.simpleMessage(
      "No registrado; puede que otra app lo esté usando",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("horas"),
    "hoursAgo": m41,
    "hoursAgoShort": m42,
    "hue": MessageLookupByLibrary.simpleMessage("Tono"),
    "icon": MessageLookupByLibrary.simpleMessage("Icono"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("Registros de iconos"),
    "iconSets": MessageLookupByLibrary.simpleMessage("Conjuntos de iconos"),
    "iconSetsEmptyTip": MessageLookupByLibrary.simpleMessage(
      "Aún no hay conjuntos de iconos. Añádelos en Recursos de perfil personalizado → Conjuntos de iconos",
    ),
    "iconStyle": MessageLookupByLibrary.simpleMessage("Estilo de icono"),
    "iconStyleFilled": MessageLookupByLibrary.simpleMessage("Relleno"),
    "iconStyleHidden": MessageLookupByLibrary.simpleMessage("Oculto"),
    "iconStylePlain": MessageLookupByLibrary.simpleMessage("Simple"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("URL del icono"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Ignorar optimización de batería",
    ),
    "import": MessageLookupByLibrary.simpleMessage("Importar"),
    "importConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "Este archivo no es una configuración importable",
    ),
    "importConfigReplaceTip": MessageLookupByLibrary.simpleMessage(
      "Al importar se reemplazan los grupos de proxies, las reglas y los ajustes que tiene ahora este perfil",
    ),
    "importFile": MessageLookupByLibrary.simpleMessage(
      "Importar desde archivo",
    ),
    "importFromLink": MessageLookupByLibrary.simpleMessage(
      "Importar desde enlace",
    ),
    "importUrl": MessageLookupByLibrary.simpleMessage("Importar desde URL"),
    "inbound": MessageLookupByLibrary.simpleMessage("Entrada"),
    "includeInterface": MessageLookupByLibrary.simpleMessage(
      "Interfaces incluidas",
    ),
    "includeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "Solo el tráfico que llega por las interfaces incluidas pasa por TUN, y las interfaces excluidas dejan de aplicarse.",
    ),
    "includeUid": MessageLookupByLibrary.simpleMessage(
      "ID de usuario incluidos",
    ),
    "includeUidDesc": MessageLookupByLibrary.simpleMessage(
      "Solo el tráfico de los procesos de los ID de usuario incluidos pasa por TUN.",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("No caduca"),
    "init": MessageLookupByLibrary.simpleMessage("Inicio"),
    "initFailed": MessageLookupByLibrary.simpleMessage("Error al iniciar"),
    "initFailedTip": MessageLookupByLibrary.simpleMessage(
      "Skyward encontró un error al iniciarse y no puede continuar. Copia los detalles para informar del problema. Si sigue ocurriendo, borrar los datos suele permitir que la app vuelva a iniciarse.",
    ),
    "initiator": MessageLookupByLibrary.simpleMessage("Origen de la solicitud"),
    "initiatorShort": MessageLookupByLibrary.simpleMessage("De"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage(
      "Introduce el nombre del grupo de proxies",
    ),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage(
      "Introduce el contenido de la regla",
    ),
    "installedAppsPermissionDeniedMessage":
        MessageLookupByLibrary.simpleMessage(
          "Se denegó el permiso de lista de apps, por lo que no se pueden mostrar las apps instaladas. Concédelo manualmente en los ajustes del sistema.",
        ),
    "installedAppsPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Este sistema oculta la lista de apps instaladas hasta que se concede el permiso. Autorízalo para configurar el proxy por app.",
    ),
    "installedAppsPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Se requiere permiso de lista de apps",
    ),
    "installedFonts": MessageLookupByLibrary.simpleMessage(
      "Fuentes instaladas",
    ),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage(
      "Selección inteligente",
    ),
    "interfaceName": MessageLookupByLibrary.simpleMessage("Nombre de interfaz"),
    "interfaceNameDesc": MessageLookupByLibrary.simpleMessage(
      "El nombre de interfaz es la interfaz de red que usan las conexiones salientes.",
    ),
    "interfaceNameMode": MessageLookupByLibrary.simpleMessage(
      "Interfaz de salida",
    ),
    "interfaceNameModeClear": MessageLookupByLibrary.simpleMessage("Ninguna"),
    "interfaceNameModeCustom": MessageLookupByLibrary.simpleMessage(
      "Personalizada",
    ),
    "interfaceNameModeFollow": MessageLookupByLibrary.simpleMessage(
      "Seguir configuración",
    ),
    "internet": MessageLookupByLibrary.simpleMessage("Internet"),
    "interval": MessageLookupByLibrary.simpleMessage("Intervalo"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("IP de intranet"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage(
      "Archivo de copia de seguridad no válido",
    ),
    "invalidCidrContent": MessageLookupByLibrary.simpleMessage(
      "Introduce un rango de IP en formato CIDR, como 192.168.0.0/16",
    ),
    "invalidDscpContent": MessageLookupByLibrary.simpleMessage(
      "Una marca DSCP no puede superar 63",
    ),
    "invalidHostContent": MessageLookupByLibrary.simpleMessage(
      "Introduce un dominio o una dirección IP",
    ),
    "invalidIconSet": MessageLookupByLibrary.simpleMessage(
      "No es un conjunto de iconos válido",
    ),
    "invalidLinkTip": MessageLookupByLibrary.simpleMessage(
      "No es un enlace de suscripción ni un enlace para compartir proxies",
    ),
    "invalidListenContent": MessageLookupByLibrary.simpleMessage(
      "Introduce una dirección y un puerto, como 0.0.0.0:1053",
    ),
    "invalidNetworkContent": MessageLookupByLibrary.simpleMessage(
      "Solo se admite tcp o udp",
    ),
    "invalidPolicy": m43,
    "invalidPortRangeContent": MessageLookupByLibrary.simpleMessage(
      "Introduce un puerto o un rango como 443 u 8000-9000",
    ),
    "invalidProfileQrcode": MessageLookupByLibrary.simpleMessage(
      "Este código QR no contiene un enlace de perfil",
    ),
    "invalidProxy": m44,
    "invalidProxyProvider": m45,
    "invalidRangeContent": MessageLookupByLibrary.simpleMessage(
      "Introduce números o rangos como 80 u 8000-9000, separados por /",
    ),
    "invalidRuleSet": m46,
    "invalidSubRule": m47,
    "ipAddress": MessageLookupByLibrary.simpleMessage("Dirección IP"),
    "ipAsn": MessageLookupByLibrary.simpleMessage("ASN"),
    "ipFlagAbuser": MessageLookupByLibrary.simpleMessage("Historial de abusos"),
    "ipFlagProxy": MessageLookupByLibrary.simpleMessage("Proxy"),
    "ipFlagTor": MessageLookupByLibrary.simpleMessage("Tor"),
    "ipFlagVpn": MessageLookupByLibrary.simpleMessage("VPN"),
    "ipFlags": MessageLookupByLibrary.simpleMessage("Indicadores"),
    "ipOrganization": MessageLookupByLibrary.simpleMessage("Organización"),
    "ipQualityFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo determinar el tipo de IP",
    ),
    "ipQualityGood": MessageLookupByLibrary.simpleMessage("Buena"),
    "ipQualityLevel": MessageLookupByLibrary.simpleMessage("Nivel"),
    "ipQualityNormal": MessageLookupByLibrary.simpleMessage("Normal"),
    "ipQualityRetry": MessageLookupByLibrary.simpleMessage(
      "Comprobar de nuevo",
    ),
    "ipQualityRisky": MessageLookupByLibrary.simpleMessage("Arriesgada"),
    "ipQualityShort": MessageLookupByLibrary.simpleMessage("Calidad"),
    "ipQualitySource": MessageLookupByLibrary.simpleMessage("Respondido por"),
    "ipQualitySources": MessageLookupByLibrary.simpleMessage("Fuentes"),
    "ipSourceIpMismatch": MessageLookupByLibrary.simpleMessage(
      "IP de salida distinta",
    ),
    "ipSourceNoType": MessageLookupByLibrary.simpleMessage("Sin tipo"),
    "ipSourceRateLimited": MessageLookupByLibrary.simpleMessage(
      "Límite de solicitudes",
    ),
    "ipType": MessageLookupByLibrary.simpleMessage("Tipo"),
    "ipTypeBusiness": MessageLookupByLibrary.simpleMessage("Empresarial"),
    "ipTypeHosting": MessageLookupByLibrary.simpleMessage("Centro de datos"),
    "ipTypeMobile": MessageLookupByLibrary.simpleMessage("Red móvil"),
    "ipTypeResidential": MessageLookupByLibrary.simpleMessage("Residencial"),
    "ipTypeUnknown": MessageLookupByLibrary.simpleMessage("Tipo desconocido"),
    "ipVersion": MessageLookupByLibrary.simpleMessage("Versión de IP"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "El tráfico IPv6 solo se recibe mientras IPv6 esté activado.",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage(
      "Con IPv6 activado, la VPN permite el tráfico IPv6 entrante.",
    ),
    "ipv6Timeout": MessageLookupByLibrary.simpleMessage(
      "Tiempo de espera IPv6 (ms)",
    ),
    "itemsCount": m48,
    "ja": MessageLookupByLibrary.simpleMessage("Japonés"),
    "justNow": MessageLookupByLibrary.simpleMessage("Ahora mismo"),
    "keepAliveIdle": MessageLookupByLibrary.simpleMessage(
      "Inactividad de keep-alive TCP",
    ),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "Intervalo de keep-alive TCP",
    ),
    "key": MessageLookupByLibrary.simpleMessage("Clave"),
    "ko": MessageLookupByLibrary.simpleMessage("Coreano"),
    "label": MessageLookupByLibrary.simpleMessage("Etiqueta"),
    "language": MessageLookupByLibrary.simpleMessage("Idioma"),
    "large": MessageLookupByLibrary.simpleMessage("Grande"),
    "last7Days": MessageLookupByLibrary.simpleMessage("Últimos 7 días"),
    "lastUpdated": MessageLookupByLibrary.simpleMessage("Última actualización"),
    "launchInterrupted": MessageLookupByLibrary.simpleMessage(
      "El inicio no se completó",
    ),
    "launchInterruptedTip": MessageLookupByLibrary.simpleMessage(
      "La última vez, la app se cerró inesperadamente mientras se iniciaba. En este inicio se ha omitido la configuración automática; puedes iniciarla manualmente para reintentarlo.",
    ),
    "layout": MessageLookupByLibrary.simpleMessage("Diseño"),
    "leakCheck": MessageLookupByLibrary.simpleMessage("Comprobación de fugas"),
    "light": MessageLookupByLibrary.simpleMessage("Claro"),
    "lineIssueTip": m49,
    "lineWrap": MessageLookupByLibrary.simpleMessage("Ajuste de línea"),
    "link": MessageLookupByLibrary.simpleMessage("Enlace"),
    "linkDesc": MessageLookupByLibrary.simpleMessage(
      "Obtén un perfil desde un enlace de suscripción o un enlace para compartir proxies",
    ),
    "liquidGlass": MessageLookupByLibrary.simpleMessage("Liquid Glass"),
    "list": MessageLookupByLibrary.simpleMessage("Lista"),
    "listen": MessageLookupByLibrary.simpleMessage("Escucha"),
    "listenRoutingMark": MessageLookupByLibrary.simpleMessage(
      "Marca de enrutamiento de escucha",
    ),
    "listenRoutingMarkDesc": MessageLookupByLibrary.simpleMessage(
      "La marca de enrutamiento de escucha solo funciona en Linux.",
    ),
    "liveConnections": MessageLookupByLibrary.simpleMessage(
      "Conexiones activas",
    ),
    "loading": MessageLookupByLibrary.simpleMessage("Cargando…"),
    "local": MessageLookupByLibrary.simpleMessage("Local"),
    "localImage": MessageLookupByLibrary.simpleMessage("Imagen local"),
    "localNetwork": MessageLookupByLibrary.simpleMessage("Proxy LAN"),
    "localNetworkDeniedTip": MessageLookupByLibrary.simpleMessage(
      "Permiso de red local denegado: con la pila gvisor, la LAN no es accesible.",
    ),
    "localNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "Si se desactiva, las direcciones de red local, bucle y multidifusión no pasan por la interfaz virtual.",
    ),
    "localProxies": MessageLookupByLibrary.simpleMessage("Proxies locales"),
    "locationPermission": MessageLookupByLibrary.simpleMessage(
      "Permiso de ubicación",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "Se denegó el permiso de ubicación, por lo que no se puede leer el nombre de la red Wi-Fi actual. Activa el permiso de ubicación manualmente en los ajustes del sistema.",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "El sistema requiere el permiso de ubicación para leer el nombre de la red Wi-Fi. En Android elige “Permitir todo el tiempo”; de lo contrario, no se podrá leer el nombre de la red Wi-Fi mientras la app esté en segundo plano.",
    ),
    "locationPermissionGuide": m50,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Se requiere permiso de ubicación",
    ),
    "log": MessageLookupByLibrary.simpleMessage("Registro"),
    "logLevel": MessageLookupByLibrary.simpleMessage("Nivel de registro"),
    "logcat": MessageLookupByLibrary.simpleMessage("Logcat"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "Si desactivas Logcat, se oculta la entrada de registros.",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("Registros"),
    "logsAndDiagnostics": MessageLookupByLibrary.simpleMessage(
      "Registros y diagnóstico",
    ),
    "logsTest": MessageLookupByLibrary.simpleMessage("Prueba de registros"),
    "loopback": MessageLookupByLibrary.simpleMessage(
      "Exención de loopback de UWP",
    ),
    "loose": MessageLookupByLibrary.simpleMessage("Amplio"),
    "matchCase": MessageLookupByLibrary.simpleMessage(
      "Coincidir mayúsculas y minúsculas",
    ),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage(
      "Coincidir con IP de origen",
    ),
    "matchTarget": MessageLookupByLibrary.simpleMessage("MATCH-TARGET"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("Máximo de fallos"),
    "maxLengthTip": m51,
    "maximize": MessageLookupByLibrary.simpleMessage("Maximizar"),
    "memoryAppResident": MessageLookupByLibrary.simpleMessage(
      "Memoria residente",
    ),
    "memoryAppShared": MessageLookupByLibrary.simpleMessage("App y compartida"),
    "memoryCoreBudget": MessageLookupByLibrary.simpleMessage(
      "Límite del núcleo",
    ),
    "memoryCoreHeapIdle": MessageLookupByLibrary.simpleMessage("Heap inactivo"),
    "memoryCoreHeapInuse": MessageLookupByLibrary.simpleMessage("Heap en uso"),
    "memoryCoreNotRunning": MessageLookupByLibrary.simpleMessage(
      "El núcleo no se está ejecutando",
    ),
    "memoryCoreRuntime": MessageLookupByLibrary.simpleMessage(
      "Sobrecarga del runtime",
    ),
    "memoryCoreStack": MessageLookupByLibrary.simpleMessage(
      "Pilas de goroutines",
    ),
    "memoryEstimateDesc": MessageLookupByLibrary.simpleMessage(
      "Estimado a partir de la memoria residente del proceso; puede diferir de lo que indica el sistema.",
    ),
    "memoryEstimateSharedDesc": MessageLookupByLibrary.simpleMessage(
      "El núcleo se ejecuta dentro del proceso de la app. Su parte se estima a partir de las estadísticas del runtime, y el resto cuenta como memoria de la app y compartida.",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage(
      "Información de memoria",
    ),
    "memoryInfoDesc": MessageLookupByLibrary.simpleMessage(
      "Memoria que usan la app y el núcleo",
    ),
    "memoryReleased": MessageLookupByLibrary.simpleMessage("Memoria liberada"),
    "memoryReleasedSize": m52,
    "messageTest": MessageLookupByLibrary.simpleMessage("Prueba de mensaje"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage(
      "Esto es un mensaje.",
    ),
    "mine": MessageLookupByLibrary.simpleMessage("Mío"),
    "minimize": MessageLookupByLibrary.simpleMessage("Minimizar"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage(
      "Minimizar al salir",
    ),
    "minutes": MessageLookupByLibrary.simpleMessage("minutos"),
    "minutesAgo": m53,
    "minutesAgoShort": m54,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Puerto mixto"),
    "mode": MessageLookupByLibrary.simpleMessage("Modo"),
    "monochromeIcon": MessageLookupByLibrary.simpleMessage("Icono monocromo"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("Monocromo"),
    "month": MessageLookupByLibrary.simpleMessage("Mes"),
    "monthsAgo": m55,
    "monthsAgoShort": m56,
    "more": MessageLookupByLibrary.simpleMessage("Más"),
    "moreThemeSettings": MessageLookupByLibrary.simpleMessage(
      "Más ajustes de tema",
    ),
    "motionSection": MessageLookupByLibrary.simpleMessage("Movimiento"),
    "name": MessageLookupByLibrary.simpleMessage("Nombre"),
    "navigationBarStyle": MessageLookupByLibrary.simpleMessage(
      "Barra inferior",
    ),
    "navigationSection": MessageLookupByLibrary.simpleMessage("Navegación"),
    "network": MessageLookupByLibrary.simpleMessage("Red"),
    "networkAccessDeniedError": m57,
    "networkBadResponseError": m58,
    "networkCancelledError": MessageLookupByLibrary.simpleMessage(
      "Se canceló la solicitud",
    ),
    "networkConnectionError": MessageLookupByLibrary.simpleMessage(
      "No se pudo conectar con el servidor. Comprueba tu conexión de red o los ajustes del proxy",
    ),
    "networkControl": MessageLookupByLibrary.simpleMessage("Control de red"),
    "networkHostLookupError": MessageLookupByLibrary.simpleMessage(
      "No se pudo resolver la dirección del servidor. Comprueba que la URL sea correcta y que el DNS funcione",
    ),
    "networkName": MessageLookupByLibrary.simpleMessage("Nombre de la red"),
    "networkNotFoundError": m59,
    "networkOverview": MessageLookupByLibrary.simpleMessage("Resumen de red"),
    "networkRateLimitedError": MessageLookupByLibrary.simpleMessage(
      "Demasiadas solicitudes (HTTP 429). Espera un momento e inténtalo de nuevo",
    ),
    "networkRequestFailed": m60,
    "networkSecret": MessageLookupByLibrary.simpleMessage("Clave de la red"),
    "networkServerError": m61,
    "networkSpeed": MessageLookupByLibrary.simpleMessage("Velocidad de red"),
    "networkTakeover": MessageLookupByLibrary.simpleMessage(
      "Control del tráfico",
    ),
    "networkTimeoutError": MessageLookupByLibrary.simpleMessage(
      "Se agotó el tiempo de espera de la solicitud. Comprueba tu red o el proxy e inténtalo de nuevo",
    ),
    "networkTlsError": MessageLookupByLibrary.simpleMessage(
      "Falló la conexión segura. Puede que el certificado del servidor no sea válido o que la conexión esté siendo interceptada",
    ),
    "networkType": MessageLookupByLibrary.simpleMessage("Tipo de red"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("Coincidencia siguiente"),
    "nextPeriod": MessageLookupByLibrary.simpleMessage("Siguiente"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noData": MessageLookupByLibrary.simpleMessage("Sin datos"),
    "noInfo": MessageLookupByLibrary.simpleMessage("Sin información"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage(
      "No volver a recordármelo",
    ),
    "noNetwork": MessageLookupByLibrary.simpleMessage("Sin red"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("Apps sin red"),
    "noResolve": MessageLookupByLibrary.simpleMessage("No resolver IP"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage(
      "No resolver nombre de host",
    ),
    "noSearchResults": MessageLookupByLibrary.simpleMessage(
      "No hay resultados",
    ),
    "nodes": MessageLookupByLibrary.simpleMessage("Nodos"),
    "nonTextProviderFile": MessageLookupByLibrary.simpleMessage(
      "Este recurso externo no es un archivo de texto",
    ),
    "none": MessageLookupByLibrary.simpleMessage("Ninguno"),
    "notRunning": MessageLookupByLibrary.simpleMessage("Detenido"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "No se puede seleccionar el grupo de proxies actual",
    ),
    "ntpInterval": MessageLookupByLibrary.simpleMessage(
      "Intervalo de sincronización (minutos)",
    ),
    "ntpStatusDesc": MessageLookupByLibrary.simpleMessage(
      "NTP obtiene la hora de un servidor NTP en lugar del reloj del sistema.",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Añade un perfil para empezar",
    ),
    "nullTip": m62,
    "numberRangeTip": m63,
    "numberTip": m64,
    "obfs": MessageLookupByLibrary.simpleMessage("Ofuscación"),
    "obfsHost": MessageLookupByLibrary.simpleMessage("Host de ofuscación"),
    "obfsMode": MessageLookupByLibrary.simpleMessage("Modo de ofuscación"),
    "obfsParam": MessageLookupByLibrary.simpleMessage(
      "Parámetro de ofuscación",
    ),
    "obfsPassword": MessageLookupByLibrary.simpleMessage(
      "Contraseña de ofuscación",
    ),
    "onDemand": MessageLookupByLibrary.simpleMessage("Bajo demanda"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "Bajo demanda pausa el proxy en las redes Wi-Fi excluidas.",
    ),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "Contar solo el tráfico del proxy",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("Opcional"),
    "options": MessageLookupByLibrary.simpleMessage("Opciones"),
    "other": MessageLookupByLibrary.simpleMessage("Otros"),
    "otherContributors": MessageLookupByLibrary.simpleMessage(
      "Otros colaboradores",
    ),
    "outbound": MessageLookupByLibrary.simpleMessage("Salida"),
    "outboundExit": MessageLookupByLibrary.simpleMessage("Salida"),
    "outboundIp": MessageLookupByLibrary.simpleMessage("IP de salida"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("Modo de salida"),
    "overrideDestination": MessageLookupByLibrary.simpleMessage(
      "Sobrescribir destino",
    ),
    "overrideDestinationDesc": MessageLookupByLibrary.simpleMessage(
      "Sobrescribir destino se conecta al dominio detectado en lugar de a la dirección original.",
    ),
    "overrideEntries": MessageLookupByLibrary.simpleMessage(
      "Entradas de sobrescritura",
    ),
    "pagesLabel": MessageLookupByLibrary.simpleMessage("Páginas"),
    "parsePureIp": MessageLookupByLibrary.simpleMessage("Analizar IP pura"),
    "parsePureIpDesc": MessageLookupByLibrary.simpleMessage(
      "Analizar IP pura analiza las conexiones que solo llevan una dirección IP.",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Contraseña"),
    "paste": MessageLookupByLibrary.simpleMessage("Pegar"),
    "pasteDesc": MessageLookupByLibrary.simpleMessage(
      "Pegar un enlace de suscripción del portapapeles",
    ),
    "peers": MessageLookupByLibrary.simpleMessage("Pares"),
    "perApp": MessageLookupByLibrary.simpleMessage("Por aplicación"),
    "perAppDesc": MessageLookupByLibrary.simpleMessage(
      "Elige qué aplicaciones usan el proxy.",
    ),
    "pickFromAlbum": MessageLookupByLibrary.simpleMessage("Elegir del álbum"),
    "pinWindow": MessageLookupByLibrary.simpleMessage("Fijar ventana"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage("Vincula WebDAV"),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "Introduce un nombre para el script",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "Sube un código QR válido",
    ),
    "plugin": MessageLookupByLibrary.simpleMessage("Complemento"),
    "pluginCipher": MessageLookupByLibrary.simpleMessage(
      "Cifrado del complemento",
    ),
    "pluginHost": MessageLookupByLibrary.simpleMessage("Host del complemento"),
    "pluginMode": MessageLookupByLibrary.simpleMessage("Modo del complemento"),
    "pluginPassword": MessageLookupByLibrary.simpleMessage(
      "Contraseña del complemento",
    ),
    "pluginPath": MessageLookupByLibrary.simpleMessage("Ruta del complemento"),
    "pluginUsername": MessageLookupByLibrary.simpleMessage(
      "Usuario del complemento",
    ),
    "port": MessageLookupByLibrary.simpleMessage("Puerto"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage(
      "Introduce un puerto diferente",
    ),
    "portHopping": MessageLookupByLibrary.simpleMessage("Salto de puertos"),
    "portTip": m65,
    "portValue": m66,
    "ports": MessageLookupByLibrary.simpleMessage("Puertos"),
    "preSharedKey": MessageLookupByLibrary.simpleMessage("Clave precompartida"),
    "preferences": MessageLookupByLibrary.simpleMessage("Preferencias"),
    "preferred": MessageLookupByLibrary.simpleMessage("Preferido"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Requisitos previos"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage(
      "Pulsa una combinación de teclas",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("Vista previa"),
    "previousMatch": MessageLookupByLibrary.simpleMessage(
      "Coincidencia anterior",
    ),
    "previousPeriod": MessageLookupByLibrary.simpleMessage("Anterior"),
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
    "privateKey": MessageLookupByLibrary.simpleMessage("Clave privada"),
    "privateKeyPassphrase": MessageLookupByLibrary.simpleMessage(
      "Frase de contraseña de la clave privada",
    ),
    "process": MessageLookupByLibrary.simpleMessage("Proceso"),
    "profile": MessageLookupByLibrary.simpleMessage("Perfil"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("Introduce un intervalo válido"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage(
          "Introduce el intervalo de actualización automática",
        ),
    "profileDaysLeft": m67,
    "profileDnsSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Se aplica solo a este perfil y tiene prioridad sobre las entradas de sobrescritura de DNS de los ajustes de red.",
    ),
    "profileExpiresIn": m68,
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "El perfil se ha modificado. ¿Desactivar la actualización automática?",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Introduce el nombre del perfil",
    ),
    "profileSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Se aplica solo a este perfil; lo que no añadas usa su valor predeterminado.",
    ),
    "profileTunSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Se aplica solo a este perfil y tiene prioridad sobre las entradas de sobrescritura de TUN de los ajustes de red.",
    ),
    "profileUpdatedAt": m69,
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Introduce una URL de perfil válida",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Introduce la URL del perfil",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("Perfiles"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("Ordenar perfiles"),
    "project": MessageLookupByLibrary.simpleMessage("Proyecto"),
    "protocol": MessageLookupByLibrary.simpleMessage("Protocolo"),
    "protocolParam": MessageLookupByLibrary.simpleMessage(
      "Parámetro del protocolo",
    ),
    "protocolVersion": MessageLookupByLibrary.simpleMessage(
      "Versión del protocolo",
    ),
    "providerInUse": m70,
    "providerUrlTip": MessageLookupByLibrary.simpleMessage(
      "Solo se admiten proveedores remotos",
    ),
    "providers": MessageLookupByLibrary.simpleMessage("Recursos externos"),
    "proxies": MessageLookupByLibrary.simpleMessage("Proxies"),
    "proxiesCount": m71,
    "proxiesProfileLabel": m72,
    "proxiesRemovedTip": m73,
    "proxiesReplacedTip": m74,
    "proxyChains": MessageLookupByLibrary.simpleMessage("Cadena de proxies"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("Grupo de proxies"),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "El grupo de proxies está vacío",
    ),
    "proxyGroupInUse": m75,
    "proxyGroupsAfterStart": MessageLookupByLibrary.simpleMessage(
      "Los grupos aparecen aquí cuando se inicia el núcleo",
    ),
    "proxyGroupsCount": m76,
    "proxyProviders": MessageLookupByLibrary.simpleMessage(
      "Proveedores de proxies",
    ),
    "proxyShare": m77,
    "proxyType": MessageLookupByLibrary.simpleMessage("Tipo de proxy"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("Depurar caché"),
    "publicKey": MessageLookupByLibrary.simpleMessage("Clave pública"),
    "pureBlack": MessageLookupByLibrary.simpleMessage("Negro puro"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("Modo negro puro"),
    "qrcode": MessageLookupByLibrary.simpleMessage("Código QR"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "Escanea un código QR para obtener un perfil",
    ),
    "qrcodeTooLongTip": MessageLookupByLibrary.simpleMessage(
      "Este enlace es demasiado largo para un código QR. Usa Copiar enlace.",
    ),
    "quickActions": MessageLookupByLibrary.simpleMessage("Acciones rápidas"),
    "quickEdit": MessageLookupByLibrary.simpleMessage("Edición rápida"),
    "rankDetail": m78,
    "rcxActiveScriptedGroups": MessageLookupByLibrary.simpleMessage(
      "Grupos programables activos",
    ),
    "rcxAddGroup": MessageLookupByLibrary.simpleMessage("Añadir grupo"),
    "rcxAddKind": MessageLookupByLibrary.simpleMessage("Añadir tipo de red"),
    "rcxAddTag": MessageLookupByLibrary.simpleMessage("Añadir etiqueta"),
    "rcxAdvanced": MessageLookupByLibrary.simpleMessage("Avanzado"),
    "rcxAllGroups": MessageLookupByLibrary.simpleMessage("Todos los grupos"),
    "rcxAnyServer": MessageLookupByLibrary.simpleMessage("Cualquiera"),
    "rcxBackToAuto": MessageLookupByLibrary.simpleMessage(
      "Volver a automático",
    ),
    "rcxBalanced": MessageLookupByLibrary.simpleMessage("Equilibrado"),
    "rcxBasedOn": MessageLookupByLibrary.simpleMessage("Basado en"),
    "rcxBehaviour": MessageLookupByLibrary.simpleMessage("Comportamiento"),
    "rcxBringChanges": MessageLookupByLibrary.simpleMessage(
      "Traer los cambios",
    ),
    "rcxBringChangesHint": MessageLookupByLibrary.simpleMessage(
      "Tus cambios se conservan",
    ),
    "rcxChangeServer": MessageLookupByLibrary.simpleMessage("Cambiar servidor"),
    "rcxChangeTo": MessageLookupByLibrary.simpleMessage("Elegir de"),
    "rcxCheckDifferent": m79,
    "rcxCheckGroup": MessageLookupByLibrary.simpleMessage("Grupo"),
    "rcxCheckNone": MessageLookupByLibrary.simpleMessage(
      "No encontraría ningún servidor",
    ),
    "rcxCheckOn": m80,
    "rcxCheckOpen": MessageLookupByLibrary.simpleMessage("abre lo bloqueado"),
    "rcxCheckSame": m81,
    "rcxChecks": MessageLookupByLibrary.simpleMessage(
      "Frecuencia de comprobación",
    ),
    "rcxCondAdd": MessageLookupByLibrary.simpleMessage("Añadir condición"),
    "rcxCondAll": MessageLookupByLibrary.simpleMessage("Todas las condiciones"),
    "rcxCondAlways": MessageLookupByLibrary.simpleMessage("Siempre"),
    "rcxCondAny": MessageLookupByLibrary.simpleMessage("Cualquier condición"),
    "rcxCondAnyServer": MessageLookupByLibrary.simpleMessage(
      "Cualquier servidor",
    ),
    "rcxCondAtLeast": MessageLookupByLibrary.simpleMessage("es como mínimo"),
    "rcxCondAtMost": MessageLookupByLibrary.simpleMessage("es como máximo"),
    "rcxCondClause": m82,
    "rcxCondCountry": MessageLookupByLibrary.simpleMessage("País"),
    "rcxCondField": MessageLookupByLibrary.simpleMessage("Campo"),
    "rcxCondIgnoreCase": MessageLookupByLibrary.simpleMessage(
      "Ignorar mayúsculas",
    ),
    "rcxCondLess": MessageLookupByLibrary.simpleMessage("es menor que"),
    "rcxCondMatch": MessageLookupByLibrary.simpleMessage("Coincidencia"),
    "rcxCondMore": MessageLookupByLibrary.simpleMessage("es mayor que"),
    "rcxCondNoNames": MessageLookupByLibrary.simpleMessage("Ninguno declarado"),
    "rcxCondNotPrefix": MessageLookupByLibrary.simpleMessage("no"),
    "rcxCondOp": MessageLookupByLibrary.simpleMessage("Operador"),
    "rcxCondPattern": MessageLookupByLibrary.simpleMessage("Patrón"),
    "rcxCondText": MessageLookupByLibrary.simpleMessage("Como texto"),
    "rcxCondTooComplex": MessageLookupByLibrary.simpleMessage(
      "Esta condición anida grupos, así que se edita como texto.",
    ),
    "rcxCondValue": MessageLookupByLibrary.simpleMessage("Valor"),
    "rcxCondValues": MessageLookupByLibrary.simpleMessage(
      "Valores separados por comas",
    ),
    "rcxConsentAllow": MessageLookupByLibrary.simpleMessage("Permitir"),
    "rcxConsentAsk": m83,
    "rcxConsentHint": MessageLookupByLibrary.simpleMessage(
      "Hasta que lo permitas, el grupo usa el comportamiento Simple. Los sitios solo se contactan a través de tus servidores o para probar la red.",
    ),
    "rcxConsentTitle": MessageLookupByLibrary.simpleMessage(
      "Se necesita permiso",
    ),
    "rcxContacts": MessageLookupByLibrary.simpleMessage("Sitios contactados"),
    "rcxContactsHint": MessageLookupByLibrary.simpleMessage(
      "Los sitios de terceros no pertenecen ni a tu proveedor ni a los comportamientos integrados.",
    ),
    "rcxControl": MessageLookupByLibrary.simpleMessage("Control"),
    "rcxCountryAll": MessageLookupByLibrary.simpleMessage("Todos los países"),
    "rcxCountryOnServers": MessageLookupByLibrary.simpleMessage(
      "En tus servidores",
    ),
    "rcxCountryPickMany": MessageLookupByLibrary.simpleMessage("Elegir países"),
    "rcxCountryPickOne": MessageLookupByLibrary.simpleMessage("Elegir un país"),
    "rcxCountryServers": m84,
    "rcxCountryVerified": MessageLookupByLibrary.simpleMessage("verificado"),
    "rcxDeleteProfile": m85,
    "rcxDetails": MessageLookupByLibrary.simpleMessage("Detalles"),
    "rcxDirectSplit": MessageLookupByLibrary.simpleMessage(
      "Sitios directos por este grupo",
    ),
    "rcxDirectSplitActive": MessageLookupByLibrary.simpleMessage(
      "Activo ahora",
    ),
    "rcxDirectSplitHint": MessageLookupByLibrary.simpleMessage(
      "Si los sitios que tus reglas envían directos dejan de abrirse, pasarán por este grupo. Las direcciones locales siempre van directas.",
    ),
    "rcxDirectSplitStandby": MessageLookupByLibrary.simpleMessage(
      "En espera: los sitios directos aún abren",
    ),
    "rcxDuplicate": MessageLookupByLibrary.simpleMessage("Editar una copia"),
    "rcxEnergyEco": MessageLookupByLibrary.simpleMessage("Económico"),
    "rcxEnergyPrecise": MessageLookupByLibrary.simpleMessage("Preciso"),
    "rcxEnergyToday": m86,
    "rcxExcept": m87,
    "rcxExcludedByProfile": MessageLookupByLibrary.simpleMessage(
      "Excluido por el comportamiento",
    ),
    "rcxExcludedCooldown": MessageLookupByLibrary.simpleMessage(
      "Omitido tras «Cambiar servidor»",
    ),
    "rcxExcludedNoMatch": MessageLookupByLibrary.simpleMessage(
      "Fuera del grupo de servidores",
    ),
    "rcxExcludedNoTier": MessageLookupByLibrary.simpleMessage(
      "No coincide con ninguna preferencia",
    ),
    "rcxExcludedPending": MessageLookupByLibrary.simpleMessage(
      "Aún sin comprobar",
    ),
    "rcxExcludedUnroutable": MessageLookupByLibrary.simpleMessage(
      "No es un servidor",
    ),
    "rcxExit": m88,
    "rcxExport": MessageLookupByLibrary.simpleMessage("Exportar"),
    "rcxFeelCalm": MessageLookupByLibrary.simpleMessage("Pocas veces"),
    "rcxFeelEager": MessageLookupByLibrary.simpleMessage("A menudo"),
    "rcxFieldAlive": MessageLookupByLibrary.simpleMessage("Funcionando"),
    "rcxFieldCurrent": MessageLookupByLibrary.simpleMessage("En uso"),
    "rcxFieldDead": MessageLookupByLibrary.simpleMessage("No funciona"),
    "rcxFieldDiag": MessageLookupByLibrary.simpleMessage("Diagnóstico de red"),
    "rcxFieldEntry": MessageLookupByLibrary.simpleMessage("País de entrada"),
    "rcxFieldExit": MessageLookupByLibrary.simpleMessage("País de salida"),
    "rcxFieldFails": MessageLookupByLibrary.simpleMessage(
      "Falla la comprobación",
    ),
    "rcxFieldKind": MessageLookupByLibrary.simpleMessage("Tipo de red"),
    "rcxFieldLatency": MessageLookupByLibrary.simpleMessage("Latencia, ms"),
    "rcxFieldMeasured": MessageLookupByLibrary.simpleMessage("Medido"),
    "rcxFieldMetered": MessageLookupByLibrary.simpleMessage(
      "Red con tarifa limitada",
    ),
    "rcxFieldName": MessageLookupByLibrary.simpleMessage("Nombre"),
    "rcxFieldPasses": MessageLookupByLibrary.simpleMessage(
      "Pasa la comprobación",
    ),
    "rcxFieldPortal": MessageLookupByLibrary.simpleMessage(
      "Página de inicio de sesión",
    ),
    "rcxFieldProvider": MessageLookupByLibrary.simpleMessage("Proveedor"),
    "rcxFieldServer": MessageLookupByLibrary.simpleMessage(
      "Dirección del servidor",
    ),
    "rcxFieldTag": MessageLookupByLibrary.simpleMessage("Etiqueta"),
    "rcxFieldTransport": MessageLookupByLibrary.simpleMessage(
      "Tipo de conexión",
    ),
    "rcxFieldType": MessageLookupByLibrary.simpleMessage("Protocolo"),
    "rcxFieldUdp": MessageLookupByLibrary.simpleMessage("Admite UDP"),
    "rcxFixedHint": MessageLookupByLibrary.simpleMessage(
      "Todo el grupo pasa por este miembro sin buscar servidor; elige un balanceador o un grupo anidado para cederle todo.",
    ),
    "rcxFixedOn": m89,
    "rcxFromScenario": m90,
    "rcxFromYours": MessageLookupByLibrary.simpleMessage(
      "Tuyo para este grupo",
    ),
    "rcxGroupProfiles": MessageLookupByLibrary.simpleMessage("Comportamientos"),
    "rcxGroupProfilesHint": MessageLookupByLibrary.simpleMessage(
      "Cómo elige servidor un grupo. Toca uno tuyo para editarlo, o cualquier otro para editar una copia.",
    ),
    "rcxHealthAlive": MessageLookupByLibrary.simpleMessage("Funciona"),
    "rcxHealthDead": MessageLookupByLibrary.simpleMessage("No funciona"),
    "rcxHealthStale": MessageLookupByLibrary.simpleMessage("Funcionaba antes"),
    "rcxHealthUnknown": MessageLookupByLibrary.simpleMessage("Sin comprobar"),
    "rcxHistory": MessageLookupByLibrary.simpleMessage("Historial"),
    "rcxHistoryVersions": MessageLookupByLibrary.simpleMessage(
      "Versiones anteriores",
    ),
    "rcxHowToChoose": MessageLookupByLibrary.simpleMessage(
      "Cómo elegir el servidor",
    ),
    "rcxHubAuto": MessageLookupByLibrary.simpleMessage("Usar un escenario"),
    "rcxHubBundle": MessageLookupByLibrary.simpleMessage("En este archivo"),
    "rcxHubChange": MessageLookupByLibrary.simpleMessage("Elegir un escenario"),
    "rcxHubCopyConfirm": MessageLookupByLibrary.simpleMessage(
      "Editar una copia",
    ),
    "rcxHubCopyMessage": m91,
    "rcxHubCopyTitle": MessageLookupByLibrary.simpleMessage(
      "¿Editar una copia?",
    ),
    "rcxHubDescriptionHint": MessageLookupByLibrary.simpleMessage(
      "Qué hace este escenario",
    ),
    "rcxHubEverythingElse": MessageLookupByLibrary.simpleMessage(
      "Todo lo demás",
    ),
    "rcxHubGroupsEmpty": MessageLookupByLibrary.simpleMessage(
      "Esta suscripción no tiene grupos programables activos.",
    ),
    "rcxHubLibrary": MessageLookupByLibrary.simpleMessage(
      "Biblioteca de escenarios",
    ),
    "rcxHubNeedsCore": MessageLookupByLibrary.simpleMessage(
      "Inicia la conexión para ver el enrutamiento automático",
    ),
    "rcxHubNetworks": MessageLookupByLibrary.simpleMessage("Tipos de red"),
    "rcxHubNoProfile": MessageLookupByLibrary.simpleMessage("Sin suscripción"),
    "rcxHubNoProfileHint": MessageLookupByLibrary.simpleMessage(
      "Primero añade una suscripción; el enrutamiento automático trabaja con sus grupos.",
    ),
    "rcxHubOffHint": MessageLookupByLibrary.simpleMessage(
      "Un escenario puede controlar las rutas, los grupos de proxies y el modo de túnel de esta suscripción.",
    ),
    "rcxHubOtherGroups": MessageLookupByLibrary.simpleMessage(
      "Grupos de este escenario",
    ),
    "rcxHubOtherGroupsHint": MessageLookupByLibrary.simpleMessage(
      "Lo que este escenario hace con cada grupo de suscripción.",
    ),
    "rcxHubRoutes": MessageLookupByLibrary.simpleMessage("Rutas"),
    "rcxHubRoutesHint": MessageLookupByLibrary.simpleMessage(
      "El tráfico toma la primera ruta que coincide, de arriba abajo; el resto va por «Todo lo demás».",
    ),
    "rcxHubRoutesRuleOnly": m92,
    "rcxImportAdd": MessageLookupByLibrary.simpleMessage(
      "Añadir a mi biblioteca",
    ),
    "rcxImportNeedsCore": MessageLookupByLibrary.simpleMessage(
      "Inicia el núcleo de la app para comprobar este archivo.",
    ),
    "rcxImportTitle": MessageLookupByLibrary.simpleMessage(
      "Importar enrutamiento automático",
    ),
    "rcxImported": m93,
    "rcxJournalFailure": m94,
    "rcxJournalMode": m95,
    "rcxKindChecking": MessageLookupByLibrary.simpleMessage("comprobando"),
    "rcxKindGroupsHint": MessageLookupByLibrary.simpleMessage(
      "En esta red sustituyen a los grupos del escenario con el mismo nombre; los demás funcionan como en cualquier red.",
    ),
    "rcxKindName": MessageLookupByLibrary.simpleMessage("Nombre"),
    "rcxKindNameInvalid": MessageLookupByLibrary.simpleMessage(
      "Letras latinas minúsculas, dígitos y guiones, hasta 24",
    ),
    "rcxKindOpen": MessageLookupByLibrary.simpleMessage("internet abierto"),
    "rcxKindPortal": MessageLookupByLibrary.simpleMessage(
      "página de inicio de sesión",
    ),
    "rcxKindWhen": MessageLookupByLibrary.simpleMessage("Se reconoce cuando"),
    "rcxKindWhenHint": MessageLookupByLibrary.simpleMessage(
      "Los tipos se prueban de arriba abajo; la red recibe el primero que se cumple.",
    ),
    "rcxKindWhitelist": MessageLookupByLibrary.simpleMessage(
      "solo listas blancas",
    ),
    "rcxLadderAdd": MessageLookupByLibrary.simpleMessage("Añadir un paso"),
    "rcxLadderAdvanced": MessageLookupByLibrary.simpleMessage(
      "Condición avanzada…",
    ),
    "rcxLadderAnyWorking": MessageLookupByLibrary.simpleMessage(
      "Cualquier servidor que funcione",
    ),
    "rcxLadderCountry": MessageLookupByLibrary.simpleMessage("País"),
    "rcxLadderEmptyHint": MessageLookupByLibrary.simpleMessage(
      "Añade pasos para preferir unos servidores a otros",
    ),
    "rcxLadderExceptCountries": MessageLookupByLibrary.simpleMessage(
      "Todos menos estos países",
    ),
    "rcxLadderFallThrough": MessageLookupByLibrary.simpleMessage(
      "si ninguno funciona",
    ),
    "rcxLadderFits": m96,
    "rcxLadderInherited": MessageLookupByLibrary.simpleMessage(
      "Del comportamiento: edita un paso para tener tu propio orden",
    ),
    "rcxLadderLastResortHint": MessageLookupByLibrary.simpleMessage(
      "Los servidores de un paso de último recurso solo se usan cuando ningún otro paso, ni siquiera uno inferior, tiene un servidor que funcione.",
    ),
    "rcxLadderLatency": m97,
    "rcxLadderLatencyUnder": MessageLookupByLibrary.simpleMessage(
      "Latencia menor de, ms",
    ),
    "rcxLadderNameContains": MessageLookupByLibrary.simpleMessage(
      "El nombre contiene",
    ),
    "rcxLadderNameHas": m98,
    "rcxLadderNot": m99,
    "rcxLadderOther": MessageLookupByLibrary.simpleMessage("Otras condiciones"),
    "rcxLadderProvider": m100,
    "rcxLadderServersIn": MessageLookupByLibrary.simpleMessage(
      "Servidores de este paso",
    ),
    "rcxLadderStep": m101,
    "rcxLadderTag": m102,
    "rcxLadderTitle": MessageLookupByLibrary.simpleMessage(
      "Orden de servidores",
    ),
    "rcxLadderUdp": MessageLookupByLibrary.simpleMessage("UDP"),
    "rcxLastResort": MessageLookupByLibrary.simpleMessage("Último recurso"),
    "rcxLevel": MessageLookupByLibrary.simpleMessage("Complejidad"),
    "rcxLevelAdvanced": MessageLookupByLibrary.simpleMessage("Avanzado"),
    "rcxLevelSimple": MessageLookupByLibrary.simpleMessage("Sencillo"),
    "rcxLine": m103,
    "rcxLintCheckUnused": m104,
    "rcxLintConsent": m105,
    "rcxLintGroupMissing": m106,
    "rcxLintPoolEmpty": m107,
    "rcxLintTagUnused": m108,
    "rcxLintTierEmpty": m109,
    "rcxLintTierUnreachable": m110,
    "rcxMainGroup": MessageLookupByLibrary.simpleMessage("Todo lo demás"),
    "rcxMakeSmart": MessageLookupByLibrary.simpleMessage(
      "Usar selección programable",
    ),
    "rcxMakeSmartHint": MessageLookupByLibrary.simpleMessage(
      "El comportamiento seleccionado determina cómo elige un servidor este grupo.",
    ),
    "rcxManageHint": MessageLookupByLibrary.simpleMessage(
      "Gestiona los comportamientos en Herramientas → Configuración avanzada → Grupos programables.",
    ),
    "rcxMatchAdd": MessageLookupByLibrary.simpleMessage("Añadir entrada"),
    "rcxMatchAllServices": MessageLookupByLibrary.simpleMessage(
      "Todos los servicios",
    ),
    "rcxMatchCidr": MessageLookupByLibrary.simpleMessage("Rango IP"),
    "rcxMatchCustom": MessageLookupByLibrary.simpleMessage("Personalizado"),
    "rcxMatchDomain": MessageLookupByLibrary.simpleMessage("Dominio"),
    "rcxMatchGeoip": MessageLookupByLibrary.simpleMessage("Categoría de IP"),
    "rcxMatchGeosite": MessageLookupByLibrary.simpleMessage(
      "Categoría de sitios",
    ),
    "rcxMatchHint": MessageLookupByLibrary.simpleMessage(
      "Dominios, rangos IP, apps o conjuntos de reglas que también toma esta ruta.",
    ),
    "rcxMatchInvalid": MessageLookupByLibrary.simpleMessage("Valor no válido"),
    "rcxMatchKeyword": MessageLookupByLibrary.simpleMessage(
      "Palabra clave de dominio",
    ),
    "rcxMatchMore": m111,
    "rcxMatchNoResolve": MessageLookupByLibrary.simpleMessage(
      "No resolver dominios",
    ),
    "rcxMatchNone": MessageLookupByLibrary.simpleMessage("Sin tráfico elegido"),
    "rcxMatchProcess": MessageLookupByLibrary.simpleMessage("App"),
    "rcxMatchRuleSet": MessageLookupByLibrary.simpleMessage(
      "Conjunto de reglas",
    ),
    "rcxMatchServices": MessageLookupByLibrary.simpleMessage("Servicios"),
    "rcxMatchSuffix": MessageLookupByLibrary.simpleMessage(
      "Dominio y subdominios",
    ),
    "rcxMatchType": MessageLookupByLibrary.simpleMessage("Tipo"),
    "rcxMatchTypeHint": MessageLookupByLibrary.simpleMessage(
      "Un sufijo de dominio también cubre todos los subdominios.",
    ),
    "rcxMatchValue": MessageLookupByLibrary.simpleMessage("Valor"),
    "rcxMergeFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudieron traer los cambios",
    ),
    "rcxMerged": MessageLookupByLibrary.simpleMessage("Cambios traídos"),
    "rcxMergedConflicts": m112,
    "rcxModeAuto": MessageLookupByLibrary.simpleMessage("Automático"),
    "rcxModeAutoHint": MessageLookupByLibrary.simpleMessage(
      "Elige el mejor servidor que funciona según el orden de servidores y cambia cuando falla.",
    ),
    "rcxModeBackToAuto": MessageLookupByLibrary.simpleMessage(
      "Devolver el modo al escenario",
    ),
    "rcxModeByScenario": MessageLookupByLibrary.simpleMessage(
      "El escenario fija el modo en esta red",
    ),
    "rcxModeIs": m113,
    "rcxModeKeep": MessageLookupByLibrary.simpleMessage("No cambiar"),
    "rcxModeManual": MessageLookupByLibrary.simpleMessage("Manual"),
    "rcxModeManualHint": MessageLookupByLibrary.simpleMessage(
      "El grupo mantiene el servidor que elijas en Proxies.",
    ),
    "rcxModeManualNow": MessageLookupByLibrary.simpleMessage(
      "Elegiste el modo tú mismo; el escenario espera hasta que elijas «Por escenario»",
    ),
    "rcxModePinnedHint": m114,
    "rcxModeScenario": MessageLookupByLibrary.simpleMessage("Por escenario"),
    "rcxModeYours": MessageLookupByLibrary.simpleMessage(
      "En esta red el modo es tuyo",
    ),
    "rcxNeedsConsent": MessageLookupByLibrary.simpleMessage(
      "Necesita tu permiso",
    ),
    "rcxNetwork": m115,
    "rcxNewProfile": MessageLookupByLibrary.simpleMessage(
      "Comportamiento nuevo",
    ),
    "rcxNewScenario": MessageLookupByLibrary.simpleMessage("Nuevo escenario"),
    "rcxOnThisNetwork": MessageLookupByLibrary.simpleMessage("En esta red"),
    "rcxOnly": m116,
    "rcxOpFail": MessageLookupByLibrary.simpleMessage("falla"),
    "rcxOpIn": MessageLookupByLibrary.simpleMessage("es uno de"),
    "rcxOpIs": MessageLookupByLibrary.simpleMessage("es"),
    "rcxOpIsNot": MessageLookupByLibrary.simpleMessage("no es"),
    "rcxOpMatches": MessageLookupByLibrary.simpleMessage("coincide con"),
    "rcxOpOk": MessageLookupByLibrary.simpleMessage("tiene éxito"),
    "rcxOwnProfile": MessageLookupByLibrary.simpleMessage(
      "Según se configura en el grupo",
    ),
    "rcxOwnProfileHint": MessageLookupByLibrary.simpleMessage(
      "El grupo mantiene el comportamiento de sus propios ajustes.",
    ),
    "rcxPatternInvalid": MessageLookupByLibrary.simpleMessage(
      "El patrón no es una expresión regular válida",
    ),
    "rcxPendingTier": m117,
    "rcxPinned": m118,
    "rcxPinnedLabel": MessageLookupByLibrary.simpleMessage("Fijado"),
    "rcxPoolExclude": MessageLookupByLibrary.simpleMessage(
      "Excluir servidores",
    ),
    "rcxPoolInclude": MessageLookupByLibrary.simpleMessage("Solo servidores"),
    "rcxProblemGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "El grupo no tiene servidores",
    ),
    "rcxProblemGroupUnavailable": MessageLookupByLibrary.simpleMessage(
      "Este grupo no es un selector en la configuración actual",
    ),
    "rcxProblemProfileInvalid": m119,
    "rcxProblemProfileMissing": m120,
    "rcxProblemStoreFailed": m121,
    "rcxProfile": MessageLookupByLibrary.simpleMessage("Comportamiento"),
    "rcxProfileDescriptionHint": MessageLookupByLibrary.simpleMessage(
      "Qué hace este comportamiento",
    ),
    "rcxProfileName": MessageLookupByLibrary.simpleMessage("Nombre"),
    "rcxProgramMember": MessageLookupByLibrary.simpleMessage("Miembro"),
    "rcxReasonBest": MessageLookupByLibrary.simpleMessage(
      "Este es el mejor servidor",
    ),
    "rcxReasonBetterTier": m122,
    "rcxReasonChangeServer": m123,
    "rcxReasonChecking": MessageLookupByLibrary.simpleMessage(
      "Comprobando un candidato mejor",
    ),
    "rcxReasonConfirming": MessageLookupByLibrary.simpleMessage(
      "Un servidor más rápido necesita otra medición",
    ),
    "rcxReasonDwell": MessageLookupByLibrary.simpleMessage(
      "Cambiado hace poco; se espera antes del siguiente",
    ),
    "rcxReasonFailover": m124,
    "rcxReasonFaster": m125,
    "rcxReasonFixed": m126,
    "rcxReasonFixedMissing": m127,
    "rcxReasonFlapLimit": m128,
    "rcxReasonHoldPinned": MessageLookupByLibrary.simpleMessage(
      "Se mantiene el servidor fijado",
    ),
    "rcxReasonIdle": m129,
    "rcxReasonInitial": MessageLookupByLibrary.simpleMessage(
      "Seleccionado el mejor servidor disponible",
    ),
    "rcxReasonManual": MessageLookupByLibrary.simpleMessage("Control manual"),
    "rcxReasonNetworkChanged": MessageLookupByLibrary.simpleMessage(
      "La red cambió",
    ),
    "rcxReasonNetworkSuspect": MessageLookupByLibrary.simpleMessage(
      "La red parece caída; no se culpa a ningún servidor",
    ),
    "rcxReasonNoAlternative": MessageLookupByLibrary.simpleMessage(
      "No hay otro servidor que funcione",
    ),
    "rcxReasonOutOfPool": m130,
    "rcxReasonPaused": m131,
    "rcxReasonRouteInvalid": m132,
    "rcxReasonRouteNameTaken": m133,
    "rcxReasonRouteToMissing": m134,
    "rcxReasonSelectFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo seleccionar el servidor",
    ),
    "rcxReasonSplitOff": MessageLookupByLibrary.simpleMessage(
      "Los sitios directos vuelven a ir directos",
    ),
    "rcxReasonSplitOn": MessageLookupByLibrary.simpleMessage(
      "Los sitios directos ahora pasan por este grupo",
    ),
    "rcxReasonStranded": MessageLookupByLibrary.simpleMessage(
      "Ningún servidor del grupo funciona; se mantiene el actual",
    ),
    "rcxReasonSwitchFixed": m135,
    "rcxReasonSwitchPinned": m136,
    "rcxReasonSwitchStranded": m137,
    "rcxReasonWorking": MessageLookupByLibrary.simpleMessage(
      "Funciona; se mantiene hasta que falle",
    ),
    "rcxRouteAdd": MessageLookupByLibrary.simpleMessage("Añadir ruta"),
    "rcxRouteChoose": MessageLookupByLibrary.simpleMessage("Elegir"),
    "rcxRouteEdit": MessageLookupByLibrary.simpleMessage("Editar la ruta"),
    "rcxRouteGroup": MessageLookupByLibrary.simpleMessage(
      "Creado por una ruta",
    ),
    "rcxRouteGroupHint": m138,
    "rcxRouteName": MessageLookupByLibrary.simpleMessage("Nombre"),
    "rcxRouteNameLong": MessageLookupByLibrary.simpleMessage(
      "El nombre es demasiado largo",
    ),
    "rcxRouteNameReserved": MessageLookupByLibrary.simpleMessage(
      "Este nombre está reservado",
    ),
    "rcxRouteNew": MessageLookupByLibrary.simpleMessage("Nueva ruta"),
    "rcxRouteSendAutoHint": MessageLookupByLibrary.simpleMessage(
      "Elige automáticamente el mejor servidor que funcione.",
    ),
    "rcxRouteSendDirectHint": MessageLookupByLibrary.simpleMessage(
      "Este tráfico no pasa por el proxy.",
    ),
    "rcxRouteSendFixed": MessageLookupByLibrary.simpleMessage("Un servidor"),
    "rcxRouteSendFixedHint": MessageLookupByLibrary.simpleMessage(
      "Este tráfico siempre pasa por el servidor o grupo elegido.",
    ),
    "rcxRouteTarget": MessageLookupByLibrary.simpleMessage("Servidor"),
    "rcxRouteWhere": MessageLookupByLibrary.simpleMessage("Destino"),
    "rcxScenario": MessageLookupByLibrary.simpleMessage("Escenario"),
    "rcxScenarioDrives": m139,
    "rcxScenarioGroups": MessageLookupByLibrary.simpleMessage("Grupos"),
    "rcxScenarioKindsHint": MessageLookupByLibrary.simpleMessage(
      "Reconoce las redes mediante diagnóstico directo y cambia el modo y los grupos en cada una.",
    ),
    "rcxScenarioMode": MessageLookupByLibrary.simpleMessage("Modo de conexión"),
    "rcxScenarios": MessageLookupByLibrary.simpleMessage("Escenarios"),
    "rcxScenariosHint": MessageLookupByLibrary.simpleMessage(
      "Toca un escenario para editarlo. Los integrados y los del proveedor se abren como copias.",
    ),
    "rcxSendBest": MessageLookupByLibrary.simpleMessage("Mejor servidor"),
    "rcxSendDirect": MessageLookupByLibrary.simpleMessage("Directo"),
    "rcxServers": MessageLookupByLibrary.simpleMessage("Servidores"),
    "rcxServersMatch": m140,
    "rcxServersPattern": MessageLookupByLibrary.simpleMessage(
      "Patrón de nombre",
    ),
    "rcxSmartGroups": MessageLookupByLibrary.simpleMessage(
      "Grupos programables",
    ),
    "rcxSourceBuiltin": MessageLookupByLibrary.simpleMessage("Integrado"),
    "rcxSourceChanged": MessageLookupByLibrary.simpleMessage(
      "El original cambió",
    ),
    "rcxSourceChanges": MessageLookupByLibrary.simpleMessage("Qué cambió"),
    "rcxSourceProvider": MessageLookupByLibrary.simpleMessage("Del proveedor"),
    "rcxSourceUser": MessageLookupByLibrary.simpleMessage("Míos"),
    "rcxStranded": MessageLookupByLibrary.simpleMessage(
      "Cuando ningún servidor funciona",
    ),
    "rcxStrandedDirect": MessageLookupByLibrary.simpleMessage("Directo"),
    "rcxStrandedHold": MessageLookupByLibrary.simpleMessage(
      "Mantener el actual",
    ),
    "rcxStrategyAllServers": MessageLookupByLibrary.simpleMessage(
      "Usar todos los servidores del perfil",
    ),
    "rcxStrategyAuto": MessageLookupByLibrary.simpleMessage(
      "Elegir servidor automáticamente",
    ),
    "rcxStrategyCoreUnavailable": MessageLookupByLibrary.simpleMessage(
      "Estrategia no disponible. El grupo puede usar su comportamiento habitual.",
    ),
    "rcxStrategyEdit": MessageLookupByLibrary.simpleMessage(
      "Editar estrategia",
    ),
    "rcxStrategyHold": MessageLookupByLibrary.simpleMessage(
      "Mantener el servidor activo",
    ),
    "rcxStrategyLines": MessageLookupByLibrary.simpleMessage(
      "Escribe un servidor, grupo o proveedor existente por línea en su campo.",
    ),
    "rcxStrategyLowestLatency": MessageLookupByLibrary.simpleMessage(
      "Preferir menor latencia medida",
    ),
    "rcxStrategyNotApplied": MessageLookupByLibrary.simpleMessage(
      "No se pudo aplicar la estrategia",
    ),
    "rcxStrategyPreferNames": MessageLookupByLibrary.simpleMessage(
      "Preferir nombres que contengan",
    ),
    "rcxStrategyProfileChanged": MessageLookupByLibrary.simpleMessage(
      "Cambió el perfil activo. Vuelve a abrir el editor para guardar.",
    ),
    "rcxStrategyYaml": MessageLookupByLibrary.simpleMessage("Editar YAML"),
    "rcxStudioCharacter": MessageLookupByLibrary.simpleMessage("Carácter"),
    "rcxStudioCharacterHint": MessageLookupByLibrary.simpleMessage(
      "Cambios: con qué facilidad pasa a un servidor más rápido; comprobaciones: precisión frente a batería.",
    ),
    "rcxStudioPreview": MessageLookupByLibrary.simpleMessage(
      "Qué elegiría ahora",
    ),
    "rcxStudioPreviewHint": MessageLookupByLibrary.simpleMessage(
      "Elija un grupo para ver qué servidor elegiría este comportamiento en él.",
    ),
    "rcxStudioRanking": MessageLookupByLibrary.simpleMessage(
      "Todos los candidatos",
    ),
    "rcxStudioServersHint": MessageLookupByLibrary.simpleMessage(
      "Los servidores fuera de estas condiciones nunca se eligen.",
    ),
    "rcxSwitching": MessageLookupByLibrary.simpleMessage("Cambios"),
    "rcxTagName": MessageLookupByLibrary.simpleMessage("Nombre de la etiqueta"),
    "rcxTagNameInvalid": MessageLookupByLibrary.simpleMessage(
      "Solo letras latinas, dígitos, - y _, hasta 24",
    ),
    "rcxTags": MessageLookupByLibrary.simpleMessage("Etiquetas"),
    "rcxTagsHint": MessageLookupByLibrary.simpleMessage(
      "Una etiqueta da nombre a un conjunto de servidores una sola vez, para usarla en las preferencias como tag(name).",
    ),
    "rcxThirdParty": MessageLookupByLibrary.simpleMessage("de terceros"),
    "rcxTierLabel": MessageLookupByLibrary.simpleMessage("Etiqueta"),
    "rcxTitle": MessageLookupByLibrary.simpleMessage("Enrutamiento automático"),
    "rcxTurnOff": MessageLookupByLibrary.simpleMessage(
      "Quitar la selección programable",
    ),
    "rcxUntilCheck": m141,
    "rcxUntilConfirm": m142,
    "rcxUntilDwell": m143,
    "rcxUseCheck": m144,
    "rcxUseDiagnostic": m145,
    "rcxUseEcho": MessageLookupByLibrary.simpleMessage(
      "comprobación del país de salida",
    ),
    "rcxWarnings": MessageLookupByLibrary.simpleMessage("Advertencias"),
    "rcxWhy": MessageLookupByLibrary.simpleMessage("Por qué este servidor"),
    "rcxWouldDo": MessageLookupByLibrary.simpleMessage(
      "Comportamiento predeterminado",
    ),
    "rcxWouldServers": m146,
    "rcxYaml": MessageLookupByLibrary.simpleMessage("YAML"),
    "recentRequests": MessageLookupByLibrary.simpleMessage(
      "Solicitudes recientes",
    ),
    "recommendedIcons": MessageLookupByLibrary.simpleMessage("Sugeridos"),
    "recordType": MessageLookupByLibrary.simpleMessage("Tipo de registro"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Puerto Redir"),
    "redo": MessageLookupByLibrary.simpleMessage("Rehacer"),
    "refresh": MessageLookupByLibrary.simpleMessage("Actualizar"),
    "regex": MessageLookupByLibrary.simpleMessage("Expresión regular"),
    "releaseMemory": MessageLookupByLibrary.simpleMessage("Liberar memoria"),
    "releaseMemoryFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo liberar la memoria",
    ),
    "remote": MessageLookupByLibrary.simpleMessage("Remoto"),
    "remoteDestination": MessageLookupByLibrary.simpleMessage("Destino remoto"),
    "remoteDnsResolve": MessageLookupByLibrary.simpleMessage(
      "Resolución DNS remota",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Quitar"),
    "rename": MessageLookupByLibrary.simpleMessage("Renombrar"),
    "replace": MessageLookupByLibrary.simpleMessage("Reemplazar"),
    "replaceAll": MessageLookupByLibrary.simpleMessage("Reemplazar todo"),
    "request": MessageLookupByLibrary.simpleMessage("Solicitud"),
    "requestHeaders": MessageLookupByLibrary.simpleMessage(
      "Encabezados de solicitud",
    ),
    "requests": MessageLookupByLibrary.simpleMessage("Solicitudes"),
    "requestsAndUpdates": MessageLookupByLibrary.simpleMessage(
      "Solicitudes y actualizaciones",
    ),
    "required": MessageLookupByLibrary.simpleMessage("Obligatorio"),
    "reset": MessageLookupByLibrary.simpleMessage("Restablecer"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "Esta página tiene cambios. ¿Seguro que quieres restablecer?",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres restablecer?",
    ),
    "resourceUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Intervalo de actualización automática",
    ),
    "resourceUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "El intervalo de actualización automática debe ser mayor que 0",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("Recursos"),
    "respectRules": MessageLookupByLibrary.simpleMessage("Respetar reglas"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "Respetar reglas enruta las conexiones DNS según las reglas y requiere un Proxy Server Nameserver.",
    ),
    "responseCode": MessageLookupByLibrary.simpleMessage("Código de respuesta"),
    "restart": MessageLookupByLibrary.simpleMessage("Reiniciar"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres reiniciar el núcleo?",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Restaurar"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage(
      "Restaurar todos los datos",
    ),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage(
      "Restaurar solo los perfiles",
    ),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage(
      "Estrategia de restauración",
    ),
    "restoreStrategyCompatible": MessageLookupByLibrary.simpleMessage(
      "Compatible",
    ),
    "restoreStrategyOverride": MessageLookupByLibrary.simpleMessage(
      "Sobrescribir",
    ),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage(
      "Restauración completada",
    ),
    "result": MessageLookupByLibrary.simpleMessage("Resultado"),
    "retry": MessageLookupByLibrary.simpleMessage("Reintentar"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("Direcciones de ruta"),
    "routeBoard": MessageLookupByLibrary.simpleMessage("Ruta"),
    "routeBoardDesc": MessageLookupByLibrary.simpleMessage(
      "El camino del tráfico desde este dispositivo",
    ),
    "routeCarrier": MessageLookupByLibrary.simpleMessage("Operador"),
    "routeExcludeAddress": MessageLookupByLibrary.simpleMessage(
      "Direcciones excluidas de la ruta",
    ),
    "routeFrom": MessageLookupByLibrary.simpleMessage("Dispositivo"),
    "routeMapFlat": MessageLookupByLibrary.simpleMessage("Mapa plano"),
    "routeMapGlobe": MessageLookupByLibrary.simpleMessage("Globo 3D"),
    "routeTo": MessageLookupByLibrary.simpleMessage("Destino"),
    "routeVia": MessageLookupByLibrary.simpleMessage("Nodo"),
    "routingMark": MessageLookupByLibrary.simpleMessage(
      "Marca de enrutamiento",
    ),
    "ru": MessageLookupByLibrary.simpleMessage("Ruso"),
    "rule": MessageLookupByLibrary.simpleMessage("Regla"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage(
      "Regla lógica AND",
    ),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el dominio completo",
    ),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una palabra clave del dominio",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una expresión regular de dominio",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un sufijo de dominio",
    ),
    "ruleActionDomainWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Coincidencia con comodines; solo se admiten * y ?",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con la marca DSCP (solo entrada UDP de tproxy)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el rango de puertos de destino",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el código de país de la IP",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con los dominios de Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el nombre de la entrada",
    ),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el puerto de entrada",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el tipo de entrada",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el nombre de usuario de entrada; separa varios usuarios con /",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el ASN de la IP",
    ),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de direcciones IP; IP-CIDR6 es solo un alias",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de direcciones IP",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de sufijo de IP",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con todas las solicitudes, sin necesidad de condiciones",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con TCP o UDP",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage(
      "Regla lógica NOT",
    ),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("Regla lógica OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el nombre del proceso; en Android coincide con el nombre del paquete",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una expresión regular del nombre del proceso; en Android coincide con el nombre del paquete",
    ),
    "ruleActionProcessNameWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con comodines en el nombre del proceso; solo se admiten * y ?",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con la ruta completa del proceso",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una expresión regular de la ruta del proceso",
    ),
    "ruleActionProcessPathWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con comodines en la ruta del proceso; solo se admiten * y ?",
    ),
    "ruleActionRematchNameDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el nombre de rematch; separa varios nombres con /",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "Hace referencia a un conjunto de reglas; requiere rule-providers",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el código de país de la IP de origen",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el ASN de la IP de origen",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de direcciones IP de origen",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de sufijo de IP de origen",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el rango de puertos de origen",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una subregla; cuidado con los paréntesis",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el ID de usuario de Linux",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("La regla está vacía"),
    "ruleHitCount": m147,
    "ruleHitDetail": m148,
    "ruleHitShare": m149,
    "ruleHits": MessageLookupByLibrary.simpleMessage("Aciertos de reglas"),
    "ruleListInvalid": MessageLookupByLibrary.simpleMessage(
      "Las reglas deben ser una lista YAML con una regla por elemento, por ejemplo - DOMAIN,example.com,DIRECT",
    ),
    "rulePresetAdBlock": MessageLookupByLibrary.simpleMessage("Block Ads"),
    "rulePresetBittorrentDirect": MessageLookupByLibrary.simpleMessage(
      "BitTorrent directo",
    ),
    "rulePresetBlockDot": MessageLookupByLibrary.simpleMessage(
      "Bloquear DNS sobre TLS",
    ),
    "rulePresetBlockLoopback": MessageLookupByLibrary.simpleMessage(
      "Bloquear bucle del proxy",
    ),
    "rulePresetBlockQuic": MessageLookupByLibrary.simpleMessage(
      "Bloquear QUIC",
    ),
    "rulePresetBlockStun": MessageLookupByLibrary.simpleMessage(
      "Bloquear STUN",
    ),
    "rulePresetLanDirect": MessageLookupByLibrary.simpleMessage("LAN directa"),
    "rulePresetSystemServicesDirect": MessageLookupByLibrary.simpleMessage(
      "Apple y Microsoft directos",
    ),
    "ruleProviders": MessageLookupByLibrary.simpleMessage(
      "Proveedores de reglas",
    ),
    "ruleSet": MessageLookupByLibrary.simpleMessage("Conjunto de reglas"),
    "ruleSetEmptyTip": MessageLookupByLibrary.simpleMessage(
      "El conjunto de reglas no tiene entradas utilizables",
    ),
    "ruleSetInvalidTip": MessageLookupByLibrary.simpleMessage(
      "No se puede leer este archivo mrs",
    ),
    "ruleSetMixedTip": MessageLookupByLibrary.simpleMessage(
      "El conjunto de reglas mezcla dominios y rangos de IP, por lo que no se puede determinar su tipo",
    ),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("Destino de la regla"),
    "ruleTextInvalid": MessageLookupByLibrary.simpleMessage(
      "La regla debe empezar con un tipo admitido, por ejemplo DOMAIN,example.com,DIRECT",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("Reglas"),
    "rulesCount": m150,
    "runTime": MessageLookupByLibrary.simpleMessage("Tiempo de ejecución"),
    "running": MessageLookupByLibrary.simpleMessage("En ejecución"),
    "runtimeConfig": MessageLookupByLibrary.simpleMessage(
      "Configuración de ejecución",
    ),
    "safeMode": MessageLookupByLibrary.simpleMessage("Modo seguro"),
    "safeModeAppTitle": m151,
    "saturation": MessageLookupByLibrary.simpleMessage("Saturación"),
    "save": MessageLookupByLibrary.simpleMessage("Guardar"),
    "saveChanges": MessageLookupByLibrary.simpleMessage(
      "¿Guardar los cambios?",
    ),
    "script": MessageLookupByLibrary.simpleMessage("Script"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "Modo script: reescribe todo el perfil con un script de extensión",
    ),
    "scrollToSelected": MessageLookupByLibrary.simpleMessage(
      "Ir a la selección",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Buscar"),
    "searchHint": MessageLookupByLibrary.simpleMessage(
      "Buscar páginas, nodos, herramientas y ajustes",
    ),
    "seconds": MessageLookupByLibrary.simpleMessage("segundos"),
    "secondsCount": m152,
    "secretKey": MessageLookupByLibrary.simpleMessage("Clave"),
    "sectionsInEffect": m153,
    "select": MessageLookupByLibrary.simpleMessage("Seleccionar"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Seleccionar todo"),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage(
      "Selecciona un conjunto de reglas",
    ),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "Selecciona una estrategia de división",
    ),
    "send": MessageLookupByLibrary.simpleMessage("Enviar"),
    "sendFromPhone": MessageLookupByLibrary.simpleMessage(
      "Enviar desde el teléfono",
    ),
    "sendFromPhoneConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "¿Importar el enlace enviado desde el teléfono?",
    ),
    "sendFromPhoneDesc": MessageLookupByLibrary.simpleMessage(
      "Escanea con el teléfono para enviar un enlace a este dispositivo",
    ),
    "sendFromPhoneNoNetwork": MessageLookupByLibrary.simpleMessage(
      "Este dispositivo no está conectado a una red local",
    ),
    "sendFromPhonePageHint": MessageLookupByLibrary.simpleMessage(
      "Enlace de suscripción o enlace para compartir un proxy",
    ),
    "sendFromPhonePageSent": MessageLookupByLibrary.simpleMessage(
      "Enviado. Confirma la importación en el otro dispositivo.",
    ),
    "sendFromPhonePageTitle": MessageLookupByLibrary.simpleMessage(
      "Enviar un enlace a Skyward",
    ),
    "sendFromPhonePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Para recibir un enlace desde el teléfono, Skyward necesita el permiso Dispositivos cercanos, que le da acceso a la red local. Actívalo en los ajustes de la aplicación.",
    ),
    "sendFromPhoneTip": MessageLookupByLibrary.simpleMessage(
      "Escanea el código con la cámara del teléfono y pega el enlace en la página que se abre. Ambos dispositivos deben estar en la misma red.",
    ),
    "server": MessageLookupByLibrary.simpleMessage("Servidor"),
    "serviceAbnormalCount": m154,
    "serviceAllAvailable": MessageLookupByLibrary.simpleMessage(
      "Todo disponible",
    ),
    "serviceAvailable": MessageLookupByLibrary.simpleMessage("Disponible"),
    "serviceBlocked": MessageLookupByLibrary.simpleMessage("Bloqueado"),
    "serviceCheck": MessageLookupByLibrary.simpleMessage("Comprobar"),
    "serviceCheckAll": MessageLookupByLibrary.simpleMessage("Comprobar todo"),
    "serviceCheckedAt": m155,
    "serviceComingSoon": MessageLookupByLibrary.simpleMessage("Próximamente"),
    "serviceDisallowedIsp": MessageLookupByLibrary.simpleMessage(
      "ISP no permitido",
    ),
    "serviceFailed": MessageLookupByLibrary.simpleMessage(
      "Error en la comprobación",
    ),
    "serviceManage": MessageLookupByLibrary.simpleMessage(
      "Gestionar servicios",
    ),
    "serviceOriginalsOnly": MessageLookupByLibrary.simpleMessage(
      "Solo originales",
    ),
    "servicePending": MessageLookupByLibrary.simpleMessage("Sin comprobar"),
    "serviceRestricted": MessageLookupByLibrary.simpleMessage(
      "Acceso restringido",
    ),
    "serviceShownOnDashboard": MessageLookupByLibrary.simpleMessage(
      "Se muestra en el panel",
    ),
    "serviceStatus": MessageLookupByLibrary.simpleMessage(
      "Estado del servicio",
    ),
    "serviceUnavailable": MessageLookupByLibrary.simpleMessage("No disponible"),
    "serviceUnsupportedRegion": MessageLookupByLibrary.simpleMessage(
      "Región no compatible",
    ),
    "settingEntries": MessageLookupByLibrary.simpleMessage("ajustes"),
    "settings": MessageLookupByLibrary.simpleMessage("Ajustes"),
    "settingsCount": m156,
    "shareLinkUnreadable": m157,
    "shareLinksInvalid": MessageLookupByLibrary.simpleMessage(
      "No se pudo leer ningún proxy de los enlaces",
    ),
    "shareQrcodeTip": MessageLookupByLibrary.simpleMessage(
      "Escanea con Skyward en otro dispositivo para importar este perfil.",
    ),
    "show": MessageLookupByLibrary.simpleMessage("Mostrar"),
    "showLess": MessageLookupByLibrary.simpleMessage("Contraer"),
    "showMore": MessageLookupByLibrary.simpleMessage("Expandir"),
    "showNotificationStopAction": MessageLookupByLibrary.simpleMessage(
      "Botón de detener en la notificación",
    ),
    "showPassword": MessageLookupByLibrary.simpleMessage("Mostrar contraseña"),
    "sidebar": MessageLookupByLibrary.simpleMessage("Barra lateral"),
    "sidebarBlurDesc": MessageLookupByLibrary.simpleMessage(
      "El desenfoque de fondo deja ver el escritorio detrás de la ventana a través de la barra lateral.",
    ),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("Inicio silencioso"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "El inicio silencioso arranca sin mostrar la ventana.",
    ),
    "singleAdd": MessageLookupByLibrary.simpleMessage("Añadir uno"),
    "singleImport": MessageLookupByLibrary.simpleMessage("Importar uno"),
    "singleShareLinkOnly": MessageLookupByLibrary.simpleMessage(
      "Introduce aquí un solo enlace; para varios, usa la edición rápida de la lista",
    ),
    "singleValueTip": m158,
    "size": MessageLookupByLibrary.simpleMessage("Tamaño"),
    "skipCertVerify": MessageLookupByLibrary.simpleMessage(
      "Omitir verificación de certificado",
    ),
    "skipDomain": MessageLookupByLibrary.simpleMessage("Omitir dominios"),
    "skipDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Un dominio detectado que esté en la lista de dominios omitidos no se usa.",
    ),
    "skipDstAddress": MessageLookupByLibrary.simpleMessage(
      "Omitir direcciones de destino",
    ),
    "skipSrcAddress": MessageLookupByLibrary.simpleMessage(
      "Omitir direcciones de origen",
    ),
    "slide": MessageLookupByLibrary.simpleMessage("Deslizar"),
    "sliders": MessageLookupByLibrary.simpleMessage("Reguladores"),
    "sniffProtocols": MessageLookupByLibrary.simpleMessage("Protocolos"),
    "sniffer": MessageLookupByLibrary.simpleMessage("Sniffer"),
    "snifferStatusDesc": MessageLookupByLibrary.simpleMessage(
      "El sniffer lee el dominio del tráfico TLS, HTTP y QUIC para que las reglas puedan aplicarse.",
    ),
    "socksPort": MessageLookupByLibrary.simpleMessage("Puerto SOCKS"),
    "softStyle": MessageLookupByLibrary.simpleMessage("Suave"),
    "sort": MessageLookupByLibrary.simpleMessage("Ordenar"),
    "source": MessageLookupByLibrary.simpleMessage("Origen"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("IP de origen"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("Proxy especial"),
    "specialRules": MessageLookupByLibrary.simpleMessage("Reglas especiales"),
    "spectrum": MessageLookupByLibrary.simpleMessage("Espectro"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage(
      "Estadísticas de velocidad",
    ),
    "speedTest": MessageLookupByLibrary.simpleMessage("Prueba de conexión"),
    "speedTestDownloading": MessageLookupByLibrary.simpleMessage(
      "Probando descarga",
    ),
    "speedTestFailed": MessageLookupByLibrary.simpleMessage("Prueba fallida"),
    "speedTestMbps": MessageLookupByLibrary.simpleMessage("Mbps"),
    "speedTestMs": MessageLookupByLibrary.simpleMessage("ms"),
    "speedTestPinging": MessageLookupByLibrary.simpleMessage(
      "Midiendo latencia",
    ),
    "speedTestProvider": MessageLookupByLibrary.simpleMessage("Proveedor"),
    "speedTestReady": MessageLookupByLibrary.simpleMessage("Listo"),
    "speedTestResult": MessageLookupByLibrary.simpleMessage("Resultado"),
    "speedTestRoute": MessageLookupByLibrary.simpleMessage("Ruta de prueba"),
    "speedTestStart": MessageLookupByLibrary.simpleMessage("Iniciar prueba"),
    "speedTestStop": MessageLookupByLibrary.simpleMessage("Detener"),
    "speedTestSystemRoute": MessageLookupByLibrary.simpleMessage(
      "Ruta del sistema",
    ),
    "speedTestTesting": MessageLookupByLibrary.simpleMessage("Probando"),
    "speedTestUploading": MessageLookupByLibrary.simpleMessage(
      "Probando subida",
    ),
    "splitStrategy": MessageLookupByLibrary.simpleMessage(
      "Estrategia de división",
    ),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "La estrategia de división no puede estar vacía",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("No hay SSID"),
    "stackGvisorDesc": MessageLookupByLibrary.simpleMessage(
      "Pila de espacio de usuario gVisor: la más completa y compatible, con mayor uso de memoria. Reinicia la VPN tras el cambio.",
    ),
    "stackMipsDesc": MessageLookupByLibrary.simpleMessage(
      "Predeterminado. Pila de espacio de usuario ligera integrada en sing-tun; solo ella admite el control de congestión TCP. Reinicia la VPN tras el cambio.",
    ),
    "stackMixedDesc": MessageLookupByLibrary.simpleMessage(
      "Híbrida: TCP por la pila del núcleo del sistema y UDP por gVisor. Reinicia la VPN tras el cambio.",
    ),
    "stackMode": MessageLookupByLibrary.simpleMessage("Modo de pila"),
    "stackSystemDesc": MessageLookupByLibrary.simpleMessage(
      "TCP lo gestiona la pila del núcleo del sistema y el núcleo reenvía UDP. Reinicia la VPN tras el cambio.",
    ),
    "stackTrace": MessageLookupByLibrary.simpleMessage("Seguimiento de pila"),
    "standard": MessageLookupByLibrary.simpleMessage("Estándar"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "Modo estándar: añade reglas sobre el perfil",
    ),
    "start": MessageLookupByLibrary.simpleMessage("Iniciar"),
    "startFromScratch": MessageLookupByLibrary.simpleMessage(
      "Empezar desde cero",
    ),
    "startVpn": MessageLookupByLibrary.simpleMessage("Iniciando VPN…"),
    "startupAndBackground": MessageLookupByLibrary.simpleMessage(
      "Inicio y segundo plano",
    ),
    "status": MessageLookupByLibrary.simpleMessage("Estado"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "Con DNS desactivado, se usa el DNS del sistema.",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("Detener"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("Deteniendo VPN…"),
    "storage": MessageLookupByLibrary.simpleMessage("Almacenamiento"),
    "strategy": MessageLookupByLibrary.simpleMessage("Estrategia"),
    "strictRoute": MessageLookupByLibrary.simpleMessage("Ruta estricta"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "La ruta estricta evita que el tráfico, como el DNS, eluda TUN y, con IPv6 desactivado, bloquea las conexiones IPv6 de este dispositivo.",
    ),
    "style": MessageLookupByLibrary.simpleMessage("Estilo"),
    "submit": MessageLookupByLibrary.simpleMessage("Enviar"),
    "subscriptionInfo": MessageLookupByLibrary.simpleMessage(
      "Información de la suscripción",
    ),
    "sudoPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Introduce tu contraseña para sudo",
    ),
    "suspended": MessageLookupByLibrary.simpleMessage("Suspendido…"),
    "switchProfile": MessageLookupByLibrary.simpleMessage("Cambiar de perfil"),
    "sync": MessageLookupByLibrary.simpleMessage("Sincronizar"),
    "system": MessageLookupByLibrary.simpleMessage("Sistema"),
    "systemApp": MessageLookupByLibrary.simpleMessage("Apps del sistema"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("Proxy del sistema"),
    "tab": MessageLookupByLibrary.simpleMessage("Pestaña"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage(
      "Animación de pestañas",
    ),
    "takeoverScope": MessageLookupByLibrary.simpleMessage(
      "Alcance del tráfico",
    ),
    "takeoverScopeAlways": MessageLookupByLibrary.simpleMessage(
      "Siempre activo",
    ),
    "takeoverScopeDesc": MessageLookupByLibrary.simpleMessage(
      "Con la VPN activa, Android enruta 0.0.0.0/0 por el túnel; no hace falta un interruptor aparte.",
    ),
    "tapIconToRetry": MessageLookupByLibrary.simpleMessage(
      "Toca el icono para reintentar",
    ),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage(
      "Toca para autorizar",
    ),
    "target": MessageLookupByLibrary.simpleMessage("Destino"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP concurrente"),
    "temporary": MessageLookupByLibrary.simpleMessage("Archivos temporales"),
    "testInterval": MessageLookupByLibrary.simpleMessage("Intervalo de prueba"),
    "testUrl": MessageLookupByLibrary.simpleMessage("URL de prueba"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("Probar al usarse"),
    "textScale": MessageLookupByLibrary.simpleMessage("Escala del texto"),
    "textScalePreview": MessageLookupByLibrary.simpleMessage(
      "Así se verá el texto en la app",
    ),
    "textSection": MessageLookupByLibrary.simpleMessage("Texto"),
    "theme": MessageLookupByLibrary.simpleMessage("Tema"),
    "themeColor": MessageLookupByLibrary.simpleMessage("Color del tema"),
    "themeMode": MessageLookupByLibrary.simpleMessage("Modo del tema"),
    "thisMonth": MessageLookupByLibrary.simpleMessage("Este mes"),
    "tight": MessageLookupByLibrary.simpleMessage("Ajustado"),
    "time": MessageLookupByLibrary.simpleMessage("Hora"),
    "timeout": MessageLookupByLibrary.simpleMessage("Tiempo agotado"),
    "tintedStyle": MessageLookupByLibrary.simpleMessage("Tintado"),
    "tip": MessageLookupByLibrary.simpleMessage("Consejo"),
    "today": MessageLookupByLibrary.simpleMessage("Hoy"),
    "toggle": MessageLookupByLibrary.simpleMessage("Alternar"),
    "tolerance": MessageLookupByLibrary.simpleMessage("Tolerancia"),
    "toolEntries": MessageLookupByLibrary.simpleMessage("Herramientas"),
    "tools": MessageLookupByLibrary.simpleMessage("Más"),
    "torch": MessageLookupByLibrary.simpleMessage("Linterna"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalDownload": MessageLookupByLibrary.simpleMessage("Descargado"),
    "totalTraffic": MessageLookupByLibrary.simpleMessage("Tráfico total"),
    "totalUpload": MessageLookupByLibrary.simpleMessage("Subido"),
    "totalUptime": MessageLookupByLibrary.simpleMessage("Tiempo de actividad"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Puerto TProxy"),
    "traffic": MessageLookupByLibrary.simpleMessage("Tráfico"),
    "trafficOverview": MessageLookupByLibrary.simpleMessage(
      "Resumen del tráfico",
    ),
    "trafficPeak": m159,
    "trafficPeakLine": m160,
    "trafficRanking": MessageLookupByLibrary.simpleMessage(
      "Clasificación de tráfico",
    ),
    "trafficTotal": m161,
    "trafficTrend": MessageLookupByLibrary.simpleMessage(
      "Tendencia del tráfico",
    ),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("Uso de tráfico"),
    "transport": MessageLookupByLibrary.simpleMessage("Transporte"),
    "transportHeaders": m162,
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunAuthorizationFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo autorizar TUN, por lo que se desactivó.",
    ),
    "tunDesc": MessageLookupByLibrary.simpleMessage(
      "TUN solo funciona en modo administrador.",
    ),
    "tunGso": MessageLookupByLibrary.simpleMessage("TUN GSO"),
    "tunGsoDesc": MessageLookupByLibrary.simpleMessage(
      "Mejora la velocidad de red. Requiere reiniciar la VPN.",
    ),
    "tunOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Las entradas añadidas aquí sustituyen los ajustes de TUN de todos los perfiles; lo que no añadas conserva el ajuste del propio perfil. Las entradas que añade un perfil personalizado tienen prioridad.",
    ),
    "tunRouteDesc": MessageLookupByLibrary.simpleMessage(
      "Una dirección de ruta vacía toma todo el tráfico; las subredes excluidas quedan fuera de la interfaz virtual.",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("Desactivar"),
    "turnOn": MessageLookupByLibrary.simpleMessage("Activar"),
    "type": MessageLookupByLibrary.simpleMessage("Tipo"),
    "udpRelayMode": MessageLookupByLibrary.simpleMessage(
      "Modo de retransmisión UDP",
    ),
    "udpTimeout": MessageLookupByLibrary.simpleMessage("Tiempo de espera UDP"),
    "udpTimeoutDesc": MessageLookupByLibrary.simpleMessage(
      "El tiempo de espera UDP se indica en segundos y solo funciona con las pilas gvisor, system y mixed.",
    ),
    "ultra": MessageLookupByLibrary.simpleMessage("Ultra"),
    "undo": MessageLookupByLibrary.simpleMessage("Deshacer"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("Latencia unificada"),
    "unknown": MessageLookupByLibrary.simpleMessage("Desconocido"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage(
      "Error de red desconocido",
    ),
    "unmaximize": MessageLookupByLibrary.simpleMessage("Restaurar tamaño"),
    "unnamed": MessageLookupByLibrary.simpleMessage("Sin nombre"),
    "unpinWindow": MessageLookupByLibrary.simpleMessage("Desfijar ventana"),
    "update": MessageLookupByLibrary.simpleMessage("Actualizar"),
    "upload": MessageLookupByLibrary.simpleMessage("Subida"),
    "uploadBandwidth": MessageLookupByLibrary.simpleMessage(
      "Ancho de banda de subida",
    ),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlTip": m163,
    "usageDetails": MessageLookupByLibrary.simpleMessage("Detalles de uso"),
    "usageStats": MessageLookupByLibrary.simpleMessage("Estadísticas de uso"),
    "useHosts": MessageLookupByLibrary.simpleMessage("Usar hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage(
      "Usar hosts del sistema",
    ),
    "usedShort": MessageLookupByLibrary.simpleMessage("usado"),
    "usedTraffic": MessageLookupByLibrary.simpleMessage("Tráfico usado"),
    "userAgent": MessageLookupByLibrary.simpleMessage("User-Agent"),
    "username": MessageLookupByLibrary.simpleMessage("Usuario"),
    "value": MessageLookupByLibrary.simpleMessage("Valor"),
    "version": MessageLookupByLibrary.simpleMessage("Versión"),
    "versionUpdate": MessageLookupByLibrary.simpleMessage(
      "Actualización de versión",
    ),
    "versionUpdateChecking": MessageLookupByLibrary.simpleMessage(
      "Comprobando…",
    ),
    "versionUpdateDownloading": MessageLookupByLibrary.simpleMessage(
      "Descargando…",
    ),
    "versionUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "Error al comprobar",
    ),
    "versionUpdateFound": MessageLookupByLibrary.simpleMessage(
      "Nueva versión disponible",
    ),
    "versionUpdateLatest": MessageLookupByLibrary.simpleMessage("Actualizado"),
    "view": MessageLookupByLibrary.simpleMessage("Ver"),
    "virtualIpv4": MessageLookupByLibrary.simpleMessage("IPv4 virtual"),
    "vividStyle": MessageLookupByLibrary.simpleMessage("Vivo"),
    "vpnBehavior": MessageLookupByLibrary.simpleMessage(
      "Comportamiento de la VPN",
    ),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "Se detectó un cambio en la configuración relacionada con la VPN",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "La VPN enruta automáticamente todo el tráfico del sistema a través de VpnService.",
    ),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage(
      "Configuración de WebDAV",
    ),
    "webrtcGuard": MessageLookupByLibrary.simpleMessage("WebRTC"),
    "webrtcGuardBlock": MessageLookupByLibrary.simpleMessage("Bloquear"),
    "webrtcGuardDesc": MessageLookupByLibrary.simpleMessage(
      "Las páginas y las llamadas preguntan a un servidor STUN la dirección pública de este equipo. Bloquear es lo más seguro, pero el punto a punto recurre a un repetidor o falla. Vía proxy entrega la dirección de salida del nodo, lo que exige un nodo con UDP. Sin cambios deja el descubrimiento a las reglas del perfil.",
    ),
    "webrtcGuardOff": MessageLookupByLibrary.simpleMessage("Sin cambios"),
    "webrtcGuardProxy": MessageLookupByLibrary.simpleMessage("Vía proxy"),
    "webrtcLeakAdvice": MessageLookupByLibrary.simpleMessage(
      "Con «Bloquear» es normal no ver una dirección reflejada. Para comprobar una fuga real, cambia temporalmente WebRTC a «Dejar pasar» en «Avanzado → Red», comprueba y vuelve a cambiarlo.",
    ),
    "webrtcLeakExternal": MessageLookupByLibrary.simpleMessage(
      "Verificar WebRTC en un navegador",
    ),
    "webrtcLeakGuard": MessageLookupByLibrary.simpleMessage(
      "Modo de protección",
    ),
    "webrtcLeakGuardOffBad": MessageLookupByLibrary.simpleMessage(
      "La protección está desactivada: una página puede leer la dirección pública del dispositivo",
    ),
    "webrtcLeakGuardProxyBad": MessageLookupByLibrary.simpleMessage(
      "El descubrimiento pasa por el proxy; el nodo debe admitir UDP",
    ),
    "webrtcLeakReflected": MessageLookupByLibrary.simpleMessage(
      "Dirección reflejada",
    ),
    "webrtcLeakStun": MessageLookupByLibrary.simpleMessage("Sonda STUN"),
    "webrtcLeakStunBlocked": MessageLookupByLibrary.simpleMessage(
      "Sin respuesta STUN, el bloqueo está activo",
    ),
    "webrtcLeakStunOpen": MessageLookupByLibrary.simpleMessage(
      "Un servidor STUN respondió",
    ),
    "webrtcLeakStunSilent": MessageLookupByLibrary.simpleMessage(
      "Sin respuesta STUN, resultado indeterminado",
    ),
    "webrtcLeakStunUnresolved": MessageLookupByLibrary.simpleMessage(
      "No se pudo resolver el host STUN: red no disponible",
    ),
    "week": MessageLookupByLibrary.simpleMessage("Semana"),
    "weeklyRange": m164,
    "whitelistMode": MessageLookupByLibrary.simpleMessage("Modo lista blanca"),
    "writeToSystem": MessageLookupByLibrary.simpleMessage(
      "Escribir en el sistema",
    ),
    "writeToSystemDesc": MessageLookupByLibrary.simpleMessage(
      "Escribir en el sistema también ajusta el reloj del sistema; Android lo ignora.",
    ),
    "yearsAgo": m165,
    "yearsAgoShort": m166,
    "yes": MessageLookupByLibrary.simpleMessage("Sí"),
    "zhCN": MessageLookupByLibrary.simpleMessage("Chino simplificado"),
  };
}
