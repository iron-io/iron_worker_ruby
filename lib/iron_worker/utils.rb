module SimpleWorker

  module Utils

      def self.ends_with?(s, suffix)
        suffix = suffix.to_s
        s[-suffix.length, suffix.length] == suffix
      end
  end

end