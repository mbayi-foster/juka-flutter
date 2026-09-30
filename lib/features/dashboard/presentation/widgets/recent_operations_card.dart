import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/features/dashboard/domain/entities/recent_operation.dart';
import 'package:juka/features/dashboard/presentation/widgets/operation_tile.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/empty_message.dart';

/// Dernières opérations enregistrées, avec un accès à l'onglet Opérations.
class RecentOperationsCard extends StatelessWidget {
  const RecentOperationsCard({super.key, required this.operations});

  final List<RecentOperation> operations;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Dernières opérations',
      icon: Icons.receipt_long_rounded,
      trailing: TextButton(
        onPressed: () => context.go(AppRoutes.operations),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Tout voir'),
      ),
      child: operations.isEmpty
          ? const EmptyMessage(
              message: 'Aucune opération enregistrée pour le moment.',
              icon: Icons.receipt_long_rounded,
            )
          : Column(
              children: [
                for (var i = 0; i < operations.length; i++) ...[
                  if (i > 0) const Divider(height: 22),
                  OperationTile(operation: operations[i]),
                ],
              ],
            ),
    );
  }
}
