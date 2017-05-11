#!/usr/bin/env julia

# Check the grid interpolation and sorting functions
verbose = true

info("#### $(basename(@__FILE__)) ####")

ocean = SeaIce.readOceanNetCDF("Baltic/00010101.ocean_month.nc",
                               "Baltic/ocean_hgrid.nc")

info("Testing coordinate retrieval functions")
sw, se, ne, nw = SeaIce.getCellCornerCoordinates(ocean, 1, 1)
@test sw ≈ [6., 53.]
@test se ≈ [7., 53.]
@test ne ≈ [7., 54.]
@test nw ≈ [6., 54.]
@test SeaIce.getCellCenterCoordinates(ocean, 1, 1) ≈ [6.5, 53.5]

info("Testing area-determination methods")
@test SeaIce.areaOfTriangle([0., 0.], [1., 0.], [0., 1.]) ≈ .5
@test SeaIce.areaOfTriangle([1., 0.], [0., 1.], [0., 0.]) ≈ .5
@test SeaIce.areaOfQuadrilateral([1., 0.], [0., 1.], [0., 0.], [1., 1.]) ≈ 1.

info("Testing area-based cell content determination")
@test SeaIce.isPointInCell(ocean, 1, 1, [6.5, 53.5]) == true
@test SeaIce.getNonDimensionalCellCoordinates(ocean, 1, 1, [6.5, 53.5]) ≈
    [.5, .5]
@test SeaIce.isPointInCell(ocean, 1, 1, [6.1, 53.5]) == true
@test SeaIce.getNonDimensionalCellCoordinates(ocean, 1, 1, [6.1, 53.5]) ≈
    [.1, .5]
@test SeaIce.isPointInCell(ocean, 1, 1, [6.0, 53.5]) == true
@test SeaIce.getNonDimensionalCellCoordinates(ocean, 1, 1, [6.0, 53.5]) ≈
    [.0, .5]
@test SeaIce.isPointInCell(ocean, 1, 1, [6.1, 53.7]) == true
@test SeaIce.isPointInCell(ocean, 1, 1, [6.1, 53.9]) == true
@test SeaIce.isPointInCell(ocean, 1, 1, [6.1, 53.99999]) == true
@test SeaIce.getNonDimensionalCellCoordinates(ocean, 1, 1, [6.1, 53.99999]) ≈
    [.1, .99999]
@test SeaIce.isPointInCell(ocean, 1, 1, [7.5, 53.5]) == false
@test SeaIce.isPointInCell(ocean, 1, 1, [0.0, 53.5]) == false
x_tilde, _ = SeaIce.getNonDimensionalCellCoordinates(ocean, 1, 1, [0., 53.5])
@test x_tilde < 0.

info("Testing conformal mapping methods")
@test SeaIce.conformalQuadrilateralCoordinates([0., 0.],
                                               [5., 0.],
                                               [5., 3.],
                                               [0., 3.],
                                               [2.5, 1.5]) ≈ [0.5, 0.5]
@test SeaIce.conformalQuadrilateralCoordinates([0., 0.],
                                               [5., 0.],
                                               [5., 3.],
                                               [0., 3.],
                                               [7.5, 1.5]) ≈ [1.5, 0.5]
@test SeaIce.conformalQuadrilateralCoordinates([0., 0.],
                                               [5., 0.],
                                               [5., 3.],
                                               [0., 3.],
                                               [7.5,-1.5]) ≈ [1.5,-0.5]
@test_throws ErrorException SeaIce.conformalQuadrilateralCoordinates([0., 0.],
                                                                     [5., 3.],
                                                                     [0., 3.],
                                                                     [5., 0.],
                                                                     [7.5,-1.5])

info("Checking cell content using conformal mapping methods")
@test SeaIce.isPointInCell(ocean, 1, 1, [6.4, 53.4], method="Conformal") == true
@test SeaIce.isPointInCell(ocean, 1, 1, [6.1, 53.5], method="Conformal") == true
@test SeaIce.isPointInCell(ocean, 1, 1, [6.0, 53.5], method="Conformal") == true
@test SeaIce.isPointInCell(ocean, 1, 1, [6.1, 53.7], method="Conformal") == true
@test SeaIce.isPointInCell(ocean, 1, 1, [6.1, 53.9], method="Conformal") == true
@test SeaIce.isPointInCell(ocean, 1, 1, [6.1, 53.99999],
                           method="Conformal") == true
@test SeaIce.isPointInCell(ocean, 1, 1, [7.5, 53.5],
                           method="Conformal") == false
@test SeaIce.isPointInCell(ocean, 1, 1, [0.0, 53.5],
                           method="Conformal") == false

info("Testing bilinear interpolation scheme on conformal mapping")
ocean.u[1, 1, 1, 1] = 1.0
ocean.u[2, 1, 1, 1] = 1.0
ocean.u[2, 2, 1, 1] = 0.0
ocean.u[1, 2, 1, 1] = 0.0
@test SeaIce.bilinearInterpolation(ocean.u, .5, .5, 1, 1, 1, 1) ≈ .5
@test SeaIce.bilinearInterpolation(ocean.u, 1., 1., 1, 1, 1, 1) ≈ .0
@test SeaIce.bilinearInterpolation(ocean.u, 0., 0., 1, 1, 1, 1) ≈ 1.
@test SeaIce.bilinearInterpolation(ocean.u, .25, .25, 1, 1, 1, 1) ≈ .75
@test SeaIce.bilinearInterpolation(ocean.u, .75, .75, 1, 1, 1, 1) ≈ .25

info("Testing cell binning - Area-based approach")
@test SeaIce.findCellContainingPoint(ocean, [6.2,53.4], method="Area") == (1, 1)
@test SeaIce.findCellContainingPoint(ocean, [7.2,53.4], method="Area") == (2, 1)
@test SeaIce.findCellContainingPoint(ocean, [0.2,53.4], method="Area") == (0, 0)

info("Testing cell binning - Conformal mapping")
@test SeaIce.findCellContainingPoint(ocean, [6.2,53.4], method="Conformal") == 
    (1, 1)
@test SeaIce.findCellContainingPoint(ocean, [7.2,53.4], method="Conformal") == 
    (2, 1)
@test SeaIce.findCellContainingPoint(ocean, [0.2, 53.4], method="Conformal") ==
    (0, 0)

sim = SeaIce.createSimulation()
sim.ocean = SeaIce.readOceanNetCDF("Baltic/00010101.ocean_month.nc",
                                   "Baltic/ocean_hgrid.nc")
SeaIce.addIceFloeCylindrical(sim, [6.5, 53.5], 10., 1., verbose=verbose)
SeaIce.addIceFloeCylindrical(sim, [6.6, 53.5], 10., 1., verbose=verbose)
SeaIce.addIceFloeCylindrical(sim, [7.5, 53.5], 10., 1., verbose=verbose)
SeaIce.sortIceFloesInOceanGrid!(sim, verbose=verbose)
@test sim.ice_floes[1].ocean_grid_pos == [1, 1]
@test sim.ice_floes[2].ocean_grid_pos == [1, 1]
@test sim.ice_floes[3].ocean_grid_pos == [2, 1]
@test sim.ocean.ice_floe_list[1, 1] == [1, 2]
@test sim.ocean.ice_floe_list[2, 1] == [3]

info("Testing ocean drag")
sim = SeaIce.createSimulation()
sim.ocean = SeaIce.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
sim.ocean.u[:,:,1,1] = 5.
SeaIce.addIceFloeCylindrical(sim, [2.5, 3.5], 1., 1., verbose=verbose)
SeaIce.addIceFloeCylindrical(sim, [2.6, 2.5], 1., 1., verbose=verbose)
SeaIce.sortIceFloesInOceanGrid!(sim, verbose=verbose)
sim.time = ocean.time[1]
SeaIce.addOceanDrag!(sim)
@test sim.ice_floes[1].force[1] > 0.
@test sim.ice_floes[1].force[2] ≈ 0.
@test sim.ice_floes[2].force[1] > 0.
@test sim.ice_floes[2].force[2] ≈ 0.
sim.ocean.u[:,:,1,1] = -5.
sim.ocean.v[:,:,1,1] = 5.
SeaIce.addIceFloeCylindrical(sim, [2.5, 3.5], 1., 1., verbose=verbose)
SeaIce.addIceFloeCylindrical(sim, [2.6, 2.5], 1., 1., verbose=verbose)
SeaIce.sortIceFloesInOceanGrid!(sim, verbose=verbose)
sim.time = ocean.time[1]
SeaIce.addOceanDrag!(sim)
@test sim.ice_floes[1].force[1] < 0.
@test sim.ice_floes[1].force[2] > 0.
@test sim.ice_floes[2].force[1] < 0.
@test sim.ice_floes[2].force[2] > 0.

info("Testing curl function")
ocean.u[1, 1, 1, 1] = 1.0
ocean.u[2, 1, 1, 1] = 1.0
ocean.u[2, 2, 1, 1] = 0.0
ocean.u[1, 2, 1, 1] = 0.0
ocean.v[:, :, 1, 1] = 0.0
@test SeaIce.curl(ocean, .5, .5, 1, 1, 1, 1) > 0.

ocean.u[1, 1, 1, 1] = 0.0
ocean.u[2, 1, 1, 1] = 0.0
ocean.u[2, 2, 1, 1] = 1.0
ocean.u[1, 2, 1, 1] = 1.0
ocean.v[:, :, 1, 1] = 0.0
@test SeaIce.curl(ocean, .5, .5, 1, 1, 1, 1) < 0.
