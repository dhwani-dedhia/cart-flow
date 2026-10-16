import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cartflow/core/theme/app_colors.dart';
import 'package:cartflow/features/orders/bloc/order_cubit.dart';
import 'package:cartflow/features/orders/bloc/order_state.dart';
import 'package:cartflow/features/orders/domain/models/order_model.dart';
import 'package:cartflow/features/products/widgets/offline_banner.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                final orders = state.orders;

                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Orders Placed Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your completed online and offline orders will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt);

    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (order.status) {
      case OrderSyncStatus.synced:
        statusColor = AppColors.success;
        statusBgColor = AppColors.successContainer;
        statusText = order.serverCartId != null
            ? 'Synced (Server Cart #${order.serverCartId})'
            : 'Synced Online';
        statusIcon = Icons.check_circle_rounded;
        break;
      case OrderSyncStatus.syncing:
        statusColor = AppColors.primary;
        statusBgColor = AppColors.primaryContainer;
        statusText = 'Syncing...';
        statusIcon = Icons.sync;
        break;
      case OrderSyncStatus.pending:
        statusColor = AppColors.offline;
        statusBgColor = AppColors.offlineContainer;
        statusText = 'Queued (Auto-syncs when online)';
        statusIcon = Icons.cloud_queue_rounded;
        break;
      case OrderSyncStatus.failed:
        statusColor = AppColors.error;
        statusBgColor = AppColors.errorContainer;
        statusText = 'Sync Failed';
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    final totalItems = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.clientOrderId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 10),

            // Items list preview
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.product.title}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 8),

            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalItems total item(s)',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            if (order.syncedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Synced at: ${DateFormat('hh:mm a, MMM dd').format(order.syncedAt!)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.synced,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
