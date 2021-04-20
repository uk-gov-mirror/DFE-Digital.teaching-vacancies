class Jobseekers::JobApplication::Details::Qualifications::QualificationForm
  include ActiveModel::Model

  attr_accessor :category, :count, :finished_studying, :finished_studying_details, :name, :institution, :subjects_and_grades, :year

  def initialize(attributes={})
    @attributes = attributes
    subject_and_grade_attributes.each { |attribute| self.class.send(:attr_accessor, attribute) }

    assign_attributes(attributes) if attributes
  end

  validates :category, presence: true
  validates :finished_studying_details, presence: true, if: -> { finished_studying == "false" }
  validates :year, presence: true, if: -> { finished_studying == "true" }
  validates :year, format: { with: /\A\d{4}\z/.freeze }, if: -> { year.present? }

  private

  def subject_and_grade_attributes
    @attributes.keys.select { |key| /\A(subject|grade)_\d+\z/.match?(key) }.presence ||
      Array.new(@attributes[:count]) { |index| %w[subject grade].each { |attr| "#{attr}_#{index + 1}".to_sym } }.flatten
  end
end
