# Aquaponics Nutrient Optimization
=======================

A framework for optimizing fish feed and nutrient profiles in recirculating aquaculture systems (RAS) to enhance drainage water reuse in hydroponics, created by the 
[Automatic Control & System Dynamics Lab](https://www.tu-chemnitz.de/etit/control/index.php.en "ACSD Lab") 
at Chemnitz University of Technology.

Introduction
------------

The framework features three distinct programs:

1. Fish feed optimization using a given database (e.g., [IAFFD](https://www.iaffd.com/))
2. Optimization of pH, nitrogen, and hydroponically relevant macronutrient concentrations by finding the optimal combination of water exchange and addition of base mixes
3. Joint optimization of fish feed, pH, nitrogen, and hydroponically relevant macronutrient concentrations

The organization of different nutrient sources, including dissolved fish excretions, base inputs, and freshwater, is performed via steady-state optimization ($\dot{x} = 0$) of a nonlinear system of ordinary differential equations $\dot{x} = f(x,u)$. The optimization is formulated as a mixed-binary static optimization problem:

$$\begin{align*}
\min_{x \in \mathbb{R}^n, u \in \mathbb{R}^m, z \in \mathbb{Z}^o}\ & J(x,u,z), \\
\text{s.t.}\ & f(x,u) = 0, \\
& g_L \le g(x,u,z) \le g_U, \\
& u_L \le u \le u_U, \\
& 0 \le z \le 1.
\end{align*}$$

The optimization problem features two main objectives:

1. Minimization of the error between a target reference concentration and the resulting nutrient concentration in the aquaculture effluent
2. Minimization of economic and ecological costs resulting from the use of feed ingredients and chemical additives

The priority of both objectives and the resulting resource consumption can be adjusted by setting the weights in the objective function.

> **Note:** This optimization is designed for the planning phase of an aquaponics system, not for real-time/online control. Therefore, calculated inputs should not be applied blindly; for example, the pH should be monitored and the base dosage adjusted accordingly during operation.

For further details, please refer to the associated publication at the end of this document.

Implementation
--------------

The framework is fully implemented in MATLAB (R2024a). Required dependencies include:
* **CasADi** (v3.6.6) with the built-in nonlinear programming (NLP) solver **IPOPT** (fully open-access)
* **Gurobi** (v11.0.3) mixed-integer solver (free only for academic use)

Future Work
--------------
Pending resources, future updates might explore:
* Multi-scenario optimization for more robust system design
* Tailoring calculated RAS effluent nutrient profiles to specific crop types in the hydroponics unit
* A user-friendly graphical interface (GUI)

Furthermore, we are actively working on translating the code to a fully open-source software stack.

Citation
--------

We provide this framework as open-source software and hope it supports your research and system design. If you use this code in your work, **please cite the following article**:

* Nestler, P.; Shaw, C.; Kloas, W.; Streif, S. (2027). **[Optimization of fish feed formulation and pH regulation in on-demand coupled aquaponic systems: A model-based framework for sustainable nutrient and water management.](https://doi.org/10.1016/j.compag.2026.112358)** *Computers and Electronics in Agriculture*, 256, 112358.
