# 🛰️ AI-Based Dynamic UAV Deployment for Emergency Communication in Disaster Zones

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/AzaanGIT/ai-uav-disaster-recovery/blob/main/ai_uav_disaster_recovery_notebook.ipynb)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An end-to-end framework integrating **Machine Learning spatiotemporal SOS demand forecasting** with an **Asynchronous Event-Driven UAV dispatch and relocation system** to restore emergency communication blackouts following severe physical cell tower destruction.

---

## 📌 Interactive Google Colab Notebook
Click the badge above or use the direct link:  
👉 **[Open in Google Colab](https://colab.research.google.com/github/AzaanGIT/ai-uav-disaster-recovery/blob/main/ai_uav_disaster_recovery_notebook.ipynb)**

The notebook is **fully pre-executed with all output graphs, tables, and metrics rendered**. You can run all cells sequentially to reproduce the model training and UAV deployment benchmarks.

---

## 🚀 Key Results & Highlights

| Metric / Dimension | Baseline (Persistence / Reactive) | AI-Assisted (Random Forest) | Improvement |
|---|:---:|:---:|:---:|
| **RMSE (Error)** | 5.63 | **4.69** | **16.7% Lower Prediction Error** |
| **MAE (Error)** | 4.28 | **3.59** | **16.1% Lower Prediction Error** |
| **Emergency Demand Served** | 39.4% (Fixed) / 67.4% (Reactive) | **68.2%** | **Highest Communication Recovery** |
| **UAV Repositioning Moves** | 98 moves | **62 moves** | **36.7% Flight Energy Conserved** |

---

## 📊 System Architecture

```
+-----------------------------------------------------------------------------------+
|                        PHYSICAL RF DISASTER MODEL                                 |
|   - Log-distance path loss (n = 4.0, fc = 2.4 GHz, Pt = 35 dBm)                   |
|   - Receiver sensitivity threshold: -90 dBm                                       |
|   - Dynamic disaster zones anchored to collapsed tower coordinates                |
+-----------------------------------------------------------------------------------+
                                        │
                                        ▼
+-----------------------------------------------------------------------------------+
|                     MACHINE LEARNING PREDICTION PIPELINE                          |
|   - Features: [sos_t, sos_t1, sos_t2, pop_density, severity, coverage]            |
|   - Model: Random Forest Regressor (100 Bagged Decision Trees)                    |
|   - Target: Foresees upcoming demand at step t+1                                  |
+-----------------------------------------------------------------------------------+
                                        │
                                        ▼
+-----------------------------------------------------------------------------------+
|                   ASYNCHRONOUS EVENT-DRIVEN DISPATCH (MATLAB)                     |
|   - Dispatches UAVs to top priority zones by demand                               |
|   - Individual Relocation: As soon as a zone clears, that drone alone flies       |
|     to the next unserved sector while others remain on-station                    |
|   - Mission Complete: 100% citizen rescue coverage across all sectors             |
+-----------------------------------------------------------------------------------+
```

---

## 🗂️ Repository Structure

* **`ai_uav_disaster_recovery_notebook.ipynb`**: Complete, self-contained Google Colab notebook.
* **`sos_disaster_dataset.csv`**: Feature-engineered disaster dataset (2,982 rows $\times$ 9 features).
* **`raw_sos_demand_matrix.csv`**: Raw time-series demand grid (500 steps $\times$ 6 zones).
* **`AI_UAV_Disaster_Recovery.m`**: Dynamic event-driven MATLAB command center dashboard.
* **`uav_predictions.json`**: AI model predictions synchronized for deployment.
* **`acsprojetlab.md`**: Complete theoretical, mathematical, and simulation report.

---

## 🎓 Academic Affiliation
* **Department:** School of Electronics Engineering (SENSE)
* **Institution:** Vellore Institute of Technology (VIT)
* **Author:** [AzaanGIT](https://github.com/AzaanGIT)
