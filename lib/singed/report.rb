module Singed
  class Report < StackProf::Report
    def filter!
      # copy and paste from StackProf::Report#print_graphviz that does filtering
      # mark_stack = []
      list = frames(true)
      # WIP to filter out frames we care about... unfortunately, speedscope just hangs while loading as is
      # # build list of frames to mark for keeping
      # list.each do |addr, frame|
      #   mark_stack << addr unless Singed.silence_line?(frame[:file])
      # end

      # # while more addresses to mark
      # while addr = mark_stack.pop
      #   frame = list[addr]
      #   # if it hasn't been marked yet
      #   unless frame[:marked]
      #     # collect edges to mark
      #     if frame[:edges]
      #       mark_stack += frame[:edges].map{ |addr, weight| addr if list[addr][:total_samples] <= weight*1.2 }.compact
      #     end
      #     # mark it so we don't process again
      #     frame[:marked] = true
      #   end
      # end
      # list = list.select{ |_addr, frame| frame[:marked] }
      # list.each{ |_addr, frame| frame[:edges]&.delete_if{ |k,v| list[k].nil? } }
      # end copy-pasted section

      list.each do |_addr, frame|
        frame[:file] = Singed.filter_line(frame[:file])
      end

      @data[:frames] = list
    end
  end
end
