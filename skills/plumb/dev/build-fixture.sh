#!/usr/bin/env bash
# Builds the eval fixture in the current directory: a small Python package with
# a git history in which one commit quietly changed money rounding.
set -eu
git init -q . 2>/dev/null
git config user.email fixture@example.com
git config user.name Fixture
c() { git add -A; git commit -q -m "$1" --date="$2 days ago"; }
mkdir -p shop tests

cat > shop/__init__.py <<'P'
P
cat > shop/money.py <<'P'
"""Money helpers. Every amount shown to a customer goes through round_money."""
from decimal import Decimal, ROUND_HALF_UP

CENT = Decimal("0.01")


def round_money(amount):
    """Round to cents, halves up, the way the accounting team expects."""
    return Decimal(amount).quantize(CENT, rounding=ROUND_HALF_UP)
P
cat > shop/cart.py <<'P'
from decimal import Decimal

from shop.money import round_money


def total(items, discount_pct=0):
    """items: list of (unit_price, quantity). Returns the discounted total."""
    gross = sum(Decimal(str(price)) * qty for price, qty in items)
    return round_money(gross * (Decimal(100) - Decimal(str(discount_pct))) / 100)
P
cat > shop/invoice.py <<'P'
from decimal import Decimal

from shop.cart import total
from shop.money import round_money

TAX_PCT = Decimal("9")


def invoice_total(items, discount_pct=0):
    net = total(items, discount_pct=discount_pct)
    return round_money(net * (100 + TAX_PCT) / 100)
P
cat > tests/__init__.py <<'P'
P
cat > tests/test_cart.py <<'P'
import unittest
from decimal import Decimal

from shop.cart import total


class CartTotalTest(unittest.TestCase):
    def test_whole_numbers(self):
        self.assertEqual(total([(10, 2), (5, 1)]), Decimal("25.00"))

    def test_with_discount(self):
        self.assertEqual(total([(100, 1)], discount_pct=10), Decimal("90.00"))
P
c "cart, invoice and money helpers" 40

python3 - <<'P'
rows = "\n".join(f'    ("SKU-{i:04d}", "Product {i}", "{(i * 37 % 900) + 99}.{i % 100:02d}"),' for i in range(1, 801))
open("shop/catalog.py", "w").write('"""Static product catalogue (sku, name, price)."""\n\nCATALOG = [\n' + rows + "\n]\n")
P
c "add product catalogue" 33

cat > shop/report.py <<'P'
from shop.cart import total
from shop.money import round_money


def monthly_summary(orders):
    """orders: list of item lists. Returns (order count, revenue, average)."""
    revenue = sum(total(items) for items in orders)
    average = round_money(revenue / len(orders)) if orders else round_money(0)
    return len(orders), round_money(revenue), average
P
c "monthly summary report" 27

cat > shop/receipt.py <<'P'
from decimal import Decimal

from shop.cart import total


def receipt_lines(items):
    """Lines printed on the till receipt."""
    net = total(items)
    vat = (net * Decimal("0.09")).quantize(Decimal("0.01"))
    return [f"Subtotal {net}", f"VAT 9% {vat}", f"Total {net + vat}"]
P
c "till receipt" 25

cat > README.md <<'P'
# shop

Tiny order maths: `shop.cart.total`, `shop.invoice.invoice_total`,
`shop.report.monthly_summary`, `shop.receipt.receipt_lines`.
Invoices and receipts add 9% VAT. Run tests with `python3 -m unittest`.
P
c "readme" 21

cat > shop/shipping.py <<'P'
from decimal import Decimal

RATES = {"standard": Decimal("4.90"), "express": Decimal("11.50")}


def shipping_cost(method, free_over=None, order_total=None):
    if free_over is not None and order_total is not None and order_total >= free_over:
        return Decimal("0.00")
    return RATES[method]
P
c "shipping rates" 15

cat > shop/money.py <<'P'
"""Money helpers. Every amount shown to a customer goes through round_money."""
from decimal import Decimal


def round_money(amount):
    """Round to cents."""
    return Decimal(int(Decimal(amount) * 100)) / 100


def format_money(amount, symbol="$"):
    return f"{symbol}{round_money(amount):,.2f}"
P
c "money: add format_money, tidy helpers" 8

cat >> tests/test_cart.py <<'P'

    def test_empty_cart(self):
        self.assertEqual(total([]), Decimal("0.00"))
P
c "test: empty cart" 6

sed -i.bak 's/"express": Decimal("11.50")/"express": Decimal("12.00")/' shop/shipping.py && rm shop/shipping.py.bak
c "shipping: express now 12.00" 3

printf '\nShipping lives in `shop.shipping`.\n' >> README.md
c "readme: mention shipping" 1
