class JobLogger
  attr_reader :subscriptions

  def initialize
    @subscriptions = {}
  end

  def info(message)
    an_object_id, message = message.split("|")[1..2]
    if an_object_id && @subscriptions[an_object_id.to_i]
      job_id = @subscriptions[an_object_id.to_i][:job_id]
      job_type = @subscriptions[an_object_id.to_i][:job_type]
      JobLog.create(:job_id => job_id, :message => message, :type => job_type)
    end
  end

  def subscribe(opts)
    an_object_id = opts[:an_object_id]
    job_id =  opts[:job_id]
    job_type = opts[:job_type]
    @subscriptions[an_object_id] = { :job_id => job_id, :job_type => job_type }
  end

  def unsubscribe(an_object_id)
    @subscriptions.delete(an_object_id)
  end

end
