module juxta

mutable struct JuxtArray
    array::AbstractArray
    dims::Tuple
    coords::Dict{String, Vector{Number}}
    attribs::Dict
    indices::Dict{String, AbstractRange}
    function JuxtArray(array, dims, coords, attribs)
        @assert ndims(array) == length(dims) "Number of dims should be equal to the number of dims of the array"
        indices = Dict{String, AbstractRange}()
        for (i, array_dim_length) in enumerate(Base.size(array))
            @assert array_dim_length == size(coords[dims[i]])[1] "Mismatch between length of array and coordinate"
            push!(indices,dims[i]=>1:array_dim_length)
        end
        new(array, dims, coords, attribs, indices)
    end
end

function isel!(ja::JuxtArray; kwargs...)
    for (k,v) in kwargs
        if String(k) in ja.dims
            if typeof(v) <: OrdinalRange
                push!(ja.indices, String(k)=>v)
            elseif typeof(v) <: Integer
                push!(ja.indices, String(k)=>v:v)
            end
        end
    end
    inds = Vector{AbstractRange}()
    for (dim, range) in ja.indices
        ja.coords[dim] = ja.coords[dim][range]
        push!(inds, range)
        push!(ja.indices, dim=>1:length(ja.coords[dim]))
    end
    ja.array = getindex(ja.array, inds...)
    ja
end

function get_start_stop_indices(dim_vector::Vector,
                                physical_start::Real,
                                physical_stop::Real,
                                method::String)

    if method == "subset"
        dim_vector_temp = dim_vector .- physical_start
        start = findfirst(x -> x>=0, dim_vector_temp)
        dim_vector_temp = dim_vector .- physical_stop
        stop = findlast(x -> x<=0, dim_vector_temp)
        if physical_start == physical_stop
            return (stop, start)
        end
    elseif method == "nearest"
        dim_vector_temp = abs.(dim_vector .- physical_start)
        start = findmin(dim_vector_temp)[2]
        dim_vector_temp = abs.(dim_vector .- physical_stop)
        stop = findmin(dim_vector_temp)[2]
    end
    return (start, stop)
end

function sel!(ja::JuxtArray, method::String = "subset"; kwargs...)
    for (k,v) in kwargs
        dim = String(k)
        if dim in ja.dims
            if typeof(v) <: AbstractRange
                physical_start, physical_stop = collect(v)[1], collect(v)[end]
            elseif typeof(v) <: Real
                physical_start, physical_stop = v, v
            end
            dim_vector = ja.coords[dim]
            start, stop = get_start_stop_indices(dim_vector, physical_start,
                                                 physical_stop, method)
            kwargs = Dict(k=>start:stop)
            isel!(ja; kwargs...)
        end
    end
    ja
end

function jsize(ja::JuxtArray)
    Base.size(ja.array)
end

function jsize(ja::JuxtArray, dim::String)
    i = findfirst(x -> x==dim, ja.dims)
    Base.size(ja.array, i)
end

function dropdims(ja::JuxtArray; dims=[])
    dim_vec = Array([ja.dims...])
    ndims = length(dim_vec)
    for (i,dim) in enumerate(reverse(dim_vec))
        if dim in dims
            irev = ndims - i + 1
            @assert jsize(ja, dim) == 1
            ja.array = Base.dropdims(ja.array, dims=irev)
            deleteat!(dim_vec, irev)
        end
    end
    ja.dims = tuple(dim_vec...)
    ja
end

end # module
