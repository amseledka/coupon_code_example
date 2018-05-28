require 'liqpay'

class PaymentController < ApplicationController

  skip_before_action :verify_authenticity_token

  protect_from_forgery except: :liqpay_result

  before_action do
    I18n.locale = if params.has_key?(:locale) && I18n.available_locales.include?(params[:locale].to_sym)
                    params[:locale].to_sym
                  elsif cookies[:lang].present?
                    cookies[:lang].to_sym
                  else
                    I18n.default_locale
                  end
  end

  def liqpay_result
    liqpay = Liqpay.new
    data = request.parameters['data']
    signature = request.parameters['signature']

    if liqpay.match?(data, signature)
      responce_hash = liqpay.decode_data(data)
      order = Order.find(responce_hash['order_id'])

      # TODO: Check payment status.
      if order
        cart = Cart.find(order.cart_id)

        if cart
          cart.status = :ordered
          cart.save

          if responce_hash['status'] == 'error'
            order.payment_status = :error
          elsif responce_hash['status'] == 'success' || responce_hash['status'] == 'sandbox'
            order.payment_status = :complete
          end
          order.api_response = responce_hash
          order.save

          if cart.coupon_id.present? && order.save
            Coupon.redeem(cart.coupon_id, order.id)
            cart.update_attributes(coupon_id: nil)
          end

          OrderNotifier.send_notifications(order)
          CheckoutMailer.send_notifications(order)
        end
      end

      render :nothing => true, :status => 200, :content_type => 'text/html'

    else
      Rails.logger.warn "Liqpay Results Payment Controller: looks like impossible, but signature is not the same as in the encrypted data. params: #{params.to_s}"
    end
  end

  def two_checkout_result
    return not_found unless params.has_key?('total')
    return not_found unless params.has_key?('order_number')
    return not_found unless params.has_key?('key')
    return not_found if !params.has_key?('sid') || params['sid'] != ENV['2CO_public_key']

    secret_word = ENV['2CO_secret_word']
    public_key = ENV['2CO_public_key']
    total = params['total']
    order_number = params['order_number']

    hash = "#{secret_word}#{public_key}#{order_number}#{total}"
    hash = Digest::MD5.hexdigest(hash)
    hash.upcase!

    if hash == params['key']
      order = Order.find(params['merchant_order_id'])
      if order
        cart = Cart.find(order.cart_id)
        if cart
          cart.status = :ordered
          cart.save
          order.payment_status = :complete
          order.api_response = params
          order.save

          if cart.coupon_id.present? && order.save
            Coupon.redeem(cart.coupon_id, order.id)
            cart.update_attributes(coupon_id: nil)
          end

          OrderNotifier.send_notifications(order)
          CheckoutMailer.send_notifications(order)
        end
      end
      redirect_to get_finalize_page_path
    else
      puts 'ERROR! ' + hash
    end
  end

end
