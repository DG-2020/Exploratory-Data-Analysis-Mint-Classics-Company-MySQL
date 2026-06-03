# ***`Mint Classics Company — Inventory Analysis & Storage Facility Optimisation`***

## ***An exploratory data analysis project using MySQL to support a data-driven business decision on warehouse consolidation.***

## ***`=> Project Overview`***
### *Mint Classics Company is a retailer of classic model cars exploring the possibility of closing one of its storage facilities to reduce operational costs. The core constraint: any restructuring must preserve the ability to fulfil customer orders within 24 hours.*
### *This project uses SQL-based exploratory data analysis on Mint Classics' relational database to surface inventory inefficiencies, identify slow-moving stock, and provide actionable recommendations that balance cost reduction with service continuity.*

## ***`=> Objectives`***
### **-** *Understand how inventory is currently distributed across storage facilities;*
### **-** *Identify the relationship between stock levels and actual sales demand;*
### **-** *Flag slow-moving, overstocked, or obsolete product lines;*
### **-** *Recommend a consolidation strategy that enables warehouse closure without disrupting order fulfilment;*

## ***`=> Tools & Technologies`***
### **`TOOL:`**      *MySQL Workbench*
### **`PURPOSE:`**   *Data Extraction, Database Exploration, Aggregation, Query Development, Data Model Review and Inventory Analysis*

## ***`=> Database & Data Model`***
## *The analysis is conducted on Mint Classics' provided relational database, which includes tables covering:*

### **-** *Products and product lines*
### **-** *Inventory levels per warehouse*
### **-** *Customer orders and order detail*s
### **-** *Employees and offices*

## *The entity-relationship model was reviewed in MySQL Workbench before analysis to understand table relationships and key joins.*
<img width="1200" height="900" alt="MintClassicsDataModel" src="https://github.com/user-attachments/assets/5de2e05f-a002-4da9-9fec-35d727e2314c" />


## ***`=> Analysis Tasks`***
### **`1. Inventory Distribution`**
### **-** *Query which products are stored in which warehouses;*
### **-** *Calculate current stock levels vs. warehouse capacity utilisation;*

### **`2. Sales vs. Inventory Alignment`**
### **-** *Compare quantity-in-stock against historical order volumes;*
### **-** *Identify products where inventory significantly exceeds demand;*

### **`3. Slow-Moving & Obsolete Items`**
### **-** *Detect products with low or zero recent sales activity;*
### **-** *Rank product lines by turnover rate;*

### **`4. Consolidation Feasibility`**
### **-** *Determine whether one warehouse's stock can be redistributed without breaching capacity or fulfilment constraints;*
### **-** *Identify candidate warehouse(s) for closure based on volume and product overlap;*


## ***`=> Expected Outcomes`***
### **-** `Inventory Reduction Targets` — *specific products or product lines where stock can be safely reduced;*
### **-** `Warehouse Closure Recommendation` — *a data-backed candidate facility, supported by redistribution analysis;*
### **-** `Risk Flags` — *any products or categories where reduction would threaten the 24-hour fulfilment SLA;*
### **-** `Strategic Insights` — *patterns in demand, seasonality, or product mix that inform longer-term inventory policy;*
