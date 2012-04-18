Sequel.migration do
  up do
    drop_column(:pads, :die_time)
    add_column(:pads, :die_time, String)
    self[:pads].update(:die_time => Time.now - 3600*24)
  end
  down do
    drop_column(:pads, :die_time)
    add_column(:pads, :die_time, Date)
  end
end