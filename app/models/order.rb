# encoding: UTF-8

class Order

  include Mongoid::Document
  include SimpleEnum::Mongoid

  field :user_uuid,     type: String
  field :cart_id,       type: BSON::ObjectId
  field :first_name,    type: String
  field :last_name,     type: String
  field :email,         type: String
  field :phone,         type: String
  field :cart,          type: Hash
  field :created_at,    type: DateTime, default: Time.now
  field :updated_at,    type: DateTime, default: Time.now
  field :api_response,  type: Hash
  field :shopping_data, type: Hash

  as_enum :shipment, ukraine: 0, worldwide: 1
  as_enum :payment_method, cod: 0, liqpay: 1, paypal: 2, two_checkout: 3, cash: 4

  # TODO: add delivery_method

  as_enum :payment_status, pending: 0, complete: 1
  as_enum :shipping_status, pending: 0, shipping_now: 1, complete: 2
  as_enum :order_status, pending: 0, complete: 1

  before_update do
    self.updated_at = DateTime.now
  end
end
