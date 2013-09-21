class PluginInfo < Struct.new(:group_id, :artifact_id, :version)

  def full_name
    "#{group_id}:#{artifact_id}:#{version}"
  end

end