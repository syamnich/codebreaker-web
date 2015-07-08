require "erb"
require "yaml"
require "./lib/game"

class Racker
	def self.call(env)
		new(env).response.finish
  end

  def initialize(env)
  	@request = Rack::Request.new(env)
  	init_game
  	guesses
  	results
  end

  def response
  	case @request.path
    	when "/" then Rack::Response.new(render("index.html.erb"))
    	when "/check_guess" then check 
    	when "/new_game" then init_game(true)
    	when "/show_hint" then show_hint
    	when "/save_result" then save_result
    	else Rack::Response.new('Not Found', 404)
  	end
  end
	
  def check
  	if @request.params["guess"].match(/^[1-6]{4}$/) 
  		@guesses.push(@request.params["guess"])
  		result = @game.check(@request.params["guess"])
  		@results.push(result)
  		Rack::Response.new do |response|
        	response.set_cookie("guesses", @guesses)
        	response.set_cookie("results", @results)
        	response.redirect("/")
      end
    else
    	@guesses.push(@request.params["guess"])
    	@results.push("Invalid guess format, enter 4 numbers between 1 and 6")
    	Rack::Response.new do |response|
    		response.set_cookie("guesses", @guesses)
    		response.set_cookie("results", @results)
    		response.redirect("/")
    	end
    end
  end

	def hint
  	@request.cookies["hint"]
  end

  def show_hint
  	Rack::Response.new do |response|
  		response.set_cookie("hint", @game.hint)
  		response.redirect("/")
  	end
  end

	def save_result
		name = @request.params["name"]
		File.open("score.yml", 'a') { |f| f.write(YAML.dump("#{name}; #{@game.turns}; #{Time.now.strftime("%d-%m-%Y %R")};"))}
    @game.saved_result = true
    Rack::Response.new do |response|
    		response.redirect("/")
    	end
  end

  def load_score
  	file = File.open('score.yml')
    saved_score = []
  	score = YAML::load_documents(file) do |doc|
  		saved_score.push  doc.split(";") 
  	end
    saved_score
  end

  def render(template)
  	path = File.expand_path("../views/#{template}", __FILE__)
  	ERB.new(File.read(path)).result(binding)
  end

	def guesses
		@guesses = @request.cookies["guesses"] || []
		@guesses = @guesses.split('&') unless @guesses.is_a? Array
	end

	def results
		@results = @request.cookies["results"] || []
		@results = @results.split('&') unless @results.is_a? Array
	end

private
  
  def init_game(renew_game = false)
    @game = if renew_game
      @request.session[:game] = Codebreaker::Game.new
      Rack::Response.new do |response|
        response.set_cookie("guesses", [])
        response.set_cookie("results", [])
        response.set_cookie("hint", nil)
        response.redirect("/")
      end
    else
      @request.session[:game] ||= Codebreaker::Game.new
    end    
  end
end