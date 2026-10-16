import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../cart/bloc/cart_cubit.dart';
import '../../cart/bloc/cart_state.dart';
import '../domain/models/product.dart';

class ProductQuantityToggle extends StatelessWidget {
  final Product product;
  final bool isFullWidth;
  final double height;

  const ProductQuantityToggle({
    super.key,
    required this.product,
    this.isFullWidth = false,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) =>
          previous.getQuantity(product.id) != current.getQuantity(product.id),
      builder: (context, state) {
        final quantity = state.getQuantity(product.id);
        final cartCubit = context.read<CartCubit>();

        if (quantity == 0) {
          final button = ElevatedButton.icon(
            onPressed: () => cartCubit.addItem(product),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(isFullWidth ? double.infinity : 0, height),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );

          return isFullWidth
              ? SizedBox(width: double.infinity, height: height, child: button)
              : button;
        }

        // Quantity controls: [-] qty [+]
        final controls = Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(
                icon: Icons.remove,
                onTap: () => cartCubit.decreaseQuantity(product),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildIconButton(
                icon: Icons.add,
                onTap: () => cartCubit.increaseQuantity(product),
              ),
            ],
          ),
        );

        return isFullWidth
            ? SizedBox(width: double.infinity, height: height, child: controls)
            : controls;
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
