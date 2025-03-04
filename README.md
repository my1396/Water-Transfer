# Water Transfer

## To-do list

- [ ] Check performance measures' baseline in classcification literature

**Improve model performance**

Current issue: low recall

- [ ] Deal with data imbalance: create 1-1 water receive or not
- [ ] Correlation among variables. Dimension reduction by PCA?
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



___

**Variable Importance**

<table><tbody>
  <tr>
    <td>Eastern</td>
    <td><span style='color:red'>Near surface wind speed</span></td>
    <td>近地表风速</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>PDSI</td>
    <td>Palmer drought severity index</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>water stress</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td><span style='color:red'>SPEI-12</span></td>
    <td>standardized precipitation evapotranspiration index, monthly</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td><span style='color:red'>SC-PDSI</span></td>
    <td>self-calibrating Palmer drought severity index</td>
    <td></td>
  </tr>
  <tr>
    <td>Central</td>
    <td>Snowfall</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>Subsurface runoff</td>
    <td>地下径流</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>Solid heat flux</td>
    <td></td>
    <td></td>
  </tr>
</tbody>
</table>

- 重要的变量：干旱指数 (PDSI , SC_PDSI, SPEI)，water stress, 地下径流，风速，降雪，heat flux
- 经济变量都不重要：land use, night light, 排名末位，population 中后段。
