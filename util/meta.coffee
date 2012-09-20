##
# Function that turns elements of dictionary into function.
# https://github.com/raganwald/homoiconic/blob/master/2012/01/reuseable-abstractions.md#readme
# #
dict2func = (dictionary) ->
    (indices...) ->
        indices.reduce (a, i) ->
            a[i]
        , dictionary
