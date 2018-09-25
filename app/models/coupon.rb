class Coupon < ActiveRecord::Base
  scope :active, ->{ where arel_table[:expire].gt(Time.current).or(arel_table[:expire].eq(nil)) }

  has_many :redemptions, class_name: 'CouponRedemption'

  before_validation :fix_percents

  validates_presence_of :code, :offer_value, :offer_type, :currency
  validates_uniqueness_of :code
  validates :offer_value, length: { maximum: 9 }
  validates :description, length: { maximum: 255 }
  validates_numericality_of :offer_value,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 100,
        only_integer: true,
        if: :percent?

  validates_numericality_of :offer_value,
        greater_than_or_equal_to: 0,
        only_integer: true,
        if: :amount?

  validates_numericality_of :redemption_limit, greater_than_or_equal_to: 0

  validate :validate_dates


  enum offer_type: %i[amount percent]
  enum currency: %i[uah usd]

  after_initialize do
    self.code ||= Coupon.generate
    self.starts_at ||= Date.current
  end

  SYMBOL = '123456789ABCDEFGHJKLMNPQRTUVWXYZ'
  PARTS  = 3
  LENGTH = 4

  def applied_to_amount(val)
    if amount?
      [0, val - offer_value].max
    elsif percent?
      [0, (val - val * offer_value/100.0.to_d).round(2)].max.to_i
    else
      val
    end
  end

  def self.generate(options = { parts: PARTS })
    num_parts = options.delete(:parts)
    parts = ['GUD']
    (1..num_parts).each do |i|
      part = ''
      (1...4).each { part << random_symbol }
      part << checkdigit_alg_1(part, i)
      parts << part
    end
    parts.join('-')
  end

  def self.validate(orig, num_parts = PARTS)
    code = orig.upcase
    return unless code.start_with?("GUD")
    code.gsub!(/^GUD\-/, '')
    code.gsub!(/[^#{SYMBOL}]+/, '')
    parts = code.scan(/[#{SYMBOL}]{#{LENGTH}}/)
    return if parts.length != num_parts
    parts.each_with_index do |part, i|
      data  = part[0...(LENGTH - 1)]
      check = part[-1]
      return if check != checkdigit_alg_1(data, i + 1)
    end
    ['GUD', parts].join('-')
  end

  def redemptions_count
    coupon_redemptions_count
  end

  def has_available_redemptions?
    redemptions_count.zero? || redemptions_count < redemption_limit
  end

  def self.redeem(coupon_id, order_id)
    coupon = find(coupon_id)
    coupon.redemptions.create!(order_id: order_id)
  end

  def started?
    starts_at <= Date.current
  end

  def redeemable?
    !expired? && has_available_redemptions? && started?
  end

  def expired?
    ends_at && ends_at < Date.current
  end

  def percent?
    offer_type == 'percent'
  end

  def amount?
    offer_type == 'amount'
  end


  def bulk_generate(count)
    self.save if self.new_record?
    count.times do
      coupon = self.dup
      coupon.code = Coupon.generate
      coupon.redemption_limit = 0
      coupon.save
    end
  end

  private

  def self.checkdigit_alg_1(orig, check)
    orig.split('').each_with_index do |c, _|
      k = SYMBOL.index(c)
      check = check * 19 + k
    end
    SYMBOL[check % 31]
  end

  def fix_percents
    if percent? && offer_value > 100
      self.offer_value = 100
    end
  end

  def self.random_symbol
    SYMBOL[rand(SYMBOL.length)]
  end

  def validate_dates
    if ends_at_before_type_cast.present?
      errors.add(:ends_at, :invalid) unless ends_at.kind_of?(Date)
      errors.add(:ends_at, :coupon_already_expired) if ends_at? && ends_at < Date.current
    end

    if starts_at.present? && ends_at.present?
      errors.add(:ends_at, :coupon_ends_at) if ends_at < starts_at
    end
  end

end
