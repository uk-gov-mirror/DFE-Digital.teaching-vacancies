# Preview all emails at http://localhost:3000/rails/mailers
class SubscriptionPreview < ActionMailer::Preview
  def confirmation
    unless Subscription.any?
      raise "I don't want to mess up your development database with factory-created subscriptions, so this preview won't
            run unless there is a subscription in the database."
    end
    SubscriptionMailer.confirmation(Subscription.first.id)
  end

  def update
    unless Subscription.any?
      raise "I don't want to mess up your development database with factory-created subscriptions, so this preview won't
            run unless there is a subscription in the database."
    end
    SubscriptionMailer.update(Subscription.first.id)
  end
end
