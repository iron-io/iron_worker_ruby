module SimpleWorker
    module UsedInWorker

        def log(str)
            puts 'gem usedinworker log=' + str.to_s
#            puts str.to_s
        end
    end
end
