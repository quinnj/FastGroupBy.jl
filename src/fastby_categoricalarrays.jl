function fastby!(fn::Function, byvec::Union{PooledArray{pooltype, indextype}, CategoricalArray{pooltype, indextype}}, valvec::AbstractVector{S}, outType = valvec[1:1] |> fn |> typeof) where {S, pooltype, indextype}
    l = length(byvec.pool)
   
    # count the number of occurences of each ref
   

    res = Dict{pooltype, outType}()


    if fn == Base.sum
        resvec = zeros(outType, l)
        @inbounds for (r,v) in zip(byvec.refs, valvec)
            resvec[r] += v
        end
        for (i,c) in enumerate(resvec)
            res[byvec.pool[i]] = c
        end
    else
        counter = zeros(UInt, l)
        for r1 in byvec.refs
            @inbounds counter[r1] += 1
        end
        
        lbyvec = length(byvec)
        r1 = byvec.refs[lbyvec]

        # check for degenerate case
        if counter[r1] == lbyvec
            return Dict(byvec[1] => fn(valvec))
        end

        uzero = zero(UInt)
        nonzeropos = fcollect(l)[counter .!= uzero]

        counter = cumsum(counter)
        rangelo = vcat(0, counter[1:end-1]) .+ 1
        rangehi = copy(counter)

        simvalvec = similar(valvec)

        ci = counter[r1]
        simvalvec[ci] = valvec[lbyvec]
        counter[r1] -= 1

        @inbounds for i = lbyvec-1:-1:1
            r1 = byvec.refs[i]
            ci = counter[r1]
            simvalvec[ci] = valvec[i]
            counter[r1] -= 1
        end

        for nzpos in nonzeropos
            (po, lo, hi) = (byvec.pool[nzpos], rangelo[nzpos], rangehi[nzpos])
            res[po] = fn(simvalvec[lo:hi])
        end
    end

    return res
end

function cate_sum_by(byvec::Union{PooledArray{pooltype, indextype}, CategoricalArray{pooltype, indextype}}, valvec::AbstractVector{S}) where {S, pooltype, indextype}
    l = length(byvec.pool)
    # count the number of occurences of each ref
    res = Dict{pooltype, S}()
    resvec = zeros(S, l)
    @inbounds for (r,v) in zip(byvec.refs, valvec)
        resvec[r] += v
    end
    for (i,c) in enumerate(resvec)
        res[byvec.pool[i]] = c
    end
end