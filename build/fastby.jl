"""
Fast Group By algorithm
"""
function fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, outType = typeof(fn(valvec[1]))) where {T, S}
    length(byvec) == length(valvec) || throw(DimensionMismatch())
    if issorted(byvec)
        h = _contiguousby(fn, byvec, valvec, outType)::Dict{T,outType}
    else
        h = _fastby!(fn, byvec, valvec, outType)::Dict{T,outType}
    end
    return h
end

"""
Internal: single-function fastby
"""
function _fastby!(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, outType = typeof(fn(valvec[1]))) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S}
    l = length(byvec)
    grouptwo!(byvec, valvec)
    return _contiguousby(fn, byvec, valvec, outType)
end


"""
Apply by-operation assuming that the vector is grouped i.e. elements that belong to the same group by stored contiguously
"""
function _contiguousby(fn::Function, byvec::AbstractVector{T}, valvec::AbstractVector{S}, outType = typeof(fn(valvec[1]))) where {T <: Union{BaseRadixSortSafeTypes, Bool, String}, S}
    l = length(byvec)
    lastby = byvec[1]
    res = Dict{T,outType}()

    j = 1

    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            viewvalvec = @view valvec[j:i-1]
            try
                @inbounds res[lastby] = fn(viewvalvec)
            catch e
                @show fn(viewvalvec)
            end
            j = i
            @inbounds lastby = byvec[i]
        end
    end

    viewvalvec = @view valvec[j:l]
    @inbounds res[byvec[l]] = fn(viewvalvec)
    return res
end


"""
Internal multi-function fastby
"""
function _fastby!(fn::Vector{Function}, byvec::AbstractVector{T}, valvec::AbstractVector{S}) where {T <: BaseRadixSortSafeTypes, S}
    l = length(byvec)
    grouptwo!(byvec, valvec)
    lastby = byvec[1]

    res = Dict{T}()

    j = 1

    for i = 2:l
        @inbounds byval = byvec[i]
        if byval != lastby
            viewvalvec = @view valvec[j:i-1]
            @inbounds res[lastby] = ((fn1(viewvalvec) for fn1 in fn)...)
            j = i
            @inbounds lastby = byvec[i]
        end
    end

    viewvalvec = @view valvec[j:l]
    @inbounds res[byvec[l]] = ((fn1(viewvalvec) for fn1 in fn)...)
    return res
end

