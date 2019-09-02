module juxta

"""
    JuxtArray(array::Array, dims::Tuple, coords::Dict{String, Vector{Number}}[, attribs::Dict])

Construct an N-dimensional JuxtArray which contains an Array as well
as Vectors representing the dimensions.

# Examples
```julia-repl
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10)))
```
"""
mutable struct JuxtArray
    array::AbstractArray
    dims::Vector{String}
    coords::Dict{String, Vector{Number}}
    attribs::Dict
    indices::Dict{String, AbstractRange}
    function JuxtArray(array, dims, coords, attribs=Dict())
        @assert ndims(array) == length(dims) "Number of dims should be equal to the number of dims of the array"
        indices = Dict{String, AbstractRange}()
        for (i, array_dim_length) in enumerate(Base.size(array))
            @assert array_dim_length == size(coords[dims[i]])[1] "Mismatch between length of array and coordinate"
            push!(indices,dims[i]=>1:array_dim_length)
        end
        new(array, dims, coords, attribs, indices)
    end
end

function Base.show(io::IO, ja::JuxtArray)
    println("Dimensions  : $(ja.dims)")
    println("Array       : $(summary(ja.array))")
    println("Coordinates :")
    for (k,v) in ja.coords
        println("    $k: $(summary(v))")
    end
    if !(isempty(ja.attribs))
        println("Attributes  : $(ja.attribs)")
    end
end

# function Base.setproperty!(ja::JuxtArray, ::Field{:coords}, d::Dict{String, Vector{Number}})

# end
# function Base.setproperty!(ja::JuxtArray, :dims, d::Dict{String, Vector{Number}})

# end
# function Base.setproperty!(ja::JuxtArray, :array, d::Dict{String, Vector{Number}})

# end


"""
    isel!(ja::JuxtArray; kwargs)

A method for index-based slicing of JuxtArray.

# Arguments

- `x::OrdinalRange`: A range that would be used to slice along the dimension `x`. Note that `x` has to be one of the dimensions. Slices for multiple dimensions can be passed in one call.

# Example
```
julia> ja = JuxtArray(randn(5,10), ("x","y"), Dict("x"=>collect(1:5),"y"=>collect(1:10)))
julia> isel!(ja, x=2:4, y=3:7)
```
See also: [`sel!`](@ref)
"""
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
    for dim in ja.dims
        range = ja.indices[dim]
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

"""
    sel!(ja::JuxtArray, method::String; kwargs)

A method for physical slicing of JuxtArray.

# Arguments

- `method::String="subset"`: can eith be `"subset"`(default) or `"nearest"`. This is used when the extremeties of the range do not exactly line up up with the axis grid. The former gives a slice where the slice is the largest possible subset of the provided range, while the latter gives a subset whose extremeties are nearest to the extremeties of the provided range.
- `x::Union{AbstractRange, Real}`: A range that would be used to slice along the dimension `x`. Note that `x` has to be one of the dimensions. Slices for multiple dimensions can be passed in one call. The range can be of integer type (`1:4`) or float type (`1.1:4.1`). For integer type ranges, step is ignored by this function i.e. `1:2:4` and `1:4` are treated in the same way. Care must be taken while using float ranges. For example, 1.1:3.3 is not the same as 1.1:0.1:3.3. The latter must be used. If `x` is `Real`, a subset encompassing `x` is returned if `method="subset"` or a single value is returned closest to `x` if `method="nearest"`.

# Example
```
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> juxta.sel!(ja, y=3.7:7.9)
```
This returns a subset where the dimension `y` ranges from 4:6.
```
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> juxta.sel!(ja, "nearest", y=3.7:7.9)
```
This returns a subset where the dimension `y` ranges from 4:8.
```
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> juxta.sel!(ja, y=3.7)
```
This returns a subset where the dimension `y` ranges from 2:4.
```
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> juxta.sel!(ja, "nearest", y=3.7)
```
This returns a subset where the dimension `y` ranges from 4:4.

See also: [`isel!`](@ref)
"""
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

"""
Returns the size of the Array.
"""
Base.size(ja::JuxtArray) = Base.size(ja.array)

"""
    size(ja::JuxtArray[, dim::String])

Returns the size of the Array.

# Arguments

- `ja::JuxtArray`: The size of this array will be returned.
- `dim::String`: The dimension whose size is queried.
"""
function Base.size(ja::JuxtArray, dim::String)
    i = findfirst(x -> x==dim, ja.dims)
    Base.size(ja.array, i)
end

"""
    dropdims(ja::JuxtArray, dims::Vector{String})

Drops dimensions from the list `dims` if and only if their length is 1.
"""
function Base.dropdims(ja::JuxtArray, dims=[])
    @assert !(ja.dims == dims) "All dimensions of an array cannot be dropped."
    ndims = length(ja.dims)
    for (i,dim) in enumerate(reverse(ja.dims))
        if dim in dims
            irev = ndims - i + 1
            @assert size(ja, dim) == 1 "Cannot drop dim with size > 1"
            ja.array = Base.dropdims(ja.array, dims=irev)
            deleteat!(ja.dims, irev)
        end
    end
    ja
end

end # module
