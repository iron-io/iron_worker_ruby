# This is an abstract module that developers creating works can mixin/include to use the SimpleWorker special functions.
module SimpleWorker

    module Worker
        def set_progress(hash)
            puts 'Progress set: ' + hash.inspect         
        end
    end
end
