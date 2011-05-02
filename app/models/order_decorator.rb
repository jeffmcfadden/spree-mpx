Order.class_eval do
  def discount_total
    promotion_credits.map( &:amount ).sum
  end
end
