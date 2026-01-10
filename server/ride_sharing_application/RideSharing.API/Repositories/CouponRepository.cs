using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace RideSharing.API.Repositories
{
    public interface ICouponRepository
    {
        Task<Coupon?> GetByCodeAsync(string code);
        Task<Coupon?> GetByIdAsync(Guid id);
        Task<List<Coupon>> GetAllActiveAsync();
        Task<Coupon> CreateAsync(Coupon coupon);
        Task<Coupon?> UpdateAsync(Guid id, Coupon coupon);
        Task<bool> DeleteAsync(Guid id);
        Task<bool> HasUserUsedCouponAsync(Guid couponId, Guid userId);
        Task<int> GetUserCouponUsageCountAsync(Guid couponId, Guid userId);
        Task<bool> HasUserMadeAnyBookingAsync(Guid userId);
        Task<CouponUsage> RecordCouponUsageAsync(CouponUsage couponUsage);
        Task<List<CouponUsage>> GetCouponUsageHistoryAsync(Guid couponId);
    }

    public class CouponRepository : ICouponRepository
    {
        private readonly RideSharingDbContext _context;

        public CouponRepository(RideSharingDbContext context)
        {
            _context = context;
        }

        public async Task<Coupon?> GetByCodeAsync(string code)
        {
            return await _context.Coupons
                .Include(c => c.CouponUsages)
                .FirstOrDefaultAsync(c => c.Code.ToUpper() == code.ToUpper());
        }

        public async Task<Coupon?> GetByIdAsync(Guid id)
        {
            return await _context.Coupons
                .Include(c => c.CouponUsages)
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<List<Coupon>> GetAllActiveAsync()
        {
            return await _context.Coupons
                .Where(c => c.IsActive && c.ValidFrom <= DateTime.UtcNow && c.ValidUntil >= DateTime.UtcNow)
                .OrderBy(c => c.Code)
                .ToListAsync();
        }

        public async Task<Coupon> CreateAsync(Coupon coupon)
        {
            await _context.Coupons.AddAsync(coupon);
            await _context.SaveChangesAsync();
            return coupon;
        }

        public async Task<Coupon?> UpdateAsync(Guid id, Coupon coupon)
        {
            var existingCoupon = await _context.Coupons.FindAsync(id);
            if (existingCoupon == null)
                return null;

            existingCoupon.Description = coupon.Description;
            existingCoupon.DiscountType = coupon.DiscountType;
            existingCoupon.DiscountValue = coupon.DiscountValue;
            existingCoupon.MaxDiscountAmount = coupon.MaxDiscountAmount;
            existingCoupon.MinOrderAmount = coupon.MinOrderAmount;
            existingCoupon.TotalUsageLimit = coupon.TotalUsageLimit;
            existingCoupon.PerUserUsageLimit = coupon.PerUserUsageLimit;
            existingCoupon.ValidFrom = coupon.ValidFrom;
            existingCoupon.ValidUntil = coupon.ValidUntil;
            existingCoupon.IsActive = coupon.IsActive;
            existingCoupon.IsFirstTimeUserOnly = coupon.IsFirstTimeUserOnly;
            existingCoupon.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return existingCoupon;
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var coupon = await _context.Coupons.FindAsync(id);
            if (coupon == null)
                return false;

            _context.Coupons.Remove(coupon);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> HasUserUsedCouponAsync(Guid couponId, Guid userId)
        {
            return await _context.CouponUsages
                .AnyAsync(cu => cu.CouponId == couponId && cu.UserId == userId);
        }

        public async Task<int> GetUserCouponUsageCountAsync(Guid couponId, Guid userId)
        {
            return await _context.CouponUsages
                .CountAsync(cu => cu.CouponId == couponId && cu.UserId == userId);
        }

        public async Task<bool> HasUserMadeAnyBookingAsync(Guid userId)
        {
            return await _context.Bookings
                .AnyAsync(b => b.PassengerId == userId && b.Status != "Cancelled");
        }

        public async Task<CouponUsage> RecordCouponUsageAsync(CouponUsage couponUsage)
        {
            await _context.CouponUsages.AddAsync(couponUsage);
            
            // Increment coupon usage count
            var coupon = await _context.Coupons.FindAsync(couponUsage.CouponId);
            if (coupon != null)
            {
                coupon.UsageCount++;
            }

            await _context.SaveChangesAsync();
            return couponUsage;
        }

        public async Task<List<CouponUsage>> GetCouponUsageHistoryAsync(Guid couponId)
        {
            return await _context.CouponUsages
                .Include(cu => cu.User)
                    .ThenInclude(u => u.Profile)
                .Include(cu => cu.Booking)
                .Where(cu => cu.CouponId == couponId)
                .OrderByDescending(cu => cu.UsedAt)
                .ToListAsync();
        }
    }
}
