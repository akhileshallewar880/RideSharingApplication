#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "VM Remote Execution Script"
echo "=========================================="
echo ""

# Check if VM_HOST is set
if [ -z "$VM_HOST" ]; then
    echo -e "${RED}Error: VM_HOST environment variable not set${NC}"
    echo ""
    echo "Usage:"
    echo "  export VM_HOST=<your-vm-ip-or-hostname>"
    echo "  ./execute-on-vm.sh"
    echo ""
    echo "Or run directly:"
    echo "  VM_HOST=<your-vm-ip> ./execute-on-vm.sh"
    exit 1
fi

VM_USER="akhileshallewar880"

echo -e "${YELLOW}Connecting to: $VM_USER@$VM_HOST${NC}"
echo ""

# Test SSH connection
echo "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$VM_USER@$VM_HOST" "echo 'Connection successful'" 2>/dev/null; then
    echo -e "${RED}Cannot connect to VM${NC}"
    echo ""
    echo "Please ensure:"
    echo "  1. VM is running"
    echo "  2. SSH keys are set up (run: ssh-copy-id $VM_USER@$VM_HOST)"
    echo "  3. VM IP/hostname is correct"
    echo "  4. Port 22 is open in VM firewall"
    exit 1
fi

echo -e "${GREEN}✓ SSH connection successful${NC}"
echo ""

# Execute the fix script on VM
echo "=========================================="
echo "Executing setup on VM..."
echo "=========================================="
echo ""

ssh "$VM_USER@$VM_HOST" 'bash -s' << 'ENDSSH'
#!/bin/bash

# Download and execute the fix script
echo "Downloading fix script..."
curl -sSL https://raw.githubusercontent.com/akhileshallewar880/vanyatra_rural_ride_booking/main/fix-api-now.sh -o /tmp/fix-api-now.sh

if [ $? -ne 0 ]; then
    echo "Error: Failed to download script"
    exit 1
fi

echo "Executing fix script..."
bash /tmp/fix-api-now.sh

# Clean up
rm -f /tmp/fix-api-now.sh

ENDSSH

EXIT_CODE=$?

echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ VM setup completed successfully!${NC}"
    echo ""
    echo "Verifying API..."
    echo ""
    
    # Verify API is working
    ssh "$VM_USER@$VM_HOST" 'curl -s http://localhost:8000/health || echo "API not responding yet"'
    
    echo ""
    echo "=========================================="
    echo "Your API is now accessible at:"
    echo "  http://$VM_HOST:8000"
    echo "=========================================="
else
    echo -e "${RED}❌ Setup failed with exit code: $EXIT_CODE${NC}"
    echo ""
    echo "Check logs on VM:"
    echo "  ssh $VM_USER@$VM_HOST 'docker logs vanyatra-server --tail 50'"
fi
echo ""
