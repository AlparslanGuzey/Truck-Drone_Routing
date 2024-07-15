using Plots

# Define the data for the pie chart
labels = ["Cluster Number", "Total Flight Time"]
sizes_original = [15, 85]
sizes_increase1 = [53, 47]
sizes_increase2 = [62, 38]

# Create the pie chart for Original Values
pie(labels, sizes_original, title="UAV Speed Sensitivity Analysis: Original Values", 
    legend=:topright, explode=[0.1,0], color=[:red, :blue], 
    label=["Cluster Number", "Total Flight Time"], 
    titlefont=font(14), legendfont=font(12), guidefont=font(10))

# Save the plot as a PNG image to the desktop
savefig(joinpath(homedir(), "diagram", "UAV_Speed_Sensitivity_Analysis_Piechart.png"))

