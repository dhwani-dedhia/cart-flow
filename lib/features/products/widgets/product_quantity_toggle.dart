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
    if (product.isOutOfStock) {
      final outOfStockBtn = Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.remove_circle_outline_rounded,
              size: 15,
              color: AppColors.textMuted,
            ),
            SizedBox(width: 6),
            Text(
              'Out of Stock',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

      return isFullWidth
          ? SizedBox(width: double.infinity, height: height, child: outOfStockBtn)
          : outOfStockBtn;
    }

    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) =>
          previous.getQuantity(product.id) != current.getQuantity(product.id) ||
          previous.enforceMoq != current.enforceMoq,
      builder: (context, state) {
        final quantity = state.getQuantity(product.id);
        final enforceMoq = state.enforceMoq;
        final cartCubit = context.read<CartCubit>();

        if (quantity == 0) {
          if (enforceMoq && !product.hasSufficientStockForMoq) {
            return _buildInsufficientStockMoqButton(context, cartCubit);
          }
          return _buildAddToCartButton(context, cartCubit, enforceMoq);
        }

        return _buildQuantityStepper(
          context,
          cartCubit,
          quantity,
          enforceMoq,
        );
      },
    );
  }

  Widget _buildInsufficientStockMoqButton(
    BuildContext context,
    CartCubit cartCubit,
  ) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only ${product.stock} in stock (MOQ requires ${product.minimumOrderQuantity}). Turn off MOQ in top bar to buy available stock.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFD97706),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Turn Off MOQ',
                textColor: Colors.white,
                onPressed: () {
                  cartCubit.setMoqEnforcement(false);
                },
              ),
            ),
          );
        },
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 5),
              Text(
                'Stock < MOQ (${product.stock}/${product.minimumOrderQuantity})',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, height: height, child: button)
        : button;
  }

  Widget _buildAddToCartButton(
    BuildContext context,
    CartCubit cartCubit,
    bool enforceMoq,
  ) {
    final hasMoq = enforceMoq && product.minimumOrderQuantity > 1;

    final button = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            final success = cartCubit.addItem(product);
            if (!success && context.mounted) {
              final err = cartCubit.state.errorMessage;
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_shopping_cart_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 7),
                const Text(
                  'Add to Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                if (hasMoq) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${product.minimumOrderQuantity})',
                    style: const TextStyle(
                      color: Color(0xFFDDD6FE),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, height: height, child: button)
        : button;
  }

  Widget _buildQuantityStepper(
    BuildContext context,
    CartCubit cartCubit,
    int quantity,
    bool enforceMoq,
  ) {
    final isAtMaxStock = quantity >= product.stock;
    final threshold = enforceMoq && product.minimumOrderQuantity > 0
        ? product.minimumOrderQuantity
        : 1;

    final controls = Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepButton(
            icon: Icons.remove,
            tooltip: quantity <= threshold
                ? 'Remove (Threshold is $threshold)'
                : 'Decrease',
            onTap: () => cartCubit.decreaseQuantity(product),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _buildStepButton(
            icon: Icons.add,
            tooltip: isAtMaxStock
                ? 'Max stock reached (${product.stock})'
                : 'Increase',
            isDisabled: isAtMaxStock,
            onTap: isAtMaxStock
                ? () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Maximum available stock (${product.stock}) reached for this item.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : () => cartCubit.increaseQuantity(product),
          ),
        ],
      ),
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, height: height, child: controls)
        : controls;
  }

  Widget _buildStepButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 38,
          height: height,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: isDisabled ? AppColors.textMuted : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
