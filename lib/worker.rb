# This is an abstract module that developers creating works can mixin/include to use the SimpleWorker special functions.
module SimpleWorker

    class Base

        def log(str)
            puts str.to_s
        end

        def set_progress(hash)
            puts 'set_progress: ' + hash.inspect
        end
    end
end
