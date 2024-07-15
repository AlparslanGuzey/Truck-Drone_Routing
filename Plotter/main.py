#cd Desktop/VSCODE/Plotter
#python3 main.py

import matplotlib.pyplot as plt #pip install matplotlib
import pandas as pd #pip install pandas
import os
import glob

color_define = ["black", "rosybrown", "brown", "red", "darkorange", "gold", "yellow", "olive", "darkgreen", "darkslategray", "teal", "deepskyblue", "steelblue", "royalblue", "midnightblue", "indigo", "purple", "deeppink", "crimson"]




def getXLSXData(fileName):
    try:
        excel_data = pd.read_excel(fileName, sheet_name='Sheet1', usecols=[1, 2, 3, 4, 5])
        data = pd.DataFrame(excel_data)
       

        x = []
        y = []
        z = []
        k = []

        fullData = []

        for column in data:
            columnSeriesObj = data[column]
            series = columnSeriesObj.values
            if series[0] == 'X Ekseni':
                x.append(series[1:])
            if series[0] == 'Y Ekseni':
                y.append(series[1:])
            if series[0] == 'Yükseklik':
                z.append(series[1:])
            if series[0] == 'Atandığı Küme':
                k.append(series[1:])

        for coordinates in range(len(x[0])):
            tempData = [x[0][coordinates], y[0][coordinates], z[0][coordinates], k[0][coordinates]]
            fullData.append(tempData)

        return fullData

    except Exception as e:
        print(e)
        return 0


def getBasePoints(sn, fileName):
    try:
        excel_data = pd.read_excel(fileName, sheet_name='Sheet2', usecols=[(a*3)+1 for a in range(sn)])
        data = pd.DataFrame(excel_data)

        basePointsList = []

        for column in data:
            columnSeriesObj = data[column]
            series = columnSeriesObj.values
            basePointsList.append(series[1])

        return basePointsList

    except Exception as e:
        print(e)
        return 0


max_x = 2
max_y = 3
fig, axs = plt.subplots(max_x, max_y, subplot_kw=dict(projection='3d'), figsize=(16, 12))
x = 0
y = 0

path = os.getcwd()
csv_files = glob.glob(os.path.join(path, "*.xlsx"))

for ax in range(len(csv_files)):
    if y == max_y:
        y = 0
        x += 1

    panel = axs[x, y]

    fn_regex = csv_files[ax].split("/")[-1].split("_")
    drh = fn_regex[0].replace("drh", "")
    tas = fn_regex[1].replace("tas", "")

    points = getXLSXData(csv_files[ax])
    stop_number = 0
    for n in points:
        if n[3] > stop_number:
            stop_number = n[3]

    panel.set_title(f"UAV Speed(m/min): {drh} \n Assembly Point: {tas} \n Cluster: {stop_number}")
    basePoints = getBasePoints(stop_number, csv_files[ax])
    basePointsCoordinates = [points[a - 1] for a in basePoints]
    for n in basePoints:
        points.pop(n - 1)

    enm = 0
    for point in points:
        panel.scatter(point[0], point[1], point[2], s=10, alpha=0.35, color=color_define[point[3] - 1])
    for point in basePointsCoordinates:
        enm += 1
        panel.scatter(point[0], point[1], point[2], s=50 if enm != 1 else 100, alpha=1, marker='.' if enm != 1 else '^',
                   color=color_define[point[3] - 1], label=f"{enm}. Durak")
    for line in range(len(basePointsCoordinates)):
        x_start = basePointsCoordinates[line][0]
        x_end = basePointsCoordinates[0][0] if line == stop_number - 1 else basePointsCoordinates[line + 1][0]
        y_start = basePointsCoordinates[line][1]
        y_end = basePointsCoordinates[0][1] if line == stop_number - 1 else basePointsCoordinates[line + 1][1]
        z_start = basePointsCoordinates[line][2]
        z_end = basePointsCoordinates[0][2] if line == stop_number - 1 else basePointsCoordinates[line + 1][2]

        panel.plot([x_start, x_end], [y_start, y_end], [z_start, z_end])

    y += 1
plt.show()
