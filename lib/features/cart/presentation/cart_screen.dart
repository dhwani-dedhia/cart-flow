import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../orders/bloc/order_cubit.dart';
import '../../orders/bloc/order_state.dart';
import '../../orders/presentation/order_success_dialog.dart';
import '../bloc/cart_cubit.dart';
import '../bloc/cart_state.dart';
import '../widgets/cart_item_tile.dart';
import '../../products/widgets/offline_banner.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderCubit, OrderState>(
      listener: (context, orderState) {
        if (orderState.submissionStatus == OrderSubmissionStatus.successOnline &&
            orderState.lastPlacedOrder != null) {
          context.read<CartCubit>().clearCart();
          OrderSuccessDialog.show(
            context,
            order: orderState.lastPlacedOrder!,
            isOfflineQueued: false,
          );
          context.read<OrderCubit>().resetSubmissionStatus();
        } else if (orderState.submissionStatus ==
                OrderSubmissionStatus.queuedOffline &&
            orderState.lastPlacedOrder != null) {
          context.read<CartCubit>().clearCart();
          OrderSuccessDialog.show(
            context,
            order: orderState.lastPlacedOrder!,
            isOfflineQueued: true,
          );
          context.read<OrderCubit>().resetSubmissionStatus();
        } else if (orderState.submissionStatus == OrderSubmissionStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                orderState.errorMessage ?? 'Failed to place order. Try again.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<OrderCubit>().resetSubmissionStatus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Cart'),
          actions: [
            BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                if (state.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => _showClearCartDialog(context),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  if (state.isEmpty) {
                    return _buildEmptyCart(context);
                  }

                  final items = state.itemList;

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return CartItemTile(item: items[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            if (state.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Summary Rows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items (${state.totalItemCount})',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${state.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shipping',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'FREE',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Total Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Cart Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${state.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Place Order Button
                    BlocBuilder<OrderCubit, OrderState>(
                      builder: (context, orderState) {
                        return ElevatedButton(
                          onPressed: orderState.isSubmitting
                              ? null
                              : () {
                                  context.read<OrderCubit>().placeOrder(
                                        items: state.itemList,
                                        totalAmount: state.totalAmount,
                                      );
                                },
                          child: orderState.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.lock_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Place Order'),
                                  ],
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_shopping_cart_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Looks like you haven\'t added any items to your cart yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              context.read<CartCubit>().clearCart();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
