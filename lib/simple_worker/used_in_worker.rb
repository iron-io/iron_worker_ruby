# UsedInWorker can be included in classes that you are merging in order to get some of the SimpleWorker features into that class.
# For instance, you can use the log() method and it will be logged to the SimpleWorker logs.

module SimpleWorker
    module UsedInWorker

        def log(str)
            puts str.to_s
        end
    end
end
