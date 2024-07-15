
using Clustering
using Distances
using GLPK, Cbc, Clp
using JuMP
using TravelingSalesmanHeuristics
using DataFrames, Gadfly, Cairo, Fontconfig, Compose
using Random
using LinearAlgebra
using HiGHS
using XLSX
using Plots, PlotlyJS
using CategoricalArrays

#Toplanma Alanı Sayısı
tas = 200
#Durak Sayısı (Eğer istenirse durak sayısı ön tanımlı olabilir)
#ds = 3
#Drone Sayısı
drs = 4
#Drone Hızı (m/dk)
drh = 10
#Drone Dolu İken Uçuş Süresi
ddus = 10
#Drone Boş İken Uçuş Süresi
dbus = 15

#Toplanma alanlarının koordinatları oluşturuluyor
kx = rand(900:1200,tas)
ky = rand(2300:2400,tas)
kz = rand(1:7,tas)
X=vcat(kx',ky',kz')

for dsd=2:tas
    global ds, R, as, c, M, T, U, dsi, DEUE
    ds=dsd

    #K-ortalamalar
    R = kmeans(X, ds; maxiter=200)
    #Toplanma Alanının Hangi Kümeye Atandığı Bilgisi
    as = assignments(R)
    #Kümelerde Kaç Toplanma Alanı Olduğu Bilgisi
    c = counts(R)
    #Kümelerin Merkez Noktaları
    M = R.centers

    #Toplanma Alanını Kümelere Atadığımızda Alanın İndis Bilgisini Tutuyor
    T = Array{Int}(undef, tas, ds)
    T=zeros(tas,ds)
    #Toplanma Alanlalarının Atandıkları Küme Merkezine Olan Uzaklıkları (dk cinsinden)
    U = Array{Float64}(undef, tas, ds)
    U=zeros(tas,ds)
    #Duraktaki Küme Merkezine En Uzak Olan Toplanma Alanının Uzaklığı (dk cinsinden)
    DEUE = Vector{Float64}(undef, ds)
    DEUE = zeros(ds)

    #dsi vektörünü T ve U Matrislerinin Satır İndisleri için Kullanılıyor
    dsi = Vector{Int}(undef, ds)
    for i=1:ds
        dsi[i] = 1
    end

    for i=1:tas
        for j=1:ds
            if as[i]==j
                T[dsi[j],j]=i
                U[dsi[j],j]=euclidean(X[:,i], M[:,j])/drh
                dsi[j] = dsi[j] + 1
            end
        end
    end

    if maximum(U) <= (dbus/(1+(dbus/ddus)))
        break
    end
end

println("Süre Cinsinden Menzil = ", round((dbus/(1+(dbus/ddus)));digits=2))
println("En Küçük Durak Sayısı = ", ds)

for i=1:ds
    DEUE[i]=maximum(U[:,i])
    println("$i. Duraktaki Toplanma Alanı Sayısı = ", c[i])
    println("$i. Durağa En Uzak Toplanma Alanının Mesafesi(süre cinsinden) = ", round(DEUE[i];digits=2))
end

#Toplanma Alanına Hangi Drone Tarafından Teslimat Yapılacağı Bilgisini Tutuyor
V = Array{Int}(undef, tas, ds)
for i=1:tas
    for j=1:ds
        V[i,j]=0
    end
end

#Her Küme için Optimal Toplama Stratejisi Oluşturuluyor

#Her Durakta Harcanan Süre Bilgisi Tutuluyor
sure_d = Array{Float64}(undef, ds)

for dngd=1:ds
    global dng
    dng=dngd

    model = Model(HiGHS.Optimizer)

    @variable(model, D[1:c[dng],1:drs], Bin)
    @variable(model, SE[1:c[dng],1:drs])
    @variable(model, SD[1:drs])
    @variable(model, SDM)

    @objective(model, Min, SDM)

    for i=1:c[dng]
        @constraint(model, sum(D[i,k] for k=1:drs) == 1)
    end

    for i=1:c[dng]
        for k=1:drs
            @constraint(model, 2.5*U[i,dng]*D[i,k] <= 60)
        end
    end

    for i=1:c[dng]
        for k=1:drs
            @constraint(model, SE[i,k] == 2.5*U[i,dng]*D[i,k])
        end
    end

    for k=1:drs
        @constraint(model, sum(2*U[i,dng]*D[i,k]+SE[i,k] for i=1:c[dng]) == SD[k])
    end

    for k=1:drs
            @constraint(model, SD[k] <= SDM)
    end

    JuMP.optimize!(model)

    sure_d[dng]=JuMP.objective_value(model)
    println("$dng. Durakta Harcanan Süre = ", round(sure_d[dng];digits=2))

    #Toplanma Alanına Hangi Drone Tarafından Teslimat Yapılacağı Bilgisini Aktarılıyor
    for i=1:c[dng]
        for j=1:drs
            if value.(D[i,j])>0.5
                V[i,dng]=j
            end
        end
    end

end

duraklar=Array{Float64}(undef, 2,ds+1)
duraklar[1,1]=900
duraklar[2,1]=2300
for i=1:ds
    duraklar[1,i+1]=M[1,i]
    duraklar[2,i+1]=M[2,i]
end

distmat = [norm(duraklar[:,i] - duraklar[:,j]) for i in 1:ds+1, j in 1:ds+1]

@time path, cost = solve_tsp(distmat; quality_factor = 100)
#Kara Taşıtının HArcadığı Süre
kths = cost/drh

println("Kara Taşıtının Harcadığı Süre = ", round(kths;digits=2))

#Toplam Toplanma Alanlarına Teslimat İçin Gerekli Süre Bilgisi Tutuluyor
sure=sum(sure_d[:])+kths

println("Toplam Harcanan Süre = ", round(sure;digits=2))


filename = "Results.xlsx"

s1columns = Vector()
push!(s1columns, 1:tas)
push!(s1columns, X[1,:])
push!(s1columns, X[2,:])
push!(s1columns, X[3,:])
push!(s1columns, as)

s1labels = [ "Toplanma Alanı No", "X Ekseni", "Y Ekseni", "Yükseklik","Atandığı Küme"]

s2columns = Vector()
s2labels = Vector()
for i=1:ds
    push!(s2labels, "$i. Kümedeki ... Toplanma Alanına")
    push!(s2columns, T[:,i])
    push!(s2labels, "$i. Kümede ... Drone Tarafından")
    push!(s2columns, V[:,i])
    push!(s2labels, "$i. Kümede ... Sürede Teslimat Yapılacaktır")
    push!(s2columns, 5*U[:,i])
end

s3columns = Vector()
s3labels = Vector()
s3labels = [ "Durak", "Duraktaki Toplanma Alanı Sayısı", "Duraktaki En Uzak Toplanma Alanı(dk)", "Durakta Harcanan Süre"]
    push!(s3columns, 1:ds)
    push!(s3columns, c[:])
    push!(s3columns, DEUE[:])
    push!(s3columns, sure_d[:])

bos=Array{Float64}(undef, 600,100)
bos=fill("", (600,100))

XLSX.openxlsx(filename, mode="rw") do xf
    sheet1 = xf[1]
    sheet2 = xf[2]
    sheet3 = xf[3]

    #Önceki Hesaplama Sonuçlarını Siliyor
    sheet1["A1:CV600"]=bos
    sheet2["A1:CV600"]=bos
    sheet3["A1:CV600"]=bos

    XLSX.writetable!(sheet1, s1columns, s1labels, anchor_cell=XLSX.CellRef("B2"))
    XLSX.writetable!(sheet2, s2columns, s2labels, anchor_cell=XLSX.CellRef("B2"))
    sheet3["B2"] = "Toplam Harcanan Süre"
    sheet3["E2"] = sure
    sheet3["B3"] = "Kara Taşıtının Duraklar Arasında Harcadığı Süre"
    sheet3["E3"] = kths
    XLSX.writetable!(sheet3, s3columns, s3labels, anchor_cell=XLSX.CellRef("B5"))
end

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
 
 

