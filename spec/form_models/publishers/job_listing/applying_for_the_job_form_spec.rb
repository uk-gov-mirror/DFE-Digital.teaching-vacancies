require "rails_helper"

RSpec.describe Publishers::JobListing::ApplyingForTheJobForm, type: :model do
  subject { described_class.new({}, persisted_vacancy: persisted_vacancy) }
  let(:persisted_vacancy) { build_stubbed(:vacancy) }

  it { is_expected.to allow_value("https://www.this-is-a-test-url.tvs").for(:application_link) }
  it { is_expected.to allow_value("").for(:application_link) }
  it { is_expected.not_to allow_value("invalid_link").for(:application_link) }

  it { is_expected.to validate_presence_of(:contact_email) }
  it { is_expected.to allow_value("thestrokes@example.com").for(:contact_email) }
  it { is_expected.not_to allow_value("invalid-email").for(:contact_email) }

  it { is_expected.to allow_value("01234 123456").for(:contact_number) }
  it { is_expected.to allow_value("").for(:application_link) }
  it { is_expected.not_to allow_value("invalid-01234").for(:contact_number) }

  context "when JobseekerApplicationsFeature is enabled" do
    before { allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true) }

    context "when the vacancy is listed" do
      let(:persisted_vacancy) { double(Vacancy, listed?: true) }

      it { is_expected.to validate_absence_of(:apply_through_teaching_vacancies) }
      specify { expect(subject.can_change_apply_through_teaching_vacancies?).to eq(false) }
    end

    context "when the vacancy is not listed" do
      let(:persisted_vacancy) { double(Vacancy, listed?: false) }

      it { is_expected.to validate_inclusion_of(:apply_through_teaching_vacancies).in_array(%w[yes no]) }
      specify { expect(subject.can_change_apply_through_teaching_vacancies?).to eq(true) }
    end
  end
end
