require "rails_helper"

RSpec.describe "Extend deadline" do
  let(:organisation) { create(:school) }
  let(:vacancy) { create(:vacancy, :published, publish_on: publish_on, expires_at: 1.month.from_now, organisation_vacancies_attributes: [{ organisation: organisation }]) }
  let(:publisher) { create(:publisher) }
  let(:publish_on) { 1.month.ago }

  before do
    allow(DisableExpensiveJobs).to receive(:enabled?).and_return(false)
    allow_any_instance_of(Publishers::AuthenticationConcerns).to receive(:current_organisation).and_return(organisation)
    sign_in(publisher, scope: :publisher)
  end

  describe "GET #show" do
    context "when the vacancy does not belong to the current organisation" do
      let(:vacancy) { create(:vacancy, :published, organisation_vacancies_attributes: [{ organisation: create(:school) }]) }

      it "returns not_found" do
        get organisation_job_extend_deadline_path(vacancy.id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the vacancy was not published in the past" do
      let(:publish_on) { 1.day.from_now }

      it "returns not_found" do
        get organisation_job_extend_deadline_path(vacancy.id)

        expect(response).to have_http_status(:not_found)
      end
    end

    it "renders the show page" do
      expect(get(organisation_job_extend_deadline_path(vacancy.id))).to render_template(:show)
    end
  end

  describe "PATCH #update" do
    let(:button) { I18n.t("buttons.extend_deadline") }
    let(:expires_on) { 6.months.from_now }
    let(:expires_at) { Time.zone.parse("#{expires_on.year}-#{expires_on.month}-#{expires_on.day} 9:00") }

    let(:form_params) do
      {
        "expires_on(1i)" => expires_on.year.to_s,
        "expires_on(2i)" => expires_on.month.to_s,
        "expires_on(3i)" => expires_on.day.to_s,
        expiry_time: "9:00",
        starts_asap: "0",
      }
    end

    let(:params) { { commit: button, publishers_job_listing_extend_deadline_form: form_params } }

    context "when the vacancy does not belong to the current organisation" do
      let(:vacancy) { create(:vacancy, :published, organisation_vacancies_attributes: [{ organisation: build_stubbed(:school) }]) }

      it "returns not_found" do
        patch organisation_job_extend_deadline_path(vacancy.id), params: params

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the vacancy was not published in the past" do
      let(:publish_on) { 1.day.from_now }

      it "returns not_found" do
        patch organisation_job_extend_deadline_path(vacancy.id), params: params

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the form is invalid" do
      before { allow_any_instance_of(Publishers::JobListing::ExtendDeadlineForm).to receive(:valid?).and_return(false) }

      it "does not extend the deadline or update google index and renders show page" do
        expect { patch organisation_job_extend_deadline_path(vacancy.id), params: params }
          .to not_change { vacancy.reload.expires_at }
          .and not_have_enqueued_job(UpdateGoogleIndexQueueJob)

        expect(response).to render_template(:show)
      end
    end

    it "extends the deadline, updates google index and redirects to active jobs dashboard" do
      freeze_time do
        expect { patch organisation_job_extend_deadline_path(vacancy.id), params: params }
            .to change { vacancy.reload.expires_at }.from(1.month.from_now).to(expires_at)
            .and have_enqueued_job(UpdateGoogleIndexQueueJob)

        expect(response).to redirect_to(jobs_with_type_organisation_path(:published))
      end
    end
  end
end
