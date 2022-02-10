---
title: "README"
author: "Joshua Schmidt"
date: "09/02/2022"
output:
  html_document:
    keep_md: true
---



# GRADE cohort simulation and power tests

Some simple functions with usage examples to derive power calculations
of PRS vs outcome, and pr affected across PRS quantiles.


```r
pacman::p_load('data.table',install=T,update = F)
source('R/power_functions.R')
```

## Example: generate a GRADE like data set
This study has recruited ~ 1000 individuals, with ~ population affected
rates 6-10%.

Defining deciles from PRS, the odds ratio for glaucoma in the top 10% versus
bottom 10% is 14.9, or 25 for HTG. We can use the base rate, quantile definiton 
and OR to simulate a dataset.

<table>
 <thead>
  <tr>
   <th style="text-align:right;"> prs </th>
   <th style="text-align:right;"> glaucoma </th>
   <th style="text-align:left;"> label </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 1.3709584 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> top </td>
  </tr>
  <tr>
   <td style="text-align:right;"> -0.5646982 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> middle </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.3631284 </td>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> middle </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.6328626 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> middle </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 0.4042683 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> middle </td>
  </tr>
  <tr>
   <td style="text-align:right;"> -0.1061245 </td>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:left;"> middle </td>
  </tr>
</tbody>
</table>

We can then check prevalence in cohort

<table>
 <thead>
  <tr>
   <th style="text-align:right;"> glaucoma </th>
   <th style="text-align:right;"> N </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 0 </td>
   <td style="text-align:right;"> 954 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:right;"> 46 </td>
  </tr>
</tbody>
</table>

and association between PRS and glaucoma (NB: exp(coefficient) is NOT comparable to 
the quantile OR, by definition!)

<table>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> Estimate </th>
   <th style="text-align:right;"> Std. Error </th>
   <th style="text-align:right;"> z value </th>
   <th style="text-align:right;"> Pr(&gt;|z|) </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> (Intercept) </td>
   <td style="text-align:right;"> -3.2746638 </td>
   <td style="text-align:right;"> 0.1830259 </td>
   <td style="text-align:right;"> -17.891808 </td>
   <td style="text-align:right;"> 0e+00 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> prs </td>
   <td style="text-align:right;"> 0.7694984 </td>
   <td style="text-align:right;"> 0.1570738 </td>
   <td style="text-align:right;"> 4.898962 </td>
   <td style="text-align:right;"> 1e-06 </td>
  </tr>
</tbody>
</table>

likewise can do regression only on the subsets (100 from top, bottom, and middle of PRS distribution)

<table>
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> Estimate </th>
   <th style="text-align:right;"> Std. Error </th>
   <th style="text-align:right;"> z value </th>
   <th style="text-align:right;"> Pr(&gt;|z|) </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> (Intercept) </td>
   <td style="text-align:right;"> -3.1255267 </td>
   <td style="text-align:right;"> 0.3337852 </td>
   <td style="text-align:right;"> -9.363886 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> prs </td>
   <td style="text-align:right;"> 0.6558636 </td>
   <td style="text-align:right;"> 0.2014360 </td>
   <td style="text-align:right;"> 3.255941 </td>
   <td style="text-align:right;"> 0.0011302 </td>
  </tr>
</tbody>
</table>

Finally, lets look at some realised OR



## Power

Now that we can simulate a realistic data set
