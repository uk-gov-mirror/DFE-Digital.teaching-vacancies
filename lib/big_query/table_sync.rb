require "google/cloud/bigquery"
require "tempfile"
require "json"

module BigQuery
  # Syncs an Enumerable of rows into a BigQuery table, so its contents end up matching the
  # source exactly.
  module TableSync
    class EmptySourceError < StandardError; end

    class << self
      def call(dataset:, table:, rows:)
        rows = rows.to_a
        raise EmptySourceError, "no rows to sync for #{table}" if rows.empty?

        with_ndjson_file(rows) do |file|
          dataset.load_job(table, file, format: "json", write: "truncate", autodetect: true)
        end
      end

      private

      # BigQuery's load_job only accepts a real file (or a Cloud Storage reference), not an
      # in-memory string, so the rows are written out as newline-delimited JSON first.
      def with_ndjson_file(rows)
        file = Tempfile.new(["dsi_sync", ".json"])
        rows.each { |row| file.puts(row.to_json) }
        file.rewind

        yield file
      ensure
        file&.close
        file&.unlink
      end
    end
  end
end
