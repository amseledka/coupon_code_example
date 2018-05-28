module CheckoutHelper

  def currency
    I18n.t('front_end.checkout.currency')
  end

  def validate_form(params)
    errors = []
    data = {}

    # Common fields.
    if params.has_key?('first_name') && !params['first_name'].empty?
      data[:first_name] = params['first_name']
    else
      errors.push('First name is a required field')
    end

    if params.has_key?('last_name') && !params['last_name'].empty?
      data[:last_name] = params['last_name']
    else
      errors.push('Last name is a required field')
    end

    if params.has_key?('email') && !params['email'].empty?
      data[:email] = params['email']
    else
      errors.push('E-mail is a required field')
    end

    if params.has_key?('phone') && !params['phone'].empty?
      data[:phone] = params['phone']
    else
      errors.push('Phone is a required field')
    end

    if params.has_key?('coupon') && !params['coupon'].empty?
      data[:coupon] = params['coupon']
    end

    available_shipments = %w(ukraine worldwide)
    if params.has_key?('shipment') && available_shipments.include?(params['shipment'])
      shipment = params['shipment']
      case shipment
        when 'ukraine'
          data[:shipment] = 'ukraine'
          shipment_methods = %w(nova-poshta courier)
          if params.has_key?('u-shipment-method') && shipment_methods.include?(params['u-shipment-method'])
            case params['u-shipment-method']
              when 'nova-poshta'
                data[:shipment_method] = 'nova-poshta'

                if params.has_key?('u-np-city') && !params['u-np-city'].empty?
                  data[:city] = params['u-np-city']
                else
                  errors.push('NP:City is a required field')
                end

                if params.has_key?('u-np-department') && !params['u-np-department'].empty?
                  data[:department] = params['u-np-department']
                else
                  errors.push('NP:Department is a required field')
                end

                available_payment_methods = %w(liqpay cod paypal)
                if params.has_key?('payment-method') && available_payment_methods.include?(params['payment-method'])
                  data[:payment_method] = params['payment-method']
                else
                  errors.push('Payment method error.')
                end
              when 'courier'
                data[:shipment_method] = 'courier'

                if params.has_key?('u-c-street') && !params['u-c-street'].empty?
                  data[:street] = params['u-c-street']
                else
                  errors.push('U:C:street is a required field')
                end

                if params.has_key?('u-c-home') && !params['u-c-home'].empty?
                  data[:home] = params['u-c-home']
                else
                  errors.push('U:C:home is a required field')
                end

                if params.has_key?('u-c-apartments') && !params['u-c-apartments'].empty?
                  data[:apartments] = params['u-c-apartments']
                else
                  errors.push('U:C:apartments is a required field')
                end

                if params.has_key?('u-с-company') && !params['u-с-company'].empty?
                  data[:company] = params['u-с-company']
                end
                available_payment_methods = %w(liqpay paypal cash)
                if params.has_key?('payment-method') && available_payment_methods.include?(params['payment-method'])
                  data[:payment_method] = params['payment-method']
                else
                  errors.push('Payment method error.')
                end
            end
          end
        when 'worldwide'
          # Wordwide
          data[:shipment] = 'worldwide'

          if params.has_key?('ww-country') && !params['ww-country'].empty?
            data[:country] = params['ww-country']
          else
            errors.push('WW:Country is a required field')
          end

          if params.has_key?('ww-city') && !params['ww-city'].empty?
            data[:city] = params['ww-city']
          else
            errors.push('WW:City is a required field')
          end

          if params.has_key?('ww-zip') && !params['ww-zip'].empty?
            data[:zip] = params['ww-zip']
          else
            errors.push('WW:Zip is a required field')
          end

          if params.has_key?('ww-address') && !params['ww-address'].empty?
            data[:address] = params['ww-address']
          else
            errors.push('WW:Address is a required field')
          end

          if params.has_key?('ww-apartments') && !params['ww-apartments'].empty?
            data[:apartments] = params['ww-apartments']
          end

          available_payment_methods = %w(liqpay paypal)
          if params.has_key?('payment-method') && available_payment_methods.include?(params['payment-method'])
            data[:payment_method] = params['payment-method']
          else
            errors.push('Payment method error.')
          end
        else

          # Error

      end
    end

    result = {
        :data => data,
        :errors => errors
    }
  end

end
