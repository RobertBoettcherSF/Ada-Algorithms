# Ada Image Segmentation Library

A modular, strongly-typed Ada implementation of core image segmentation algorithms detailed in computer vision literature and Wikipedia's Image Segmentation specification.

## Project Overview
This library provides high-performance Ada implementations for classic digital image processing segmentation methods. It includes automatic and manually parameterized algorithms for splitting an image grid into meaningful regions or boundary sets.

## Features
- **Thresholding Methods**:
  - `Global_Threshold`: Single fixed intensity cut-off.
  - `Otsu_Threshold`: Automatic optimal threshold determination maximizing inter-class variance.
- **Clustering Methods**:
  - `KMeans_Segmentation`: Iterative centroid grouping based on intensity proximity.
- **Region-Growing Methods**:
  - `Region_Growing`: Seed-based pixel connectivity expansion with custom tolerance and 4/8-way connectivity modes.
- **Edge-Based Segmentation**:
  - `Edge_Based_Segmentation`: Convolution gradient boundary identification supporting **Sobel** and **Prewitt** kernels.
- **Watershed Transformation**:
  - `Watershed_Segmentation`: Topographic intensity flooding and catchment basin identification.

## Usage

### Compilation
To compile both the main demonstration program and test suite, run:
```bash
make
