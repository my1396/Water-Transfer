# Water Transfer

## To-do list

- [ ] Check performance measures' baseline in classcification literature

**Improve model performance**

Current issue: low recall

- [ ] Deal with data imbalance: create 1-1 water receive or not

  2025-03-12

  Average performance (average of 10-fold CV) before and after stratified sampling:

  |                | accuracy | recall | precision | F1   |
  | -------------- | -------- | ------ | --------- | ---- |
  | Eastern before | 0.93     | 0.64   | 0.86      | 0.73 |
  | Eastern after  | 0.93     | 0.85   | 0.74      | 0.79 |
  | Central before | 0.91     | 0.48   | 0.65      | 0.55 |
  | Central after  | 0.90     | 0.76   | 0.57      | 0.65 |
  | All before     | 0.91     | 0.52   | 0.78      | 0.62 |
  | All after      | 0.92     | 0.79   | 0.66      | 0.72 |

  **Comment**: improved recall but at the cost of precision, but overall speaking, the F1 score is improved. \
  $$
  F1 = \frac{2\times \text{precision}\times \text{recall}}{\text{precision}+\text{recall}}
  $$
  

  <img src="https://drive.google.com/thumbnail?id=18fKUj-dZ7ZLhxPAegyud4Smxqsij8Ahj&sz=w1000" alt="Confusion matrix" style="display: block; margin-right: auto; margin-left: auto; zoom:1-0%;" />

- [ ] Correlation among variables. Dimension reduction by PCA?

  For Random Forest, colinearity is not a problem. $\rightarrow$ Do not need to deal with it for RF.

  - [ ] Remove aridity measures, PDSI, SPEI-12, SC-PDSI, and see how **variable importance** changes


**Other ML models**

- [ ] Gradient Boost
- [ ] Neural Network

**Questions to confirm**

- [ ] Whether can merge Easter and Central line

**Steps for later**

- [ ] Use historically trained model to predict future, e.g., 2020, or 3-year average.





___

Issue: False Negative is high due to inbalanced data. Easter: 85% False and 15% True; higher imbalance in Central line (91% False); 

Fix: try to apply class.weights, adjust threshold, etc.



| Location | Number of points              |
| -------- | ----------------------------- |
| Eastern  | 3723 (580 water receive, 15%) |
| Central  | 3893 (338 water receive, 9%)  |
| All      | 7616 (918 water receive, 12%) |





___

## Performance Evaluation

### Eastern

2015-01 V1: Random Forest 1st attempt

| group   | accuracy | recall | precision | F1   |
| ------- | -------- | ------ | --------- | ---- |
| G1      | 0.93     | 0.65   | 0.81      | 0.72 |
| G2      | 0.93     | 0.66   | 0.87      | 0.75 |
| G3      | 0.94     | 0.65   | 0.86      | 0.74 |
| G4      | 0.91     | 0.60   | 0.85      | 0.70 |
| G5      | 0.92     | 0.61   | 0.88      | 0.72 |
| G6      | 0.94     | 0.66   | 0.86      | 0.75 |
| G7      | 0.93     | 0.64   | 0.88      | 0.74 |
| G8      | 0.92     | 0.60   | 0.83      | 0.70 |
| G9      | 0.93     | 0.69   | 0.87      | 0.77 |
| G10     | 0.92     | 0.61   | 0.88      | 0.72 |
| Average | 0.93     | 0.64   | 0.86      | 0.73 |

2025-03-12 V2: rebalance class

| group   | accuracy | recall | precision | F1   |
| ------- | -------- | ------ | --------- | ---- |
| G1      | 0.93     | 0.87   | 0.71      | 0.78 |
| G2      | 0.92     | 0.84   | 0.70      | 0.76 |
| G3      | 0.93     | 0.86   | 0.72      | 0.78 |
| G4      | 0.92     | 0.79   | 0.74      | 0.76 |
| G5      | 0.93     | 0.84   | 0.76      | 0.80 |
| G6      | 0.93     | 0.88   | 0.71      | 0.79 |
| G7      | 0.95     | 0.89   | 0.78      | 0.83 |
| G8      | 0.93     | 0.84   | 0.73      | 0.78 |
| G9      | 0.94     | 0.88   | 0.78      | 0.83 |
| G10     | 0.93     | 0.84   | 0.78      | 0.81 |
| Average | 0.93     | 0.85   | 0.74      | 0.79 |

___

### Central

| group   | accuracy | recall | precision | F1   |
| ------- | -------- | ------ | --------- | ---- |
| G1      | 0.90     | 0.40   | 0.65      | 0.50 |
| G2      | 0.91     | 0.50   | 0.63      | 0.56 |
| G3      | 0.92     | 0.47   | 0.73      | 0.57 |
| G4      | 0.92     | 0.53   | 0.67      | 0.59 |
| G5      | 0.91     | 0.50   | 0.67      | 0.57 |
| G6      | 0.91     | 0.50   | 0.67      | 0.57 |
| G7      | 0.90     | 0.42   | 0.60      | 0.49 |
| G8      | 0.91     | 0.52   | 0.64      | 0.57 |
| G9      | 0.90     | 0.42   | 0.58      | 0.48 |
| G10     | 0.91     | 0.53   | 0.69      | 0.60 |
| Average | 0.91     | 0.48   | 0.65      | 0.55 |

2025-03-12 V2

| group   | accuracy | recall | precision | F1   |
| ------- | -------- | ------ | --------- | ---- |
| G1      | 0.91     | 0.74   | 0.60      | 0.66 |
| G2      | 0.90     | 0.79   | 0.55      | 0.65 |
| G3      | 0.91     | 0.75   | 0.60      | 0.67 |
| G4      | 0.90     | 0.78   | 0.55      | 0.65 |
| G5      | 0.91     | 0.77   | 0.57      | 0.65 |
| G6      | 0.90     | 0.77   | 0.56      | 0.65 |
| G7      | 0.89     | 0.71   | 0.54      | 0.61 |
| G8      | 0.90     | 0.78   | 0.53      | 0.63 |
| G9      | 0.90     | 0.73   | 0.55      | 0.62 |
| G10     | 0.91     | 0.80   | 0.62      | 0.70 |
| Average | 0.90     | 0.76   | 0.57      | 0.65 |

___

### All

| group   | accuracy | recall | precision | F1   |
| ------- | -------- | ------ | --------- | ---- |
| G1      | 0.91     | 0.51   | 0.76      | 0.61 |
| G2      | 0.91     | 0.50   | 0.80      | 0.62 |
| G3      | 0.92     | 0.52   | 0.78      | 0.62 |
| G4      | 0.91     | 0.52   | 0.78      | 0.62 |
| G5      | 0.92     | 0.50   | 0.79      | 0.61 |
| G6      | 0.92     | 0.52   | 0.79      | 0.63 |
| G7      | 0.92     | 0.52   | 0.76      | 0.62 |
| G8      | 0.90     | 0.49   | 0.77      | 0.60 |
| G9      | 0.92     | 0.53   | 0.78      | 0.63 |
| G10     | 0.91     | 0.53   | 0.77      | 0.63 |
| Average | 0.91     | 0.52   | 0.78      | 0.62 |

2025-03-12 V2

| group   | accuracy | recall | precision | F1   |
| ------- | -------- | ------ | --------- | ---- |
| G1      | 0.91     | 0.77   | 0.65      | 0.71 |
| G2      | 0.92     | 0.80   | 0.68      | 0.74 |
| G3      | 0.91     | 0.80   | 0.63      | 0.71 |
| G4      | 0.91     | 0.77   | 0.67      | 0.72 |
| G5      | 0.93     | 0.79   | 0.67      | 0.72 |
| G6      | 0.92     | 0.79   | 0.65      | 0.71 |
| G7      | 0.92     | 0.79   | 0.65      | 0.71 |
| G8      | 0.91     | 0.79   | 0.67      | 0.73 |
| G9      | 0.92     | 0.79   | 0.65      | 0.71 |
| G10     | 0.92     | 0.80   | 0.67      | 0.73 |
| Average | 0.92     | 0.79   | 0.66      | 0.72 |

___

**Variable Importance**

<table><tbody>
  <tr>
    <td>Eastern</td>
    <td><span style='color:red'>Near surface wind speed</span></td>
    <td>近地表风速</td>
  </tr>
  <tr>
    <td></td>
    <td>PDSI</td>
    <td>Palmer drought severity index</td>
  </tr>
  <tr>
    <td></td>
    <td>water stress</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td><span style='color:red'>SPEI-12</span></td>
    <td>standardized precipitation evapotranspiration index, monthly</td>
  </tr>
  <tr>
    <td></td>
    <td><span style='color:red'>SC-PDSI</span></td>
    <td>self-calibrating Palmer drought severity index</td>
  </tr>
  <tr>
    <td>Central</td>
    <td>Snowfall</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>Subsurface runoff</td>
    <td>地下径流</td>
  </tr>
  <tr>
    <td></td>
    <td>Solid heat flux</td>
    <td></td>
  </tr>
</tbody>
</table>


- 重要的变量：干旱指数 (PDSI , SC_PDSI, SPEI)，water stress, 地下径流，风速，降雪，heat flux
- 经济变量都不重要：land use, night light, 排名末位，population 中后段。

2025-03-12 V2

<table style="border-collapse: collapse;"><tbody>
  <tr>
    <td><strong>Eastern</strong></td>
    <td>humidity</td>
  </tr>
  <tr>
    <td></td>
    <td>water_stress</td>
  </tr>
  <tr>
    <td></td>
    <td>solid_heat_flux</td>
  </tr>
  <tr>
    <td></td>
    <td>wind_speed</td>
  </tr>
  <tr style="border-bottom: 1pt solid #D3D3D3;">
    <td></td>
    <td>spei</td>
  </tr>
  <tr>
    <td><strong>Central</strong></td>
    <td>wind_speed</td>
  </tr>
  <tr>
    <td></td>
    <td>water_stress</td>
  </tr>
  <tr>
    <td></td>
    <td>radiation</td>
  </tr>
  <tr>
    <td></td>
    <td>soil_temp_10</td>
  </tr>
  <tr style="border-bottom: 1pt solid #D3D3D3;">
    <td></td>
    <td>soil_moisture_10</td>
  </tr>
  <tr>
    <td><strong>All</strong></td>
    <td>wind_speed</td>
  </tr>
  <tr>
    <td></td>
    <td>solid_heat_flux</td>
  </tr>
  <tr>
    <td></td>
    <td>water_stress</td>
  </tr>
  <tr>
    <td></td>
    <td>humidity</td>
  </tr>
  <tr>
    <td></td>
    <td>radiation</td>
  </tr>
</tbody>
</table>
