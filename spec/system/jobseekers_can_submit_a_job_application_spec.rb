require "rails_helper"

RSpec.describe "Jobseekers can submit a job application" do
  include ActiveJob::TestHelper

  let(:jobseeker) { create(:jobseeker) }
  let(:organisation) { create(:school) }
  let(:vacancy) { create(:vacancy, organisation_vacancies_attributes: [{ organisation: organisation }]) }

  before do
    allow(JobseekerApplicationsFeature).to receive(:enabled?).and_return(true)
    login_as(jobseeker, scope: :jobseeker)
    visit jobseekers_job_application_review_path(job_application)
  end

  context "when the application is complete" do
    let(:job_application) { create(:job_application, jobseeker: jobseeker, vacancy: vacancy) }

    it "allows jobseekers to submit application and receive confirmation email" do
      click_on I18n.t("buttons.submit_application")
      expect(page).to have_content("There is a problem")

      check I18n.t("helpers.label.jobseekers_job_application_review_form.confirm_data_accurate_options.1")
      check I18n.t("helpers.label.jobseekers_job_application_review_form.confirm_data_usage_options.1")

      expect { perform_enqueued_jobs { click_on I18n.t("buttons.submit_application") } }
        .to change { JobApplication.first.status }.from("draft").to("submitted")
        .and change { delivered_emails.count }.by(1)

      expect(page).to have_content(I18n.t("jobseekers.job_applications.submit.panel.title"))

      visit first_link_from_last_mail
      expect(current_path).to eq(jobseekers_job_applications_path)
    end
  end

  context "when the application is incomplete" do
    let(:job_application) { create(:job_application, :status_draft, jobseeker: jobseeker, vacancy: vacancy) }

    it "does not allow jobseekers to submit application and go to confirmation page" do
      check I18n.t("helpers.label.jobseekers_job_application_review_form.confirm_data_accurate_options.1")
      check I18n.t("helpers.label.jobseekers_job_application_review_form.confirm_data_usage_options.1")

      click_on I18n.t("buttons.submit_application")

      expect(JobApplication.first.status).to eq("draft")
      expect(page).to have_content("There is a problem")
    end

    it "allows jobseekers to save application and go to dashboard" do
      click_on I18n.t("buttons.save_and_come_back")

      expect(JobApplication.first.status).to eq("draft")
      expect(page).to have_content(I18n.t("messages.jobseekers.job_applications.saved"))
      expect(current_path).to eq(jobseekers_job_applications_path)
    end
  end
end
