require_relative 'bot_data_to_yaml'
require_relative 'wordplay'

class Bot
  attr_reader :name
  def initialize(options)
    @name = options[:name] || "Unnamed Bot"
    begin
      @data = YAML.load(File.read(options[:data_file]))
    rescue
      raise "Can't load bot data"
    end
  end

  def greeting
    random_response :greeting
  end

  def farewell
    random_response :farewell
  end

  def response_to(input)
    prepared_input = preprocess(input).downcase
    sentence = best_sentence(prepared_input)
    responses = possible_responses(sentence)
    responses[rand(responses.length)]
  end

  def perform_substitutions(input)
    @data[:presubs].each { |s| input.gsub!(s[0], s[1]) }
    input
  end

  def possible_responses(sentence)
    responses = []
  # Find all patterns to try to match against
    @data[:responses].keys.each do |pattern|
      next unless pattern.is_a?(String)
  # For each pattern, see if the supplied sentence contains
  # a match. Remove substitution symbols (*) before checking.
  # Push all responses to the responses array.
      if sentence.match('\b' + pattern.gsub(/\*/, '') + '\b')
        responses << @data[:responses][pattern]
      end
    end
  # If there were no matches, add the default ones
    responses << @data[:responses][:default] if responses.empty?
  # Flatten the blocks of responses to a flat array
    responses.flatten
  end

  private

  def random_response(key)
    random_index = rand(@data[:responses][key].length)
    @data[:responses][key][random_index].gsub(/\[name\]/, @name)
  end

  def preprocess(input)
    perform_substitutions input
  end

  def best_sentence(input)
    hot_words = @data[:responses].keys.select do |k|
      k.class == String && k =~ /^\w+$/
    end
    WordPlay.best_sentence(input.sentences, hot_words)
  end
end