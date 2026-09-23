require "rails_helper"
require "big_query/table_sync"

RSpec.describe BigQuery::TableSync do
  # A hand-rolled instance_double rather than one built against the full
  # Google::Cloud::Bigquery::Dataset API: the real class's #load_job signature is heavier
  # than this unit needs to assert against, and pinning to the exact gem API here would make
  # this spec break on every gem bump rather than on a real behaviour change.
  let(:dataset) { instance_double(Google::Cloud::Bigquery::Dataset) }

  describe ".call" do
    context "with a non-empty source" do
      let(:rows) { [{ user_id: "1", email: "a@contoso.com" }, { user_id: "2", email: "b@contoso.com" }].each }

      it "loads the source into the target table with a truncating write, replacing its contents" do
        # No SQL and no staging table: the whole sync is one batch-load job with
        # write: "truncate", which BigQuery only applies atomically once the file has
        # loaded in full — that's what fixes the old "half-populated table" failure mode.
        expect(dataset).to receive(:load_job)
          .with("dsi_users", instance_of(Tempfile), format: "json", write: "truncate", autodetect: true)

        described_class.call(dataset: dataset, table: "dsi_users", rows: rows)
      end

      it "writes every source row as newline-delimited JSON" do
        # BigQuery's load_job only accepts a real file, not an in-memory string, so this
        # pins the one part of that translation that could silently drop or reorder data.
        # Read inside the stub, not after .call returns: TableSync closes (and unlinks) the
        # file as soon as load_job has been handed it, so by the time .call returns the file
        # handle is already gone — reading it here is what proves it held the right content
        # *while load_job could still see it*, which is the only point that matters.
        parsed_rows = nil
        allow(dataset).to receive(:load_job) do |_table, file, **|
          parsed_rows = file.read.each_line.map { |line| JSON.parse(line, symbolize_names: true) }
        end

        described_class.call(dataset: dataset, table: "dsi_users", rows: rows)

        expect(parsed_rows).to eq(rows.to_a)
      end

      it "cleans up the temp file once the load job has it, rather than leaking it" do
        loaded_file = nil
        allow(dataset).to receive(:load_job) { |_table, file, **| loaded_file = file }

        described_class.call(dataset: dataset, table: "dsi_users", rows: rows)

        expect(loaded_file.closed?).to be true
        # Tempfile#path returns nil once the file has been unlinked — the file no longer
        # has a path to check with File.exist?, which is itself evidence it's gone.
        expect(loaded_file.path).to be_nil
      end

      it "still cleans up the temp file when the load job itself fails" do
        loaded_file = nil
        allow(dataset).to receive(:load_job) do |_table, file, **|
          loaded_file = file
          raise Google::Cloud::Error, "quota exceeded"
        end

        expect { described_class.call(dataset: dataset, table: "dsi_users", rows: rows) }
          .to raise_error(Google::Cloud::Error)
        expect(loaded_file.closed?).to be true
        expect(loaded_file.path).to be_nil
      end
    end

    context "with an empty source" do
      let(:rows) { [].each }

      # This is the specific bug "replace the table with the source" would otherwise
      # reintroduce: a transient empty DSI response must not wipe dsi_users — so this is
      # the single most important spec in the set.
      it "refuses to run and does not touch the target table" do
        expect(dataset).not_to receive(:load_job)

        expect { described_class.call(dataset: dataset, table: "dsi_users", rows: rows) }
          .to raise_error(BigQuery::TableSync::EmptySourceError)
      end
    end

    context "when the source enumerator raises while being read" do
      let(:rows) do
        Enumerator.new do |y|
          y << { user_id: "1", email: "a@contoso.com" }
          raise DfeSignIn::API::ExternalServerError
        end
      end

      # Rows are read into memory in full before any file is written or BigQuery is
      # touched, so a source that dies mid-fetch is caught before the target table's
      # current contents are put at risk at all.
      it "does not touch the target table at all" do
        expect(dataset).not_to receive(:load_job)

        expect { described_class.call(dataset: dataset, table: "dsi_users", rows: rows) }
          .to raise_error(DfeSignIn::API::ExternalServerError)
      end
    end
  end
end
