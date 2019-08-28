using juxta
using Test

ja = juxta.JuxtArray(randn(5,10), ("x","y"),
                     Dict("x"=>collect(1:5),"y"=>collect(1:10)),
                     Dict())
ja1 = juxta.JuxtArray(randn(5,10), ("x","y"),
                     Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2),
                     Dict())
ja2 = juxta.JuxtArray(randn(5,10), ("x","y"),
                     Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2),
                     Dict())
ja3 = juxta.JuxtArray(randn(5,10), ("x","y"),
                     Dict("x"=>collect(1:5),"y"=>collect(1:10) .* 2),
                     Dict())
@testset "juxta.jl" begin
    @test typeof(ja) == juxta.JuxtArray
    @test ja.indices["x"] == 1:5
    @test ja.indices["y"] == 1:10
    @test ja1.indices["x"] == 1:5
    @test ja1.indices["y"] == 1:10
    @test juxta.isel!(ja, x=2:4).indices["x"] == 1:3
    @test juxta.isel!(ja, y=2).indices["y"] == 1:1
    @test ja.coords["y"][1] == 2
    @test size(ja.array,1) == 3
    @test juxta.isel!(ja1, x=2:4, y=3:2:8).indices["x"] == 1:3
    @test ja1.indices["y"] == 1:3
    @test ja1.coords["y"] == [3,5,7] .* 2
    @test ja1.coords["x"] == collect(2:4)
    @test juxta.sel!(ja2, x=1.1:0.2:4.1).indices["x"] == 1:3
    @test ja2.coords["x"] == collect(2:4)
    @test juxta.sel!(ja3, "nearest", x=1.1:0.2:4.1).indices["x"] == 1:4
    @test ja3.coords["x"] == collect(1:4)
    @test juxta.sel!(ja3, "nearest", x=0.8).indices["x"] == 1:1
    @test ja3.coords["x"] == Number[1]
    @test juxta.sel!(ja3, y=10.3).indices["y"] == 1:2
    @test ja3.coords["y"] == Number[10,12]
    @test juxta.jsize(ja3) == (1,2)
    @test juxta.jsize(ja3, "x") == 1
    @test juxta.jsize(ja3, "y") == 2
    @test juxta.jsize(juxta.dropdims(ja3, dims=["x"])) == (2,)
end
