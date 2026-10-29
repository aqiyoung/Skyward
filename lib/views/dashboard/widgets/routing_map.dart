import 'dart:math' as math;

import 'package:skyward/common/common.dart';
import 'package:skyward/ui/ui.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

/// Where a stop sits on the route.
enum RouteStopRole {
  /// The phone or the machine the traffic starts from.
  local,

  /// A hop the subscription put in the way.
  relay,

  /// What the traffic was addressed to.
  destination,
}

@immutable
final class RouteStop {
  const RouteStop(this.country, this.role, {this.place});

  final GeoCountry country;
  final RouteStopRole role;

  /// A city or province the name points at more exactly than the country
  /// does. Without one the country's own stand-in is used.
  final GeoPlace? place;

  double get latitude => place?.latitude ?? country.latitude;

  double get longitude => place?.longitude ?? country.longitude;

  @override
  bool operator ==(Object other) =>
      other is RouteStop &&
      other.country == country &&
      other.role == role &&
      other.place == place;

  @override
  int get hashCode => Object.hash(country, role, place);

  @override
  String toString() => 'RouteStop(${country.code}, ${role.name}, $place)';
}

/// The coastlines, a ring at a time, ready to be filled.
///
/// Rasterised once from the 110m outline so the card carries no map package and
/// no runtime projection. Every ring was unwrapped across the antimeridian, cut
/// to the frame's latitudes -- which drops the Antarctic and the empty top of
/// the Arctic -- and thinned to the detail a card can show. It is written here
/// five base-36 characters a point: three for the x, which may reach past the
/// right edge because the sheet is drawn three times, and two for the y. Two
/// more characters open each ring with its length.
const _coastline = [
  '0bin1zfiptznipdzrinvzpimnzviljzuiiezlifxz5ijlzhilez2in1zf07iwiyoix1ywivnyziv6yvi',
  'ubz0itsyviwiyo05ml2ybmjhycmjoy1mlby5ml2yb08oqcvyorcw1otbvzosxwloskwjoruwpoqdwgoq',
  'cvy0cpirvzpk0w3pitwrph5wvpgaxbpe0xipc8xepcmx3pg6wkphtw0pijvvpirvz0apkeuqpmlv6poe',
  'v5pl1w7pkovqpjlvmpkhv2pidubpk3uipkeuq05pcor1pcar3pazqwp9iqhpcor104po9prpntq0pn5p',
  'vpo9pr04ppxpjpompoppxpfppxpj03pdfpjpcspdpdfpj03pcop4pcupcpcop40em09orm0kpblxorgl',
  'x7rrlvgrylu2rsltcr7luiqbltzpsluhpglwepclxup1lzdocm09or1doogotoqbp4orcq6otwqkouqr',
  '3ovtr3oy0ruoyqslov2v2oravhopyv7ooivfolfv8okcuqoiuuloixu9ohiuioijtvognueoewtsobvt',
  'io6jtpo3zu4o03u5ny6ugnwqufnv3u7nvrtjntcs2ntgrynuas4ntermnu6qxnu9r4nwtqno13qdo62o',
  'xo7hoto8tp3oa3p4ob4ohod5odocdo5ofyoeoh6obog5p5ol0puomzo3oogot04p7jnyp74o1p6pnvp7',
  'jny04o0ynvnz5npo03nno0ynv03p68nsp52nmp68ns03p73npp5yndp73np05o4rnuo3rnvo4bnmo7dn',
  'do4rnu04ny1nbnzbnhnwunkny1nb06o37nbo31ngo04nio0ynco1lnfo37nb03p58ndp3on3p58nd03p',
  '2tn4p1tmxp2tn409noimynqhmznqpmvnvsndnumnhno5n8nl5mznlvmqnoimy03ofdmtof4mmofdmt03',
  'p14mzozvmip14mz08ox4mmovbmuotcmoov7mhovwmmownm9oxhmbox4mm04o7om3o7am6o6dm0o7om30',
  '5oazlzobcm7o8cm2o8klxoazlz03oybmdow1luoybmd0noerlhog4m2ogzlsoj2lmopim7osnmsos6n4',
  'ovsnzosxnuopon6onhnnojwnboibneojfn3oinmloe9m3odkm9ocjlxoealrocslrob1lfocyl9oerlh',
  '0jo5lkso40l4o0el4o16ljo3nlco1rloo3gmlo2xmno2imko30mco1zmgo1qmdo17lvo00monyxlwo08',
  'l0o14kto38kxo5lks05o95kvo8jleo81kpo8dklo95kv09nlmmpnkhmqniamanasjqnd1jsnjll5nj6l',
  'dnlxlznlmmp0jny0konz6kxnxykynw9m8nw3m5nuxm9nt9lzns1m3nrolynq5lynoyktnpkknnr4konr',
  'bkgnt0kcnwujcnzdjqnxgkbny0ko09o6riyo5rjpo3xj3o26j9o3sivo45izo5uiso5silo6riy06mwb',
  'jjmvejlmuxjdmv7ikmwwj6mwbjj04iu2ihit0iiitwiaiu2ih06o4bigo3aiso38iao3nigo4ei7o4bi',
  'g04nyoipnxbiynzpi6nyoip04o25i1o3fi3o29ieo25i104o5vhyo55iho4lhuo5vhy04o1shpo1ihyo',
  '0jhmo1shp0co1kgao2igao2sgno1zhdo49hjo4ehuo38hlo2yhoo2bhjo0uhio0ah7o1kga04ip9gcin',
  'mgfinqg9ip9gc04idmggicagaidngbidmgg0dii3fxiksfzimgg9im3gcik1gaijagiiiagcigpgeig5',
  'gbig8g8iicg8ih8fzii3fx07nq9g8npdgcnojganoig1nq5funqyfynq9g804g4qg4g4eftg5hg0g4qg',
  '403g46fpg3mfmg46fp02g3hfkg3hfk03g2kfjg26ffg2kfj02g0tfcg0tfc0aiasf5igbfvicrfxidgf',
  'ribrfgi8kfai8lf6i5cfdi84f1iasf503iczewicbeiiczew05o1ff5o0zfdo0bexo1reho1ff504ico',
  'e5ibke6ibie3icoe504idje5idcebicqe0idje504of9c5odlciodic5of9c504lkbbqlioc1lhxbwlk',
  'bbq04l94bqlbobwla6bxl94bq05l0qb2l0abhkxjb8kxob3l0qb205ku8a9kupatkttavkt5acku8a90',
  'iolsbcol1bvohxc0oggcbofqc0obic7ockceob7cyo9wcdod6bsogcbrohfbboi3bfok7b2ol3a9om7a',
  '8omralolsbc05kula0ku8a8ktj9zkue9skula00boot9hopj9joq99foqh9qooy9soo2a2omg9volva6',
  'okqa6omt94oot9h04ir98visy8wisg8zir98v03it686iqd7zit68605h1o8cgzh89gwp7qgzd7vh1o8',
  'c0eiz07riyb7ziyz7wizb82j1q85j258uj108sj0y8jizr8riyv8kivs8kixq7riz97iiz07r05gs76v',
  'gt76ugts7dgrv71gs76v0aooj7ropk87oo184onf8iooe8yonm8tomx90omi72oni6sooj7r07kdr7ck',
  'by7ikah7gkas6xkdt6kkex6qkdr7c05kxt6gkx66okvy6fkxh6bkxt6g06g7c62g6b66g5m5zg735ug8',
  '85xg7c620nkhn5nkgk5ykiq5wkhj6dkil6dkl876kmh78km87lklb7qkhp7rkfc7ykh87kkfc7fkge7c',
  'kg170khk71khq6wkfr6okfk6fkf06jkef65kfl5nkhn5n04fue5bfsh58fub58fue5b04ib74qias4vi',
  'a44rib74q04i8h4li6k4qi734ji8h4l04fo24afr44gfo94ffo24a09i553tiac4bi9f4ei7947i4r4h',
  'i4e4ci304di4e3si553t0gk5t3lk6r3yk5e45k1k4djxc49jyc45jw340jxx3yjvq3tjwf3njxz3ljzl',
  '3sk153nk2f3pk443kk5t3l06iep3eidj3fida3aieo34ifh36iep3ebyppx2xpv53epvr3mpvi3fpyb3',
  'hq0b3qpxm3vpx646ptu3vprm3vpra3opq23qppx3zpn943pp54ppn84mpjf4vpfz5cpei55pbu5cpbd5',
  '9pad5dp905cp7f5rp8n5xp7j6np5q6sp5d73p3u75p227op1565p235vp3o5tp9550p9y4mp8p4np5h5',
  '5p4n4up1z4xoze5dp095jowd5mowg5fouu5eotk5ion15kofr6pohe6qoiw6yojk6toko6uom77coiy8',
  'xofi9poe59uocu9qo7yano9xbfo9kbwo6vc2o79beo52b3o5oapo4lamo1aavo1wacny7asnxoaxnz3b',
  '9nzwbco12b5o2mb9o2tbeo1cbhnzcbxo26cso1xdpnyteonvzf5nqqfinqdfsnpsfinoeffnlofynp8h',
  'mnp3i3nkxiwnkuijnj8idniahynghhungnhmnfqhmneuiqniojpnjzktnh2kfnfqjgne3iyndxj4nedi',
  '5ncpgpnavh0n9ngxn9sgcn6tf5n5uf5n5mfen4cfcn28fhn1qfumxbgsmvegymuwifmsij2moegymnhf',
  'iml9fnmh1egmc0ejm7sedm6vdzm51e6m1rdsm0bd7ly4d8m10emm1tecm21etm4besm6qe6m78erm96e',
  'xmaaf9m84g5m5mgmm2ngum2fh1lyuhglv1htlthhtlsmgqlp0fjlocewlkddrlkoddljnduli4dalmof',
  'clnbg9ltbhwlspi2luniem1chzm19iclxvk2lq6lulp3melqpp2lpcpllkjqell8rjli9rzlhvssldst',
  'ulbau5l7zu4l4xudl3iu4l3itjl0esckzfr0kwwpykyuo0kx0miktslgkufk6ktijwkqtk1kp7jikmoj',
  'jkiqjxkfyjtkd0k0kbhjwk7yj9k3nhyk2mhak45gdk3afdk5we8kawd9kb6ckkenbpkiibvkm9bhktfb',
  'ekujbakv8bgkw6bekvec8l0fcnl0xcvl4ed6l5gcnl6xchleid0lgmctlhmczlhvcwljiczllybhlkgb',
  'fljrblli7bmlhdbhlfbbmld6bhlboaqlctahleeahleua9lgsablj8a2lkxa1lo7aclqaablrna2lmh9',
  '7lp08olkq8xlm498ljm9fli596lj08zlge8uld89wleeabld6ablbvajlbkadlaeacl95ael9call81a',
  'il9hb7l8jb5l7wbjl4pail4ua5ky992kxp9il3rajl3kanl23ahl1bb4l0makktw9fkrg9rkpf9pkny9',
  'sknva3kllabkkvaxkijbhkg9bhkf8bnke1bekblbfkb39skcj9lkis9okjb9jkji90khp8lkg48hkg18',
  'akj38bkir80kjq84km47wkmf7pkoo7ikpl74ks26ykt470ktj62kvm5wkvz68kuo6ikw06vkxm6rkza6',
  'yl2v6nl4z6sl6m6kl6y5zl7x5wl9k63l9v5ql8r5ildj5flep5aldm56l8a5cl6o54l6w4glav3yl9c3',
  'pl7k3sl6q44l344kl2d4yl425al225nl136ckzu6bkz96iky26jkve5fktd5rks05tkqk5okpw4skqu4',
  'mkvl44kzx38l4h2pl8f2lla02dldq2clgy2jlfm2llgr2rlht2olq737lr23ilpx3nlo83pliw3jlkk3',
  'qlkp44lmu4aln03xlph43lqc41lpn3uls23llty3pltg31lwc34lwx39lvm3alvm3glwf3jm402ym4s2',
  'zm3s34m982ymaf34mbl2xmb12pme32smj835mjx30mhm2smhd2dmjx1wmnf1xmmo2amoj32mm33mmn93',
  'ompy39mpu2xmoq2wmoh2rmpa2hmny29mps23mpk1wmqm21mq72bmrb2cmqu25msk22mup21mwl27mvk1',
  'on221mn181hn2f1bn8o12nc713ngf0ynho0qnk40mnlv0pnkh0rnmt0tnn30ynr10vnu614ntx18npb1',
  'jnt11lntj1rnvn1no3i1vo3k1oo7d1po911uo8w24obt2goct26oeg2aokn29ojw20ol91wouk22oy42',
  'fp4b2fp522qp6b2tpdf2rpf730pgh2xpg42mplj2oppx2x0llzaa9m0lailz0awlzdb8m2ibgm48bcm2',
  'yalm36adm45afm52acm40a1m33aam2r9um0j9gm1j97m3b97m3b8sm1f8qlxs93lws9dlzaa905huc2w',
  'htp2zhq22thrp2mhuc2w04ppx29ppx2fpot2gppx2904ffk29fhz2cffk2fffk297shzl2shzl32i0y2',
  'ui2w3ei4r2oi7r2qi942vi953ai703li4i3ki2w41i1q47i0948hzd4ihww4rhvc5khwu5mhxs62hz86',
  '0i5a6ji846li8972iaj7mibw79iam6pie067ibz5mid65cice4oigs4nijb50il550ilg5kin55riqb5',
  '7itl63it669ixr6qizg7diuz7viog7vijl8sim48eipt85iqq8aipr8giqf8xirr92itg91iuh8qiv89',
  '1ipi9nioo9eiqh96ino98ik19sikra5igxaciiqacigoaeifoavif1aqiembbie7atidkb2ieubri92c',
  'uia2eii8oebi68d7i56dci3vd4i10d5i0ydfi00dhhyhdbhw7dbhtddohs2f8htog2hvlgdhy2g8hzdg',
  '2hzvfmi37fhi19gyi5bgxi6xh4i6ji8i8yiuiawimidpivifoi8ih8i7iixhviizirijai9ikshyimli',
  'diomicipziiiqlicit3iciskijiu6ioixyjlj18jnj3yk2j5ckpj4wl7j6ql8j6rlij7jlbjaklljawl',
  'vjc3lsjfmlxjigmgjk4mjjl0n4jkmnjjgyomjemqzjdkr8jatrcj7qrrj6gsrj1eu9j08ufiyxueiwnu',
  '5iybuxivtveismvfis7w0iprw1ipwwaiqlwdir5wairgwfippwoipax3inix8in8xfip8xoiovxwilmy',
  'limnz0ilaz0ijvz5ij9zfifnyzieyy1ighxliexxiig9wuihewxihxwdih9wbigawlih1v0ij9tqikkq',
  'eij8priekp1iapn2i95msi90mfiaolvi9glri9hlgidek5icbiziawiti9jj9i9cj3i6uixi5biii56i',
  'ni4miji2qhni1qhohywhhhvcgvhteh1hm9gchk7fwhjof5hblcthaocrhard7hg6ezhfjf4hdcemhd7e',
  'ahadduhbadmh82cfh4nc0h0raih0h8fh238gh2m8ph2d87gxn7qgx77bgvw77gqt5sgo65rgku5fgde5',
  '2gc954gch5bg8o5ig9s4yg6a5hg715lg625sg1r6dfv76sg2h5yg365lg145pfzs5jfy45nfy75efxj5',
  'bfw75cftu4wfvg4gfwz4hfzc4bfyl45fzc41fxb45fv144frs3sfvj3kfwd3kfw83pfyf3oft633ftr2',
  'yfwv2tfy62kg3n2ag5y2hgh12mgob2ygqg2rgrz2sgv72lgvx2pgwx2jgzd2sh0q2mh0v2th3s2pha62',
  'yhbk32ha437hfn36hgq3chhu37hgt33hhg30hjj2zhle36hod3ahrh38hs931htv34htu3dhvt2whti2',
  'mhus25hx72bhyl2lhxo2qhzl2s0qhba1uhas1yhd21vhei20hfn1vhhg27hh81uhkb1yhla2ehov2nho',
  'r2rhn22shnd2zhjq2vhc631hbm2xh9a2vh812ohd32kh7g2ih6w2fh9a2bh5w28h7h1xha81shba1u04',
  'hl81rhkc1xhiq1qhl81r06ie71uieb1wiaz1xi9l1oicf1oie71u17i3p1ti4i1zi5g1ri821oi9o24i',
  'co1xige26igi2biif28imv2minu2vily2ziq038iri3git43hiqz3zio43mims3nimn3sipj45iq84ei',
  'pv4lilz4bioo4sijo4jifr42ict46ibx43icm3wign3uihq39ido2yieb2vibi2mi932qi1i2ji0n2gi',
  '1q2ci0a2chzy22i1s1qi4g1ni3p1t0bhpi1nhsu1qhrv1vhtf1zht827hrk2bhna1zhnb1whpf1xhoa1',
  'rhpi1n04ooh1tokn1romw1mooh1t07hwv1xhvr24hul24hui1mhvj1khzm1mhwv1x09h4t2ah242fgz7',
  '25h181oh081ih7t1jh9w1qh631zh4t2a05ovt1boun1for31aorb17ovt1b05hwf1chvv1fht51chv61',
  '5hwf1c06oq016op71dojp1foho19ojl11oq01608hrf0vhrr1chq21dhoy1bhoz16hna16hn80zhrf0v',
  '0chhf10hht14hjt12hjd1chbq1hhdq1ah7n19ha00yhgj17hf20yhg00vhhf100cm7y2gm3z2gm1u29m',
  '5z1bmbo10miv0tmiw10mc419m8w1im5r21m5z29m7y2g0chvc0shyi0vi1016i9a15iam1ci8g1hi221',
  'hhxo1dhw50zhsu0vht70rhvc0s06h970mh890xh3r13h2c11h670oh970m03hw70ohtj0lhw70o06hfe',
  '0mhdh0phby0mhea0ihfq0jhfe0m06la60kl7w0ol620ml660hl8a0fla60k04hfx0dhcy0fhe10bhfx0',
  'd05hu50jhrs0ihra0bhuf0fhu50j07hpt0ghq70khkj0fhlj0dhk707hp00bhpt0g05nku0gnf20knhs',
  '06nl50cnku0g0dl3j03l6x0al4b0el2d0ul140vkyw0pkzu0mkwa0bkvi03ky700kyv03l0p00l3j030',
  '4lcs00lbf05l8f06l3e0005nfk0bnag09n8400nfa00nfk0b0bi3803i4g06i150ghzb0hhx70ghw30c',
  'hwx06hv106hth00i2t00i38030gijy00idm06if108iec09if60eiap0ricm0vi9v10i0o0yi0k0ti2g',
  '0ri1y0ki5b0ni290gi5706i3j001ek2a00k0h0ck1q0tjyg0wk0c11k0l19jzh1ak0t1ijyj1jjze1qj',
  'wi1sjxt22jvs1yjv821jxz29jyd2hjwj2jjuh2ajut2gjtm2ljxr2mjs732jo235jlk3jjfs3ujcp4lj',
  'c45ajao5aj9552j7352j3m4cj183ej4f2oj1r2uj0h2rj0t2fj3v2ij1628izb27j0g1ziwh17itq11i',
  'ma12ija0sio20pihc0jihh0fip506ipj02ino00',
];

/// The latitudes the sheet's top and bottom edges sit on.
const worldMapTopLatitude = 80.0;
const worldMapBottomLatitude = -56.0;

/// The longitude the sheet's left edge sits on when the chain asks for nothing
/// else. Both edges share it: the sheet is one strip of the world, cut where
/// the strip closes.
const _leftEdgeLongitude = -180.0;

/// Every ring in one path, read once and reused at every size.
final Path _coastPath = _readCoastline();

Path _readCoastline() {
  final codes = _coastline.join();
  // A ring that closes over itself is land around water, and the outline
  // carries a few: the Caspian is a hole in the land, not a sea beside it.
  final path = Path()..fillType = PathFillType.evenOdd;
  var at = 0;
  while (at < codes.length) {
    final count = int.parse(codes.substring(at, at + 2), radix: 36);
    at += 2;
    for (var i = 0; i < count; i++) {
      final x = int.parse(codes.substring(at, at + 3), radix: 36);
      final y = int.parse(codes.substring(at + 3, at + 5), radix: 36);
      at += 5;
      final point = Offset(x * 3 / 40000 - 1.5, y / 1295);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
  }
  return path;
}

/// Draws the route a request takes, over a flat map of the world.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.stops});

  final List<RouteStop> stops;

  /// Past this the map stops growing: a tablet should not spend half a card on
  /// empty ocean, and the top of the frame is the emptiest part of it.
  static const maxHeight = 176.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = worldMapTopLatitude - worldMapBottomLatitude;
        final size = Size(
          constraints.maxWidth,
          constraints.maxWidth * span / 360,
        );
        final map = RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: _RouteMapPainter(
              stops: stops,
              land: colorScheme.onSurfaceVariant.withValues(alpha: 0.16),
              line: colorScheme.primary.withValues(alpha: 0.55),
              marker: colorScheme.primary,
              halo: colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
        );
        if (size.height <= maxHeight) {
          return map;
        }
        return SizedBox(
          height: maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            child: SizedBox.fromSize(size: size, child: map),
          ),
        );
      },
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter({
    required this.stops,
    required this.land,
    required this.line,
    required this.marker,
    required this.halo,
  });

  final List<RouteStop> stops;
  final Color land;
  final Color line;
  final Color marker;
  final Color halo;

  @override
  void paint(Canvas canvas, Size size) {
    final left = _leftEdgeOf(stops);
    _paintLand(canvas, size, left);
    final points = [for (final stop in stops) _project(stop, size, left)];
    if (points.length > 1) {
      final paint = Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, size.width / 240);
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      for (var i = 0; i < points.length - 1; i++) {
        final from = points[i];
        var to = points[i + 1];
        // A chain is only turned when it steps over the seam, so a leg wider
        // than half the sheet means one wider than a world even after that --
        // two ends of it, or a hop that really is half a world. The far end
        // comes round to the near side, and the copies below decide which side
        // of the cut the leg shows on.
        final dx = to.dx - from.dx;
        if (dx.abs() > size.width / 2) {
          to = Offset(to.dx - dx.sign * size.width, to.dy);
        }
        for (final shift in const [-1.0, 0.0, 1.0]) {
          _drawArc(canvas, from, to, shift * size.width, size, paint);
        }
      }
      canvas.restore();
    }
    _paintStops(canvas, points);
  }

  void _paintLand(Canvas canvas, Size size, double left) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // The sheet is drawn three times, a world apart, so a ring that reaches
    // past the right edge comes back in on the left.
    canvas.scale(size.width, size.height);
    // The outline is held with the antimeridian at its edges, so turning the
    // sheet moves its edges under it.
    final turn = (left + 180) / 360;
    final paint = Paint()..color = land;
    for (final copy in const [-1.0, 0.0, 1.0]) {
      canvas.save();
      canvas.translate(copy - turn, 0);
      canvas.drawPath(_coastPath, paint);
      canvas.restore();
    }
    canvas.restore();
  }

  /// A hop on the map's one flat sheet; the curve stands in for the great
  /// circle without pretending to be the exact arc.
  void _drawArc(
    Canvas canvas,
    Offset from,
    Offset to,
    double dx,
    Size size,
    Paint paint,
  ) {
    final start = Offset(from.dx + dx, from.dy);
    final end = Offset(to.dx + dx, to.dy);
    final span = end - start;
    if (span.distanceSquared < 1) {
      return;
    }
    final lift = math.min(span.distance * 0.26, size.height * 0.45);
    final top = math.max(0.0, math.min(start.dy, end.dy) - lift);
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(start.dx + span.dx / 2, top, end.dx, end.dy),
      paint,
    );
  }

  void _paintStops(Canvas canvas, List<Offset> points) {
    final fill = Paint()..color = marker;
    final haloPaint = Paint()..color = halo;
    final ring = Paint()
      ..color = marker
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final role = stops[i].role;
      final radius = role == RouteStopRole.relay ? 2.4 : 3.0;
      canvas.drawCircle(point, radius + 4.5, haloPaint);
      canvas.drawCircle(point, radius, fill);
      if (role == RouteStopRole.destination) {
        canvas.drawCircle(point, radius + 2.0, ring);
      }
    }
  }

  /// The longitude the sheet's left edge sits on for this chain.
  ///
  /// A chain whose hops reach past both sides of the cut cannot be drawn in
  /// one stroke: each hop would leave one edge and come back on the other,
  /// which reads as a break rather than as the short way round. Such a chain
  /// gets a sheet of its own -- its hops are laid end to end, each taken the
  /// short way round, and the cut is put under the middle of that run -- so
  /// every hop stays inside the frame. A chain that fits where the cut already
  /// is keeps the map as it is, so the world does not move about between
  /// routes.
  static double _leftEdgeOf(List<RouteStop> stops) {
    if (stops.length < 2) {
      return _leftEdgeLongitude;
    }
    var run = stops.first.longitude;
    var previous = run;
    var low = run;
    var high = run;
    for (final stop in stops.skip(1)) {
      // A hop the short way round: a route that doubles back then stays as
      // wide as its hops and no wider.
      run += _near(stop.longitude - previous);
      previous = stop.longitude;
      low = math.min(low, run);
      high = math.max(high, run);
    }
    if (high - low > 340) {
      // Too wide for one sheet however it is turned, so the cut stays where it
      // was rather than trading the usual map for one that cannot hold it.
      return _leftEdgeLongitude;
    }
    for (var world = -3; world <= 3; world++) {
      final cut = _leftEdgeLongitude + world * 360.0;
      if (cut > low && cut < high) {
        return (low + high) / 2 - 180.0;
      }
    }
    return _leftEdgeLongitude;
  }

  /// [degrees] folded into (-180, 180], the way a difference in longitude
  /// reads: the way round that is shorter.
  static double _near(double degrees) {
    final folded = degrees % 360;
    return folded > 180 ? folded - 360 : folded;
  }

  Offset _project(RouteStop stop, Size size, double left) {
    final x = ((stop.longitude - left) % 360) / 360;
    final y = (worldMapTopLatitude - stop.latitude) /
        (worldMapTopLatitude - worldMapBottomLatitude);
    return Offset(
      x * size.width,
      y.clamp(0.0, 1.0).toDouble() * size.height,
    );
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      oldDelegate.land != land ||
      oldDelegate.line != line ||
      oldDelegate.marker != marker ||
      oldDelegate.halo != halo ||
      !listEquals(oldDelegate.stops, stops);
}
