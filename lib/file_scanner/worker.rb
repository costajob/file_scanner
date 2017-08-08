require "logger"

module FileScanner
  class Worker
    attr_reader :filters, :policies

    def self.default_logger
      Logger.new(nil).tap do |logger|
        logger.level = Logger::ERROR
      end
    end

    def initialize(loader:, 
                   filters: Filters::defaults, policies: [], 
                   logger: self.class.default_logger, slice: nil)
      @loader = loader
      @filters = filters
      @policies = policies
      @slice = slice.to_i
      @logger = logger
    end

    def call
      slices.each do |slice|
        yield(slice) if block_given? && policies.empty?
        policies.each do |policy|
          @logger.info { "applying \e[33m#{policy}\e[0m to #{slice.size} files" }
          policy.call(slice)
        end
      end
    rescue StandardError => e
      @logger.error { e.message }
      raise e
    end

    private def files
      Array(@loader.call).select do |f|
        @filters.any? do |filter|
          @logger.info { "applying \e[35m#{filter}\e[0m to #{File.basename(f)}" }
          filter.call(f)
        end
      end
    end

    private def slices
      return [files] if @slice.zero?
      files.each_slice(@slice)
    end
  end
end
