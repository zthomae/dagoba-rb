# Based on the rspec-github formatter: https://github.com/Drieam/rspec-github
# Original copyright (c) 2020 Stef Schenkelaars

require "minitest/reporters"

class GithubReporter < Minitest::Reporters::DefaultReporter
  # See https://github.community/t/set-output-truncates-multiline-strings/16852/3.
  ESCAPE_MAP = {
    "%" => "%25",
    "\n" => "%0A",
    "\r" => "%0D"
  }.freeze

  def report
    super

    tests.each do |test|
      next if test.passed?

      file, line = test.source_location
      if test.skipped?
        annotation = escape_annotation("Skipped: #{test.failure}")
        puts "\n::warning file=#{file},line=#{line}::#{annotation}"
      elsif test.failure
        annotation = escape_annotation(test.failure.error.to_s)
        puts "\n::error file=#{file},line=#{line}::#{annotation}"
      end
    end
  end

  private

  def escape_annotation(msg)
    msg.gsub(Regexp.union(ESCAPE_MAP.keys), ESCAPE_MAP)
  end
end

Minitest::Reporters.use!
