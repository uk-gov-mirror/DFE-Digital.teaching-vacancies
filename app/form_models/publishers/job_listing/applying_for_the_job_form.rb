class Publishers::JobListing::ApplyingForTheJobForm < Publishers::JobListing::VacancyForm
  validates :application_link, url: true, if: :application_link?

  validates :apply_through_teaching_vacancies, inclusion: { in: %w[yes no] }, if: ->(f) { JobseekerApplicationsFeature.enabled? && f.can_change_apply_through_teaching_vacancies? }
  validates :apply_through_teaching_vacancies, absence: true, if: ->(f) { JobseekerApplicationsFeature.enabled? && !f.can_change_apply_through_teaching_vacancies? }

  validates :contact_email, presence: true
  validates :contact_email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, if: :contact_email?

  validates :contact_number, format: { with: /\A\+?(?:\d\s?){10,12}\z/ }, if: :contact_number?

  def can_change_apply_through_teaching_vacancies?
    !persisted_vacancy.listed?
  end

  def apply_through_teaching_vacancies?
    persisted_vacancy.apply_through_teaching_vacancies == "yes"
  end
end
