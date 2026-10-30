# AI-Based Dynamic UAV Deployment for Emergency Communication in Disaster Zones
**Project Documentation & Comprehensive Technical Report**  
**File Name:** `prolab.md`  
**Author:** Azaan Ahamed.K ([AzaanGIT](https://github.com/AzaanGIT))  
**Academic Institution:** School of Electronics Engineering (SENSE), Vellore Institute of Technology (VIT)  
**Lab / Course:** Advanced Communication Systems Lab (`ACS_LAB`)  
**GitHub Repository:** [https://github.com/AzaanGIT/ai-uav-disaster-recovery](https://github.com/AzaanGIT/ai-uav-disaster-recovery)  
**Live Colab Notebook:** [Open in Google Colab](https://colab.research.google.com/github/AzaanGIT/ai-uav-disaster-recovery/blob/main/ai_uav_disaster_recovery_notebook.ipynb)  

---

## Table of Contents
1. [Project Overview & Problem Statement](#1-project-overview--problem-statement)
2. [End-to-End System Architecture](#2-end-to-end-system-architecture)
3. [Mathematical Formulations & Physical Channel Modeling](#3-mathematical-formulations--physical-channel-modeling)
4. [Machine Learning Training Pipeline & Methodology](#4-machine-learning-training-pipeline--methodology)
5. [Experimental Results & Benchmarking](#5-experimental-results--benchmarking)
6. [MATLAB Dynamic Command Center Simulation](#6-matlab-dynamic-command-center-simulation)
7. [Chronology of Iterations, Debugging & Solutions](#7-chronology-of-iterations-debugging--solutions)
8. [Complete Project Artifacts & Files Inventory](#8-complete-project-artifacts--files-inventory)
9. [Conclusion & Future Research Directions](#9-conclusion--future-research-directions)

---

## 1. Project Overview & Problem Statement

### 1.1 The Disaster Scenario
During major catastrophic events such as earthquakes, tsunamis, floods, or cyclones, ground-based telecommunication infrastructure is heavily compromised. Base transceiver station (BTS) towers collapse, power grids fail, and fiber backhaul links are severed. 

At the same time, thousands of trapped survivors and first responders attempt to transmit emergency distress calls (SOS packets). This creates a massive mismatch: **telecommunication capacity drops to near zero exactly where demand peaks**.

### 1.2 Limitations of Existing Approaches
* **Static Relay Deployment (Fixed Placement):** Positioning UAVs at static coordinates fails as disaster victims migrate and floodwaters or fire fronts shift.
* **Myopic Heuristic (Reactive Deployment):** Drones dispatch only after distress calls accumulate. Drones constantly chase lagging indicators, resulting in high flight churn, delayed emergency response, and rapid battery depletion without serving peak demand.

### 1.3 Proposed AI Solution
We implement an integrated **Machine Learning + Asynchronous Event-Driven UAV Deployment Framework**:
1. **Predictive AI Engine:** A Random Forest Regressor analyzes temporal demand lags ($t, t-1, t-2$), population density, physical damage severity, and network coverage flags to forecast future SOS demand ($t+1$) across all disaster sectors.
2. **Asynchronous Dynamic Dispatch:** Drones are prioritized to anticipated hotspots. Once a drone satisfies the demand in its assigned sector, it **independently relocates** to the next highest-priority sector while other drones remain on station, maximizing flight endurance and citizen survival.

---

## 2. End-to-End System Architecture

```
+-------------------------------------------------------------------------------------------------+
|                                 1. DISASTER PHYSICAL ENVIRONMENT                                |
|   - Base Stations (e.g., 7 towers deployed across 1000m x 1000m urban area)                     |
|   - Disaster Event: Physical collapse of N towers (e.g., 3 destroyed)                           |
|   - Mobile Users: Disconnected survivors sending SOS emergency distress requests                |
+-------------------------------------------------------------------------------------------------+
                                                 │
                                                 ▼
+-------------------------------------------------------------------------------------------------+
|                                 2. RF PROPAGATION & CHANNEL LAYER                               |
|   - Carrier Frequency: 2.4 GHz | Transmit Power: 35 dBm                                         |
|   - Log-Distance Path Loss Model (n = 4.0 for post-disaster debris urban environment)           |
|   - Sensitivity Threshold: Pr < -90 dBm marks citizen as disconnected                          |
|   - Disconnected Citizens Mapped -> Emergency SOS Load per Disaster Zone                        |
+-------------------------------------------------------------------------------------------------+
                                                 │
                                                 ▼
+-------------------------------------------------------------------------------------------------+
|                            3. AI PREDICTIVE DEMAND ENGINE (Colab / Python)                      |
|   - Feature Engineering: [SOS(t), SOS(t-1), SOS(t-2), PopDensity, Severity, Coverage]           |
|   - Model: Random Forest Regressor (100 Bagged Bootstrap Trees)                                 |
|   - Target: Predicts SOS(t+1) ahead of time                                                     |
|   - Accuracy: RMSE = 4.69 (16.7% improvement over Persistence baseline)                         |
+-------------------------------------------------------------------------------------------------+
                                                 │
                                                 ▼
+-------------------------------------------------------------------------------------------------+
|                         4. ASYNCHRONOUS DYNAMIC DISPATCH (MATLAB Online)                        |
|   - Priority Queue: Sectors ordered by descending SOS emergency demand                          |
|   - Dynamic Zone Allocation: N_zones = N_destroyed towers                                       |
|   - Earliest-Finish Event Engine: Drone with lowest remaining SOS finishes first                |
|   - Independent Relocation: Finished drone flies alone to next unserved sector                 |
|   - Mission Complete: 100% citizen recovery across all disaster zones                           |
+-------------------------------------------------------------------------------------------------+
```

---

## 3. Mathematical Formulations & Physical Channel Modeling

### 3.1 RF Propagation & Path Loss Model
To determine whether a citizen on the ground is connected to a surviving base station or aerial UAV relay, we implement the log-distance path loss model:

$$L_0 = 20 \log_{10}\left(\frac{4\pi d_0 f}{c}\right)$$

$$PL(d) = L_0 + 10 \cdot n \cdot \log_{10}\left(\frac{\max(d, d_0)}{d_0}\right)$$

$$P_r(d) = P_t - PL(d)$$

**Channel Parameters:**
* Reference Distance ($d_0$): $1\text{ m}$
* Carrier Frequency ($f$): $2.4\text{ GHz}$ ($2.4 \times 10^9\text{ Hz}$)
* Speed of Light ($c$): $3 \times 10^8\text{ m/s}$
* Free Space Reference Path Loss ($L_0$): $\approx 40.04\text{ dB}$
* Path Loss Exponent ($n$): $4.0$ (represents harsh urban post-disaster rubble and non-line-of-sight shadowing)
* Transmit Power ($P_t$): $35\text{ dBm}$
* Receiver Sensitivity Threshold: $-90\text{ dBm}$

**Disconnection Rule:**
A user at position $(x_u, y_u)$ is marked as disconnected and generates an emergency SOS demand if:

$$\max_{s \in \text{Surviving Towers}} P_r\left(\|(x_u, y_u) - (x_s, y_s)\|\right) < -90\text{ dBm}$$

### 3.2 Spatiotemporal Disaster Demand Formulation
Disaster dynamics are non-stationary; disaster centers drift over time (e.g., advancing flood lines, fire propagation). We formulate the moving disaster hotspot and resulting demand:

1. **Moving Hotspot Center:**
   $$h(t) = 3.5 + 2.2 \sin\left(\frac{2\pi t}{150}\right)$$

2. **Expected Demand per Zone $z$ ($z \in \{1, 2, \dots, N\}$):**
   $$m(z, t) = 3 + \frac{\text{PopDensity}(z)}{150} + 8 \cdot \text{Severity}(z) + 18 \exp\left(-\frac{(z - h(t))^2}{1.5}\right)$$

3. **Stochastic Realization with Noise:**
   $$\text{SOS}(z, t) = \max\left(0, \text{round}\left(m(z, t) + \sqrt{m(z, t)} \cdot \mathcal{N}(0, 1)\right)\right)$$

---

## 4. Machine Learning Training Pipeline & Methodology

### 4.1 Feature Engineering Matrix
A 500-step simulation across 6 zones generated 3,000 raw time-slice observations. Accounting for lag lookbacks ($t-2$) and future target horizons ($t+1$), we compiled a feature matrix of **2,982 training rows $\times$ 9 attributes**:

| Feature Name | Feature Type | Role & Significance |
|---|---|---|
| `time_step` | Index | Simulation time step ($t \in [2, 498]$) |
| `zone` | Spatial ID | Categorical identifier of the disaster zone |
| `sos_t` | Temporal Lag 0 | Current reported SOS call count at step $t$ |
| `sos_t1` | Temporal Lag 1 | Previous SOS call count at step $t-1$ |
| `sos_t2` | Temporal Lag 2 | Two-step lag SOS call count at step $t-2$ |
| `pop_density`| Demographic | Citizen concentration ($\text{people/km}^2$) |
| `severity` | Physical Impact | Normalized disaster severity coefficient ($0.1 - 1.0$) |
| `coverage` | RF Network Flag | Binary status ($1$ = covered by tower, $0$ = blackout) |
| **`sos_next`** | **Target ($Y$)** | **Ground truth SOS demand at step $t+1$ to be predicted** |

The engineered dataset was exported as [`sos_disaster_dataset.csv`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/sos_disaster_dataset.csv).

### 4.2 Time-Series Train/Test Split
To mirror real-world deployment where future disaster progression is unknown, we avoided random shuffling and utilized a **chronological time-series split**:
* **Training Set:** Time steps $2 \le t < 350$ (70% of dataset, 2,088 samples).
* **Testing Set:** Time steps $350 \le t < 499$ (30% future horizon, 894 samples).

### 4.3 Model Architecture: Random Forest Regressor
We trained an ensemble **Random Forest Regressor** with bootstrap aggregation (bagging):
* **Estimators:** 100 bagged decision trees (`n_estimators=100`)
* **Random Seed:** `random_state=42`
* **Parallel Execution:** `n_jobs=-1` (multiprocessing across all CPU cores)
* **Rationale:** Decision trees naturally segment non-linear Gaussian demand boundaries; bagging prevents variance overfitting and smooths out stochastic noise.

---

## 5. Experimental Results & Benchmarking

### 5.1 Model Prediction Accuracy vs. Persistence Baseline
The trained Random Forest model was benchmarked against the **Persistence Baseline** (the standard operational assumption that demand at $t+1$ will simply equal current demand at $t$):

$$\text{RMSE} = \sqrt{\frac{1}{N}\sum_{i=1}^N (y_i - \hat{y}_i)^2}, \quad \text{MAE} = \frac{1}{N}\sum_{i=1}^N |y_i - \hat{y}_i|$$

```
============================================================
           PREDICTION ACCURACY EVALUATION RESULTS
============================================================
  Metric          Random Forest      Persistence Baseline   Improvement
  --------------------------------------------------------------------
  RMSE                 4.69                  5.63              16.7%
  MAE                  3.59                  4.28              16.1%
============================================================
```

### 5.2 150-Step Multi-UAV Deployment Simulation
We simulated a multi-UAV fleet ($N_{\text{UAV}} = 3$) deployed over 150 disaster time steps ($t = 350 \dots 499$) under three distinct operational strategies:

1. **Fixed Allocation:** Drones remain static at fixed coordinates throughout the mission.
2. **Reactive Allocation:** Drones re-evaluate and fly to top demand zones based solely on current step demand.
3. **AI-Assisted Allocation:** Drones anticipate future hotspots using Random Forest predictions and dispatch proactively.

```
========================================================================================
                         UAV DEPLOYMENT STRATEGY COMPARISON
========================================================================================
  Strategy           Total Demand Served (%)   Repositioning Moves   Overhead & Stability
  --------------------------------------------------------------------------------------
  Fixed                     39.4%                      0             Severe service starvation
  Reactive                  67.4%                     98             Excessive battery churn
  AI-Assisted (Ours)        68.2%                     62             36.7% Flight Savings
========================================================================================
```

> **Key Takeaway:** The AI-assisted deployment achieved the highest demand recovery rate (**68.2%**) while eliminating **36.7% of unnecessary repositioning flights** (62 moves vs. 98 moves). This preserves critical drone battery life during emergency missions.

---

## 6. MATLAB Dynamic Command Center Simulation

The dynamic operational command center was implemented in MATLAB ([`AI_UAV_Disaster_Recovery.m`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/AI_UAV_Disaster_Recovery.m)).

### 6.1 Dynamic User Inputs
The script prompts the operator in the MATLAB Command Window:
* `Total Base Stations in City (Default 6)`: e.g., 7
* `Number of Towers destroyed`: e.g., 3
* `Number of UAVs available`: e.g., 1, 2, or 3+

### 6.2 Dynamic Disaster Zones
* The number of disaster zones dynamically matches the number of destroyed towers ($N_{\text{zones}} = N_{\text{destroyed}}$).
* Zone centers are anchored directly to the $(X, Y)$ coordinates of the collapsed towers.
* Clean zone labels (**`Z1`**, **`Z2`**, **`Z3`**, etc.) are displayed directly above each zone boundary on the spatial map.

### 6.3 Asynchronous Event-Driven Independent Dispatch
Unlike conventional simulations where all drones move in synchronized lockstep, our algorithm executes an **asynchronous event loop**:
1. Drones are initially dispatched to the top-demand zones.
2. Demand decays as drones provide cellular relay coverage.
3. The system detects which drone's sector clears first (lowest initial remaining SOS).
4. **Independent Relocation:** The free drone alone departs its cleared sector and flies along a dashed trajectory line to the next unserved sector in the waiting queue.
5. All other drones remain stationary, actively serving their respective citizens.
6. The loop continues until all disaster sectors are marked `[CLEARED]`, achieving **100% emergency communication recovery**.

### 6.4 Single-Window Responsive Dashboard Layout
Configured with normalized figure positioning `[0.04, 0.06, 0.92, 0.84]` to ensure seamless fitting in browser-based MATLAB Online (`matlab.mathworks.com`):
* **Left Panel (Spatial Disaster Map):** Real-time contour heatmap showing RF signal coverage, red crosses for collapsed towers, yellow triangles for surviving stations, mobile users (green = connected, red = disconnected), and persistent UAV diamond markers.
* **Top-Right Panel (Live SOS Demand Bar Chart):** Real-time countdown bar chart with dynamic status indicators (`CLEARED!` / `↓ UAV N`).
* **Bottom-Right Panel (Mission Log & Telemetry):** Real-time event log tracking drone flight paths, stationary statuses, and overall mission progress.

---

## 7. Chronology of Iterations, Debugging & Solutions

Throughout development, several engineering challenges were diagnosed and resolved:

| # | Challenge / User Feedback | Root Cause | Solution Implemented |
|---|---|---|---|
| 1 | **Window Overflowing in MATLAB Online** | Multiple `figure` windows with `[0 0 1 1]` full-screen sizing overflowed Chrome viewports. | Refactored into a single unified 3-panel dashboard with normalized bounds `[0.04, 0.06, 0.92, 0.84]`. |
| 2 | **Drones Moving in a Pack** | Synchronous round-based updates forced all drones to move together. | Implemented an asynchronous event-driven loop where each drone relocates individually as soon as its sector finishes. |
| 3 | **Array Index Error with < 3 Drones** | Code had hardcoded index lookups `uavPlots(3)`. | Generalised all UAV arrays to dynamically size based on `nUAVs` (supports 1, 2, 3, or more drones). |
| 4 | **Script Ignoring User Inputs** | Code had `nUAVs = max(3, nUAVs)` and hardcoded SOS array `[44, 4, 67, 12, 34, 23]`. | Removed hardcoded overrides; linked SOS demand dynamically to the physical RF propagation model and user inputs. |
| 5 | **Mismatched Zone Count** | Entering 3 destroyed towers still rendered 6 hardcoded zones. | Dynamically set $N_{\text{zones}} = N_{\text{destroyed}}$ with zone coordinates pinned to the collapsed tower locations. |
| 6 | **Cluttered Zone Map Labels** | Zone labels read `Z1: 20 SOS`, creating visual clutter on the map. | Cleaned labels to display only zone identifiers (**`Z1`**, **`Z2`**, etc.). |
| 7 | **Colab Missing CSV Error** | Running Colab in a clean VM produced `FileNotFoundError` for the CSV. | Inlined synthetic dataset generation and published pre-executed notebook with embedded outputs. |
| 8 | **GitHub / Colab Integration** | User requested a one-click runnable Colab link under profile `AzaanGIT`. | Created GitHub repository `ai-uav-disaster-recovery`, pushed all assets, and enabled direct Colab access via GitHub badge. |

---

## 8. Complete Project Artifacts & Files Inventory

All project deliverables are preserved and accessible in the workspace:

| Artifact Name | Format | Description |
|---|---|---|
| [`AI_UAV_Disaster_Recovery.m`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/AI_UAV_Disaster_Recovery.m) | MATLAB (`.m`) | Fully dynamic, asynchronous event-driven command center simulation. |
| [`ai_uav_disaster_recovery_notebook.ipynb`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/ai_uav_disaster_recovery_notebook.ipynb) | Jupyter Notebook | Complete pre-executed notebook with embedded base64 plots and metrics. |
| [`sos_disaster_dataset.csv`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/sos_disaster_dataset.csv) | Dataset (`.csv`) | 2,982 rows $\times$ 9 features engineered machine learning dataset. |
| [`raw_sos_demand_matrix.csv`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/raw_sos_demand_matrix.csv) | Dataset (`.csv`) | Raw demand matrix (500 steps $\times$ 6 zones). |
| [`uav_predictions.json`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/outputs/uav_predictions.json) | Data (`.json`) | Exported model predictions synchronized for deployment. |
| [`colab_clean_run.py`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/colab_clean_run.py) | Python (`.py`) | Self-contained Python training script without comments. |
| [`README.md`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/README.md) | Markdown | Repository documentation with the "Open in Colab" badge. |
| [`acsprojetlab.md`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/acsprojetlab.md) | Markdown | Earlier project report draft. |
| [`prolab.md`](file:///Users/azaanahamed.k/Desktop/ACS_LAB/prolab.md) | Markdown | **This master document** compiling all project details. |
| `outputs/01_sos_heatmap.png` | Image (`.png`) | Spatiotemporal heatmap of emergency SOS demands. |
| `outputs/02_prediction_accuracy.png` | Image (`.png`) | Actual vs. Predicted scatter plot and zone distribution. |
| `outputs/03_zone3_timeseries.png` | Image (`.png`) | Time-series tracking of actual vs. predicted SOS. |
| `outputs/04_strategy_comparison.png`| Image (`.png`) | Bar charts comparing Demand Served % and Repositioning Moves. |
| `outputs/05_phase1_stable.png` | Image (`.png`) | Pre-disaster normal operational cellular network. |
| `outputs/06_phase2_disaster.png` | Image (`.png`) | Post-disaster state with collapsed towers and disconnected users. |
| `outputs/07_phase3_ai_prediction.png` | Image (`.png`) | Initial AI-guided UAV dispatch. |
| `outputs/08_phase4_mission_complete.png`| Image (`.png`)| Final mission complete state (100% recovery across all sectors). |

---

## 9. Conclusion & Future Research Directions

### 9.1 Summary of Contributions
* Successfully formulated and simulated a realistic post-disaster RF propagation environment with dynamic cellular blackouts.
* Developed and trained a **Random Forest Regressor** achieving a **16.7% reduction in RMSE** compared to standard persistence models.
* Demonstrated through multi-step simulation that proactive AI deployment achieves **68.2% demand coverage** while reducing flight maneuvers by **36.7%**, conserving critical UAV battery power.
* Implemented an interactive, asynchronous event-driven Command Center in MATLAB Online capable of handling arbitrary numbers of towers, destroyed sites, and UAVs.
* Deployed the entire pipeline to GitHub ([`AzaanGIT/ai-uav-disaster-recovery`](https://github.com/AzaanGIT/ai-uav-disaster-recovery)) with a one-click pre-executed Google Colab notebook.

### 9.2 Future Research Scope
1. **3D Aerial Trajectory & Altitude Optimization:** Dynamically adjusting drone altitudes ($Z$-axis) to balance line-of-sight (LoS) elevation angle probability against free-space path loss.
2. **Energy Harvesting & Tethered Drones:** Incorporating battery recharge cycles, solar-powered drones, or tethered base stations for sustained multi-day operations.
3. **Multi-Agent Reinforcement Learning (MARL):** Implementing decentralized policies (such as MAPPO) for autonomous collision avoidance and distributed drone coordination in GPS-denied environments.
