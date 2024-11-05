# Collaborative Truck/Drone Routing Problem: An Application to Disaster Logistics

## Overview
This project involves disaster mission planning using a combination of truck and drone routing. The objective is to optimize the routing of drones and trucks for efficient delivery of medical kits to various locations. This repository contains the code and research paper for the study *Collaborative Truck/Drone Routing Problem: An Application to Disaster Logistics*. This project presents an optimization model for coordinating trucks (UGVs) and drones (UAVs) in disaster logistics, aiming to improve delivery efficiency of critical supplies to assembly points during emergencies.

## Project Structure
The project contains a single Julia script which performs the following tasks:
- Clustering locations using k-means
- Assigning drones to clusters
- Solving the Traveling Salesman Problem (TSP) for optimal truck routing
- Calculating and outputting results

## Dependencies
The project relies on the following Julia packages:
- Clustering
- Distances
- GLPK, Cbc, Clp
- JuMP
- TravelingSalesmanHeuristics
- DataFrames
- Gadfly, Cairo, Fontconfig, Compose
- Random
- LinearAlgebra
- HiGHS
- XLSX
- Plots, PlotlyJS
- CategoricalArrays

## Installation
To install the necessary packages, you can use Julia's package manager. Open Julia and run:
```julia
using Pkg
Pkg.add([
    "Clustering", "Distances", "GLPK", "Cbc", "Clp", "JuMP", 
    "TravelingSalesmanHeuristics", "DataFrames", "Gadfly", 
    "Cairo", "Fontconfig", "Compose", "Random", "LinearAlgebra", 
    "HiGHS", "XLSX", "Plots", "PlotlyJS", "CategoricalArrays"
])

## Table of Contents

- [Introduction](#introduction)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Methodology](#methodology)
- [Results](#results)
- [Citation](#citation)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Introduction

In disaster scenarios, logistics efficiency is vital for timely relief efforts. This study proposes a hybrid routing model for unmanned ground vehicles (UGVs) and unmanned aerial vehicles (UAVs) to deliver medical supplies to emergency assembly points, optimizing both vehicle routes and delivery times. Using Mixed Integer Linear Programming (MILP) with clustering and heuristic methods, the model finds the optimal balance between UAV speed, UGV stops, and cluster numbers, significantly enhancing the effectiveness of emergency logistics.

This work is published in *Journal of Statistics & Applied Sciences*, Issue 9, 2024.

## Installation

To set up and run the code, install [Julia](https://julialang.org/) and the required packages. Follow these steps:

1. **Install Julia**:
   - Download and install Julia from [https://julialang.org/downloads/](https://julialang.org/downloads/).

2. **Install Required Julia Packages**:
   - Open the Julia REPL and install the necessary packages:
     ```julia
     using Pkg
     Pkg.add("JuMP")
     Pkg.add("Clustering")
     Pkg.add("Distances")
     Pkg.add("HiGHS") # Optimizer required for solving MILP problems.
     ```
   - **Note**: Ensure you have the latest versions of these packages for optimal compatibility.

## Usage

1. **Clone the Repository**:
   - In a terminal, clone this repository and navigate to the `src` directory:
     ```bash
     git clone https://github.com/yourusername/Collaborative_Truck_Drone_Routing.git
     cd Collaborative_Truck_Drone_Routing/src
     ```

2. **Run the Julia Code**:
   - Open Julia in the `src` directory and execute the code:
     ```julia
     include("Disaster Mission Planning.jl")
     ```
   - The code will compute optimized routes for UAVs and UGVs based on the defined disaster logistics parameters.

## Methodology

The model combines clustering, routing, and optimization techniques to maximize the efficiency of disaster response logistics:

1. **K-Means Clustering**: Divides the disaster area into clusters, designating cluster centers as UGV stops.
2. **Traveling Salesman Problem (TSP)**: Determines the optimal UGV routes between cluster centers.
3. **Mixed Integer Linear Programming (MILP)**: Assigns specific UAV delivery tasks from each UGV stop to minimize overall delivery time.

### Parameters
- **UGV Capacity**: Maximum UAVs a UGV can carry.
- **UAV Capacity**: Payload capacity for each UAV.
- **Speed Constraints**: Maximum speeds for both UAVs and UGVs.
- **Cluster Constraints**: Limits on the number of clusters based on UAV flight range and recharge requirements.

## Results

The model’s simulations indicate that balancing UAV speed, cluster numbers, and UGV stops can significantly reduce total delivery time in disaster logistics. The optimal scenario achieved total delivery times around 649 minutes with 200 assembly points, balancing minimal UAV speeds with cluster optimization.

## Citation

If you use this research or code in your work, please cite it as follows:

Güzey, A., & Satman, M.H. (2024). Collaborative Truck/Drone Routing Problem: An Application to Disaster Logistics. Journal of Statistics & Applied Sciences, Issue 9, pp. 77-94. DOI: 10.52693/jsas.1474515


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

This research was conducted at Istanbul University and benefited from contributions in both modeling and algorithm development by Alparslan Güzey and Mehmet Hakan Satman. Special thanks to those who supported this project.





