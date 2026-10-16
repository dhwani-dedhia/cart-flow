import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cartflow/core/network/network_cubit.dart';
import 'package:cartflow/core/theme/app_colors.dart';
import 'package:cartflow/features/orders/bloc/order_cubit.dart';
import 'package:cartflow/features/orders/bloc/order_state.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, networkState) {
        return BlocBuilder<OrderCubit, OrderState>(
          builder: (context, orderState) {
            final isOffline = networkState.isOffline;
            final isSyncing = orderState.isSyncingOfflineOrders;
            final pendingCount = orderState.pendingOfflineCount;

            if (!isOffline && !isSyncing && pendingCount == 0) {
              return const SizedBox.shrink();
            }

            Color bgColor;
            Color textColor;
            IconData icon;
            String message;

            if (isSyncing) {
              bgColor = AppColors.primaryContainer;
              textColor = AppColors.primaryDark;
              icon = Icons.sync;
              message = 'Syncing offline orders to server...';
            } else if (isOffline) {
              bgColor = AppColors.offlineContainer;
              textColor = AppColors.offline;
              icon = Icons.wifi_off_rounded;
              message = pendingCount > 0
                  ? 'Offline Mode — $pendingCount order(s) will auto-sync when online'
                  : 'Offline Mode — browsing cached catalog & local cart';
            } else if (pendingCount > 0) {
              bgColor = AppColors.warningContainer;
              textColor = AppColors.warning;
              icon = Icons.cloud_upload_outlined;
              message = '$pendingCount offline order(s) awaiting auto-sync';
            } else {
              return const SizedBox.shrink();
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: bgColor,
              child: Row(
                children: [
                  if (isSyncing)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  else
                    Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
