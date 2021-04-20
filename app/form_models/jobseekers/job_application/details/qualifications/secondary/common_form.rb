class Jobseekers::JobApplication::Details::Qualifications::Secondary::CommonForm < Jobseekers::JobApplication::Details::Qualifications::QualificationForm
  validates :institution, :year, presence: true
  validate :subjects_and_grades_correspond?, if: -> { count > 1 }
  validates :subject_1, :grade_1, presence: true, if: -> { count == 1 }
  validates :year, format: { with: /\A\d{4}\z/.freeze }, if: -> { year.present? }

  def subjects_and_grades_correspond?

    # Remember that someone could delete the 3rd row of 4 and thereby submit 1, 2, and 4

    error_already_added = false
    subject_and_grade_attributes.each_slice(2) do |subject_key, grade_key|
      if error_already_added
        errors.add(subject_key.to_sym, "")
      elsif send(subject_key.to_sym).blank? || send(grade_key.to_sym).blank?
        errors.add(subject_key.to_sym, I18n.t("qualification_errors.subject_and_grade_correspond.false"))
        error_already_added = true
      end
      # Empty string: highlight field red with error, and rely on the user reading the error message on earlier field.
      errors.add(grade_key.to_sym, "") if send(grade_key.to_sym).blank?
    end
  end
end
