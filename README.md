# Truck-Drone Routing Project

## Overview
This project involves disaster mission planning using a combination of truck and drone routing. The objective is to optimize the routing of drones and trucks for efficient delivery of medical kits to various locations.

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
