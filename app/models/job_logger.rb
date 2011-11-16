class JobLogger
  attr_reader :subscriptions

  def initialize
    @subscriptions = {}
  end

  def info(message)
    an_object_id, message = message.split("|")[1..2]
    if an_object_id && @subscriptions[an_object_id.to_i]
      job_id = @subscriptions[an_object_id.to_i][:job_id]
      type = @subscriptions[an_object_id.to_i][:type]
      puts [type, job_id, message].join "|"
      JobLog.create(:job_id => job_id, :message => message, :type => type)
    end
  end

  def subscribe(opts)
    an_object_id = opts[:an_object_id]
    job_id =  opts[:job_id]
    type = opts[:type]
    @subscriptions[an_object_id] = { :job_id => job_id, :type => type }
  end

  def unsubscribe(an_object_id)
    @subscriptions.delete(an_object_id)
  end

end
