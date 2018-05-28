# encoding: UTF-8

class Cart

  include Mongoid::Document
  include SimpleEnum::Mongoid

  field :user_uuid,  type: String
  field :cart_uuid,  type: String
  field :coupon_id, type: Integer # MySQL id.
  field :created_at, type: DateTime, default: Time.now
  field :updated_at, type: DateTime, default: Time.now
  embeds_many :cart_items, cascade_callbacks: true, store_as: 'items'

  as_enum :status, shopping: 0, ordered: 1

  before_create do
    self.created_at = Time.now
  end

  before_save do
    self.updated_at = Time.now
  end

  rails_admin do
    visible false
  end

  def self.create_new_cart(cart_uuid, user_uuid)
    cart = self.new
    cart.cart_uuid = cart_uuid
    cart.user_uuid = user_uuid
    cart.status = :shopping
    cart.save
    cart
  end

  def put_cart_item(product_id)
    cart_item = cart_items.where(product_id: product_id).first
    if cart_item
      cart_item.increment
    else
      cart_items.create({ product_id: product_id, amount: 1 })
    end
    self.updated_at = Time.now
    self.save
  end

  def remove_cart_item(product_id)
    cart_item = cart_items.where(product_id: product_id).first
    cart_item.remove
    self.updated_at = Time.now
    self.save
  end

  def get_products
    result = []
    products = Product.published.where(id: get_product_ids)
    cart_items.each do |item|
      # Search for product
      put_to_result = nil
      products.each do |product|
        if product.id == item.product_id
          put_to_result = product
          break
        end
      end
      unless put_to_result.nil?
        item.amount.times { result.push(put_to_result) }
      end
    end
    result
  end

  protected
  def get_product_ids
    ids = []
    cart_items.each { |item| ids.push(item.product_id) unless ids.include?(item.product_id) }
    ids
  end

end
