require "rails_helper"

RSpec.describe UpdateDSIUsersInDbJob do
  let(:first_page_users) do
    JSON.parse(Rails.root.join("spec/fixtures/dfe_sign_in_service_users_response_page_1.json").read).fetch("users")
  end
  let(:second_page_users) do
    JSON.parse(Rails.root.join("spec/fixtures/dfe_sign_in_service_users_response_page_2.json").read).fetch("users")
  end

  before do
    # DfeSignIn::API.users already hides pagination, so this job's own spec doesn't need to
    # know about pages either — it stubs the enumerator directly, same as the job consumes it.
    allow(DfeSignIn::API).to receive(:users).and_return((first_page_users + second_page_users).each)
  end

  it "creates a publisher for each distinct user across the source", :perform_enqueued do
    # page_2's fixture repeats "CCC-333" for multiple organisations, so the distinct users
    # across both pages (AAA-111, CCC-333, DEF-456) is fewer than the raw record count.
    expect { described_class.perform_later }.to change(Publisher, :count).by(3)
  end

  it "enqueues one UpdateSingleDSIUserInDbJob per user DfeSignIn::API.users yields" do
    # perform_now rather than perform_later + perform_enqueued_jobs: this only needs to run
    # UpdateDSIUsersInDbJob itself and check what it enqueues, not cascade into actually
    # performing every UpdateSingleDSIUserInDbJob too (the first example already covers that).
    expect { described_class.new.perform_now }
      .to have_enqueued_job(UpdateSingleDSIUserInDbJob).exactly(first_page_users.size + second_page_users.size).times
  end
end
