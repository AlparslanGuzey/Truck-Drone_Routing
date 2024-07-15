module DataPreparation

using Random
using LinearAlgebra

export prepare_data

function prepare_data(tas)
    kx = rand(900:1200, tas)
    ky = rand(2300:2400, tas)
    kz = rand(1:7, tas)
    X = vcat(kx', ky', kz')
    return X, kx, ky, kz
end

end
