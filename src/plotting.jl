module Plotting

using Gadfly
using DataFrames

export plot_results

function plot_results(df, duraklar, path, ds)
    X1 = zeros(Float64, ds + 1)
    X2 = zeros(Float64, ds + 1)
    Y1 = zeros(Float64, ds + 1)
    Y2 = zeros(Float64, ds + 1)

    for i in 1:ds + 1
        X1[i] = duraklar[1, path[i]]
        X2[i] = duraklar[1, path[i + 1]]
        Y1[i] = duraklar[2, path[i]]
        Y2[i] = duraklar[2, path[i + 1]]
    end

    D = DataFrame(x1=X1, y1=Y1, x2=X2, y2=Y2, colv=1:ds + 1)
    durak = DataFrame(X=duraklar[1, :], Y=duraklar[2, :], K2=0:ds)

    grafik = Gadfly.plot(
        Coord.cartesian(xmin=900, ymin=2300, xmax=1200, ymax=2400),
        layer(df, x=:X, y=:Y, color=:K1, Geom.point),
        layer(D, x=:x1, y=:y1, xend=:x2, yend=:y2, Geom.segment, Theme(default_color="black")),
        layer(durak, x=:X, y=:Y, color=:K2, shape=[xcross], Geom.point, Theme(point_size=7pt)),
        Theme(key_position=:none), Guide.xlabel(nothing), Guide.ylabel(nothing)
    )

    draw(PNG("results/Results.png", dpi=300), grafik)
end

end
