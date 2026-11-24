import 'package:skyward/common/common.dart';
import 'package:skyward/ui/icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A round country flag, matching the official mark used elsewhere. Falls
/// back to a globe in a circle when the node has no recognizable country.
class RoundFlag extends StatelessWidget {
  const RoundFlag(this.name, {super.key, this.size = 32, this.dimmed = false});

  final String name;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final code = geoCountryOfNode(name)?.code.toLowerCase();
    final valid = code != null && RegExp(r'^[a-z]{2}$').hasMatch(code);
    final fallback = ClipOval(
      child: Container(
        width: size,
        height: size,
        color: context.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.public, size: size * 0.55),
      ),
    );
    if (!valid) return fallback;
    final flag = ClipOval(
      child: SvgPicture.asset(
        'assets/images/flags/$code.svg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => fallback,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
    if (!dimmed) return flag;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.5, 0, 0, 0, 0, //
        0, 0.5, 0, 0, 0, //
        0, 0, 0.5, 0, 0, //
        0, 0, 0, 1, 0,
      ]),
      child: flag,
    );
  }
}

/// Two overlapping flags: the entry's on the left, the exit's on the right.
class PairedFlags extends StatelessWidget {
  const PairedFlags(this.entry, this.exit, {super.key, this.size = 28});

  final String entry;
  final String exit;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.6,
    height: size,
    child: Stack(
      children: [
        Positioned(left: 0, child: RoundFlag(exit, size: size)),
        Positioned(
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colorScheme.surface,
                width: 1.5,
              ),
            ),
            child: RoundFlag(entry, size: size),
          ),
        ),
      ],
    ),
  );
}
