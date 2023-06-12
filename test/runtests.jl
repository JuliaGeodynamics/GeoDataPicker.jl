using DataPicker, Test




@testset "Read SVG" begin
    # reads an SVG file and returns a NamedTuple with the various 3D curves
    fname="../playground/Alps.HZ.svg";
    Curves = parse_SVG(fname, verbose=false)

    @test length(Curves.S_Apennines) == 8
    @test sum(Curves.S_Apennines[1]) ≈ 19083.235458436666

end
