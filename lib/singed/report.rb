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

    # override so we can clean it here
    def print_json(f)
      json = super
      cleanup_io_wait_and_gc_stacks(json)
    end

    # from https://gist.github.com/tiagotex/3d1dd48c26b36a5013dcbd84401f38b8
    # TODO: refactor to work on the reporter class instead of json data (?)
    #
    # To avoid interrupting the root frames when IO wait or garbage collection happens we modify the raw data to merge
    # these stacks into the previous stacks or append previous stacks in the current stack.
    #
    # We are currently only updating the raw data and not the frames data. This is enough to make this display the data
    # correctly in speedscope but it might not be enough for other tools, including the stackprof reports.
    #
    # We are also only supporting Puma IO wait, we will need to update this script to support other servers.

    GC_FRAME_ID    = 1 # This is static as defined in ext/stackprof/stackprof.c
    IO_FRAME_NAMES = ["Puma::Single#run", "Puma::Cluster::Worker#run"].freeze

    def cleanup_io_wait_and_gc_stacks(result)
      raw            = result[:raw]
      frames         = result[:frames]
      updated_raw    = []
      previous_stack = nil
      current_stack  = nil

      # Currently we are only supporting transforming puma IO wait
      io_wait_frame_id      = frames.find { |_key, frame| IO_FRAME_NAMES.include?(frame[:name]) }&.fetch(0)&.to_i
      io_wait_root_frame_id = nil

      index = 0
      while (current_stack_height = raw[index])
        index += 1

        # We first get current_stack including the current stack number of samples and pop it out leaving only the stack
        # in current_stack
        current_stack               = raw.slice(index, current_stack_height + 1)
        current_stack_samples_count = current_stack.pop

        # Leave index at the start of the next stack
        index += current_stack_height + 1

        # First iteration we just push the current stack
        if previous_stack.nil?
          updated_raw.push(current_stack_height, *current_stack, current_stack_samples_count)

          previous_stack = current_stack
          next
        end

        # When we know puma io wait frame exists we can check if current stack last frame is the io wait frame
        if io_wait_frame_id && current_stack[-1] == io_wait_frame_id
          # Update previous stack sample count if previous stack is io wait
          if previous_stack[-1] == io_wait_root_frame_id
            updated_raw[-1] += current_stack_samples_count
            next
          end

          # First time we encounter io wait we need to update the frame name so it is displayed correctly in the UI
          if io_wait_root_frame_id.nil?
            io_wait_root_frame_id = current_stack[0]

            frames[current_stack[0]] = frames[current_stack[0]].merge(name: "(io wait)", file: nil)
          end

          # When previous stack is gc we need to remove the gc frames from the previous stack before appending
          if (previous_stack_gc_frame_index = previous_stack.find_index(GC_FRAME_ID))
            new_stack = previous_stack[0..previous_stack_gc_frame_index - 1] + [current_stack[0]]
            updated_raw.push(new_stack.length, *new_stack, current_stack_samples_count)

            previous_stack = new_stack
            next
          end

          # Otherwise we just append the current stack to the previous stack
          new_stack = previous_stack + [current_stack[0]]
          updated_raw.push(previous_stack.length + 1, *new_stack, current_stack_samples_count)

          previous_stack = new_stack
          next
        end

        # If current stack is not GC we don't need to do anything and just return the current stack
        if current_stack[0] != GC_FRAME_ID
          updated_raw.push(current_stack_height, *current_stack, current_stack_samples_count)

          previous_stack = current_stack
          next
        end

        previous_stack_gc_frame_index = previous_stack.find_index(GC_FRAME_ID)

        # If the previous stack doesn't have GC we can append the current stack to the previous stack
        if previous_stack_gc_frame_index.nil?
          # When previous stack is io wait we need to remove the io wait frame from the previous stack before appending
          if previous_stack[-1] == io_wait_root_frame_id
            new_stack = previous_stack[0..-2] + current_stack
            updated_raw.push(new_stack.length, *new_stack, current_stack_samples_count)

            previous_stack = new_stack
            next
          end

          # Otherwise we just append the current stack to the previous stack
          new_stack = previous_stack + current_stack
          updated_raw.push(previous_stack.length + current_stack_height, *new_stack, current_stack_samples_count)

          previous_stack = new_stack
          next
        end

        # If the previous gc frames are the same as the current gc frames (Array of frame IDs are the same) we update the
        # previous stack by adding the current stack number of samples
        if previous_stack[previous_stack_gc_frame_index..] == current_stack
          updated_raw[-1] += current_stack_samples_count
        else
          # Otherwise we find the previous stack frame before the GC frame and append the current stack to it
          new_stack = previous_stack[0..previous_stack_gc_frame_index - 1] + current_stack
          updated_raw.push(new_stack.length, *new_stack, current_stack_samples_count)
        end
      end

      result[:raw] = updated_raw
      result
    end
    
  end
end
