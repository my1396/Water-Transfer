# Water Transfer

To-do list:

- [ ] check performance measures' baseline in classcification literature
- [x] merge eastern and central line; train model using data before 2014 [MY]
- [x] run eastern and central separately [MY]
  - [x] Eastern before and including 2012
  - [x] Central before and including 2014



Issue: False Negative is high due to inbalanced data. Easter: 85% False and 15% True; higher imbalance in Central line (91% False); 

Fix: try to apply class.weights, adjust threshold, etc.



| Location | Number of points              |
| -------- | ----------------------------- |
| Eastern  | 3723 (580 water receive, 15%) |
| Central  | 3893 (338, 9%)                |
| All      | 7616 (918, 12%)               |





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
    <td>Near surface wind speed</td>
    <td>近地表风速</td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>PDSI</td>
    <td></td>
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
    <td>SPEI-12</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td>SC-PDSI</td>
    <td></td>
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
