module Codebreaker
  class Game

    attr_reader :attempts_count, :win, :secret_code
    attr_accessor :saved_result

    TOTAL_COUNT = 10

    def initialize
      @secret_code = generate_code 
      @attempts_count = TOTAL_COUNT
      @hint = nil   
      @win = nil 
      @saved_result = nil
    end
    
    def check(guess)
      @attempts_count -= 1
      
      if guess == @secret_code
        @win = true
        return "++++" 
      end
      result = ""
      index = []
      code_guess = str_to_array(guess)
      secret_code = str_to_array(@secret_code)
      code_guess.each_index { |i| result << "+" && index << i if code_guess[i]==secret_code[i] }
      
      delete_index(code_guess, index)
      delete_index(secret_code, index)
            
      code_guess.each do |i| 
        if secret_code.include?(i)
          result << "-" 
          index = secret_code.index(i)
          secret_code.delete_at(index)
        end
      end
      result
    end

    def hint
      return @hint if @hint
      @hint = "****"
      ind = rand(4)
      @hint[ind] = @secret_code[ind]
      @hint
    end

    def turns
      TOTAL_COUNT - @attempts_count
    end
      
    
    private

    def generate_code
      (1..4).map { rand(1..6) }.join
    end

    def str_to_array(str)
      str.chars.map { |i| i.to_i }
    end

    def delete_index(array, index)
      array.map!.with_index { |item, i| item unless index.include?(i) }.compact!
    end
  end
end