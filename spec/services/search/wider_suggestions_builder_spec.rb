require "rails_helper"

RSpec.describe Search::WiderSuggestionsBuilder do
  subject { described_class.new(initial_search) }

  let(:search_params) do
    {
      radius: radius,
      keyword: "test",
      location: location,
      filters: [],
      sort_by: nil,
    }
  end
  let(:radius) { 6 }
  let(:initial_search) { Search::VacancySearch.new(search_params) }

  describe ".call" do
    let(:pg_search) { double("search") }
    let(:suggestions) { described_class.call(initial_search) }
    let(:location) { "somewhere" }

    before do
      allow(pg_search).to receive(:total_count).and_return(0, 0, 2, 4, 15, 80, 80)
    end

    context "when initial_search is missing the search_criteria[:location] then suggestion search is not allowed" do
      let(:location) { nil }

      it { expect(suggestions).to be_nil }
    end

    context "when initial_search has some results then suggestion search is not allowed" do
      before { allow(initial_search).to receive(:total_count).and_return(1) }

      it { expect(described_class.call(initial_search)).to be_nil }
    end

    context "returns suggestions" do
      let(:expected_suggestions) do
        [
          ["20", 2],
          ["25", 4],
          ["50", 15],
          ["100", 80],
        ]
      end

      before do
        [10, 15, 20, 25, 50, 100, 200].each do |radius|
          allow(initial_search.class)
            .to receive(:new)
                  .with(hash_including(radius:), scope: kind_of(ActiveRecord::Relation))
                  .and_return(pg_search)
        end
      end

      context "when initial_search is a Search::VacancySearch" do
        let(:initial_search) { Search::VacancySearch.new(search_params) }

        it {
          pending("test refactor")
          expect(suggestions).to eq(expected_suggestions)
        }
      end

      context "when initial_search is a Search::SchoolSearch" do
        let(:initial_search) { Search::SchoolSearch.new(search_params, scope: Organisation.all) }

        it {
          pending("test refactor")
          expect(suggestions).to eq(expected_suggestions)
        }
      end
    end
  end

  describe "#suggestions" do
    let(:location) { "Hatfield" }

    context "given a radius" do
      before do
        YAML.unsafe_load_file(Rails.root.join("spec/fixtures/polygons.yml")).map(&:attributes).each { |s| LocationPolygon.create!(s) }
        YAML.unsafe_load_file(Rails.root.join("spec/fixtures/liverpool_schools.yml")).map(&:attributes).each { |s| School.create!(s) }
        YAML.unsafe_load_file(Rails.root.join("spec/fixtures/basildon_schools.yml")).map(&:attributes).each { |s| School.create!(s) }
        YAML.unsafe_load_file(Rails.root.join("spec/fixtures/st_albans_schools.yml")).map(&:attributes).each { |s| School.create!(s) }
        liverpool_org = School.find_by!(town: "Liverpool")
        basildon_org = School.find_by!(town: "Basildon")
        st_albans_org = School.find_by!(town: "St Albans")

        create(:vacancy, :published_slugged, job_title: "liv", organisations: [liverpool_org])
        create(:vacancy, :published_slugged, job_title: "bas", organisations: [basildon_org])
        create(:vacancy, :published_slugged, job_title: "sta", organisations: [st_albans_org])
        create(:vacancy, :published_slugged, job_title: "bas-sta", organisations: [basildon_org, st_albans_org])
      end

      it "provides radius suggestions beyond the current radius" do
        # pending("test refactor")

        # [10, 15, 20, 25, 50, 100, 200].each do |radius|
        #   expect(initial_search.class)
        #     .to receive(:new)
        #           .with(hash_including(radius:), scope: kind_of(ActiveRecord::Relation))
        #           .and_return(pg_search)
        # end

        expect(subject.suggestions).to eq([
          ["20", 2],
          ["25", 4],
          ["50", 15],
          ["100", 80],
        ])
      end
    end
  end
end
