require 'health_monitor/configuration'

module HealthMonitor
  STATUSES = {
    ok: 'OK',
    error: 'ERROR'
  }.freeze

  extend self

  attr_accessor :configuration

  def configure
    self.configuration ||= Configuration.new

    yield configuration if block_given?
  end

  def check(request: nil, params: {})
    providers = configuration.providers
    
    if params[:providers].present?
      providers = providers.select { |provider| params[:providers].include?(provider[:class].provider_name.downcase) }
    end

    results = providers.map { |provider| provider_result(provider, request) }

    {
      results: results,
      status: results.any? { |res| res[:status] != STATUSES[:ok] } ? :service_unavailable : :ok,
      timestamp: Time.now.to_s(:rfc2822)
    }
  end

  private

  def provider_result(provider, request)
    result = {
      name: provider[:class].provider_name,
      message: '',
      url: provider[:url]
    }

    begin
      monitor = provider[:class].new(request: request)
      monitor.check!

      result[:status] = STATUSES[:ok]
    rescue StandardError => e
      configuration.error_callback.call(e) if configuration.error_callback
      
      result[:message] = e.message
      result[:status]  = STATUSES[:error]
    end
    
    result
  end
end

HealthMonitor.configure
