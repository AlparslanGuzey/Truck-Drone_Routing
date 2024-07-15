using Clustering
using Distances
using Statistics
using JuMP, GLPK, Gurobi, Cbc, Clp
const MOI = JuMP.MathOptInterface

using TravelingSalesmanHeuristics
using DataFrames, Gadfly, Cairo, Fontconfig, Compose
using Random
using Plots, PlotlyJS
using LinearAlgebra
using XLSX

global iter, maksuzak, maksuzak1
iter=50
itersure=zeros(Float64,iter,6)

for xyz=1:iter
    global ibs, ilcmkt, ilcsur, maksuzak, maksuzak1
    #İlaçlanacak Bölge Sayısı
    ibs = 50
    #Durak Sayısı (Eğer istenirse durak sayısı ön tanımlı olabilir)
    #ds = 3
    #Drone Sayısı
    drs = 4
    #Drone Hızı (m/dk) (42km/s)
    drh = 700
    #Drone Boş İken Uçuş Süresi (dk)
    dbus = 50
    #Drone Dolu İken Uçuş Süresi (dk)
    ddus = 30
    # İlaçlama Süresi 100m^2 için 10 sn
    # İlaçlama Miktarı 100m^2 için 1lt
    #İlaçlama Tankının Büyüklüğü
    ilctnk=100

    sure=zeros(Float64,6)


    #İlaçlama Bölgeleri Türlerinin Adetleri Oluşturuluyor
    xx = Vector{Int}(undef, 50*ibs)
    xy = Vector{Int}(undef, ibs)

    for i=1:ibs
        xy[i] = ilctnk
    end

    while sum(xy) >= ilctnk

        xx = rand(1:5,50*ibs)
        for i=1:ibs
            xy[i] = xx[50*(i-1)+rand(1:5)]
        end
        sum(xy)
    end

    #İlaçlama Bölgeleri koordinatları oluşturuluyor
    kx = rand(0:1200,ibs)
    ky = rand(0:150,ibs)
    X=vcat(kx',ky')

    #Kullanılacak İlaç Miktarı Hesaplanıyor
    ilcmkt=sum(xy)

    #İlaçlama İçin Gerekli Süre
    ilcsur = ilcmkt/6

    #1. Senaryo
    #Uzun Kenarın Ortasındaki Tek Drone

    duraklar=Array{Float64}(undef, 2,ibs+1)
    duraklar[1,1]=600
    duraklar[2,1]=0
    for i=1:ibs
        duraklar[1,i+1]=X[1,i]
        duraklar[2,i+1]=X[2,i]
    end

    distmat = [norm(duraklar[:,i] - duraklar[:,j]) for i in 1:ibs+1, j in 1:ibs+1]

    @time path, cost = solve_tsp(distmat; quality_factor = 100)
    #Kara Taşıtının HArcadığı Süre
    dhs = cost/drh

    println("1. Senaryo Dronun Harcadığı Süre = ", round(dhs;digits=2))

    #Toplan Elma Toplamak İçin Gerekli Süre Bilgisi Tutuluyor
    sure[1]=dhs+ilcsur

    println("1. Senaryo Toplam Harcanan Süre = ", round(sure[1];digits=2))

    #2. Senaryo
    #Her Bir Köşede Drone Kendi Bölgesini İlaçlıyor

    #İlaçlanacak Alanlar Bölgelerine Atanıyor
    Y = zeros(Int, 4, 2, ibs)
    bias=Vector{Int}(undef, 4)
    #dngicsyc vektörünü Y Matrislerinin Satır İndisleri için Kullanılıyor
    global dngicsyc = Vector{Int}(undef, 4)
    for i=1:4
        dngicsyc[i] = 1
    end

    for i=1:ibs
        if X[1,i]>=0 && X[1,i]<=600 && X[2,i]>=0 && X[2,i]<=75
            Y[1,1,dngicsyc[1]]=X[1,i]
            Y[1,2,dngicsyc[1]]=X[2,i]
            dngicsyc[1]=dngicsyc[1]+1
        end
        if X[1,i]>600 && X[1,i]<=1200 && X[2,i]>=0 && X[2,i]<=75
            Y[2,1,dngicsyc[2]]=X[1,i]
            Y[2,2,dngicsyc[2]]=X[2,i]
            dngicsyc[2]=dngicsyc[2]+1
        end
        if X[1,i]>=0 && X[1,i]<=600 && X[2,i]>75 && X[2,i]<=150
            Y[3,1,dngicsyc[3]]=X[1,i]
            Y[3,2,dngicsyc[3]]=X[2,i]
            dngicsyc[3]=dngicsyc[3]+1
        end
        if X[1,i]>600 && X[1,i]<=1200 && X[2,i]>75 && X[2,i]<=150
            Y[4,1,dngicsyc[4]]=X[1,i]
            Y[4,2,dngicsyc[4]]=X[2,i]
            dngicsyc[4]=dngicsyc[4]+1
        end
    end
    #Her Bir Bölgede İlaçlanacak Alan sayısı
    global hbias = Vector{Int}(undef, 4)
    for i=1:4
        hbias[i]=dngicsyc[i]-1
    end

    # Her Bir Bölgedeki Dolaşım Süresi Elde Ediliyor

    #1.Bölge
    duraklar1=Array{Float64}(undef, 2,hbias[1]+1)
    duraklar1[1,1]=0
    duraklar1[2,1]=0
    for i=1:hbias[1]
        duraklar1[1,i+1]=Y[1,1,i]
        duraklar1[2,i+1]=Y[1,2,i]
    end

    distmat = [norm(duraklar1[:,i] - duraklar1[:,j]) for i in 1:hbias[1]+1, j in 1:hbias[1]+1]

    @time path, cost = solve_tsp(distmat; quality_factor = 100)
    #Kara Taşıtının HArcadığı Süre
    dhs = cost/drh
    println("2. Senaryo 1.Bölg Dronun Harcadığı Süre = ", round(dhs;digits=2))
    #Toplan Elma Toplamak İçin Gerekli Süre Bilgisi Tutuluyor
    sure[2]=dhs+ilcsur

    #2.Bölge
    duraklar2=Array{Float64}(undef, 2,hbias[2]+1)
    duraklar2[1,1]=0
    duraklar2[2,1]=0
    for i=1:hbias[2]
        duraklar2[1,i+1]=Y[2,1,i]
        duraklar2[2,i+1]=Y[2,2,i]
    end

    distmat = [norm(duraklar2[:,i] - duraklar2[:,j]) for i in 1:hbias[2]+1, j in 1:hbias[2]+1]

    @time path, cost = solve_tsp(distmat; quality_factor = 100)
    #Kara Taşıtının HArcadığı Süre
    dhs = cost/drh
    println("2. Senaryo 2.Bölg Dronun Harcadığı Süre = ", round(dhs;digits=2))

    #Toplan Elma Toplamak İçin Gerekli Süre Bilgisi Tutuluyor
    sure[2]=sure[2]+dhs


    #3.Bölge
    duraklar3=Array{Float64}(undef, 2,hbias[3]+1)
    duraklar3[1,1]=0
    duraklar3[2,1]=0
    for i=1:hbias[3]
        duraklar3[1,i+1]=Y[3,1,i]
        duraklar3[2,i+1]=Y[3,2,i]
    end

    distmat = [norm(duraklar3[:,i] - duraklar3[:,j]) for i in 1:hbias[3]+1, j in 1:hbias[3]+1]

    @time path, cost = solve_tsp(distmat; quality_factor = 100)
    #Kara Taşıtının HArcadığı Süre
    dhs = cost/drh
    println("2. Senaryo 3.Bölg Dronun Harcadığı Süre = ", round(dhs;digits=2))

    #Toplan Elma Toplamak İçin Gerekli Süre Bilgisi Tutuluyor
    sure[2]=sure[2]+dhs

    #4.Bölge
    duraklar4=Array{Float64}(undef, 2,hbias[4]+1)
    duraklar4[1,1]=0
    duraklar4[2,1]=0
    for i=1:hbias[4]
        duraklar4[1,i+1]=Y[4,1,i]
        duraklar4[2,i+1]=Y[4,2,i]
    end

    distmat = [norm(duraklar4[:,i] - duraklar4[:,j]) for i in 1:hbias[4]+1, j in 1:hbias[4]+1]

    @time path, cost = solve_tsp(distmat; quality_factor = 100)
    #Kara Taşıtının HArcadığı Süre
    dhs = cost/drh
    println("2. Senaryo 4.Bölg Dronun Harcadığı Süre = ", round(dhs;digits=2))

    #Toplan Elma Toplamak İçin Gerekli Süre Bilgisi Tutuluyor
    sure[2]=sure[2]+dhs

    println("2. Senaryo Toplam Harcanan Süre = ", round(sure[2];digits=2))


    #3. Senaryo
    #Her Bir Köşede Drone Kümeleme Sonucuna Göre Kendi Bölgesini İlaçlıyor
    #1 Bölge Olduğu Durumda

    NKT31=Array{Float64}(undef, 2,5)
    NKT31[1,1]=0
    NKT31[2,1]=0
    NKT31[1,2]=1200
    NKT31[2,2]=0
    NKT31[1,3]=0
    NKT31[2,3]=150
    NKT31[1,4]=1200
    NKT31[2,4]=150
    NKT31[1,5]=mean(X[1,:])
    NKT31[2,5]=mean(X[2,:])

    #duraklar=Array{Float64}(undef, 2,ibs+1)
    duraklar=zeros(Float64,2,ibs+1)

    maksuzak=1000000
    for i=1:4
    global maksuzak
        if euclidean(NKT31[:,i], NKT31[:,5])<=maksuzak
            duraklar[:,1]=NKT31[:,i]
            maksuzak=euclidean(NKT31[:,i], NKT31[:,5])
        end
    end

    for i=1:ibs
        duraklar[1,i+1]=X[1,i]
        duraklar[2,i+1]=X[2,i]
    end

    distmat = [norm(duraklar[:,i] - duraklar[:,j]) for i in 1:ibs+1, j in 1:ibs+1]

    @time path, cost = solve_tsp(distmat; quality_factor = 100)
    #Kara Taşıtının HArcadığı Süre
    dhs = cost/drh

    println("3/1. Senaryo Dronun Harcadığı Süre = ", round(dhs;digits=2))

    #Toplan Elma Toplamak İçin Gerekli Süre Bilgisi Tutuluyor
    sure[3]=dhs+ilcsur

    println("3/1. Senaryo Toplam Harcanan Süre = ", round(sure[3];digits=2))

    #2-4 Bölge Olduğu Durumda

    for dsd=2:4
        global ds, R, as, c, M, T, U, dsi, DEUE, kds, maksuzak1
        global Z = zeros(Int, 4, 2, ibs)
        ds=dsd

        #K-ortalamalar
        R = kmeans(X, ds; maxiter=200)
        #Elmaların Hangi Kümeye Atandığı Bilgisi
        as = assignments(R)
        #Kümelerde Kaç Elma Olduğu Bilgisi
        c = counts(R)
        #Kümelerin Merkez Noktaları
        M = R.centers

        #Elmaları Kümelere Atadığımızda Elmanın İndis Bilgisini Tutuyor
        T = Array{Int}(undef, ibs, ds)
        T=zeros(ibs,ds)

        dsi = Vector{Int}(undef, ds)
        for i=1:ds
            dsi[i] = 1
        end

        for i=1:ibs
            for j=1:ds
                if as[i]==j
                    Z[j,:,dsi[j]]=X[:,i]
                    dsi[j] = dsi[j] + 1
                end
            end
        end

        for y1=1:ds
            global maksuzak1
            NKT3=Array{Float64}(undef, 2,5)
            NKT3[1,1]=0
            NKT3[2,1]=0
            NKT3[1,2]=1200
            NKT3[2,2]=0
            NKT3[1,3]=0
            NKT3[2,3]=150
            NKT3[1,4]=1200
            NKT3[2,4]=150
            NKT3[1,5]=M[1,y1]
            NKT3[2,5]=M[2,y1]

            #duraklar=Array{Float64}(undef, 2,ibs+1)
            duraklar7=zeros(Float64,2,c[y1]+1)

            maksuzak1=1000000
            for i=1:4
            global maksuzak1
                if euclidean(NKT3[:,i], NKT3[:,5])<=maksuzak1
                    duraklar7[:,1]=NKT3[:,i]
                    maksuzak1=euclidean(NKT3[:,i], NKT3[:,5])
                end
            end

            for i=1:c[y1]
                duraklar7[:,i+1]=Z[ds,:,i]
            end

            distmat = [norm(duraklar7[:,i] - duraklar7[:,j]) for i in 1:c[y1]+1, j in 1:c[y1]+1]

            @time path, cost = solve_tsp(distmat; quality_factor = 100)
            #Kara Taşıtının HArcadığı Süre
            dhs = cost/drh

            println("3/$ds/$y1. Dronun Harcadığı Süre = ", round(dhs;digits=2))

            #Toplan Elma Toplamak İçin Gerekli Süre Bilgisi Tutuluyor
            sure[2+dsd]=sure[2+dsd]+dhs
        end

        sure[2+dsd]=sure[2+dsd]+ilcsur
        println("3/$ds. Senaryo Toplam Harcanan Süre = ", round(sure[2+dsd];digits=2))


    end


    println("1. Senaryo Toplam Harcanan Süre = ", round(sure[1];digits=2))
    println("2. Senaryo Toplam Harcanan Süre = ", round(sure[2];digits=2))
    println("3/1. Senaryo Toplam Harcanan Süre = ", round(sure[3];digits=2))
    println("3/2. Senaryo Toplam Harcanan Süre = ", round(sure[4];digits=2))
    println("3/3. Senaryo Toplam Harcanan Süre = ", round(sure[5];digits=2))
    println("3/4. Senaryo Toplam Harcanan Süre = ", round(sure[6];digits=2))

    for i=1:6
        itersure[xyz,:]=sure[:]
    end
end
for i=1:6
    println("1. Senaryo Toplam Harcanan Süre = ", round(mean(itersure[:,1]);digits=2))
    println("2. Senaryo Toplam Harcanan Süre = ", round(mean(itersure[:,2]);digits=2))
    println("3/1. Senaryo Toplam Harcanan Süre = ", round(mean(itersure[:,3]);digits=2))
    println("3/2. Senaryo Toplam Harcanan Süre = ", round(mean(itersure[:,4]);digits=2))
    println("3/3. Senaryo Toplam Harcanan Süre = ", round(mean(itersure[:,5]);digits=2))
    println("3/4. Senaryo Toplam Harcanan Süre = ", round(mean(itersure[:,6]);digits=2))
end
