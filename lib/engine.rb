require 'rmagick'
require 'logger'
require 'require_all'

require_relative './instruction'
require_relative './piston'
require_relative './instructions'
require_relative './color'

require_rel './basic'

include Magick

# object for reading, executing, and providing input for pixel_lang pistons.
class Engine
  # contains the active running pistons on the machine
  attr_reader :pistons
  # 2d array of instructions
  attr_reader :instructions
  # output of the machine
  attr_reader :output
  # the number of completed cycles
  attr_reader :cycles
  # logger log
  attr_reader :log
  # name of the machine, is the file identifier of the image
  attr_reader :name
  # how many times has this machine been run
  attr_reader :runs
  # static memory for pistons
  attr_reader :memory
  # input
  attr_reader :input
  # Last number to be written to output
  attr_reader :last_output

  def initialize(image_file, input = '')
    @original_input = input.clone
    @name = image_file.split('/').last.split('.').first
    @runs = 0
    @instructions = Instructions.new image_file
    reset # start the machine
  end

  # reset the machine
  def reset
    @cycles = 0
    @output = ''
    @to_merge = []
    @pistons = []
    @id = 0
    @memory = {}
    @memory.default = 0
    @input = @original_input.clone
    @last_output = 0

    @log = Logger.new(File.new(File.dirname(__FILE__) + '/../log/' + name + '.log', 'w'))
    log.info "#{name} has reset! Runs: #{runs}"
    log.level = Logger::ERROR

    @instructions.start_points.each do |sp|
      @pistons << Piston.new(self, sp.x, sp.y, sp.p.direction)
    end
    @runs += 1
  end

  # runs until all pistons are killed
  def run
    run_one_instruction until ended?
  end

  # runs a single instruction on all pistons
  def run_one_instruction
    # don't run if the machine has already ended.
    return if ended?
    # run an instruction on all pistons.
    pistons.each(&:run_one_instruction)
    # merge pistons
    # pistons end up in @to_merge from fork_piston and are added
    # after instructions are ran
    @to_merge.each do |hash|
      piston_index = pistons.find_index { |piston| piston.id == hash[:piston].id }
      # sort pistons based on turn direction
      if hash[:direction] == :left
        pistons.insert(piston_index, hash[:new_piston])
      elsif hash[:direction] == :right
        pistons.insert(piston_index + 1, hash[:new_piston])
      end
    end
    @to_merge.clear

    # prune old pistons, delete the ones that no longer are active
    @pistons.select! { |t| not t.ended? }
    @cycles += 1
  end

  # forks a piston in a specific direction
  def fork(piston, turn_direction)
    new_piston = piston.clone

    if turn_direction == :left
      new_piston.turn_left
    elsif turn_direction == :right
      new_piston.turn_right
    elsif turn_direction == :reverse
      new_piston.reverse
    end
    new_piston.move 1

    @to_merge << {piston: piston, new_piston: new_piston, direction: turn_direction}
    log.debug "^  piston forked! Id: #{new_piston.id}"
  end

  def priority_changed(piston)
    #remove the piston
    @pistons.delete(piston)
    #find the first piston whose priority is
    p = @pistons.find {|p| p.priority <= piston.priority}
    @to_merge << {old_piston: p, new_piston: piston, direction: :left}
  end

  def kill
    pistons.clear
    @to_merge.clear
  end

  # writes to the output
  def write_output(item)
    if item.is_a? String
      if item[1] == 'x'
        @last_output = item.to_i(16)
      else
        @last_output = item.ord
      end
    else
      @last_output = item
    end
    @output << item.to_s
  end

  # gets a number from input until it hits the end or a non-number char
  def grab_input_number
    # ''.to_i is equal to 0
    i = '0'
    while input.length != 0 and ('0'..'9').include?(input[0])
      i << @input.slice!(0)
    end
    i.to_i % Piston::MAX_INTEGER
  end

  # gets the next input char
  def grab_input_char
    (@input.length == 0) ? 0 : @input.slice!(0).ord
  end

  # gets an id number for the Piston
  def make_id
    new_id = @id
    @id += 1
    new_id
  end

  def ended?
    pistons.empty? and @to_merge.empty?
  end
end