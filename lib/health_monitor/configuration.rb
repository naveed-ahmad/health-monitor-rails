module HealthMonitor
  class Configuration
    PROVIDERS = %i[cache database delayed_job redis resque sidekiq].freeze

    attr_accessor :error_callback, :basic_auth_credentials, :environment_variables
    attr_reader :providers

    def initialize
    end

    PROVIDERS.each do |provider_name|
      define_method provider_name do |provider_url=nil|
        require "health_monitor/providers/#{provider_name}"
        add_provider("HealthMonitor::Providers::#{provider_name.to_s.titleize.delete(' ')}".constantize, provider_url)
      end
    end

    def add_custom_provider(custom_provider_class, provider_url=nil)
      unless custom_provider_class < HealthMonitor::Providers::Base
        raise ArgumentError.new 'custom provider class must implement '\
          'HealthMonitor::Providers::Base'
      end

      add_provider(custom_provider_class, provider_url)
    end

    private

    def add_provider(provider_class, service_url=nil)
      (@providers ||= Set.new) <<  { class: provider_class, url: service_url}

      provider_class
    end
  end
end
