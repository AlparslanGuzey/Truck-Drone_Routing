module KMeansClustering

using Clustering
using Distances

export perform_kmeans

function perform_kmeans(X, tas, drh, dbus, ddus)
    for dsd in 2:tas
        global ds, R, as, c, M, T, U, dsi, DEUE
        ds = dsd

        # K-means clustering
        R = kmeans(X, ds; maxiter=200)
        as = assignments(R)
        c = counts(R)
        global M = R.centers

        T = zeros(Int, tas, ds)
        U = zeros(Float64, tas, ds)
        DEUE = zeros(ds)

        dsi = ones(Int, ds)

        for i in 1:tas
            for j in 1:ds
                if as[i] == j
                    T[dsi[j], j] = i
                    U[dsi[j], j] = euclidean(X[:, i], M[:, j]) / drh
                    dsi[j] += 1
                end
            end
        end

        if maximum(U) <= (dbus / (1 + (dbus / ddus)))
            break
        end
    end

    return ds, R, as, c, M, T, U, DEUE
end

end
