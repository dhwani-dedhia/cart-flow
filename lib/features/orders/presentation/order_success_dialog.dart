import 'package:flutter/material.dart';
import 'package:cartflow/core/theme/app_colors.dart';
import 'package:cartflow/features/orders/domain/models/order_model.dart';
import 'order_history_screen.dart';

class OrderSuccessDialog extends StatelessWidget {
  final OrderModel order;
  final bool isOfflineQueued;

  const OrderSuccessDialog({
    super.key,
    required this.order,
    required this.isOfflineQueued,
  });

  static Future<void> show(
    BuildContext context, {
    required OrderModel order,
    required bool isOfflineQueued,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderSuccessDialog(
        order: order,
        isOfflineQueued: isOfflineQueued,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isOfflineQueued
                    ? AppColors.offlineContainer
                    : AppColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOfflineQueued
                    ? Icons.cloud_done_outlined
                    : Icons.check_circle_outline_rounded,
                size: 38,
                color: isOfflineQueued ? AppColors.offline : AppColors.success,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              isOfflineQueued
                  ? 'Order Saved (Offline Mode)'
                  : 'Order Placed Successfully!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              isOfflineQueued
                  ? 'Your order has been safely queued locally. It will AUTOMATICALLY sync to the server when internet connectivity is detected — no manual sync required!'
                  : 'Your order was successfully verified and placed with the server.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Order details summary box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Order ID',
                    '${order.clientOrderId.substring(0, 8)}...',
                  ),
                  const SizedBox(height: 6),
                  if (order.serverCartId != null) ...[
                    _buildDetailRow(
                      'Server Cart #',
                      '${order.serverCartId}',
                    ),
                    const SizedBox(height: 6),
                  ],
                  _buildDetailRow(
                    'Total Items',
                    '${order.items.fold<int>(0, (s, i) => s + i.quantity)} items',
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    'Total Amount',
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    isHighlight: true,
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    'Status',
                    isOfflineQueued ? 'Queued (Auto-sync)' : 'Synced Online',
                    statusColor: isOfflineQueued
                        ? AppColors.offline
                        : AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderHistoryScreen(),
                  ),
                );
              },
              child: const Text('View Order History'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Continue Shopping',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: statusColor ??
                (isHighlight ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
