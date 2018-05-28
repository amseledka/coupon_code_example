class CreateCoupon < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :code
      t.integer :currency, default: 0, null: false
      t.integer :offer_type, default: 0, null: false
      t.integer :offer_value, default: 0, null: false
      t.string :description
      t.integer :redemption_limit, default: 1, null: false
      t.integer :coupon_redemptions_count, default: 0, null: false
      t.date :starts_at
      t.date :ends_at
    end
  end
end
