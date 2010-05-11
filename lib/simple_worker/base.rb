# This is an abstract module that developers creating works can mixin/include to use the SimpleWorker special functions.

require 'digest/md5'

module SimpleWorker

    class Base

        attr_accessor :task_set_id, :task_id

        class << self
            attr_accessor :subclass, :caller_file
        end

        def self.inherited(subclass)
            puts "New subclass: #{subclass}"
            puts "subclass.inspect=" + subclass.inspect
            @subclass = subclass
            puts 'existing caller=' + (subclass.class_variable_defined?(:@@caller_file) ? subclass.class_variable_get(:@@caller_file).inspect : "nil")
            puts "caller=" + caller.inspect
            splits = caller[0].split(":")
            caller_file = splits[0] + ":" + splits[1]
            puts 'caller_file=' + caller_file
            # don't need these class_variables anymore probably
            subclass.class_variable_set(:@@caller_file, caller_file)

        end

        attr_accessor :data

        def log(str)
            puts str.to_s
        end

        def set_progress(hash)
            puts 'set_progress: ' + hash.inspect
        end

        def who_am_i?
            return self.class.name
        end

        def uploaded?
            @uploaded
        end

        def upload_if_needed

#            $LOADED_FEATURES.each_with_index { |feature, idx|
#  puts "#{ sprintf("%2s", idx) } #{feature}"
#                if feature[feature.rindex("/")..feature.length] ==
#}
            unless uploaded?
                subclass = Base.subclass
                rfile = subclass.class_variable_get(:@@caller_file) # Base.caller_file # File.expand_path(Base.subclass)
                puts 'rfile=' + rfile.inspect
                puts 'self.class.name=' + subclass.name
                SimpleWorker.service.upload(rfile, subclass.name)
                @uploaded = true
            else
                puts 'already uploaded for ' + self.class.name
            end
        end

        # Will send in all instance_variables.
        def queue
            upload_if_needed

            response = SimpleWorker.service.queue(self.class.name, sw_get_data)
            @task_set_id = response["task_set_id"]
            @task_id = response["tasks"][0]["task_id"]
            response
        end

        def status
            SimpleWorker.service.status(task_id)
        end

        def sw_get_data
            data = {}
            self.instance_variables.each do |iv|
                data[iv] = instance_variable_get(iv)
            end
            return data
        end

        def queue_other(class_name, data)

        end

        def schedule_other(class_name, data, schedule)

        end
    end
end
