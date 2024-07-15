using Clustering
using Distances
using JuMP, GLPK, Gurobi, Cbc, Clp 
const MOI = JuMP.MathOptInterface

using TravelingSalesmanHeuristics
using DataFrames, Gadfly, Cairo, Fontconfig, Compose
using Random
using Plots, PlotlyJS
using LinearAlgebra
using XLSX

global ds, eds, es, drs, drh, dbus, ddus

#Elma Sayısı
es = 500
#Durak Sayısı (Eğer istenirse durak sayısı ön tanımlı olabilir)
#ds = 3
#Drone Sayısı
drs = 5
#Drone Hızı (m/dk)
drh = 12
#Drone Boş İken Uçuş Süresi
dbus = 30
#Drone Dolu İken Uçuş Süresi
ddus = 25

#Elmaların koordinatları oluşturuluyor
kx = rand(900:1200,es)
ky = rand(2300:2400,es)
kz = rand(1:7,es)
X=vcat(kx',ky',kz')

#Menzilden kaynaklı en küçük durak sayısı bulunuyor
for dsd=2:es
    global ekds, R, as, c, M, T, U, dsi, DEUE
    ekds=dsd

    #K-ortalamalar
    R = kmeans(X, ekds; maxiter=200)
    #Elmaların Hangi Kümeye Atandığı Bilgisi
    as = assignments(R)
    #Kümelerde Kaç Elma Olduğu Bilgisi
    c = counts(R)
    #Kümelerin Merkez Noktaları
    M = R.centers

    #Elmaları Kümelere Atadığımızda Elmanın İndis Bilgisini Tutuyor
    T = Array{Int}(undef, es, ekds)
    T=zeros(es,ekds)
    #Elmaların Atandıkları Küme Merkezi Olan Uzaklıkları (dk cinsinden)
    U = Array{Float64}(undef, es, ekds)
    U=zeros(es,ekds)
    #Duraktaki Küme Merkezi En Uzak Olan Elmanın Uzaklığı (dk cinsinden)
    DEUE = Vector{Float64}(undef, ekds)
    DEUE = zeros(ekds)

    #dsi vektörünü T ve U Matrislerinin Satır İndisleri için Kullanılıyor
    dsi = Vector{Int}(undef, ekds)
    for i=1:ekds
        dsi[i] = 1
    end

    for i=1:es
        for j=1:ekds
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
eds=ekds
println("Süre Cinsinden Menzil = ", round((dbus/(1+(dbus/ddus)));digits=2))
println("En Küçük Durak Sayısı = ", eds)



function harv_opt(ds)
    global R, as, c, M, T, U, dsi, DEUE

    #K-ortalamalar
    R = kmeans(X, ds; maxiter=200)
    #Elmaların Hangi Kümeye Atandığı Bilgisi
    as = assignments(R)
    #Kümelerde Kaç Elma Olduğu Bilgisi
    c = counts(R)
    #Kümelerin Merkez Noktaları
    M = R.centers

    #Elmaları Kümelere Atadığımızda Elmanın İndis Bilgisini Tutuyor
    T = Array{Int}(undef, es, ds)
    T=zeros(es,ds)
    #Elmaların Atandıkları Küme Merkezi Olan Uzaklıkları (dk cinsinden)
    U = Array{Float64}(undef, es, ds)
    U=zeros(es,ds)
    #Duraktaki Küme Merkezi En Uzak Olan Elmanın Uzaklığı (dk cinsinden)
    DEUE = Vector{Float64}(undef, ds)
    DEUE = zeros(ds)

    #dsi vektörünü T ve U Matrislerinin Satır İndisleri için Kullanılıyor
    dsi = Vector{Int}(undef, ds)
    for i=1:ds
        dsi[i] = 1
    end

    for i=1:es
        for j=1:ds
            if as[i]==j
                T[dsi[j],j]=i
                U[dsi[j],j]=euclidean(X[:,i], M[:,j])/drh
                dsi[j] = dsi[j] + 1
            end
        end
    end



    #Elmanın Hangi Drone Tarafından Toplanacağı Bilgisini Tutuyor
    V = Array{Int}(undef, es, ds)
    for i=1:es
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
        #"threads=Sys.CPU_THREADS-1" ile Hesaplama Sırasında Bilgisayarın Mantıksal İşlemcilerinin Bir Tanesi Dışında Hepsini Kullanarak Hesaplama Süresini Azaltıyor
        model = Model(with_optimizer(Cbc.Optimizer, logLevel=0, seconds=30, threads=Sys.CPU_THREADS-1))

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
                @constraint(model, 2.2*U[i,dng]*D[i,k] <= 30)
            end
        end

        #for i=1:c[dng]
        #    for k=1:drs
        #        @constraint(model, SE[i,k] == 2.2*U[i,dng]*D[i,k])
        #    end
        #end

        for k=1:drs
            #@constraint(model, sum(2*U[i,dng]*D[i,k]+SE[i,k] for i=1:c[dng]) == SD[k])
            @constraint(model, sum(2*U[i,dng]*D[i,k] for i=1:c[dng]) == SD[k])
        end

        for k=1:drs
                @constraint(model, SD[k] <= SDM)
        end

        JuMP.optimize!(model)

        sure_d[dng]=JuMP.objective_value(model)
        #println("$dng. Durakta Harcanan Süre = ", round(sure_d[dng];digits=2))

        #Elmanın Hangi Drone Tarafından Toplanacağı Bilgisini Aktarılıyor
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

    #println("Kara Taşıtının Harcadığı Süre = ", round(kths;digits=2))

    #Toplan Elma Toplamak İçin Gerekli Süre Bilgisi Tutuluyor
    sure=sum(sure_d[:])+kths

    #println("Toplam Harcanan Süre = ", round(sure;digits=2))
    return sure
end


#----------------------------------


# Parçacık Sürü Optimizasyonu ile Optimum Durak Sayısı Bulunmaya Başlıyor
# PSO için Değişkenler
global pso_d, pso_n, pso_x, pso_v, pso_w, wmax, wmin, pso_c1, pso_c2, pso_r1, pso_r2, pso_nite, pso_sure, pso_best, pso_ara1, pso_ara2, pso_ara3, pso_par_i_sure, pso_n_sure
pso_d=1 #Boyut sayısı
pso_n=5  #Parçacık Sayısı
wmax=0.9 #inertia weight
wmin=0.4 #inertia weight
pso_c1=2 #Bilişsel Faktör
pso_c2=2 #Sosyal Faktör
pso_nite=5 #İterasyon Sayısı
pso_bsl_v=10 #Başlangıç hız değeri
pso_sure = Vector{Float64}(undef, pso_n+1)
pso_v = Array{Int}(undef, pso_nite, pso_n)
pso_best = Vector{Int}(undef, pso_n+1)
pso_x = Array{Int}(undef, pso_nite, pso_n)
pso_v=fill(pso_bsl_v,(pso_nite,pso_n)) #Parçacık Hızı
pso_n_sure=Vector{Float64}(undef, es)
pso_n_sure=zeros(es)
# pso main program----------------------------------------------------start
#equation(d) = -22 * sind(d-100) + 12 * sind(5d + 450)+50;
#Plots.plot(equation, 2:500)
#ysure(d) = -25 * sind(d-100) + 22 * sind(4d + 750)+70
#Plots.plot(ysure, 2:es)


for pso_par_i=1:pso_n
    pso_x[1,pso_par_i]=pso_par_i*round(es/(pso_n+1))
    pso_best[pso_par_i]=pso_x[1,pso_par_i]
end

for pso_par_i=1:pso_n
    println(pso_par_i,". parçacığın değeri",pso_x[1,pso_par_i])
end

for pso_par_i=1:pso_n
    println(pso_par_i,". parçacığın değeri",pso_x[1,pso_par_i])
    if pso_n_sure[pso_x[1,pso_par_i]]==0
        pso_n_sure[pso_x[1,pso_par_i]]=harv_opt(pso_x[1,pso_par_i])
        println(pso_x[1,pso_par_i],". durak için optimizasyon çalıştırıldı")
        pso_sure[pso_par_i]=pso_n_sure[pso_x[1,pso_par_i]]
    else
        println("optimizasyonun çalıştırılmasına gerek kalmadı")
        pso_sure[pso_par_i]=pso_n_sure[pso_x[1,pso_par_i]]
    end
end

pso_sure[pso_n+1]=minimum(pso_sure[1:pso_n])
pso_best[pso_n+1]=pso_best[argmin(pso_sure[1:pso_n])]

println("Başlangıç durakları")
for i=1:pso_n
    println(pso_x[1,i]," ; ",floor(pso_sure[i]))
end
println(" ")


println("1. iter: Durak:",pso_best[pso_n+1],"  Değer:",pso_sure[pso_n+1])


for pso_ite_i=2:pso_nite

    for pso_par_i=1:pso_n
        w=wmax-(((wmax-wmin)*pso_ite_i)/pso_nite) # update inertial weight
        #println("W - ",w)
        #Parçacıklar için yeni konumlar hesaplanıyor
        #pso_ara1=(w*pso_v[pso_ite_i-1,pso_par_i]+pso_c1*rand()*(pso_best[pso_par_i]-pso_x[pso_ite_i,pso_par_i])+pso_c2*rand()*(pso_best[pso_n+1]-pso_x[pso_ite_i,pso_par_i]))
        #pso_ara2=mod(pso_ara1,1)
        #pso_ara3=floor(Int,pso_ara1)
        #println("pso_ara1 - ",pso_ara1)
        #println("pso_ara2 - ",pso_ara2)
        #println("pso_ara3 - ",pso_ara3)
        pso_r1=rand()
        pso_r2=rand()
        pso_v[pso_ite_i,pso_par_i]=floor((w*pso_v[pso_ite_i-1,pso_par_i])+(pso_c1*pso_r1*(pso_best[pso_par_i]-pso_x[pso_ite_i-1,pso_par_i]))+(pso_c2*pso_r2*(pso_best[pso_n+1]-pso_x[pso_ite_i-1,pso_par_i])))
        #println(pso_par_i,". paçacık için değerler","W: ",round(w, digits=2)," /önc v:",pso_v[pso_ite_i-1,pso_par_i]," /c1:",pso_c1," /r1:",round(pso_r1, digits=2)," /p best:",pso_best[pso_par_i]," /c2:",pso_c2," /r2:",round(pso_r2, digits=2)," /g best:",pso_best[pso_n+1]," /önc konum:",pso_x[pso_ite_i-1,pso_par_i])
        #pso_v[pso_ite_i,pso_par_i]=pso_ara3
        pso_x[pso_ite_i,pso_par_i]=pso_v[pso_ite_i,pso_par_i]+pso_x[pso_ite_i-1,pso_par_i]
        #Parçacıkların yeni konumunun sınırların dışına çıkması engelleniyor
        if pso_x[pso_ite_i,pso_par_i] > es-1
            pso_x[pso_ite_i,pso_par_i]=es-1
        end
        if pso_x[pso_ite_i,pso_par_i] < eds
            pso_x[pso_ite_i,pso_par_i]=eds
        end

        #Parçacıklar için fonksiyon değerleri hesaplanıyor ve parçacık en iyi değerleri güncelleniyor
        if pso_n_sure[pso_x[pso_ite_i,pso_par_i]]==0
            pso_n_sure[pso_x[pso_ite_i,pso_par_i]]=harv_opt(pso_x[pso_ite_i,pso_par_i])
            println(pso_x[pso_ite_i,pso_par_i],". durak için optimizasyon çalıştırıldı")
            pso_par_i_sure=pso_n_sure[pso_x[pso_ite_i,pso_par_i]]
        else
            println(pso_x[pso_ite_i,pso_par_i],". durak için optimizasyonun çalıştırılmasına gerek kalmadı")
            pso_par_i_sure=pso_n_sure[pso_x[pso_ite_i,pso_par_i]]
        end

        #pso_par_i_sure=harv_opt(pso_x[pso_ite_i,pso_par_i])
        if pso_par_i_sure<pso_sure[pso_par_i]
            pso_best[pso_par_i]=pso_x[pso_ite_i,pso_par_i]
            pso_sure[pso_par_i]=pso_par_i_sure
        end
    end
    #İterasyon Sonucu güncellemeler
    pso_sure[pso_n+1]=minimum(pso_sure[1:pso_n])
    pso_best[pso_n+1]=pso_best[argmin(pso_sure[1:pso_n])]
    println(pso_ite_i,". iter: Durak:",pso_best[pso_n+1],"  Değer:",pso_sure[pso_n+1])
    println("Duraklar")
    for i=1:pso_n
        println(pso_x[pso_ite_i,i]," ; ",floor(pso_sure[i]))
    end
    println(" ")


end
println("En iyi sonuç")
println(pso_nite,". iter: Durak:",pso_best[pso_n+1],"  Değer:",pso_sure[pso_n+1])
