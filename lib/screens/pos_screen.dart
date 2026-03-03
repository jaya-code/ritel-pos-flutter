import 'package:flutter/material.dart';
import '../state/pos_state.dart';
import '../models/product.dart';
import '../models/member.dart';
import '../models/promo.dart';
import 'package:intl/intl.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final PosState _posState = PosState();
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Keep focus on barcode scanner input for quick scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _posState.dispose();
    _barcodeController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _posState,
      builder: (context, child) {
        if (_posState.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat Data Toko...'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              // Left: Products Area
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildTopBar(),
                    _buildMemberPromoBar(),
                    Expanded(child: _buildProductGrid()),
                  ],
                ),
              ),
              // Right: Cart Panel
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildCartHeader(),
                    Expanded(child: _buildCartList()),
                    _buildCartSummary(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: _posState.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Cari nama produk atau SKU...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocusNode,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _posState.addBySku(value);
                  _barcodeController.clear();
                  _barcodeFocusNode.requestFocus();
                }
              },
              decoration: InputDecoration(
                hintText: 'Scan Barcode / SKU...',
                prefixIcon: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.blueAccent,
                ),
                filled: true,
                fillColor: Colors.blueAccent.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blueAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberPromoBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Member Dropdown
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<Member>(
              value: _posState.selectedMember,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Pilih Member',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<Member>(
                  value: null,
                  child: Text(
                    'Tanpa Member',
                    style: TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ..._posState.members.map((member) {
                  return DropdownMenuItem<Member>(
                    value: member,
                    child: Text(
                      '${member.name} (${member.points} pts)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: _posState.selectMember,
            ),
          ),
          const SizedBox(width: 16),
          // Promo Dropdown
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<Promo>(
              value: _posState.selectedPromo,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Pilih Promo',
                prefixIcon: const Icon(
                  Icons.local_offer_outlined,
                  color: Colors.orange,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<Promo>(
                  value: null,
                  child: Text(
                    'Tanpa Promo',
                    style: TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ..._posState.promos.map((promo) {
                  return DropdownMenuItem<Promo>(
                    value: promo,
                    child: Text(
                      '${promo.code} - ${promo.discountPercentage}%',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: _posState.selectPromo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _posState.filteredProducts;

    if (products.isEmpty) {
      final isSearchEmpty = _posState.searchQuery.isEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchEmpty ? Icons.qr_code_scanner : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isSearchEmpty
                  ? 'Silakan cari nama produk atau scan barcode'
                  : 'Produk tidak ditemukan',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          onTap: () => _posState.addToCart(product),
        );
      },
    );
  }

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Current Order',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _posState.cart.isEmpty ? null : _posState.clearCart,
            color: Colors.red,
            tooltip: 'Clear Cart',
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    if (_posState.cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Cart is empty',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _posState.cart.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = _posState.cart[index];
        final currencyFormat = NumberFormat.currency(
          locale: 'id',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        return Row(
          children: [
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(item.product.price),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Quantity control
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () => _posState.updateQuantity(item.product, -1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _posState.updateQuantity(item.product, 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Total price
            SizedBox(
              width: 85,
              child: Text(
                currencyFormat.format(item.totalPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartSummary() {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              Text(
                currencyFormat.format(_posState.subtotal),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          if (_posState.selectedPromo != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discount (${_posState.selectedPromo!.discountPercentage}%)',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '- ${currencyFormat.format(_posState.discountAmount)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (11%)',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              Text(
                currencyFormat.format(_posState.tax),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                currencyFormat.format(_posState.total),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _posState.cart.isEmpty
                  ? null
                  : () {
                      _showCheckoutModal(context);
                    },
              icon: const Icon(Icons.payments),
              label: const Text(
                'Pay Now',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _CheckoutModal(posState: _posState);
      },
    );
  }
}

class _CheckoutModal extends StatefulWidget {
  final PosState posState;
  const _CheckoutModal({required this.posState});

  @override
  State<_CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<_CheckoutModal> {
  String _selectedMethod = 'Tunai';
  final TextEditingController _cashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() {
      setState(() {}); // Rebuild to update the change calculation
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final total = widget.posState.total;

    double changeAmount = 0;
    if (_selectedMethod == 'Tunai') {
      final inputAmount = double.tryParse(_cashController.text) ?? 0;
      if (inputAmount > total) {
        changeAmount = inputAmount - total;
      }
    }

    return AlertDialog(
      title: const Text('Konfirmasi Pembayaran'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    currencyFormat.format(total),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Metode Pembayaran',
                prefixIcon: const Icon(Icons.payment_outlined),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: widget.posState.paymentMethods.map((method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value ?? 'Tunai';
                  _cashController.clear();
                });
              },
            ),
            if (_selectedMethod == 'Tunai') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Uang Diterima',
                  prefixText: 'Rp ',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (changeAmount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kembalian:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currencyFormat.format(changeAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickCashBtn(
                    amount: total,
                    label: 'Uang Pas',
                    onSelect: (val) =>
                        _cashController.text = val.toInt().toString(),
                  ),
                  _QuickCashBtn(
                    amount: 50000,
                    label: '50k',
                    onSelect: (val) =>
                        _cashController.text = val.toInt().toString(),
                  ),
                  _QuickCashBtn(
                    amount: 100000,
                    label: '100k',
                    onSelect: (val) =>
                        _cashController.text = val.toInt().toString(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: () async {
            double amountPaid = total; // default to total
            if (_selectedMethod == 'Tunai') {
              final parsed = double.tryParse(_cashController.text);
              print('--- CHECKOUT VALIDATION ---');
              print('Total Expected: $total');
              print('Cash Text: "${_cashController.text}"');
              print('Parsed Cash: $parsed');
              print('Difference: ${parsed != null ? (total - parsed) : "N/A"}');

              // Allow a small epsilon (e.g., 0.01) to account for double precision differences
              if (parsed == null || (total - parsed) > 0.01) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jumlah uang tidak boleh kurang dari total!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              amountPaid = parsed;
            }

            // Show loading dialog? Nah, state triggers it
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            Navigator.pop(context); // close modal

            final status = await widget.posState.checkout(
              amountPaid,
              _selectedMethod,
            );

            if (status == 'online') {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Transaksi Berhasil (Online)!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (status.startsWith('offline')) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Tersimpan Offline: $status'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 10),
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Transaksi Gagal: $status'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 10),
                ),
              );
            }
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Konfirmasi & Bayar'),
        ),
      ],
    );
  }
}

class _QuickCashBtn extends StatelessWidget {
  final double amount;
  final String label;
  final Function(double) onSelect;

  const _QuickCashBtn({
    required this.amount,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => onSelect(amount),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    child: Center(
                      child: Text(
                        product.imageUrl, // Using emoji as placeholder
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.stock > 10
                            ? Colors.green.withOpacity(0.9)
                            : Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stok: ${product.stock}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.sku,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      currencyFormat.format(product.price),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
