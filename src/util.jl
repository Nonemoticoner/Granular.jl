#!/usr/bin/env julia

export randpower
"""
    randpower([nvals], [distribution_power], [min_val], [max_val])

Returns one or more random numbers from a power-law probability distribution.

# Arguments
* `dims::Any`: the dimensions of random values (default = 1)
* `distribution_power::Number`: the distribution power (default = 1.)
* `min_val::Number`: the lower bound of the distribution range (default = 0.)
* `max_val::Number`: the upper bound of the distribution range (default = 1.)
"""
@inline function randpower(dims::Any = 1,
                           distribution_power::Number = 1.,
                           min_val::Number = 0.,
                           max_val::Number = 1.)

    val = ((max_val^(distribution_power + 1.) - 
            min_val^(distribution_power + 1.)) * rand(dims) .+ 
           min_val^(distribution_power + 1.)) .^ 
            (1. / (distribution_power + 1.))

    if dims == 1
        return val[1]
    else
        return val
    end
end

export harmonicMean
"""
    harmonicMean(a, b)

Returns the harmonic mean of two numbers `a::Number` and `b::Number`.
"""
function harmonicMean(a::Number, b::Number)::Number
    if a ≈ 0. && b ≈ 0
        return 0.
    else
        return 2. * a * b / (a + b)
    end
end
