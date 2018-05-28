class CouponController < ApplicationController
  include CartHelper

  before_action do
    I18n.locale =
        params.has_key?(:locale) && I18n.available_locales.include?(params[:locale].to_sym) ?
            params[:locale].to_sym : I18n.default_locale
  end

  def apply_coupon
    cart = Cart.shoppings.where(
          cart_uuid: cookies[:cart_uuid],
          user_uuid: cookies[:user_uuid]
      ).first

    coupon = Coupon.find_by(code: params[:coupon])

    if cart.present? && coupon.present? && coupon.redeemable?
      if (coupon.currency == 'uah' && I18n.locale == :en) || (coupon.currency == 'usd' && I18n.locale != :en)
        render json: {
               status: 'fail'
           }
           return
       end

      cart.update_attributes(coupon_id: coupon.id)

      configure_cart
      render json: {
               status: 'success',
               cart: @cart
             }
    else
      render json: {
               status: 'fail'
             }
    end
  end

  def remove_coupon
    cart = Cart.shoppings.where(
          cart_uuid: cookies[:cart_uuid],
          user_uuid: cookies[:user_uuid]
      ).first
    if cart.present?
      cart.update_attributes(coupon_id: nil)
      configure_cart
      render json: {
               status: 'success',
               cart: @cart
             }
    else
      render json: {
               status: 'fail'
             }
    end
  end

end
