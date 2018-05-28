# Legacy controller

require 'liqpay'

class CheckoutController < ApplicationController
  include ApplicationHelper
  include CheckoutHelper
  include PaypalHelper

  protect_from_forgery except: :finalize

  layout 'checkout'
  before_action do
    I18n.locale = params[:locale]
  end

  def index
    set_settings
    configure_cart

    # Urls for the language switcher and hreflang
    @page_translations_urls = page_translations_urls('checkout_path')
  end

  def checkout
    # Validate form's data and regroup it for future processing.
    data = validate_form(params)
    errors = data[:errors]
    data = data[:data]

    # TODO: error handling
    if errors.length == 0
      set_settings

      # Get current user's cart
      cart = Cart.shoppings.where(
          cart_uuid: cookies[:cart_uuid],
          user_uuid: cookies[:user_uuid]
      ).first

      # TODO Check if order is already exist but not paid.
      # Create order.
      order = Order.new
      order.user_uuid = cookies[:user_uuid]
      order.first_name = data[:first_name]
      order.last_name = data[:last_name]
      order.email = data[:email]
      order.phone = data[:phone]

      order.cart = configure_order_cart(cart)
      order.cart_id = cart.id

      # Add currency and courier fee.
      data[:currency] = render_currency
      if data[:shipment_method] === 'courier'
        data[:delivery_fee] = render_setting(
            "common.checkout.courier.cost.#{I18n.locale === :en ? 'usd' : 'uah'}",
            @settings
        ).to_i
      end

      # Store shopping data to order.
      order.shopping_data = data

      order.shipment = data[:shipment]
      order.shipping_status = :pending
      order.payment_status = :pending
      order.order_status = :pending

      case data[:payment_method]
      when 'cash', 'cod'
        cart.status = :ordered
        cart.save

        order.payment_method = :cash
        order.save

        if cart.coupon_id && order.save
          Coupon.redeem(cart.coupon_id, order.id)
          cart.update_attributes(coupon_id: nil)
        end

        OrderNotifier.send_notifications(order)
        CheckoutMailer.send_notifications(order)

        # Respond.
        render :json => {
                   :status => 'success',
                   :data => {
                       :payment_method => :cash,
                       :redirect_to => get_finalize_page_path
                   }
               }
      when 'liqpay'
        order.payment_method = :liqpay
        order.save

        configure_liqpay order, data
      when 'two_checkout'
        order.payment_method = :two_checkout
        order.save

        configure_2_checkout order, data
      when 'paypal'
        order.payment_method = :paypal
        order.save

        render :json => configure_checkout_response(order)
      end
    end
  end

  # TODO: move to helpers
  def configure_liqpay(order, data)
    amount = order.cart[:total]
    if data[:shipment_method] === 'courier'
      amount += data[:delivery_fee]
    end

    liqpay = Liqpay.new
    data = {
        :version => '3',
        :action => 'pay',
        :amount => amount,
        :currency => currency,
        :description => I18n.t('front_end.checkout.payment_description'),
        :order_id => order.id.to_s,
        :language => I18n.locale,
        :pay_way => 'card, liqpay, privat24',
        :result_url => request.base_url + post_finalize_page_path,
        :server_url => request.base_url + liqpay_result_handler_path,
        :sandbox => Rails.env.production? ? 0 : 1
    }
    # Respond.
    render :json => {
               :status => 'success',
               :data => {
                   :payment_method => :liqpay,
                   :form => liqpay.cnb_form(data)
               }
           }
  end

  # TODO: move to helpers
  def configure_2_checkout(order, data)
    locals = {
        :total => order.cart[:total], # TODO remove from properties
        :items => order.cart[:items], # TODO remove from properties
        :currency => currency,
        :description => I18n.t('front_end.checkout.payment_description'),
        :order_id => order.id.to_s,
        :city => data[:city],
        :country => data[:country],
        :zip => data[:zip],
        :email => data[:email],
        :phone => data[:phone],
        :card_holder_name => "#{data[:first_name]} #{data[:last_name]}"
    }
    # Respond.
    render :json => {
               :status => 'success',
               :data => {
                   :payment_method => :two_checkout,
                   :form => render_to_string(
                       :partial => 'checkout/two_checkout', :locals => locals
                   )
               }
           }
  end

  def finalize
    set_settings
    cookies.delete :cart_uuid
    @page_translations_urls = page_translations_urls('get_finalize_page_path')
    render :layout => 'main'
  end

end
