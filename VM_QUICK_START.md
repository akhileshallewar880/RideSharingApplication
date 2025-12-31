# 🚀 QUICK START - Run on Azure VM

## ONE-LINE SETUP

```bash
curl -sSL https://raw.githubusercontent.com/akhileshallewar880/vanyatra_rural_ride_booking/main/vm-setup-test.sh | bash
```

OR manually:

```bash
# 1. Find your repo (adjust path if needed)
cd ~/vanyatra_rural_ride_booking || cd /home/*/vanyatra_rural_ride_booking

# 2. Pull latest
git pull origin main

# 3. Run setup script
chmod +x vm-setup-test.sh
./vm-setup-test.sh
```

---

## VERIFY EVERYTHING WORKS

```bash
# Quick health check
curl http://localhost:8000/health

# Check containers
docker ps

# Check test data exists
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence"
```

---

## TEST CI/CD (On your local machine)

```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking

# Re-enable CI/CD if disabled
if [ -f .github/workflows/deploy-to-azure-vm.yml.DISABLED ]; then
  git mv .github/workflows/deploy-to-azure-vm.yml.DISABLED .github/workflows/deploy-to-azure-vm.yml
fi

# Trigger CI/CD
echo "# Test $(date)" >> README.md
git add .
git commit -m "Test CI/CD persistence"
git push origin main
```

Wait for GitHub Actions to complete, then on VM:

```bash
# Verify data still exists after CI/CD
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence"

# Should show same test data - proves persistence!
```

---

## TEST VM RESTART

```bash
# On VM
sudo reboot

# After reboot (wait 2-3 min, SSH back in)
docker ps

# Verify data survived reboot
docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence"

# Should show same test data - proves persistence!
```

---

## ✅ SUCCESS = All 3 Tests Pass

1. ✅ **Initial Setup**: API responds, test data created
2. ✅ **CI/CD Test**: Data survives deployment
3. ✅ **VM Restart**: Data survives reboot

---

## 🆘 IF ANYTHING BREAKS

```bash
# Restart everything
docker restart vanyatra-sql vanyatra-server
sleep 15
curl http://localhost:8000/health

# View logs
docker logs vanyatra-server --tail 50
docker logs vanyatra-sql --tail 50

# Check connection string
docker exec vanyatra-server printenv | grep ConnectionStrings
# Should show: Server=vanyatra-sql (NOT localhost)

# Re-run setup
cd ~/vanyatra_rural_ride_booking
./vm-setup-test.sh
```

---

## 📊 FINAL VERIFICATION COMMAND

```bash
echo "=== SYSTEM STATUS ==="
echo "Containers:" && docker ps --format "{{.Names}}: {{.Status}}"
echo ""
echo "Volume:" && docker volume ls | grep sqldata-persistent
echo ""
echo "API:" && curl -s http://localhost:8000/health | head -1
echo ""
echo "Test Data:" && docker exec vanyatra-sql /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "Akhilesh@22" -d RideSharingDb \
  -Q "SELECT * FROM TestPersistence WHERE Id=1" -h -1
```

**If all show success = YOU'RE PRODUCTION READY! 🎉**

---

For detailed guide see: **VM_COMPLETE_SETUP.md**
