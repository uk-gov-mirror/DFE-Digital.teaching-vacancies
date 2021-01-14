class Publisher < ApplicationRecord
  include Auditor::Model

  devise :omniauthable, :timeoutable, omniauth_providers: %i[dfe]
  self.timeout_in = 60.minutes # Overrides default Devise configuration

  has_many :emergency_login_keys

  def accepted_terms_and_conditions?
    accepted_terms_at.present?
  end
end
