# encoding: UTF-8

require "sequel/plugins/mssql_geography/version"

module Sequel
  module Plugins
    module MssqlGeography
      attr_reader :geolocation_field

      def self.configure(model, opts=OPTS)
        model.instance_eval do
          @geolocation_field = opts[:geolocation_field] || :geolocation
        end
      end

      module ClassMethods
        attr_reader :geolocation_field
        Plugins.inherited_instance_variables(self, :geolocation_field => nil)
        Sequel::Plugins.def_dataset_methods(self, :near)

        # Constructs a geography instance representing a Point instance from its latitude and longitude values and
        # a spatial reference ID (SRID).
        def point(latitude, longitude, srid: 4326)
          st_point = <<~sql
            DECLARE @point geography = geography::STPointFromText('POINT(#{longitude} #{latitude})', #{srid});
            SELECT @point as point;
          sql
          db.fetch(st_point).first[:point]
        end

        def point_lit(latitude, longitude, srid: 4326)
          Sequel.lit("geography::STPointFromText('POINT(#{longitude} #{latitude})', #{srid})")
        end
      end

      module DatasetMethods
        def near(latitude, longitude, within: 500, srid: 4326)
          field  = model.geolocation_field
          center = "geography::Point(#{latitude}, #{longitude}, #{srid})"
          select_append(Sequel.lit("#{center}.STDistance([#{field}])").as(:distance)).from_self
              .where(Sequel.lit("[distance] <= #{within}"))
        end
      end
    end
  end
end
