# juxta

[![Build Status](https://travis-ci.com/beta-effect/juxta.jl.svg?branch=master)](https://travis-ci.com/beta-effect/juxta.jl)
[![Codecov](https://codecov.io/gh/beta-effect/juxta.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/beta-effect/juxta.jl)

This package facilitates creation and manipulation of multi-dimensional labeled arrays. The eventual aim of this package is to emulate something similar to Xarray in python. 

A container, `JuxtArray`, is provided. Only slicing is currently implemented.

## Examples

Creation:

```julia
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10)))
Dimensions  : ["x", "y"]
Array       : 5×10 Array{Float64,2}
Coordinates :
    x: 5-element Array{Number,1}
    y: 10-element Array{Number,1}
Attributes  : Dict{Any,Any}()
```

Index-based slicing:

```julia
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10)))
Dimensions  : ["x", "y"]
Array       : 5×10 Array{Float64,2}
Coordinates :
    x: 5-element Array{Number,1}
    y: 10-element Array{Number,1}
Attributes  : Dict{Any,Any}()

julia> juxta.isel!(ja, x=2:4, y=3:7)
Dimensions  : ["x", "y"]
Array       : 3×5 Array{Float64,2}
Coordinates :
    x: 3-element Array{Number,1}
    y: 5-element Array{Number,1}
Attributes  : Dict{Any,Any}()
```
Indexing based on physical values of dimensions:


```julia
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> juxta.sel!(ja, y=3.7:7.9)
Dimensions  : ["x", "y"]
Array       : 5×2 Array{Float64,2}
Coordinates :
    x: 5-element Array{Number,1}
    y: 2-element Array{Number,1}
Attributes  : Dict{Any,Any}()
```
This returns a subset where the dimension `y` ranges from 4:2:6.

```julia
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> juxta.sel!(ja, "nearest", y=3.7:7.9)
Dimensions  : ["x", "y"]
Array       : 5×3 Array{Float64,2}
Coordinates :
    x: 5-element Array{Number,1}
    y: 3-element Array{Number,1}
Attributes  : Dict{Any,Any}()
```
This returns a subset where the dimension `y` ranges from 4:2:8.

```julia
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> juxta.sel!(ja, y=3.7)
Dimensions  : ["x", "y"]
Array       : 5×2 Array{Float64,2}
Coordinates :
    x: 5-element Array{Number,1}
    y: 2-element Array{Number,1}
Attributes  : Dict{Any,Any}()
```
This returns a subset where the dimension `y` ranges from 2:2:4.

```julia
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> juxta.sel!(ja, "nearest", y=3.7)
Dimensions  : ["x", "y"]
Array       : 5×1 Array{Float64,2}
Coordinates :
    x: 5-element Array{Number,1}
    y: 1-element Array{Number,1}
Attributes  : Dict{Any,Any}()
```
This returns a subset where the dimension `y` ranges from 4:4.

Dropping singleton dimensions:

```julia
julia> ja = juxta.JuxtArray(randn(5,10), ["x","y"], Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2))
julia> ja = juxta.sel!(ja, "nearest", x=0.8)
julia> ja = dropdims(ja, ["x"])
Dimensions  : ["y"]
Array       : 10-element Array{Float64,1}
Coordinates :
    x: 1-element Array{Number,1}
    y: 10-element Array{Number,1}
Attributes  : Dict{Any,Any}()
```

All of the above operations can be combined using Julia's piping functionality:
```julia
julia> ja = juxta.JuxtArray(randn(5,10,1), ["x","y","za"],
                     Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2,"za"=>[2]))
julia> ja = (ja
               |> j->juxta.isel!(j,x=2)
               |> j->dropdims(j,["x","za"])
               |> j->size(j))
(10,)
```
or by using Pipe.jl:
```julia
julia> using Pipe
julia> ja = juxta.JuxtArray(randn(5,10,1), ["x","y","za"],
                     Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2,"za"=>[2]))
julia> ja = @pipe (ja
                     |> juxta.isel!(_,x=2)
                     |> dropdims(_,["x","za"])
                     |> size(_))
(10,)
```
or by using Lazy.jl:
```julia
julia> using Lazy
julia> ja = juxta.JuxtArray(randn(5,10,1), ["x","y","za"],
                     Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2,"za"=>[2]))
julia> ja = @> ja juxta.isel!(x=2) dropdims(["x","za"]) size()
(10,)
```

## TODO

- Test with datetime dimensions
- Implement plotting