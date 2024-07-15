module Results

using XLSX

export save_results

function save_results(filename, tas, X, as, ds, T, V, U, c, DEUE, sure_d, sure, kths)
    s1columns = Any[1:tas, X[1, :], X[2, :], X[3, :], as]
    s1labels = ["Toplanma Alanı No", "X Ekseni", "Y Ekseni", "Yükseklik", "Atandığı Küme"]

    s2columns = Any[]
    s2labels = Any[]
    for i in 1:ds
        push!(s2labels, "$i. Kümedeki ... Toplanma Alanına")
        push!(s2columns, T[:, i])
        push!(s2labels, "$i. Kümede ... Drone Tarafından")
        push!(s2columns, V[:, i])
        push!(s2labels, "$i. Kümede ... Sürede Teslimat Yapılacaktır")
        push!(s2columns, 5 * U[:, i])
    end

    s3columns = Any[1:ds, c[:], DEUE[:], sure_d[:]]
    s3labels = ["Durak", "Duraktaki Toplanma Alanı Sayısı", "Duraktaki En Uzak Toplanma Alanı(dk)", "Durakta Harcanan Süre"]

    bos = fill("", 600, 100)

    XLSX.openxlsx(filename, mode="rw") do xf
        sheet1 = xf[1]
        sheet2 = xf[2]
        sheet3 = xf[3]

        sheet1["A1:CV600"] = bos
        sheet2["A1:CV600"] = bos
        sheet3["A1:CV600"] = bos

        XLSX.writetable!(sheet1, s1columns, s1labels, anchor_cell=XLSX.CellRef("B2"))
        XLSX.writetable!(sheet2, s2columns, s2labels, anchor_cell=XLSX.CellRef("B2"))
        sheet3["B2"] = "Toplam Harcanan Süre"
        sheet3["E2"] = sure
        sheet3["B3"] = "Kara Taşıtının Duraklar Arasında Harcadığı Süre"
        sheet3["E3"] = kths
        XLSX.writetable!(sheet3, s3columns, s3labels, anchor_cell=XLSX.CellRef("B5"))
    end
end

end
