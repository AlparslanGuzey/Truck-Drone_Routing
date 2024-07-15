
# Create a scatter plot of x, y, z points
scatter3d(X1, Y1, 1:ds+1, color=:blue, label="Data Points")
scatter3d!(duraklar[1,:], duraklar[2,:], zeros(length(duraklar[1,:])), color=:red, label="Duraklar")

# Add lines connecting data points
for i=1:ds
    plot3d!([X1[i], X2[i]], [Y1[i], Y2[i]], [i, i+1], color=:black, label="")
end

# Set the title and axis labels
title!("Results")
xlabel!("X")
ylabel!("Y")
zlabel!("Z")

# Save the plot as a PNG image
savefig("Results.png")

#------------------------------------------------------

df = DataFrame(X=kx,Y=ky,Z=kz, K1=as)

X1 = Vector{Float64}(undef, ds+1)
X2 = Vector{Float64}(undef, ds+1)
Y1 = Vector{Float64}(undef, ds+1)
Y2 = Vector{Float64}(undef, ds+1)
Z1 = Vector{Float64}(undef, ds+1)
Z2 = Vector{Float64}(undef, ds+1)

for i=1:ds+1
X1[i]=duraklar[1,path[i]]
X2[i]=duraklar[1,path[i+1]]
Y1[i]=duraklar[2,path[i]]
Y2[i]=duraklar[2,path[i+1]]
Z1[i]=duraklar[3,path[i]]
Z2[i]=duraklar[3,path[i+1]]
end

D = DataFrame(x1=X1, y1=Y1, z1=Z1, x2=X2, y2=Y2,z2=Z2 colv=1:ds+1)
durak = DataFrame(X=duraklar[1,:],Y=duraklar[2,:], Z=duraklar[3,:] K2=0:ds)

grafik = Gadfly.plot(Coord.cartesian(xmin=900, ymin=2300, zmin=1, xmax=1200, ymax=2400, zmax=7),
     layer(df, x = :X, y = :Y, z = :Z, color = :K1, Geom.point),
     layer(D, x=:x1, y=:y1, z=:z1, xend=:x2, yend=:y2, zend=:z2, Geom.segment, Theme(default_color="black")),
     layer(durak, x = :X, y = :Y, z =:Z, color = :K2, shape=[xcross], Geom.point, Theme(point_size=7pt)),
     Theme(key_position = :none), Guide.xlabel(nothing), Guide.ylabel(nothing)
     )

 draw(PNG("Results.png", dpi=300), grafik)

#-------------------------------------------------------
df = DataFrame(X=kx,Y=ky,K1=as)


X1 = Vector{Float64}(undef, ds+1)
X2 = Vector{Float64}(undef, ds+1)
Y1 = Vector{Float64}(undef, ds+1)
Y2 = Vector{Float64}(undef, ds+1)

for i=1:ds+1
X1[i]=duraklar[1,path[i]]
X2[i]=duraklar[1,path[i+1]]
Y1[i]=duraklar[2,path[i]]
Y2[i]=duraklar[2,path[i+1]]
end

D = DataFrame(x1=X1, y1=Y1, x2=X2, y2=Y2, colv=1:ds+1)
durak = DataFrame(X=duraklar[1,:],Y=duraklar[2,:],K2=0:ds)

grafik = Gadfly.plot(Coord.cartesian(xmin=900, ymin=2300, xmax=1200, ymax=2400),
     layer(df, x = :X, y = :Y, color = :K1, Geom.point),
     layer(D, x=:x1, y=:y1, xend=:x2, yend=:y2, Geom.segment, Theme(default_color="black")),
     layer(durak, x = :X, y = :Y,color = :K2, shape=[xcross], Geom.point, Theme(point_size=7pt)),
     Theme(key_position = :none), Guide.xlabel(nothing), Guide.ylabel(nothing)
     )

 draw(PNG("Results.png", dpi=300), grafik)

