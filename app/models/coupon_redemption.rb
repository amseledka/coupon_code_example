class CouponRedemption < ActiveRecord::Base
  belongs_to :coupon, counter_cache: true

  def coupon_code
    coupon.code
  end
end
