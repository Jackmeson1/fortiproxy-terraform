#!/bin/bash
# Syntax and Logic Check Script

echo "=== Configuration Analysis ==="
echo ""

# Check for common Terraform syntax issues
echo "1. Checking for common syntax issues..."

# Check for missing quotes
if grep -n "[^\"]\${[^}]*}[^\"(]" *.tf; then
    echo "⚠ Found unquoted variable references"
else
    echo "✓ Variable references properly quoted"
fi

# Check for missing commas
if grep -n "}$" *.tf | grep -v "^[^:]*:[[:space:]]*}" | head -5; then
    echo "✓ Block closures look correct"
fi

# Check resource naming
echo ""
echo "2. Checking resource naming..."
grep "^resource " *.tf | sed 's/.*"\([^"]*\)".*/\1/' | sort

echo ""
echo "3. Checking variable usage..."

# Extract all variables defined
echo "Defined variables:"
grep "^variable " variables-enhanced-fixed.tf | sed 's/variable "\([^"]*\)".*/\1/' | sort

echo ""
echo "Used variables:"
grep -o "\${var\.[^}]*}" *.tf | sed 's/.*\${var\.\([^}]*\)}.*/\1/' | sort | uniq

echo ""
echo "4. Template validation..."

# Check template file references
echo "Template files referenced:"
grep -o "templatefile([^)]*)" *.tf

echo ""
echo "5. Resource dependencies..."
echo "Resource references (depends_on and direct refs):"
grep -E "(depends_on|\.id)" *.tf | head -10

echo ""
echo "=== Analysis Complete ==="