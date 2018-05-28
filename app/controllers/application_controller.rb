# Legacy controller

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include CartHelper
  include SideNavigationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action do
    set_cart_uuid
    set_user_uuid
  end
  before_action :language_change, except: :not_found

  # 404 page
  def not_found
    I18n.locale =
        !cookies[:current_lang].nil? && I18n.locale_available?(cookies[:current_lang]) ?
        cookies[:current_lang] : :en
    configure_cart
    set_settings
    respond_to do |format|
      format.html { render :template => 'errors/404', :layout => 'main', :status => :not_found }
    end
  end

  def set_cart_uuid
    if cookies[:cart_uuid].nil?
      cookies[:cart_uuid] = uuid_cookie
    end
  end

  def set_user_uuid
    if cookies[:user_uuid].nil?
      cookies[:user_uuid] = uuid_cookie
    end
  end

  def set_settings
    @settings = Setting.find_all_as_kv
  end

  def language_change
    @redirect_another_lang = false

    unless request.bot?
      # Set cookie to keep language changes.
      if cookies[:lang_is_changed].nil?
        cookies[:lang_is_changed] = false
      end

      # Set cookie with country where user is from.
      if cookies[:country_code].nil?
        cookies[:country_code] = request.location.country_code
      end

      # Set language cookie. Ukraine = Ukrainian. Other = English.
      if cookies[:lang].nil?
        if cookies[:country_code] == 'UA'
          cookies[:lang] = 'ua'
        else
          cookies[:lang] = 'en'
        end
        @redirect_another_lang = true
      end

      # Current user's language.
      cookies[:current_lang] = params[:locale]

      # Detect user's changes of the language.
      cookies[:lang_is_changed] = params.has_key?(:locale) && params[:locale] != cookies[:lang]

      # Remove coupon when coupon currency doesn't match language
      cart = Cart.shoppings.where(
          cart_uuid: cookies[:cart_uuid],
          user_uuid: cookies[:user_uuid]
        ).first

      if cart.present? && cart.coupon_id.present?
        coupon = Coupon.find(cart.coupon_id)
        if (coupon.currency == 'uah' && I18n.locale == :en) || (coupon.currency == 'usd' && I18n.locale != :en)
          cart.update_attributes(coupon_id: nil)
        end
      end
    end
  end

end
