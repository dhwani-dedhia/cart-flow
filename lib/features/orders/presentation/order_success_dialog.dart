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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Icon with Soft Glow
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isOfflineQueued
                    ? AppColors.offlineContainer
                    : AppColors.successContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isOfflineQueued
                            ? AppColors.offline
                            : AppColors.success)
                        .withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isOfflineQueued
                    ? Icons.cloud_done_rounded
                    : Icons.check_circle_rounded,
                size: 42,
                color: isOfflineQueued
                    ? AppColors.offlineDark
                    : AppColors.successDark,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              isOfflineQueued
                  ? 'Order Saved (Offline Mode)'
                  : 'Order Placed Successfully!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              isOfflineQueued
                  ? 'Your order has been safely queued locally. It will automatically sync to the server when connection is restored — zero action required.'
                  : 'Your order was successfully transmitted and confirmed by the cloud server.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),

            // Order details summary receipt box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Order ID',
                    '#${order.clientOrderId.substring(0, 8)}',
                  ),
                  const SizedBox(height: 8),
                  if (order.serverCartId != null) ...[
                    _buildDetailRow(
                      'Server Cart #',
                      '${order.serverCartId}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildDetailRow(
                    'Total Items',
                    '${order.items.fold<int>(0, (s, i) => s + i.quantity)} item(s)',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Total Amount',
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    isHighlight: true,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Sync State',
                    isOfflineQueued ? 'Queued (Auto-sync)' : 'Synced Online',
                    statusColor: isOfflineQueued
                        ? AppColors.offlineDark
                        : AppColors.successDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                  child: const Center(
                    child: Text(
                      'View Order History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Continue Shopping',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
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
            fontWeight: FontWeight.w500,
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
