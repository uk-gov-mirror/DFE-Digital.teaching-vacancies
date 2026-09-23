require "rails_helper"
require "dfe_sign_in/user_rows"

RSpec.describe DfeSignIn::UserRows do
  describe ".la_code" do
    # These two contexts are the whole reason a separate Parsing concern exists today: the
    # users and approvers endpoints capitalise the same fields differently. Writing them
    # side by side as the first two specs makes that the visible spec, not a buried comment.
    context "with a /users-shaped organisation (PascalCase keys)" do
      it "returns the establishment number when the organisation is a local authority" do
        user = {
          "organisation" => {
            "Category" => Publishers::DfeSignIn::OrgIdMappings::CATEGORIES[:local_authority],
            "EstablishmentNumber" => "800",
          },
        }

        expect(described_class.la_code(user)).to eq("800")
      end

      it "returns nil when the organisation is not a local authority" do
        user = { "organisation" => { "Category" => Publishers::DfeSignIn::OrgIdMappings::CATEGORIES[:single_establishment], "EstablishmentNumber" => "800" } }

        expect(described_class.la_code(user)).to be_nil
      end
    end

    context "with a /users/approvers-shaped organisation (camelCase keys)" do
      it "returns the establishment number when the organisation is a local authority" do
        user = {
          "organisation" => {
            "category" => { "id" => Publishers::DfeSignIn::OrgIdMappings::CATEGORIES[:local_authority] },
            "establishmentNumber" => "800",
          },
        }

        expect(described_class.la_code(user)).to eq("800")
      end
    end

    it "returns nil rather than raising when organisation is missing entirely" do
      # A malformed/partial DSI record shouldn't blow up a whole sync run over one field.
      expect(described_class.la_code({})).to be_nil
    end
  end

  describe ".for_users" do
    let(:dsi_user) do
      {
        "userId" => "user-1",
        "email" => Faker::Internet.email(domain: TEST_EMAIL_DOMAIN),
        "givenName" => Faker::Name.first_name,
        "familyName" => Faker::Name.last_name,
        "roleName" => "End user",
        "approvedAt" => "2026-01-01T00:00:00Z",
        "updatedAt" => "2026-01-02T00:00:00Z",
        "organisation" => { "URN" => 100_000, "UID" => nil, "Category" => Publishers::DfeSignIn::OrgIdMappings::CATEGORIES[:single_establishment] },
      }
    end

    it "maps every field BigQuery expects, keyed by the DSI-shaped input" do
      # One example asserting the full hash, rather than one `it` per field: the mapping is
      # the whole unit of behaviour, and a per-field split would hide a swapped key (e.g.
      # given/family name reversed) that a full-hash `eq` catches immediately.
      expect(described_class.for_users(dsi_user)).to eq(
        user_id: "user-1",
        email: dsi_user["email"],
        given_name: dsi_user["givenName"],
        family_name: dsi_user["familyName"],
        role: "End user",
        school_urn: 100_000,
        trust_uid: nil,
        la_code: nil,
        approval_datetime: dsi_user["approvedAt"],
        update_datetime: dsi_user["updatedAt"],
      )
    end
  end

  describe ".for_approvers" do
    let(:dsi_approver) do
      {
        "userId" => "user-2",
        "email" => Faker::Internet.email(domain: TEST_EMAIL_DOMAIN),
        "givenName" => Faker::Name.first_name,
        "familyName" => Faker::Name.last_name,
        "roleId" => "approver",
        "roleName" => "Approver",
        "organisation" => { "urn" => nil, "uid" => 555, "category" => { "id" => Publishers::DfeSignIn::OrgIdMappings::CATEGORIES[:single_establishment] } },
      }
    end

    # Approvers have no approval_datetime/update_datetime and an extra role_id — asserting
    # the full hash here is what pins that shape difference from .for_users.
    it "maps the approver shape, which has no timestamps and an extra role_id" do
      expect(described_class.for_approvers(dsi_approver)).to eq(
        user_id: "user-2",
        email: dsi_approver["email"],
        given_name: dsi_approver["givenName"],
        family_name: dsi_approver["familyName"],
        role_id: "approver",
        role_name: "Approver",
        school_urn: nil,
        trust_uid: 555,
        la_code: nil,
      )
    end
  end
end
