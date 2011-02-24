class TraceObject < ActiveRecord::Base
    belongs_to :tracking_device
    has_many :location_updates


end
