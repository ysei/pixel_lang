class PMetaPosY < PMetaICount
  set_cc 0xD
  set_char ?P

  set_mc 5


  def self.reference_card
    puts %q{
        Piston Meta Position Y
        puts this pistons pos_y to a register

        0bCCCCMMMRRROOAAAAAAAAAAAA
        C = Control Code (Instruction)    [4 bits]
        M = Meta Command                  [3 bits]
        R = Register                      [3 bits]
        O = Register Options              [2 bits]
        A = Meta Command Arguments        [17 bits]
        }
  end

  def self.run(piston, *args)
    register = args[0]
    register_options = [1]

    piston.send("set_#{register}", piston.pos_y % Piston::MAX_INTEGER, register_options)

  end
end