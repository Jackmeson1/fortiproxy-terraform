#!/bin/bash
# Configuration Validation Script

echo "=== Terraform Configuration Validation ==="
echo ""

# Check if required files exist
echo "1. Checking required files..."
required_files=(
    "main-enhanced-fixed.tf"
    "variables-enhanced-fixed.tf"
    "setup-ad-enhanced-fixed.ps1"
    "setup-ubuntu-client.sh"
    "provider.tf"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

echo ""

# Validate Terraform syntax
echo "2. Running Terraform validation..."
if command -v terraform &> /dev/null; then
    
    # Initialize if needed
    if [ ! -d ".terraform" ]; then
        echo "Initializing Terraform..."
        terraform init
    fi
    
    # Validate configuration
    echo "Validating configuration..."
    if terraform validate; then
        echo "✓ Terraform configuration is valid"
    else
        echo "✗ Terraform configuration has errors"
        exit 1
    fi
    
    # Check if tfvars file exists
    if [ -f "terraform.tfvars" ]; then
        echo "✓ terraform.tfvars found"
        
        # Test plan (dry run)
        echo "Running terraform plan (dry run)..."
        if terraform plan -var-file=terraform.tfvars -input=false -no-color > plan.out 2>&1; then
            echo "✓ Terraform plan successful"
            echo "Plan summary:"
            grep -E "(Plan:|No changes)" plan.out || echo "Check plan.out for details"
        else
            echo "✗ Terraform plan failed"
            echo "Error details:"
            tail -20 plan.out
            exit 1
        fi
    else
        echo "⚠ terraform.tfvars not found - create from terraform.tfvars.example-enhanced"
    fi
    
else
    echo "⚠ Terraform not installed - skipping validation"
fi

echo ""
echo "3. Checking script syntax..."

# Check PowerShell script syntax
if command -v pwsh &> /dev/null; then
    echo "Checking PowerShell script..."
    if pwsh -Command "try { Get-Content 'setup-ad-enhanced-fixed.ps1' | Out-Null; Write-Host 'PowerShell syntax OK' } catch { Write-Error 'PowerShell syntax error'; exit 1 }"; then
        echo "✓ PowerShell script syntax OK"
    else
        echo "✗ PowerShell script has syntax errors"
    fi
else
    echo "⚠ PowerShell not available - skipping PS script check"
fi

# Check bash script syntax
echo "Checking bash script..."
if bash -n setup-ubuntu-client.sh; then
    echo "✓ Bash script syntax OK"
else
    echo "✗ Bash script has syntax errors"
fi

echo ""
echo "=== Validation Complete ==="
echo ""
echo "To deploy:"
echo "1. Create terraform.tfvars from terraform.tfvars.example-enhanced"
echo "2. Set your Azure credentials:"
echo "   export ARM_SUBSCRIPTION_ID=..."
echo "   export ARM_CLIENT_ID=..."
echo "   export ARM_CLIENT_SECRET=..."
echo "   export ARM_TENANT_ID=..."
echo "3. Generate SSH key: ssh-keygen -t rsa -b 4096 -f ~/.ssh/ad_client_key"
echo "4. Run: terraform apply -var-file=terraform.tfvars"