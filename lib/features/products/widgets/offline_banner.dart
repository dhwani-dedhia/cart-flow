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

            final isVisible = isOffline || isSyncing || pendingCount > 0;

            if (!isVisible) {
              return const SizedBox.shrink();
            }

            Color bgColor;
            Color borderColor;
            Color textColor;
            IconData icon;
            String message;
            String badgeText;

            if (isSyncing) {
              bgColor = AppColors.primaryContainer;
              borderColor = AppColors.primaryLight.withValues(alpha: 0.5);
              textColor = AppColors.primaryDark;
              icon = Icons.sync_rounded;
              message = 'Syncing offline orders with cloud server...';
              badgeText = 'SYNCING';
            } else if (isOffline) {
              bgColor = AppColors.offlineContainer;
              borderColor = AppColors.offline.withValues(alpha: 0.35);
              textColor = AppColors.offlineDark;
              icon = Icons.wifi_off_rounded;
              message = pendingCount > 0
                  ? '$pendingCount order(s) queued locally • Auto-syncs on reconnect'
                  : 'Offline Mode • Browsing cached catalog & local cart';
              badgeText = 'OFFLINE';
            } else {
              bgColor = AppColors.warningContainer;
              borderColor = AppColors.warning.withValues(alpha: 0.4);
              textColor = AppColors.warningDark;
              icon = Icons.cloud_upload_rounded;
              message = '$pendingCount offline order(s) awaiting auto-sync';
              badgeText = 'PENDING';
            }

            return AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
