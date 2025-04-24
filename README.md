# Water Transfer

## To-do list

- [ ] Check performance measures' baseline in classcification literature
- [x] Remove night light, see if performance drops
  
  There might be data quality issue for night light.
  
  Conclusion: 
  
  - Model performance drop by .01 for the Central line, and the difference is negligible for the Eastern line and the two combined together. 
  
  - Night light does not affect the performance significantly.
  
- [ ] Use historically trained model (before operation) to predict future (after operation)
  - [ ] 0-1 prediction: 3-year average, massive vote.
  - [ ] Maybe by year, so we can see whether there is a trend of increasing deviation.



___

<h3>Prediction after operation</h3>

2025-04-24

Notes about night light: Performance maintains afteral the removing NL. See [Performance_no_NightLight.xlsx](https://github.com/my1396/Water-Transfer/blob/d2967122217802eb69ae7e14d91a39959247efc1/Performance_no_NightLight.xlsx) for detailed performance.

**The main update** is dividing data into periods before and after the water transfer operation. Using data before as trainning data, and predicting water receive for data after.

**Main conclusion**: Model performance drops when we divide by time, which indicates the realationship varies across time. (i.e., the model trained on historical data may not be suitable for predicting future values.) I tried to boost performance by detrending the climate variables and improving probability threshold of predicting `water receive = 0`.  

The performance I achieve is as follows:

| year | accuracy | recall | precision | F1     |
| :--- | :------- | :----- | :-------- | :----- |
| 2014 | 0.7663   | 0.6603 | 0.3627    | 0.4682 |
| 2015 | 0.7489   | 0.6103 | 0.3330    | 0.4309 |
| 2016 | 0.7717   | 0.5603 | 0.3533    | 0.4333 |
| 2017 | 0.7811   | 0.6121 | 0.3757    | 0.4656 |
| 2018 | 0.8378   | 0.4379 | 0.4774    | 0.4568 |
| 2019 | 0.7846   | 0.6155 | 0.3814    | 0.4710 |
| 2020 | 0.8249   | 0.5707 | 0.4510    | 0.5038 |

Side notes about performance drop: The high performance before was based on randomly selected training and testing across time. I tried using time to divide training and testing samples, the model performance drops too.

 

**Data Quality Issue for the central line**: I notice some locations have inconsistent water_receive in 2010. For instance, water receive is 0 in 2010, but 1 in 2011-2020. I noticed this for 452 locations. This would lead to poor performance of the model. Need to be corrected.



___

<h3>Detailed Procedure</h3>

**Eastern line**

- Use before operation (<=2013) as training and after operation (>2013) as testing period.

| year | accuracy | recall | precision | F1     |
| :--- | :------- | :----- | :-------- | :----- |
| 2014 | 0.8480   | 0.0845 | 0.5833    | 0.1476 |
| 2015 | 0.8410   | 0.0517 | 0.4167    | 0.0920 |
| 2016 | 0.8343   | 0.0397 | 0.2771    | 0.0694 |
| 2017 | 0.8396   | 0.0207 | 0.2927    | 0.0386 |
| 2018 | 0.8464   | 0.0862 | 0.5435    | 0.1488 |
| 2019 | 0.8450   | 0.0328 | 0.5429    | 0.0618 |
| 2020 | 0.8426   | 0.0638 | 0.4625    | 0.1121 |

❗️Recall 太低的问题又出现了，model tends to predict 0 too much.

| **Prediction** | **Observation** | 2014 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 |
| :------------: | :-------------: | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
|       0        |        0        | 3108 | 3101 | 3083 | 3114 | 3101 | 3127 | 3100 |
|                |        1        | 531  | 550  | 557  | 568  | 530  | 561  | 543  |
|       1        |        0        | 35   | 42   | 60   | 29   | 42   | 16   | 43   |
|                |        1        | 49   | 30   | 23   | 12   | 50   | 19   | 37   |



**I did two things to improve performance**:

1. <span style='color:#00CC66'>**Detrend climate variables**</span>

<img src="https://drive.google.com/thumbnail?id=1P3IM12VRrIwLHRvuPv1KJSD7e1z3ioOY&sz=w1000" alt="" style="display: block; margin-right: auto; margin-left: auto; zoom:80%;" />

The ideal scenario is there are distinct distribution for water receive or not, no overlapping and low volatility. But we see thre are overlaps between the lower quartiles and the upper quartiles of the distributions. And the climate variables fluctuates.

To make the patterns more distinguishable, I detrend the climate variables. Subtract each year's cross section mean. After centralizing, each year's climate becomes more comprable across time. This is essential as we use historical data to predict future.

<img src="https://drive.google.com/thumbnail?id=1nguC0F4wP0LWUqfyd1fwYcUi9sdkgxeQ&sz=w1000" alt="" style="display: block; margin-right: auto; margin-left: auto; zoom:80%;" />

Performance after detrending climate variables

| year | accuracy | recall | precision | F1     |
| :--- | :------- | :----- | :-------- | :----- |
| 2014 | 0.8528   | 0.3052 | 0.5497    | 0.3925 |
| 2015 | 0.8536   | 0.2310 | 0.5751    | 0.3296 |
| 2016 | 0.8482   | 0.1414 | 0.5503    | 0.2250 |
| 2017 | 0.8603   | 0.2190 | 0.6546    | 0.3282 |
| 2018 | 0.8662   | 0.2310 | 0.7204    | 0.3499 |
| 2019 | 0.8560   | 0.3103 | 0.5696    | 0.4018 |
| 2020 | 0.8697   | 0.2121 | 0.8146    | 0.3365 |

2. <span style='color:#00CC66'>**Improve threoshold of prediction** `water_receive = 0`</span>

The threshold value (0.72) is chosen to maximize F1 score, i.e., when the predited probability of class 0 is larger than 0.72, we classify as 0. This makes the model more conservative in predicting 0 compared to the neural threshold 0.5.

<img src="https://drive.google.com/thumbnail?id=1Ovi2llAEqhixkvjwU7T9xgJV2ex6Bjue&sz=w1000" alt="" style="display: block; margin-right: auto; margin-left: auto; zoom:80%;" />

Performance at threshold being 0.72

| year | accuracy | recall | precision | F1     |
| :--- | :------- | :----- | :-------- | :----- |
| 2014 | 0.7663   | 0.6603 | 0.3627    | 0.4682 |
| 2015 | 0.7489   | 0.6103 | 0.3330    | 0.4309 |
| 2016 | 0.7717   | 0.5603 | 0.3533    | 0.4333 |
| 2017 | 0.7811   | 0.6121 | 0.3757    | 0.4656 |
| 2018 | 0.8378   | 0.4379 | 0.4774    | 0.4568 |
| 2019 | 0.7846   | 0.6155 | 0.3814    | 0.4710 |
| 2020 | 0.8249   | 0.5707 | 0.4510    | 0.5038 |





___

**Improve model performance**

Main Issue: low recall, about 0.5x

Current Status: improved recall, to about 0.8, at the cost of lower precision, about 0.7.

- [x] Deal with data imbalance: 

  Fix: assign class weights, 0-1 water receive or not, to generate balanced training samples.

  Time period: 2010-2020 (all)

  - Eastern: 2010-2013 (inclusive)
  - Central: 2010-2014 (inclusive)

  2025-03-12

  Average performance (average of 10-fold CV) before and after stratified sampling (V1 for before, V2 for after):
  
  |            | accuracy | recall | precision | F1   |
  | ---------- | -------- | ------ | --------- | ---- |
  | Eastern V1 | 0.93     | 0.64   | 0.86      | 0.73 |
  | Eastern V2 | 0.93     | 0.85   | 0.74      | 0.79 |
  | Central V1 | 0.91     | 0.48   | 0.65      | 0.55 |
  | Central V2 | 0.90     | 0.76   | 0.57      | 0.65 |
  | All V1     | 0.91     | 0.52   | 0.78      | 0.62 |
  | All V2     | 0.92     | 0.79   | 0.66      | 0.72 |

  2025-03-19

  After changing the operational year from 2012 to 2013 for Eastern line, performance improves a bit, of a scale .01.

  |            | accuracy | recall | precision | F1   |
  | ---------- | -------- | ------ | --------- | ---- |
  | Eastern V3 | 0.93     | 0.85   | 0.75      | 0.80 |
  
  General standard: accuracy > 0.8, the other three > 0.7.

  **Comment**: improved recall but at the cost of precision, but overall speaking, the F1 score is improved. 
  
  $$F1 = \frac{2\times \text{precision}\times \text{recall}}{\text{precision}+\text{recall}}$$

  <img src="https://drive.google.com/thumbnail?id=18fKUj-dZ7ZLhxPAegyud4Smxqsij8Ahj&sz=w1000" alt="Confusion matrix" style="display: block; margin-right: auto; margin-left: auto; zoom:1-0%;" />

- [ ] Correlation among variables. Dimension reduction by PCA?

  For Random Forest, colinearity is not a problem. $\rightarrow$ Do not need to deal with it for RF.

  - [ ] Remove aridity measures, PDSI, SPEI-12, SC-PDSI, and see how **variable importance** changes

**Other ML models**

- [ ] Gradient Boost
- [ ] Support Vector Machine
- [ ] Neural Network

**Questions to confirm**

- [ ] Whether can merge Easter and Central line





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

2025-03-12 V2: rebalance classes

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

2025-01 V1

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

2025-01 V1

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
