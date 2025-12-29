# 🌿 FloraBot: Autonomous Bio-Mimetic Plant Agent

![MATLAB](https://img.shields.io/badge/MATLAB-R2023b-orange) ![Robotics](https://img.shields.io/badge/Field-Autonomous_Robotics-blue) ![Status](https://img.shields.io/badge/Status-Thesis_Complete-green)

**FloraBot** is a simulation of an autonomous mobile robotic platform designed to turn passive houseplants into active, "pet-like" companions. By integrating biological data into a robotic control loop, the system gives plants the agency to communicate their needs (water, light) through movement and "emotions," solving the problem of plant neglect due to human alert fatigue.

---

## 🎥 Simulation Demos

### Scenario A: Low Maintenance (Snake Plant)
*The robot remains stoic. It rarely seeks attention, prioritizing battery conservation.*
[Insert GIF or Link to SnakePlant.mp4 here]

### Scenario C: High Stress (Peace Lily)
*The robot enters "Distress Mode" early due to high water consumption. Critically, it prioritizes **Self-Preservation (Charging)** over seeking water when the battery is low.*
[Insert GIF or Link to PeaceLily.mp4 here]

*(Note: Full MP4 simulation runs are available in the `/results` folder.)*

---

## 🧠 System Architecture

The robot operates on a hierarchical **Finite State Machine (FSM)** governed by species-specific biological profiles. It does not run on a simple timer; instead, it simulates a **Metabolic Decay Model** based on the specific plant it is carrying.

### 1. Adaptive Bio-Profiles
The system changes its behavior based on the loaded biological profile:
| Profile | Metabolism ($k$) | Thirst Threshold | Personality |
| :--- | :---: | :---: | :--- |
| **Snake Plant** | $0.5\times$ | 15% | Stoic, Lazy |
| **Golden Pothos** | $1.0\times$ | 30% | Balanced |
| **Peace Lily** | $1.8\times$ | 50% | Needy, Expressive |

### 2. Mathematical Model
**Biological Decay Algorithm:**
Soil moisture $S(t)$ is not linear. It decays based on the species multiplier $k_{species}$ and stochastic environmental factors $\alpha_{env}$:

$$S(t+1) = S(t) - \left( \frac{D_{nom}}{T_{cycle}} \cdot k_{species} \cdot \alpha_{env} \right)$$

**Priority Stack:**
To prevent system failure (dead battery), the FSM enforces strict survival priorities:
1.  🔴 **CRITICAL:** Battery < 20% (Seek Dock immediately)
2.  🔵 **DISTRESS:** Soil < Threshold (Seek Water / Beg)
3.  🌑 **DORMANT:** Night Cycle (Sleep/Conserve Energy)
4.  🟢 **NOMINAL:** Play / Follow Human

---

## 🚀 Getting Started

### Prerequisites
* MATLAB (R2018b or newer recommended)
* No additional toolboxes required (Standard Library only)

### Installation
1.  Clone this repository:
    ```bash
    git clone [https://github.com/YourUsername/FloraBot.git](https://github.com/YourUsername/FloraBot.git)
    ```
2.  Open MATLAB and navigate to the repository folder.

### Running the Simulation
1.  Open `plant_bot_thesis_with_emotions.m`.
2.  Run the script.
3.  Select a profile from the command window:
    ```text
    === AUTONOMOUS PLANT BOT CONFIGURATION ===
    [1] Snake Plant (Low Water)
    [2] Golden Pothos (Medium Water)
    [3] Peace Lily (High Water)
    >> Enter Choice (1-3): 
    ```
4.  The simulation window will open.
    * **Controls:** Press `W` on your keyboard to simulate "Watering" the plant.

---

## 📊 Results Analysis

The system was stress-tested across 72 virtual hours.

### Key Finding: Conflict Resolution
In the **Peace Lily** scenario (Graph below), the Green Line (Battery) recovers *before* the Blue Line (Soil). This proves the robot successfully ignored its "biological" urge to get water in order to save its own life (charge battery), validating the autonomous survival logic.

![Peace Lily Analysis](results/peace_lily_results.png)

---

## 🔮 Future Work
* **Hardware:** Porting the FSM to an **ESP32** microcontroller.
* **Chassis:** 3D printed omni-wheel base with a capacitive soil sensor.
* **Vision:** Integration of `Pixy2` camera for human face tracking.

## ✍️ Author
**Yashwanth Gowda** Master of Applied Engineering (MAE) Thesis Project.

---
*If you find this project interesting, please give it a ⭐!*
