import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/carona_api.dart';
import '../api/models.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Foto de perfil da pessoa ou, sem foto, um círculo lilás com as iniciais (ou um ícone, para grupos).
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final IconData? icon;

  /// `avatarUrl` que vem da API (`/users/{id}/avatar?v=...`).
  final String? url;

  const Avatar({super.key, required this.name, this.size = 44, this.icon, this.url});

  /// Avatar de um motorista ou passageiro, com a foto se ele tiver.
  Avatar.person(Person person, {Key? key, double size = 44}) : this(key: key, name: person.name, size: size, url: person.avatarUrl);

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, color: AppColors.primary, size: size * 0.45)
          : Text(
              initials(name),
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: size * 0.34),
            ),
    );
    final path = url;
    if (path == null || icon != null) return placeholder;

    final api = Get.find<CaronaApi>();
    return ClipOval(
      child: Image.network(
        api.avatarUrl(path),
        // A rota da foto exige o mesmo token da API
        headers: api.client.authHeaders,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
      ),
    );
  }
}
