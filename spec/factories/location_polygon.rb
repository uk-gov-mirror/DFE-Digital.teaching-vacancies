FactoryBot.define do
  factory :location_polygon do
    name { "London" }
    location_type { "cities" }
    boundary { [51.466517484391, -0.4919530143329] }
    # In this step (2) of the LocationPolygon refactor, the format of buffers will be different
    # before and after running the import task. Before it's a 1D array; after, it's 2D. So I include both
    # formats in this test. This will be reverted in step 3.
    buffers do
      {
        "5" => [51.46822890300007, -0.564208123999947],
        "10" => [[51.47012161100008, -0.6364669129999356]],
        "15" => [51.47621236300006, -0.7085774819999529],
        "20" => [[51.47944372100005, -0.7807775579999543]],
        "25" => [51.48267548200005, -0.8529853679999633],
      }
    end
    polygons do
      {
        "polygons" => [[51.466517484391, -0.4919530143329]],
      }
    end
  end
end
