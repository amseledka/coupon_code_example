module CartHelper

  def empty_cart_data
    cart = {
        :amount => 0,
        :items => [],
        :total => 0
    }
  end

  def configure_cart
    if !cookies[:cart_uuid].nil? and !cookies[:user_uuid].nil?

      cart = Cart.shoppings.where(
          cart_uuid: cookies[:cart_uuid],
          user_uuid: cookies[:user_uuid]
      ).first

      if cart.nil?
        @cart = empty_cart_data
        # TODO Cookie refresh every request if cart is empty.
        cookies.delete :cart_uuid
        set_cart_uuid
        return
      end

      # Grad products.
      products = retrieve_cart_data(cart.get_products)

      total = 0
      products.each { |p| total += p[:discount_price].nil? ? p[:price] : p[:discount_price] }
      total = Coupon.find(cart.coupon_id).applied_to_amount(total) if cart.coupon_id.present?

      @cart = {
          amount: products.length,
          coupon: cart.coupon_id.present? ? Coupon.find(cart.coupon_id).code : '',
          items: products,
          total: total
      }
    else
      set_cart_uuid
      set_user_uuid
    end
  end

  def configure_order_cart(cart)
    current_locale = I18n.locale
    result = {
        total: 0,
        items: [],
        coupon: cart.coupon_id.present? ? Coupon.find(cart.coupon_id).code : '',
    }

    cart.get_products.each do |product|
      price = product.get_price
      discount_price = product.get_discount_price
      currency = render_currency

      item = {
          :id => product.id,
          :name => product.name,
          :color => product.color,
          :code => product.code,
          :regular_price => price,
          :currency => currency
      }

      if !discount_price.nil?
        result[:total] += discount_price
        sale = product.get_product_current_sale
        item[:discount_price] = discount_price
        item[:sale] = {
            :name => sale.name,
            :discount => sale.discount
        }
      else
        result[:total] += price
      end

      result[:items].push(item)
      I18n.locale = current_locale
    end

    result[:total] = Coupon.find(cart.coupon_id).applied_to_amount(result[:total]) if cart.coupon_id.present?

    result
  end

  # Assemble cart data from products to store it to JSON.
  def retrieve_cart_data(products)
    data = []
    products.each do |product|
      if product.published?
        data.append({
          id: product.id,
          name: product.name,
          price: product.get_price,
          discount_price: product.get_discount_price,
          url: product_path(product.slug),
          image: product.primary_img.shop.url,
          code: product.code,
          dimensions: product.dimensions.scan(/{key: ?(.*?), ?value: ?(.*?) ?}/),
          color: (product.color.nil? || product.color.empty?) ? nil : product.color})
      end
    end

    data
  end

end
