# UsedInWorker can be included in classes that you are merging in order to get some of the IronWorker features into that class.
# For instance, you can use the log() method and it will be logged to the IronWorker logs.

module IronWorker
    module UsedInWorker

        def log(str)
            puts str.to_s
        end
    end
end
