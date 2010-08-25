# This is an abstract module that developers creating works can mixin/include to use the SimpleWorker special functions.

require 'digest/md5'

module SimpleWorker

    class Base

        attr_accessor :task_set_id, :task_id, :schedule_id

        class << self
            attr_accessor :subclass, :caller_file
            @merged = []
            @merged_workers = []

            def reset!
                @merged = []
                @merged_workers = []
            end

            def inherited(subclass)
                subclass.reset!

                puts "subclass.inspect=" + subclass.inspect
                puts 'existing caller=' + (subclass.instance_variable_defined?(:@caller_file) ? subclass.instance_variable_get(:@caller_file).inspect : "nil")
                puts "caller=" + caller.inspect
#                splits = caller[0].split(":")
#                caller_file = splits[0] + ":" + splits[1]
                caller_file = caller[0][0...(caller[0].index(":in"))]
                caller_file = caller_file[0...(caller_file.rindex(":"))]
                puts 'caller_file=' + caller_file
                # don't need these class_variables anymore probably
                subclass.instance_variable_set(:@caller_file, caller_file)

                super
            end

            # merges the specified files.
            def merge(*files)
                files.each do |f|
                    unless File.exist? f
                        raise "File not found: " + f
                    end
                    require f
                    @merged << File.expand_path(f)
                end
            end

            def merge_worker(file, class_name)
                puts 'merge_worker in ' + self.name
                merge(file)
                @merged_workers << [File.expand_path(file), class_name]
            end
        end


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
            self.class.instance_variable_defined?(:@uploaded) && self.class.instance_variable_get(:@uploaded)
        end


        # Will send in all instance_variables.
        def queue
            puts 'in queue'
            upload_if_needed

            response = SimpleWorker.service.queue(self.class.name, sw_get_data)
            puts 'queue response=' + response.inspect
            @task_set_id = response["task_set_id"]
            @task_id = response["tasks"][0]["task_id"]
            response
        end

        def status
            SimpleWorker.service.status(task_id)
        end

        def upload
            upload_if_needed
        end

        def schedule(schedule)
            upload_if_needed

            response = SimpleWorker.service.schedule(self.class.name, sw_get_data, schedule)
            puts 'schedule response=' + response.inspect
            @schedule_id = response["schedule_id"]
            response
        end

        def schedule_status
            SimpleWorker.service.schedule_status(schedule_id)
        end

        # Callbacks for developer
        def before_upload

        end

        def after_upload

        end

           def before_run

        end
        def after_run

        end

        private

        def upload_if_needed

            before_upload

            puts 'upload_if_needed'
            # Todo, watch for this file changing or something so we can reupload
            unless uploaded?
                subclass = self.class
                rfile = subclass.instance_variable_get(:@caller_file) # Base.caller_file # File.expand_path(Base.subclass)
                puts 'rfile=' + rfile.inspect
                puts 'self.class.name=' + subclass.name
                merged = self.class.instance_variable_get(:@merged)
                puts 'merged1=' + merged.inspect
                superclass = subclass
                # Also get merged from subclasses up to SimpleWorker::Base
                while (superclass = superclass.superclass)
                    puts 'superclass=' + superclass.name
                    break if superclass.name == SimpleWorker::Base.name
                    super_merged = superclass.instance_variable_get(:@merged)
#                     puts 'merging caller file: ' + superclass.instance_variable_get(:@caller_file).inspect
                    super_merged << superclass.instance_variable_get(:@caller_file)
                    merged = super_merged + merged
                    puts 'merged with superclass=' + merged.inspect

                end
                SimpleWorker.service.upload(rfile, subclass.name, :merge=>merged)
                self.class.instance_variable_set(:@uploaded, true)
            else
                puts 'already uploaded for ' + self.class.name
            end
            puts 'uploading merged workers'
            self.class.instance_variable_get(:@merged_workers).each do |mw|
                # to support merges in the secondary worker, we should instantiate it here, then call "upload"
                puts 'instantiating and uploading ' + mw[1]
                Kernel.const_get(mw[1]).new.upload
#                    SimpleWorker.service.upload(mw[0], mw[1])
            end

            after_upload
        end

        def sw_get_data
            data = {}
            self.instance_variables.each do |iv|
                data[iv] = instance_variable_get(iv)
            end
            return data
        end


    end
end
