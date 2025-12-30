# GitHub Secrets Setup Guide

## Problem Identified

You have **3 workflows** that all triggered simultaneously:
1. `.github/workflows/deploy-admin-web.yml`
2. `.github/workflows/deploy-passenger-web.yml`  
3. `.github/workflows/deploy-to-azure-vm.yml` (old backend workflow)

All 3 failed with SSH authentication error because **GitHub Secrets are not configured yet**.

## Fix Steps

### Step 1: Configure GitHub Secrets

1. **Go to your GitHub repository**:
   ```
   https://github.com/YOUR_USERNAME/YOUR_REPO/settings/secrets/actions
   ```

2. **Add these 3 secrets** (click "New repository secret" for each):

#### Secret 1: AZURE_VM_HOST
```
Name: AZURE_VM_HOST
Value: 57.159.31.172
```

#### Secret 2: AZURE_VM_USERNAME
```
Name: AZURE_VM_USERNAME
Value: akhileshallewar880
```

#### Secret 3: AZURE_VM_SSH_KEY
```
Name: AZURE_VM_SSH_KEY
Value: [Paste the ENTIRE contents of akhileshallewar880-key.pem]
```

**To get the SSH key contents:**
```bash
cat server/ride_sharing_application/akhileshallewar880-key.pem
```

**Copy the ENTIRE output** including:
- `-----BEGIN RSA PRIVATE KEY-----`
- All the encoded lines
- `-----END RSA PRIVATE KEY-----`

**Important:** 
- Paste it as-is with all line breaks
- Don't add quotes or modify it
- Should look like this in the secret value:
  ```
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA...
  [many lines of encoded text]
  ...
  -----END RSA PRIVATE KEY-----
  ```

### Step 2: Prevent Multiple Workflows from Triggering

The old backend workflow `.github/workflows/deploy-to-azure-vm.yml` is conflicting with the new web deployment workflows. You have 2 options:

#### Option A: Disable the old workflow (Recommended)
Rename it to prevent it from running:
```bash
mv .github/workflows/deploy-to-azure-vm.yml .github/workflows/deploy-to-azure-vm.yml.disabled
```

#### Option B: Fix the path filters
Keep all 3 workflows but ensure they only trigger for their specific directories (I can help with this).

### Step 3: Test the Deployment

After configuring secrets:

1. **Make a small change** to test:
   ```bash
   # Test admin deployment
   echo "# Updated $(date)" >> admin_web/README.md
   git add admin_web/README.md
   git commit -m "test: trigger admin deployment"
   git push
   ```

2. **Check GitHub Actions tab** to see the workflow run

3. **Verify deployment** by accessing:
   - Admin: http://57.159.31.172/
   - Passenger: http://57.159.31.172:81/

## Common Issues

### Issue: "Permission denied (publickey)"
- **Cause**: SSH key not configured or incorrectly formatted in GitHub Secrets
- **Fix**: Double-check the AZURE_VM_SSH_KEY secret includes the full key with headers

### Issue: Multiple workflows running at once
- **Cause**: Overlapping `paths` triggers in workflow files
- **Fix**: Use more specific path filters or disable unused workflows

### Issue: "tar: unexpected end of file"
- **Cause**: SCP failed to transfer the complete file
- **Fix**: Check SSH authentication first (this is likely your current issue)

## Quick Commands

### Display SSH key for copying:
```bash
cat server/ride_sharing_application/akhileshallewar880-key.pem
```

### Test SSH connection manually:
```bash
ssh -i server/ride_sharing_application/akhileshallewar880-key.pem akhileshallewar880@57.159.31.172 'echo "Connection successful"'
```

### Check GitHub Actions status:
Go to: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`

### Re-run failed workflow:
1. Go to GitHub Actions tab
2. Click on the failed workflow run
3. Click "Re-run all jobs"

## Next Steps

1. ✅ Configure the 3 GitHub Secrets (Step 1)
2. ✅ Disable or fix the old backend workflow (Step 2)
3. ✅ Test with a small commit (Step 3)
4. 🔒 (Optional) Open Azure NSG ports 80 and 81 for public access

---

**Need Help?** Check the [DEPLOYMENT_COMPLETE.md](DEPLOYMENT_COMPLETE.md) for full deployment documentation.
